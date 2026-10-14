using System;
using System.Runtime.InteropServices;
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

    // 退出前等一下，避免进程结束时还来不及把屏幕点亮
    public static void WaitForMonitorWork(int timeoutMs)
    {
        System.Diagnostics.Stopwatch sw = System.Diagnostics.Stopwatch.StartNew();
        while (sw.ElapsedMilliseconds < timeoutMs)
        {
            lock (monitorSync)
            {
                if (!monitorWorkerRunning && !monitorOffPending && !monitorOnPending) return;
            }
            Thread.Sleep(25);
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

    private static IntPtr monitorTarget = IntPtr.Zero;

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

    public static void KeepSystemAwake()
    {
        SetThreadExecutionState(0x80000000u | 0x00000001u);   // ES_CONTINUOUS | ES_SYSTEM_REQUIRED
    }

    public static void ReleaseKeepAwake()
    {
        SetThreadExecutionState(0x80000000u);                 // ES_CONTINUOUS
    }

    // ---------------- idle / last input ----------------
    [StructLayout(LayoutKind.Sequential)]
    private struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }

    [DllImport("user32.dll")]
    private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetLastInputTick()
    {
        LASTINPUTINFO info = new LASTINPUTINFO();
        info.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
        if (!GetLastInputInfo(ref info)) return 0;
        return info.dwTime;
    }

    public static uint GetIdleMilliseconds()
    {
        uint last = GetLastInputTick();
        if (last == 0) return 0;
        uint now = unchecked((uint)Environment.TickCount);
        return unchecked(now - last);
    }

    // ---------------- window z-order / foreground ----------------
    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr lpdwProcessId);
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
        uint fgThread = GetWindowThreadProcessId(fg, IntPtr.Zero);
        bool attached = false;
        if (fgThread != 0 && fgThread != current)
        {
            attached = AttachThreadInput(fgThread, current, true);
        }
        SetForegroundWindow(hWnd);
        if (attached) AttachThreadInput(fgThread, current, false);
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

    // ---------------- console window ----------------
    [DllImport("kernel32.dll")]
    private static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public static void HideConsole()
    {
        IntPtr h = GetConsoleWindow();
        if (h != IntPtr.Zero) ShowWindow(h, 0);
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
    // Win+G 这类真实的视觉泄露路径。只挡这几个组合，其余按键一律放行。
    // 注意：只拦下面这几组组合键，其余按键一律放行。
    public static bool BlockSystemKeys = false;

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
            if (nCode >= 0 && BlockSystemKeys)
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
