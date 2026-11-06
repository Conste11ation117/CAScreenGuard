using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class ScreenLockNative
{
    // ---------------- monitor power ----------------
    // 注意：SC_MONITORPOWER 的广播要在所有顶层窗口上等待，实测最坏可达十几秒，
    //       所以一律丢到后台线程执行，界面永不被阻塞；后发的请求覆盖先发的。
    private const int WM_SYSCOMMAND = 0x0112;
    private const int SC_MONITORPOWER = 0xF170;
    private const uint SMTO_ABORTIFHUNG = 0x0002;
    private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xFFFF);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam,
                                                    uint fuFlags, uint uTimeout, out IntPtr lpdwResult);

    private static readonly object monitorSync = new object();
    private static bool monitorOffPending = false;
    private static bool monitorOnPending = false;
    private static bool monitorWorkerRunning = false;

    public static void MonitorOff()
    {
        lock (monitorSync)
        {
            monitorOffPending = true;
            monitorOnPending = false;
            EnsureMonitorWorker();
        }
    }

    public static void MonitorOn()
    {
        lock (monitorSync)
        {
            monitorOnPending = true;
            monitorOffPending = false;
            EnsureMonitorWorker();
        }
    }

    private static void EnsureMonitorWorker()
    {
        if (monitorWorkerRunning) return;
        monitorWorkerRunning = true;
        Thread t = new Thread(MonitorWorkerLoop);
        t.IsBackground = true;
        t.Start();
    }

    private static void MonitorWorkerLoop()
    {
        while (true)
        {
            bool doOff, doOn;
            lock (monitorSync)
            {
                doOff = monitorOffPending;
                doOn = monitorOnPending;
                monitorOffPending = false;
                monitorOnPending = false;
                if (!doOff && !doOn)
                {
                    monitorWorkerRunning = false;
                    return;
                }
            }
            if (doOff) BroadcastMonitorPower(2);
            else if (doOn) BroadcastMonitorPower(-1);
        }
    }

    private static volatile IntPtr monitorTarget = IntPtr.Zero;   // UI 线程写，投递线程读

    // 关屏/亮屏消息的投递目标：只发给我们自己的那一个窗口。
    // 不要用 HWND_BROADCAST —— 广播会被每个顶层窗口各处理一份，
    // 实测会让关屏动作在数秒内反复落地（屏幕每秒抖一次），
    // 并且可能在用户唤醒屏幕之后又被一份迟到的"关屏"打灭。
    public static IntPtr TargetWindow
    {
        get { return monitorTarget; }
        set { monitorTarget = value; }
    }

    private static void BroadcastMonitorPower(int power)
    {
        try
        {
            IntPtr result;
            IntPtr target = monitorTarget;
            if (target == IntPtr.Zero) target = HWND_BROADCAST;   // 兜底：没有可用目标窗口时才广播
            SendMessageTimeout(target, WM_SYSCOMMAND, new IntPtr(SC_MONITORPOWER), new IntPtr(power),
                               SMTO_ABORTIFHUNG, 1000, out result);
        }
        catch { }
    }

    // ---------------- keep the machine awake ----------------
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint SetThreadExecutionState(uint esFlags);
    [DllImport("kernel32.dll", EntryPoint = "SetLastError")]
    private static extern void SetLastErrorNative(uint dwErrCode);

    private const uint ES_CONTINUOUS = 0x80000000u;
    private const uint ES_SYSTEM_REQUIRED = 0x00000001u;

    // ES_SYSTEM_REQUIRED 只是"重置系统空闲计时器"，而且按线程生效。Modern Standby (S0) 上息屏之后，
    // 光靠它挡不住系统进低功耗、也挡不住"在此时间后休眠"到期，桌面进程还会被挂起。
    // 所以另外挂一个进程级电源请求（句柄级、不绑线程）：SystemRequired 要求系统别睡，
    // ExecutionRequired 要求别把本进程挂起。两者都不含 DisplayRequired，屏幕照熄。
    [StructLayout(LayoutKind.Sequential)]
    private struct REASON_CONTEXT_DETAILED
    {
        public IntPtr LocalizedReasonModule;
        public uint LocalizedReasonId;
        public uint ReasonStringCount;
        public IntPtr ReasonStrings;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct REASON_CONTEXT
    {
        [FieldOffset(0)] public uint Version;
        [FieldOffset(4)] public uint Flags;
        [FieldOffset(8)] public REASON_CONTEXT_DETAILED Detailed;
        [FieldOffset(8)] public IntPtr SimpleReasonString;   // union：与 Detailed 共用同一块内存
    }

    private const uint POWER_REQUEST_CONTEXT_VERSION = 0;
    private const uint POWER_REQUEST_CONTEXT_SIMPLE_STRING = 1;
    private const int PowerRequestSystemRequired = 1;
    private const int PowerRequestExecutionRequired = 3;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr PowerCreateRequest(ref REASON_CONTEXT Context);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool PowerSetRequest(IntPtr PowerRequest, int RequestType);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool PowerClearRequest(IntPtr PowerRequest, int RequestType);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);

    private static readonly object awakeSync = new object();
    private static IntPtr powerRequest = IntPtr.Zero;
    private static IntPtr reasonString = IntPtr.Zero;
    private static int systemRequests = 0;
    private static int executionRequests = 0;

    private static bool IsValidRequestHandle(IntPtr h)
    {
        return h != IntPtr.Zero && h != new IntPtr(-1);
    }

    private static void ClearPowerRequest()
    {
        try
        {
            if (IsValidRequestHandle(powerRequest))
            {
                while (systemRequests > 0) { PowerClearRequest(powerRequest, PowerRequestSystemRequired); systemRequests--; }
                while (executionRequests > 0) { PowerClearRequest(powerRequest, PowerRequestExecutionRequired); executionRequests--; }
                CloseHandle(powerRequest);
            }
        }
        catch { }
        powerRequest = IntPtr.Zero;
        systemRequests = 0;
        executionRequests = 0;
        if (reasonString != IntPtr.Zero)
        {
            try { Marshal.FreeHGlobal(reasonString); } catch { }
            reasonString = IntPtr.Zero;
        }
    }

    // 每次重发都重建：睡眠/休眠会作废旧请求，Modern Standby + 电池供电还会在睡眠超时
    // 5 分钟后终止 System/Execution 请求，重建才能续上。引用计数始终是 0 或 1。
    private static bool EnsurePowerRequest()
    {
        ClearPowerRequest();
        try
        {
            REASON_CONTEXT ctx = new REASON_CONTEXT();
            ctx.Version = POWER_REQUEST_CONTEXT_VERSION;
            ctx.Flags = POWER_REQUEST_CONTEXT_SIMPLE_STRING;
            reasonString = Marshal.StringToHGlobalUni("CAScreenGuard is keeping long-running work alive while the screen is off");
            ctx.SimpleReasonString = reasonString;
            IntPtr h = PowerCreateRequest(ref ctx);
            if (!IsValidRequestHandle(h)) { ClearPowerRequest(); return false; }
            powerRequest = h;
            if (PowerSetRequest(h, PowerRequestSystemRequired)) systemRequests++;
            if (PowerSetRequest(h, PowerRequestExecutionRequired)) executionRequests++;
            // ExecutionRequired 是 Win8 才有的类型，老系统上拿不到不算失败
            return systemRequests > 0;
        }
        catch { ClearPowerRequest(); return false; }
    }

    // 返回值表示"进程级电源请求是否建立"。STES 每次仍重发，作为老系统上的兜底：
    // 它成功时返回上一次的状态，首次成功也可能是 0，不能拿返回值直接判成败。
    public static bool KeepSystemAwake()
    {
        SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED);
        lock (awakeSync) { return EnsurePowerRequest(); }
    }

    public static bool ReleaseKeepAwake()
    {
        SetLastErrorNative(0);
        uint prev = SetThreadExecutionState(ES_CONTINUOUS);
        bool threadOk = (prev != 0) || (Marshal.GetLastWin32Error() == 0);
        lock (awakeSync) { ClearPowerRequest(); }
        return threadOk;
    }

    // ---------------- 电源方案：睡眠 / 休眠超时 ----------------
    // 只改活动方案 SUB_SLEEP 下的两个设置（AC / DC 各一份），不改电源方案本身，也不需要提权。
    // 调用方必须先把原值落盘，退出或崩溃后靠那份文件还原；失败一律返回 false，让调用方降级。
    private static readonly Guid SUB_SLEEP_GUID = new Guid("238c9fa8-0aad-41ed-83f4-97be242c8f20");
    private static readonly Guid STANDBYIDLE_GUID = new Guid("29f6c1db-86da-48c5-9fdb-f2b67b1f44da");
    private static readonly Guid HIBERNATEIDLE_GUID = new Guid("9d7815a6-7ee4-497e-8888-515a05f02364");

    [DllImport("powrprof.dll")]
    private static extern uint PowerGetActiveScheme(IntPtr UserRootPowerKey, out IntPtr ActivePolicyGuid);
    [DllImport("powrprof.dll")]
    private static extern uint PowerReadACValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupGuid, ref Guid SettingGuid, out uint Value);
    [DllImport("powrprof.dll")]
    private static extern uint PowerReadDCValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupGuid, ref Guid SettingGuid, out uint Value);
    [DllImport("powrprof.dll")]
    private static extern uint PowerWriteACValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupGuid, ref Guid SettingGuid, uint Value);
    [DllImport("powrprof.dll")]
    private static extern uint PowerWriteDCValueIndex(IntPtr RootPowerKey, ref Guid SchemeGuid, ref Guid SubGroupGuid, ref Guid SettingGuid, uint Value);
    [DllImport("powrprof.dll")]
    private static extern uint PowerSetActiveScheme(IntPtr UserRootPowerKey, ref Guid SchemeGuid);
    [DllImport("kernel32.dll")]
    private static extern IntPtr LocalFree(IntPtr hMem);

    private static Guid ActiveSchemeGuid()
    {
        IntPtr p = IntPtr.Zero;
        try
        {
            if (PowerGetActiveScheme(IntPtr.Zero, out p) != 0 || p == IntPtr.Zero) return Guid.Empty;
            return (Guid)Marshal.PtrToStructure(p, typeof(Guid));
        }
        catch { return Guid.Empty; }
        finally { if (p != IntPtr.Zero) LocalFree(p); }
    }

    // 快照格式：方案GUID,AC睡眠秒,DC睡眠秒,AC休眠秒,DC休眠秒。读不到返回 null。
    public static string GetPowerTimeoutSnapshot()
    {
        try
        {
            Guid scheme = ActiveSchemeGuid();
            if (scheme == Guid.Empty) return null;
            Guid sub = SUB_SLEEP_GUID, st = STANDBYIDLE_GUID, hi = HIBERNATEIDLE_GUID;
            uint sac, sdc, hac, hdc;
            if (PowerReadACValueIndex(IntPtr.Zero, ref scheme, ref sub, ref st, out sac) != 0) return null;
            if (PowerReadDCValueIndex(IntPtr.Zero, ref scheme, ref sub, ref st, out sdc) != 0) return null;
            if (PowerReadACValueIndex(IntPtr.Zero, ref scheme, ref sub, ref hi, out hac) != 0) return null;
            if (PowerReadDCValueIndex(IntPtr.Zero, ref scheme, ref sub, ref hi, out hdc) != 0) return null;
            return scheme.ToString("D") + "," + sac + "," + sdc + "," + hac + "," + hdc;
        }
        catch { return null; }
    }

    private static bool WriteTimeouts(Guid scheme, uint sac, uint sdc, uint hac, uint hdc)
    {
        Guid sub = SUB_SLEEP_GUID, st = STANDBYIDLE_GUID, hi = HIBERNATEIDLE_GUID;
        bool ok = true;
        if (PowerWriteACValueIndex(IntPtr.Zero, ref scheme, ref sub, ref st, sac) != 0) ok = false;
        if (PowerWriteDCValueIndex(IntPtr.Zero, ref scheme, ref sub, ref st, sdc) != 0) ok = false;
        if (PowerWriteACValueIndex(IntPtr.Zero, ref scheme, ref sub, ref hi, hac) != 0) ok = false;
        if (PowerWriteDCValueIndex(IntPtr.Zero, ref scheme, ref sub, ref hi, hdc) != 0) ok = false;
        // 只在该方案仍活动时刷新；用户中途换了方案就不要把他切回来
        Guid active = ActiveSchemeGuid();
        if (active == scheme && PowerSetActiveScheme(IntPtr.Zero, ref scheme) != 0) ok = false;
        return ok;
    }

    private static string[] ParseSnapshot(string snapshot)
    {
        if (string.IsNullOrEmpty(snapshot)) return null;
        string[] p = snapshot.Split(',');
        if (p.Length != 5) return null;
        try
        {
            Guid g = new Guid(p[0]);
            if (g == Guid.Empty) return null;
            uint v;
            for (int i = 1; i < 5; i++) { if (!uint.TryParse(p[i], out v)) return null; }
            return p;
        }
        catch { return null; }
    }

    // 临时把四项超时置 0（从不），只改快照里记下的那个方案。
    public static bool DisablePowerTimeouts(string snapshot)
    {
        string[] p = ParseSnapshot(snapshot);
        if (p == null) return false;
        try { return WriteTimeouts(new Guid(p[0]), 0, 0, 0, 0); }
        catch { return false; }
    }

    // 把快照里的四个值写回原方案；失败时调用方要保留备份文件，下次启动再补。
    public static bool RestorePowerTimeouts(string snapshot)
    {
        string[] p = ParseSnapshot(snapshot);
        if (p == null) return false;
        try { return WriteTimeouts(new Guid(p[0]), uint.Parse(p[1]), uint.Parse(p[2]), uint.Parse(p[3]), uint.Parse(p[4])); }
        catch { return false; }
    }

    // ---------------- 隐藏窗口跑一个命令并收下输出 ----------------
    // 只用来读 Wi-Fi 信号（netsh wlan show interfaces）。产品是 winexe，直接 & netsh 会闪一下
    // 控制台窗口；CreateNoWindow + 重定向既没有窗口也不会挂住（有 5 秒上限）。
    public static string RunHidden(string exePath, string arguments)
    {
        try
        {
            System.Diagnostics.ProcessStartInfo psi = new System.Diagnostics.ProcessStartInfo(exePath, arguments);
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            using (System.Diagnostics.Process p = System.Diagnostics.Process.Start(psi))
            {
                string output = p.StandardOutput.ReadToEnd();
                p.StandardError.ReadToEnd();       // 不读完的话管道可能把子进程卡住
                if (!p.WaitForExit(5000)) { try { p.Kill(); } catch { } return ""; }
                return output;
            }
        }
        catch { return ""; }
    }

    // ---------------- idle / last input ----------------
    [StructLayout(LayoutKind.Sequential)]
    private struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }

    [DllImport("user32.dll")]
    private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    // 失败时返回 uint.MaxValue 而不是 0：0 是合法 tick（刚开机那一瞬），
    // 而且主脚本里 $script:BlankTick 的初值也是 0，两者撞上会让"用户动没动过"的判断失灵。
    public static uint GetLastInputTick()
    {
        LASTINPUTINFO info = new LASTINPUTINFO();
        info.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
        if (!GetLastInputInfo(ref info)) return uint.MaxValue;
        return info.dwTime;
    }

    public static uint GetIdleMilliseconds()
    {
        uint last = GetLastInputTick();
        if (last == 0 || last == uint.MaxValue) return 0;
        uint now = unchecked((uint)Environment.TickCount);
        return unchecked(now - last);
    }

    // ---------------- window z-order / foreground ----------------
    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();
    // 第二个参数是"可选的进程 ID 出参"：这里只需要线程 ID，所以统一传一个丢弃用的变量，
    // 不能再传 IntPtr.Zero —— 那是 8 字节，而 API 要的是一个指向 DWORD 的指针。
    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    private static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_NOMOVE = 0x0002;
    private const uint SWP_NOACTIVATE = 0x0010;
    private const uint SWP_SHOWWINDOW = 0x0040;

    public static IntPtr ForegroundWindow { get { return GetForegroundWindow(); } }

    public static void ReassertTopMost(IntPtr hWnd)
    {
        if (hWnd == IntPtr.Zero) return;
        SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
    }

    public static void ForceForeground(IntPtr hWnd)
    {
        if (hWnd == IntPtr.Zero) return;
        IntPtr fg = GetForegroundWindow();
        if (fg == hWnd) return;
        uint current = GetCurrentThreadId();
        uint ignoredProcessId;
        uint fgThread = GetWindowThreadProcessId(fg, out ignoredProcessId);
        bool attached = false;
        if (fgThread != 0 && fgThread != current)
        {
            attached = AttachThreadInput(fgThread, current, true);
        }
        try
        {
            SetForegroundWindow(hWnd);
        }
        finally
        {
            // 一定要摘掉：SetForegroundWindow 万一抛异常，本线程会和前台的输入队列一直挂着
            if (attached) AttachThreadInput(fgThread, current, false);
        }
    }

    // ---------------- screen saver ----------------
    private const uint SPI_GETSCREENSAVEACTIVE = 0x0010;
    private const uint SPI_SETSCREENSAVEACTIVE = 0x0011;

    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfoW")]
    private static extern bool SystemParametersInfoGet(uint uiAction, uint uiParam, ref int pvParam, uint fWinIni);
    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfoW")]
    private static extern bool SystemParametersInfoSet(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

    public static int GetScreenSaverActive()
    {
        int value = 0;
        SystemParametersInfoGet(SPI_GETSCREENSAVEACTIVE, 0, ref value, 0);
        return value;
    }

    public static void SetScreenSaverActive(bool active)
    {
        SystemParametersInfoSet(SPI_SETSCREENSAVEACTIVE, active ? 1u : 0u, IntPtr.Zero, 0);
    }

    // ---------------- desktop wallpaper ----------------
    // 遮罩背景想用系统壁纸时，先问系统要当前壁纸的文件路径。
    // 注意：幻灯片、跨屏拼接等模式下这个路径可能指向一个临时/不存在的文件，
    //       调用方拿不到图时应当退回纯黑，别在这里抛。
    private const uint SPI_GETDESKWALLPAPER = 0x0073;

    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfoW", CharSet = CharSet.Unicode)]
    private static extern bool SystemParametersInfoGetString(uint uiAction, uint uiParam, StringBuilder pvParam, uint fWinIni);

    public static string GetDesktopWallpaperPath()
    {
        try
        {
            StringBuilder sb = new StringBuilder(1024);
            if (!SystemParametersInfoGetString(SPI_GETDESKWALLPAPER, (uint)sb.Capacity, sb, 0)) return null;
            string path = sb.ToString();
            return string.IsNullOrEmpty(path) ? null : path;
        }
        catch { return null; }
    }

    // ---------------- IME ----------------
    [DllImport("imm32.dll")]
    private static extern IntPtr ImmAssociateContext(IntPtr hWnd, IntPtr hIMC);

    public static void DisableIme(IntPtr hWnd)
    {
        if (hWnd != IntPtr.Zero) ImmAssociateContext(hWnd, IntPtr.Zero);
    }

    // ---------------- low level keyboard hook ----------------
    // 锁屏期间吞掉 Win / Alt+Tab / Alt+Esc / Ctrl+Esc：堵住开始菜单、窗口缩略图、
    // Win+G 这类真实的视觉泄露路径。只挡这几组，其余按键一律放行。
    public static volatile bool BlockSystemKeys = false;   // UI 线程写，钩子回调线程读

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_KEYUP = 0x0101;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int WM_SYSKEYUP = 0x0105;
    private const int VK_TAB = 0x09;
    private const int VK_ESCAPE = 0x1B;
    private const int VK_MENU = 0x12;
    private const int VK_CONTROL = 0x11;
    private const int VK_LWIN = 0x5B;
    private const int VK_RWIN = 0x5C;

    private static IntPtr keyboardHook = IntPtr.Zero;
    private static LowLevelKeyboardProc keyboardProcRef = null;   // 必须保持引用，否则委托被 GC 回收后钩子失效

    public static bool InstallKeyboardHook()
    {
        if (keyboardHook != IntPtr.Zero) return true;
        keyboardProcRef = HookCallback;
        keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, keyboardProcRef, IntPtr.Zero, 0);
        return (keyboardHook != IntPtr.Zero);
    }

    public static void RemoveKeyboardHook()
    {
        if (keyboardHook != IntPtr.Zero)
        {
            UnhookWindowsHookEx(keyboardHook);
            keyboardHook = IntPtr.Zero;
        }
        keyboardProcRef = null;
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        try
        {
            if (nCode >= 0 && BlockSystemKeys && lParam != IntPtr.Zero)
            {
                int msg = wParam.ToInt32();
                if (msg == WM_KEYDOWN || msg == WM_KEYUP || msg == WM_SYSKEYDOWN || msg == WM_SYSKEYUP)
                {
                    KBDLLHOOKSTRUCT info = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
                    int vk = (int)info.vkCode;
                    bool altDown = ((GetAsyncKeyState(VK_MENU) & 0x8000) != 0);
                    bool ctrlDown = ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0);
                    if (vk == VK_LWIN || vk == VK_RWIN) return new IntPtr(1);
                    if (vk == VK_TAB && altDown) return new IntPtr(1);
                    if (vk == VK_ESCAPE && (altDown || ctrlDown)) return new IntPtr(1);
                }
            }
        }
        catch { }
        return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
    }
}
