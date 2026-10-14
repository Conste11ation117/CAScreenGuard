using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;
using Microsoft.Win32;

// 安装器界面文案：中英两套，S("键") 取当前语言
public static class Str
{
    public static string Lang = "zh";   // 中文系统默认中文，其余默认英文（欢迎页可切换）
    static readonly System.Collections.Generic.Dictionary<string, string> ZH = new System.Collections.Generic.Dictionary<string, string>
    {
        { "k01", "ERROR: 参数不足" },
        { "k02", "上一次的安装没能删干净，可能 CAScreenGuard 还在运行中：\n" },
        { "k03", "\n\n请先解锁、退出 CAScreenGuard（或者重启一次），再重新安装。" },
        { "k04", "这个位置里已经有同名的安装文件夹了：\n" },
        { "k05", "\n\n请换一个安装位置，或者先把那个文件夹删掉，再重新安装。" },
        { "k06", " · 一键息屏保护" },
        { "k07", "桌面已创建快捷方式「" },
        { "k08", "」，按 " },
        { "k09", " 可以随时启动。\n\n" },
        { "k10", "桌面已创建快捷方式「" },
        { "k11", "这次没有创建桌面快捷方式。\n\n" },
        { "k12", "安装完成。\n\n安装位置：" },
        { "k13", "授权码是忘记解锁密码时唯一的凭据，安装后不能再改，请连同提示一起牢记。" },
        { "k14", "要卸载 CAScreenGuard 吗？\n\n程序文件、配置、外部凭证、桌面快捷方式都会删除，安装文件夹本身也会一并删掉。" },
        { "k15", " · 卸载" },
        { "k16", "已删除外部凭证与桌面快捷方式。" },
        { "k17", "\n\n整个安装文件夹也会一起删掉：\n" },
        { "k18", " · 卸载完成" },
        { "k19", "安装 " },
        { "k20", "安装 " },
        { "k21", "安装后会创建桌面快捷方式；点击它就能熄屏并锁定，只有输入解锁密码才能恢复屏幕。" },
        { "k22", "填写要求：解锁密码至少 4 位；授权码至少 6 位，且不能和解锁密码相同。" },
        { "k23", "两者都区分大小写，只能用英文、数字和符号（不能用空格和中文）。" },
        { "k24", "装到哪里" },
        { "k25", "浏览…" },
        { "k26", "解锁密码（至少 4 位）" },
        { "k27", "再输一遍密码" },
        { "k28", "授权码（至少 6 位）" },
        { "k29", "再输一遍授权码" },
        { "k30", "授权码提示" },
        { "k31", "快捷键" },
        { "k32", "在桌面创建快捷方式" },
        { "k33", "授权码仅在忘记解锁密码时使用，安装后不能再改，请连同提示一起牢记。" },
        { "k34", "安装" },
        { "k35", "取消" },
        { "k36", "没有快捷方式，就没有快捷键" },
        { "k37", "留空 = 不要快捷键（以后也能在快捷方式属性里改）" },
        { "k38", "任何地方按 Ctrl + Alt + " },
        { "k39", " 都能启动" },
        { "k40", "会装到：请先选一个位置" },
        { "k41", "会装到：（这个路径看着不太对）" },
        { "k42", "会装到：" },
        { "k43", "　（这个文件夹已经有了，得换一个位置）" },
        { "k44", "　（本机已经装过：会先把上一次的那一份整个删掉，再装这个新的）" },
        { "k45", "会装到：" },
        { "k46", "选择装到哪里（程序会在这里新建一个自己的子文件夹）" },
        { "k47", "请先选择要装到哪里。" },
        { "k48", "解锁密码至少需要 4 个字符。" },
        { "k49", "解锁密码只能用英文、数字和符号，不能用空格和中文。" },
        { "k50", "两次输入的解锁密码不一致，请重新输入。" },
        { "k51", "授权码至少需要 6 个字符。" },
        { "k52", "授权码只能用英文、数字和符号，不能用空格和中文。" },
        { "k53", "两次输入的授权码不一致，请重新输入。" },
        { "k54", "授权码不能和解锁密码相同。" },
        { "k55", "请填写授权码提示。忘记解锁密码时，只能靠它回忆。" },
        { "k56", "快捷键只能填一个字母或数字，例如 L。" },
        { "k57", "这个路径不能用来安装，请换一个文件夹。" },
        { "k58", "这里已经有「" },
        { "k59", "」了：请换一个位置，或者先把它删掉。" },
        { "k60", "没有权限往这个位置写文件。请换一个文件夹，或者用默认位置。" },
        { "k61", "写入安装文件时出错：" },
        { "k62", "安装失败：" },
        { "k63", "安装 " },
        { "k64", "注意：部分杀毒软件可能对本程序报警。已实测：360 会给出提示但不会判定为病毒，Windows Defender 完全放行。如果你信任本软件，建议把它加入杀毒软件的信任目录／白名单，否则安装或运行时可能被拦截。" },
        { "k65", "查看说明文档（README）" },
        { "k66", "界面语言" },
        { "k67", "下一步" },
        { "k68", "CAScreenGuard 会在你离开时替你看着屏幕：只关显示器（不休眠、不锁定 Windows 会话、保持系统唤醒），最上层盖一层全屏黑幕挡住桌面内容，只有输对解锁密码才会恢复。它不是安全边界，只防「路过的人随手看一眼」，详细说明见 README。" },
        { "k69", "欢迎" },
        { "k70", "上一页" },
        { "k71", "请只使用本程序提供的卸载程序卸载，不要使用第三方管理程序卸载，否则可能导致系统关键组件缺失。" },
        { "k72", "正在安装：可能需要 3~10 秒，请耐心等待，不要关闭这个窗口。" },    };
    static readonly System.Collections.Generic.Dictionary<string, string> EN = new System.Collections.Generic.Dictionary<string, string>
    {
        { "k01", "ERROR: missing arguments" },
        { "k02", "The previous installation could not be removed completely; CAScreenGuard may still be running:\n" },
        { "k03", "\n\nPlease unlock and quit CAScreenGuard (or restart once), then install again." },
        { "k04", "There is already an installation folder with the same name here:\n" },
        { "k05", "\n\nPlease choose another location, or delete that folder first and install again." },
        { "k06", " · one-click screen guard" },
        { "k07", "Desktop shortcut “" },
        { "k08", "” created. Press " },
        { "k09", " to launch it from anywhere.\n\n" },
        { "k10", "Desktop shortcut “" },
        { "k11", "No desktop shortcut was created this time.\n\n" },
        { "k12", "Installation complete.\n\nInstalled to: " },
        { "k13", "The authorization code is the only way back if you forget the unlock password; it cannot be changed after installation, so keep it and the hint safe." },
        { "k14", "Uninstall CAScreenGuard?\n\nProgram files, configuration, external credentials and the desktop shortcut will be deleted, and the installation folder itself will be removed as well." },
        { "k15", " · Uninstall" },
        { "k16", "External credentials and the desktop shortcut have been deleted." },
        { "k17", "\n\nThe whole installation folder will be removed as well:\n" },
        { "k18", " · Uninstall complete" },
        { "k19", "Install " },
        { "k20", "Install " },
        { "k21", "A desktop shortcut will be created; click it to blank the screen and lock it — only the unlock password brings it back." },
        { "k22", "Requirements: unlock password at least 4 chars; authorization code at least 6 chars and different from the password." },
        { "k23", " Both are case-sensitive and may only use ASCII letters, digits and symbols (no spaces, no non-ASCII)." },
        { "k24", "Install where" },
        { "k25", "Browse…" },
        { "k26", "Unlock password ≥4" },
        { "k27", "Repeat password" },
        { "k28", "Authorization code ≥6" },
        { "k29", "Repeat code" },
        { "k30", "Authorization hint" },
        { "k31", "Hotkey" },
        { "k32", "Create a desktop shortcut" },
        { "k33", "The authorization code is only used when you forget the unlock password and cannot be changed later — keep it and the hint safe." },
        { "k34", "Install" },
        { "k35", "Cancel" },
        { "k36", "No shortcut, no hotkey" },
        { "k37", "Leave empty = no hotkey (you can change it later in the shortcut properties)" },
        { "k38", "Press Ctrl + Alt + " },
        { "k39", " to launch it from anywhere" },
        { "k40", "Will install to: choose a location first" },
        { "k41", "Will install to: (that path does not look right)" },
        { "k42", "Will install to: " },
        { "k43", " (that folder already exists, pick another location)" },
        { "k44", " (already installed here: the previous copy will be removed first)" },
        { "k45", "Will install to: " },
        { "k46", "Choose where to install (the program creates its own sub-folder there)" },
        { "k47", "Please choose where to install first." },
        { "k48", "The unlock password needs at least 4 characters." },
        { "k49", "The unlock password may only use ASCII letters, digits and symbols — no spaces, no non-ASCII." },
        { "k50", "The two passwords do not match, please retype." },
        { "k51", "The authorization code needs at least 6 characters." },
        { "k52", "The authorization code may only use ASCII letters, digits and symbols — no spaces, no non-ASCII." },
        { "k53", "The two codes do not match, please retype." },
        { "k54", "The authorization code must differ from the unlock password." },
        { "k55", "Please fill in the authorization hint — it is the only reminder if you forget the unlock password." },
        { "k56", "The hotkey must be a single letter or digit, for example L." },
        { "k57", "That path cannot be used for installation, please pick another folder." },
        { "k58", "There is already “" },
        { "k59", "” here: pick another location, or delete it first." },
        { "k60", "No permission to write there. Please pick another folder, or use the default location." },
        { "k61", "Error while writing the installation files: " },
        { "k62", "Installation failed: " },
        { "k63", "Install " },
        { "k64", "Note: some antivirus products may warn about this program. Measured: 360 shows a prompt but does not classify it as a virus; Windows Defender passes it completely. If you trust this software, add it to your antivirus whitelist — otherwise the installer or the program may be blocked." },
        { "k65", "Open the README" },
        { "k66", "Language" },
        { "k67", "Next" },
        { "k68", "CAScreenGuard watches the screen while you are away: it turns the monitor off (no sleep, no session lock, the machine stays awake) and covers the desktop with a full-screen mask. Only the unlock password brings it back. It is not a security boundary — it stops a passer-by from glancing at your screen. See the README for details." },
        { "k69", "Welcome" },
        { "k70", "Back" },
        { "k71", "Please uninstall only with the uninstaller provided by this program. Do not remove it with third-party uninstall managers, or key system components may end up missing." },
        { "k72", "Installing: this may take 3-10 seconds. Please wait and do not close this window." },    };
    public static string S(string key)
    {
        var d = (Lang == "en") ? EN : ZH;
        string v;
        return d.TryGetValue(key, out v) ? v : ZH[key];
    }
    // 跟随系统语言定初值（中文系统用中文，其余用英文）
    public static void Detect()
    {
        try { if (!System.Globalization.CultureInfo.CurrentUICulture.Name.StartsWith("zh")) Lang = "en"; } catch { }
    }
}

public class CAScreenGuardInstaller
{
    // ---------- 载荷（由构建脚本注入，base64） ----------
    const string PAYLOAD_PS1 = "{PAYLOAD_PS1}";
    internal const string PAYLOAD_ICO = "{PAYLOAD_ICO}";
    const string PAYLOAD_EARLY = "{PAYLOAD_EARLY}";
    const string PAYLOAD_NATIVE = "{PAYLOAD_NATIVE}";

    internal const string ScriptLeaf = "CAScreenGuard.ps1";
    internal const string IconLeaf = "CAScreenGuard.ico";
    internal const string EarlyLeaf = "ScreenLockEarly.cs";
    internal const string NativeLeaf = "ScreenLockNative.cs";
    internal const string LnkLeaf = "CAScreenGuard.lnk";
    internal const string AppName = "CAScreenGuard";
    internal const string AppVersion = "V1.0.0";
    const string CfgLeaf = ".cascreenguard.config.json";
    const string StoreKey = @"Software\CAScreenGuard";
    const string UninstallKey = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\CAScreenGuard";

    internal static string DefaultDir
    {
        get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CAScreenGuard"); }
    }

    // 每次安装都在用户选定的位置里新建这么一个子文件夹：位置唯一，卸载时整棵删掉也安全
    internal static string SubFolderName
    {
        get { return AppName + "-" + DateTime.Now.ToString("yyyy-MM-dd"); }
    }
    static string MirrorDir
    {
        get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "CAScreenGuard"); }
    }
    static string MirrorPath { get { return Path.Combine(MirrorDir, "store.json"); } }
    static string DesktopDir { get { return Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory); } }
    static string SystemDir { get { return Environment.GetFolderPath(Environment.SpecialFolder.System); } }

    [DllImport("user32.dll")]
    static extern bool SetProcessDPIAware();

    [STAThread]
    public static void Main(string[] args)
    {
        try { SetProcessDPIAware(); } catch { }
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        if (args.Length > 0 && args[0].Equals("/uninstall", StringComparison.OrdinalIgnoreCase))
        {
            bool silent = args.Length > 1 && args[1].Equals("/quiet", StringComparison.OrdinalIgnoreCase);
            DoUninstall(silent);
            return;
        }
        if (args.Length > 0 && args[0].Equals("/silent", StringComparison.OrdinalIgnoreCase))
        {
            // /silent <装到哪里> <解锁密码> <授权码> <提示> [nolink] [快捷键字母，空=不要]
            string msg;
            if (args.Length >= 5)
            {
                bool link = !(args.Length > 5 && args[5].Equals("nolink", StringComparison.OrdinalIgnoreCase));
                string hk = (args.Length > 6) ? args[6] : "";
                try { msg = Install(args[1], args[2], args[3], args[4], link, hk); }
                catch (Exception ex) { msg = "ERROR: " + ex.ToString(); }
            }
            else { msg = Str.S("k01"); }
            File.WriteAllText(Path.Combine(Path.GetTempPath(), "sg_setup_silent.log"), msg, new UTF8Encoding(false));
            return;
        }
        while (true) {
            SetupForm sf = new SetupForm();
            Application.Run(sf);
            if (sf.DialogResult != DialogResult.Retry) { break; }
        }
    }

    // ---------- 基础工具 ----------
    static byte[] RandomBytes(int n)
    {
        byte[] b = new byte[n];
        using (RandomNumberGenerator r = RandomNumberGenerator.Create()) { r.GetBytes(b); }
        return b;
    }

    static string Pbkdf2B64(string password, byte[] salt, int iterations)
    {
        using (Rfc2898DeriveBytes k = new Rfc2898DeriveBytes(password, salt, iterations))
        {
            return Convert.ToBase64String(k.GetBytes(32));
        }
    }

    static string HmacB64(string keyB64, string text)
    {
        using (HMACSHA256 h = new HMACSHA256(Convert.FromBase64String(keyB64)))
        {
            return Convert.ToBase64String(h.ComputeHash(Encoding.UTF8.GetBytes(text)));
        }
    }

    static string Json(string s)
    {
        StringBuilder sb = new StringBuilder("\"");
        foreach (char c in s)
        {
            if (c == '"' || c == '\\') { sb.Append('\\').Append(c); }
            else if (c < ' ') { sb.Append("\\u").Append(((int)c).ToString("x4")); }
            else { sb.Append(c); }
        }
        return sb.Append('"').ToString();
    }

    // 密码/授权码只收半角可见字符（英文、数字、符号）：不含空格、不含中文。
    // 界面上会提前写明这条要求，这里再兜一道，免得用户填了却对不上。
    internal static bool IsPlainAscii(string s)
    {
        if (s == null) { return false; }
        foreach (char c in s)
        {
            if (c < (char)33 || c > (char)126) { return false; }
        }
        return true;
    }

    // 配置文件的正文。两次调用只差 marker（算摘要时传空串）——两边都按“把 marker 的值清空后的原文”算 HMAC
    static string ConfigText(string algorithm, int iterations, string salt, string hash,
                             int authIterations, string authSalt, string authHash, string authHint,
                             string created, string marker)
    {
        return "{" +
            "\"version\":2," +
            "\"algorithm\":" + Json(algorithm) + "," +
            "\"iterations\":" + iterations + "," +
            "\"salt\":" + Json(salt) + "," +
            "\"hash\":" + Json(hash) + "," +
            "\"authIterations\":" + authIterations + "," +
            "\"authSalt\":" + Json(authSalt) + "," +
            "\"authHash\":" + Json(authHash) + "," +
            "\"authHint\":" + Json(authHint) + "," +
            "\"created\":" + Json(created) + "," +
            "\"marker\":" + Json(marker) +
            "}";
    }

    internal static bool AlreadyInstalled()
    {
        using (RegistryKey k = Registry.CurrentUser.OpenSubKey(StoreKey)) { return k != null; }
    }

    static string InstalledDir()
    {
        try
        {
            using (RegistryKey k = Registry.CurrentUser.OpenSubKey(StoreKey))
            {
                if (k != null) { return k.GetValue("InstallDir") as string; }
            }
        }
        catch { }
        return null;
    }

    // 上一次设的快捷键；没装过或没记过就返回 null（null = 不知道，"" = 上次就是不要快捷键）
    internal static string InstalledHotkey()
    {
        try
        {
            using (RegistryKey k = Registry.CurrentUser.OpenSubKey(StoreKey))
            {
                if (k == null) { return null; }
                object v = k.GetValue("Hotkey");
                return (v == null) ? null : v.ToString();
            }
        }
        catch { }
        return null;
    }

    // 只对"确实是我们装的那一份"动手：文件夹里有我们的文件，或者它本来就是空的。
    // 万一这个登记值被改成了别的目录，也不会误删用户的东西。
    static bool LooksLikeOurInstall(string dir)
    {
        try
        {
            if (File.Exists(Path.Combine(dir, ScriptLeaf))) { return true; }
            if (File.Exists(Path.Combine(dir, IconLeaf))) { return true; }
            if (File.Exists(Path.Combine(dir, CfgLeaf))) { return true; }
            if (File.Exists(Path.Combine(dir, EarlyLeaf))) { return true; }
            if (File.Exists(Path.Combine(dir, NativeLeaf))) { return true; }
            if (File.Exists(Path.Combine(dir, "uninstall.exe"))) { return true; }
            return Directory.GetFileSystemEntries(dir).Length == 0;
        }
        catch { }
        return false;
    }

    static bool DeleteFolderTree(string dir)
    {
        try
        {
            foreach (string f in Directory.GetFiles(dir, "*", SearchOption.AllDirectories))
            {
                try { File.SetAttributes(f, FileAttributes.Normal); } catch { }
            }
            Directory.Delete(dir, true);
        }
        catch { }
        return !Directory.Exists(dir);
    }

    // 程序运行时在 %LOCALAPPDATA%\CAScreenGuard\state 下放标记文件与崩溃日志
    internal static string StateDir
    {
        get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CAScreenGuard", "state"); }
    }

    // 把"安装/运行时创建、现在空了"的文件夹删掉；里面还有别的东西就绝不碰
    static void RemoveIfEmpty(string path)
    {
        try
        {
            if (string.IsNullOrEmpty(path)) { return; }
            string p = path.TrimEnd('\\');
            if (!Directory.Exists(p)) { return; }
            if (Directory.GetFileSystemEntries(p).Length != 0) { return; }
            if (Path.GetDirectoryName(p) == null) { return; }   // 别去动盘根
            Directory.Delete(p);
        }
        catch { }
    }
    // ---------- 安装 ----------
    // baseDir 是用户在向导里选的"装到哪里"，真正的安装目录是它下面的「CAScreenGuard-当天日期」
    public static string Install(string baseDir, string lockPwd, string authCode, string authHint, bool createLink, string hotkeyKey)
    {
        // 本机装过就直接重装：先把上一次那一整套（程序、配置、整个文件夹）端掉，再干净地装一份。
        // 顺序是有意的 —— 文件夹先删，删不掉就当场退出，
        // 免得凭证已经删了、旧文件夹却还在，变成"既装不上、又开不了"的烂摊子。
        string dir = Path.Combine(baseDir, SubFolderName);
        if (AlreadyInstalled())
        {
            string oldDir = InstalledDir();
            if (!string.IsNullOrEmpty(oldDir) && Directory.Exists(oldDir) && LooksLikeOurInstall(oldDir))
            {
                if (!DeleteFolderTree(oldDir))
                {
                    return Str.S("k02") + oldDir +
                           Str.S("k03");
                }
            }
            try { Registry.CurrentUser.DeleteSubKeyTree(StoreKey, false); } catch { }
            try { Registry.CurrentUser.DeleteSubKeyTree(UninstallKey, false); } catch { }
            try { if (File.Exists(MirrorPath)) { File.Delete(MirrorPath); } } catch { }
            try { string ban = Path.Combine(MirrorDir, "authban.txt"); if (File.Exists(ban)) { File.Delete(ban); } } catch { }
            try { string mdir = MirrorDir; if (Directory.Exists(mdir) && Directory.GetFileSystemEntries(mdir).Length == 0) { Directory.Delete(mdir); } } catch { }
            try { string lnk = Path.Combine(DesktopDir, LnkLeaf); if (File.Exists(lnk)) { File.Delete(lnk); } } catch { }
        }
        // 目标位置必须是一个还不存在的「CAScreenGuard-当天日期」文件夹，保证每次装的都是干净的唯一位置
        if (Directory.Exists(dir))
        {
            return Str.S("k04") + dir +
                   Str.S("k05");
        }
        Directory.CreateDirectory(dir);
        File.WriteAllBytes(Path.Combine(dir, ScriptLeaf), Convert.FromBase64String(PAYLOAD_PS1));
        File.WriteAllBytes(Path.Combine(dir, IconLeaf), Convert.FromBase64String(PAYLOAD_ICO));
        // 脚本运行时要 Add-Type 加载这两个 C# 源文件，必须和脚本放在一起
        File.WriteAllBytes(Path.Combine(dir, EarlyLeaf), Convert.FromBase64String(PAYLOAD_EARLY));
        File.WriteAllBytes(Path.Combine(dir, NativeLeaf), Convert.FromBase64String(PAYLOAD_NATIVE));

        int iterations = 120000;
        byte[] salt = RandomBytes(16);
        byte[] aSalt = RandomBytes(16);
        string hash = Pbkdf2B64(lockPwd, salt, iterations);
        string aHash = Pbkdf2B64(authCode.Trim(), aSalt, iterations);
        string keyB64 = Convert.ToBase64String(RandomBytes(32));
        string token = Guid.NewGuid().ToString("N");
        string created = DateTime.Now.ToString("s");
        string saltB64 = Convert.ToBase64String(salt);
        string aSaltB64 = Convert.ToBase64String(aSalt);

        string marker = HmacB64(keyB64, ConfigText("PBKDF2-SHA1", iterations, saltB64, hash, iterations, aSaltB64, aHash, authHint, created, ""));
        string cfg = ConfigText("PBKDF2-SHA1", iterations, saltB64, hash, iterations, aSaltB64, aHash, authHint, created, marker);
        string cfgPath = Path.Combine(dir, CfgLeaf);
        if (File.Exists(cfgPath)) { File.SetAttributes(cfgPath, FileAttributes.Normal); }
        File.WriteAllText(cfgPath, cfg, new UTF8Encoding(false));
        File.SetAttributes(cfgPath, FileAttributes.Hidden);

        using (RegistryKey k = Registry.CurrentUser.CreateSubKey(StoreKey))
        {
            k.SetValue("Token", token);
            k.SetValue("MarkerKey", keyB64);
            k.SetValue("AuthSalt", aSaltB64);
            k.SetValue("AuthHash", aHash);
            k.SetValue("AuthIterations", iterations.ToString());
            k.SetValue("AuthHint", authHint);
            k.SetValue("Provisioned", created);
            k.SetValue("InstallDir", dir);
            k.SetValue("Lang", Str.Lang);
            k.SetValue("Hotkey", hotkeyKey == null ? "" : hotkeyKey.Trim());
            // 重新安装 = 全新的开始：把「认证码永久封禁」一并清掉，
            // 否则那次的记录会跟着这台机器一直走下去（警告里让用户重新安装，就得真能解决）
            k.DeleteValue("AuthBan", false);
        }

        Directory.CreateDirectory(MirrorDir);
        string mirror = "{\"token\":" + Json(token) + ",\"markerKey\":" + Json(keyB64) +
            ",\"authSalt\":" + Json(aSaltB64) + ",\"authHash\":" + Json(aHash) +
            ",\"authIterations\":" + iterations + ",\"authHint\":" + Json(authHint) +
            ",\"provisioned\":" + Json(created) + "}";
        File.WriteAllText(MirrorPath, mirror, new UTF8Encoding(false));
        try { string ban = Path.Combine(MirrorDir, "authban.txt"); if (File.Exists(ban)) { File.Delete(ban); } } catch { }

        string lnkNote;
        // 快捷键也写进快捷方式的说明里：鼠标停在桌面图标上就能看到，不用翻设置
        string desc = AppName + Str.S("k06");
        string hkDesc = HotkeyText(hotkeyKey);
        if (hkDesc.Length > 0) { desc = desc + "（" + hkDesc + "）"; }
        if (createLink)
        {
            CreateShortcut(Path.Combine(DesktopDir, LnkLeaf), Path.Combine(SystemDir, "conhost.exe"),
                "--headless powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + Path.Combine(dir, ScriptLeaf) + "\"",
                dir, Path.Combine(dir, IconLeaf), desc, hotkeyKey);
            if (hkDesc.Length > 0) { lnkNote = Str.S("k07") + AppName + Str.S("k08") + hkDesc + Str.S("k09"); }
            else { lnkNote = Str.S("k10") + AppName + "」。\n\n"; }
        }
        else
        {
            lnkNote = Str.S("k11");
        }

        string exePath = Application.ExecutablePath;
        string uninst = Path.Combine(dir, "uninstall.exe");
        File.Copy(exePath, uninst, true);
        using (RegistryKey u = Registry.CurrentUser.CreateSubKey(UninstallKey))
        {
            u.SetValue("DisplayName", AppName);
            u.SetValue("DisplayVersion", "1.0");
            u.SetValue("Publisher", "Conste11ation117");
            u.SetValue("InstallLocation", dir);
            u.SetValue("DisplayIcon", uninst);
            u.SetValue("UninstallString", "\"" + uninst + "\" /uninstall");
            u.SetValue("NoModify", 1, RegistryValueKind.DWord);
            u.SetValue("NoRepair", 1, RegistryValueKind.DWord);
        }

        return Str.S("k12") + dir + "\n" + lnkNote +
               Str.S("k13");
    }

    // ---------- 卸载 ----------
    static void DoUninstall(bool silent)
    {
        if (!silent)
        {
            if (MessageBox.Show(Str.S("k14"),
                                AppName + " " + AppVersion + Str.S("k15"), MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes)
            {
                return;
            }
        }
        string dir = InstalledDir();
        try { Registry.CurrentUser.DeleteSubKeyTree(StoreKey, false); } catch { }
        try { Registry.CurrentUser.DeleteSubKeyTree(UninstallKey, false); } catch { }
        try { if (File.Exists(MirrorPath)) { File.Delete(MirrorPath); } } catch { }
        try { string ban = Path.Combine(MirrorDir, "authban.txt"); if (File.Exists(ban)) { File.Delete(ban); } } catch { }
        try { string mdir = MirrorDir; if (Directory.Exists(mdir) && Directory.GetFileSystemEntries(mdir).Length == 0) { Directory.Delete(mdir); } } catch { }
        try { string lnk = Path.Combine(DesktopDir, LnkLeaf); if (File.Exists(lnk)) { File.Delete(lnk); } } catch { }
        string msg = Str.S("k16");
        if (!string.IsNullOrEmpty(dir) && Directory.Exists(dir))
        {
            foreach (string f in new string[] { CfgLeaf, ScriptLeaf, IconLeaf, EarlyLeaf, NativeLeaf })
            {
                try
                {
                    string p = Path.Combine(dir, f);
                    if (File.Exists(p)) { File.SetAttributes(p, FileAttributes.Normal); File.Delete(p); }
                }
                catch { }
            }
            msg += Str.S("k17") + dir;
            // 程序运行时建的 state 目录（标记文件、崩溃日志）也一起清掉，
            // 再把"安装时创建、现在空了"的父文件夹删掉 —— 重装前的现场要干净
            try { if (Directory.Exists(StateDir)) { Directory.Delete(StateDir, true); } } catch { }
            RemoveIfEmpty(Path.GetDirectoryName(dir.TrimEnd('\\')));
            RemoveIfEmpty(Path.GetDirectoryName(StateDir));
            ScheduleFolderDelete(dir);
        }
        if (silent)
        {
            File.WriteAllText(Path.Combine(Path.GetTempPath(), "sg_setup_silent.log"), msg, new UTF8Encoding(false));
        }
        else
        {
            MessageBox.Show(msg, AppName + " " + AppVersion + Str.S("k18"), MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }

    // 卸载程序自己就住在这个文件夹里，没法当场把自己删掉，
    // 所以交给一个脱离了本进程的 cmd：等它两秒，再整棵删掉。
    // 只有确认"要删的就是本程序所在的文件夹"才会动手，避免误伤。
    static void ScheduleFolderDelete(string dir)
    {
        try
        {
            string exeDir = Path.GetDirectoryName(Path.GetFullPath(Application.ExecutablePath));
            if (string.IsNullOrEmpty(exeDir) || string.IsNullOrEmpty(dir)) { return; }
            if (!Path.GetFullPath(dir).TrimEnd('\\').Equals(exeDir.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase)) { return; }
            string sys = Environment.GetFolderPath(Environment.SpecialFolder.System);
            ProcessStartInfo psi = new ProcessStartInfo(
                Path.Combine(sys, "cmd.exe"),
                "/c ping -n 3 127.0.0.1 >nul & rd /s /q \"" + Path.GetFullPath(dir).TrimEnd('\\') + "\" & rd /q \"" + Path.GetDirectoryName(Path.GetFullPath(dir).TrimEnd('\\')) + "\"");
            psi.CreateNoWindow = true;
            psi.UseShellExecute = false;
            psi.WorkingDirectory = sys;
            Process.Start(psi);
        }
        catch { }
    }

    // ---------- 桌面快捷方式（IShellLink，避免调用外部程序） ----------
    [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
    class ShellLinkObject { }

    [ComImport, Guid("000214F9-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IShellLinkW
    {
        void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cch, IntPtr pfd, uint fFlags);
        void GetIDList(out IntPtr ppidl);
        void SetIDList(IntPtr pidl);
        void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cch);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cch);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cch);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
        void GetHotkey(out short pwHotkey);
        void SetHotkey(short wHotkey);
        void GetShowCmd(out int piShowCmd);
        void SetShowCmd(int iShowCmd);
        void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cch, out int piIcon);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
        void Resolve(IntPtr hwnd, uint fFlags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
    }

    [ComImport, Guid("0000010b-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IPersistFile
    {
        void GetClassID(out Guid pClassID);
        [PreserveSig] int IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, uint dwMode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, [MarshalAs(UnmanagedType.Bool)] bool fRemember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
    }

    // Ctrl + Alt + 一个键：高字节是修饰键（HOTKEYF_CONTROL | HOTKEYF_ALT），低字节是虚拟键码
    internal static bool IsHotkeyKey(string key)
    {
        if (key == null) { return false; }
        key = key.Trim();
        if (key.Length == 0) { return false; }
        char c = char.ToUpperInvariant(key[0]);
        return (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
    }

    static short HotkeyValue(string key)
    {
        if (!IsHotkeyKey(key)) { return 0; }
        char c = char.ToUpperInvariant(key.Trim()[0]);
        return (short)(((0x02 | 0x04) << 8) | (int)c);
    }

    internal static string HotkeyText(string key)
    {
        if (!IsHotkeyKey(key)) { return ""; }
        return "Ctrl + Alt + " + char.ToUpperInvariant(key.Trim()[0]);
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);

    // 告诉资源管理器"这个快捷方式变了"，快捷键才会立刻生效，不用等下次登录
    static void NotifyShell(string lnkPath)
    {
        try
        {
            IntPtr p = Marshal.StringToHGlobalUni(lnkPath);
            try { SHChangeNotify(0x00002000, 0x0005, p, IntPtr.Zero); }   // SHCNE_UPDATEITEM | SHCNF_PATHW
            finally { Marshal.FreeHGlobal(p); }
        }
        catch { }
    }

    static void CreateShortcut(string lnkPath, string target, string arguments, string workDir,
                               string iconPath, string description, string hotkeyKey)
    {
        IShellLinkW link = (IShellLinkW)new ShellLinkObject();
        link.SetPath(target);
        link.SetArguments(arguments);
        link.SetWorkingDirectory(workDir);
        link.SetIconLocation(iconPath, 0);
        link.SetDescription(description);
        short hk = HotkeyValue(hotkeyKey);
        if (hk != 0) { link.SetHotkey(hk); }
        ((IPersistFile)link).Save(lnkPath, false);
        Marshal.ReleaseComObject(link);
        if (hk != 0) { NotifyShell(lnkPath); }
    }
}

// ---------- 安装向导 ----------
public class SetupForm : Form
{
    const string UIFont = "Microsoft YaHei UI";

    Panel pageWelcome, pageInstall;
    ComboBox cboLang;
    Label lblWelcome, lblAuthor, lblIntro, lblAv, lblLang;
    LinkLabel lnkReadme;
    TextBox txtDir, txtPwd, txtPwd2, txtAuth, txtAuth2, txtHint, txtHotkey;
    CheckBox chkLink;
    Label lblError, lblFinal, lblHotkeyHint;
    Button btnInstall, btnBrowse;
    float s = 1F;

    int S(int v) { return (int)Math.Round(v * (double)s); }

    Label AddLabel(string text, int x, int y, int w, int h, float pt, FontStyle st, Color c, ContentAlignment align)
    {
        Label l = new Label();
        l.AutoSize = false;
        l.Text = text;
        l.Location = new Point(S(x), S(y));
        l.Size = new Size(S(w), S(h));
        l.Font = new Font(UIFont, pt, st, GraphicsUnit.Point);
        l.ForeColor = c;
        l.TextAlign = align;
        l.BackColor = Color.Transparent;
        pageInstall.Controls.Add(l);
        return l;
    }

    TextBox AddBox(int x, int y, int w, bool secret)
    {
        TextBox t = new TextBox();
        t.Location = new Point(S(x), S(y));
        t.Size = new Size(S(w), S(26));
        t.Font = new Font(UIFont, 10.5F, FontStyle.Regular, GraphicsUnit.Point);
        t.BorderStyle = BorderStyle.FixedSingle;
        if (secret) { t.UseSystemPasswordChar = true; t.ImeMode = ImeMode.Disable; }
        pageInstall.Controls.Add(t);
        return t;
    }

    public SetupForm()
    {
        AutoScaleMode = AutoScaleMode.None;
        using (Graphics g = CreateGraphics()) { s = g.DpiX / 96F; }
        if (s < 1F) { s = 1F; }

        Str.Detect();
        Text = Str.S("k19") + CAScreenGuardInstaller.AppName + " " + CAScreenGuardInstaller.AppVersion;
        pageWelcome = new Panel(); pageWelcome.Dock = DockStyle.Fill; pageWelcome.BackColor = Color.White; Controls.Add(pageWelcome);
        pageInstall = new Panel(); pageInstall.Dock = DockStyle.Fill; pageInstall.BackColor = Color.White; Controls.Add(pageInstall);
        BuildWelcome();
        try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }
        Font = new Font(UIFont, 9F, FontStyle.Regular, GraphicsUnit.Point);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.White;
        ClientSize = new Size(S(560), S(620));

        AddLabel(Str.S("k20") + CAScreenGuardInstaller.AppName, 28, 18, 400, 34, 16F, FontStyle.Bold,
                 Color.FromArgb(27, 35, 48), ContentAlignment.MiddleLeft);
        AddLabel(Str.S("k21"),
                 28, 54, 504, 36, 9F, FontStyle.Regular, Color.FromArgb(90, 100, 114), ContentAlignment.TopLeft);
        AddLabel(Str.S("k22") +
                 Str.S("k23"),
                 28, 92, 504, 48, 8.5F, FontStyle.Regular, Color.FromArgb(90, 100, 114), ContentAlignment.TopLeft);

        int y = 148;
        const int step = 38;
        const int lx = 28;      // 标签列
        const int lw = 144;
        const int fx = 180;     // 输入框列
        const int fw = 352;
        Color lc = Color.FromArgb(45, 52, 64);

        AddLabel(Str.S("k24"), lx, y, lw, 26, 9F, FontStyle.Regular, lc, ContentAlignment.MiddleRight);
        txtDir = AddBox(fx, y, 264, false);
        txtDir.Text = CAScreenGuardInstaller.DefaultDir;
        txtDir.TextChanged += new EventHandler(OnDirChanged);
        btnBrowse = new Button();
        btnBrowse.Text = Str.S("k25");
        btnBrowse.Location = new Point(S(452), S(y - 1));
        btnBrowse.Size = new Size(S(80), S(28));
        btnBrowse.Font = new Font(UIFont, 9F, FontStyle.Regular, GraphicsUnit.Point);
        btnBrowse.Click += new EventHandler(OnBrowse);
        pageInstall.Controls.Add(btnBrowse);

        y += step;
        AddLabel(Str.S("k26"), lx, y, lw, 26, 9F, FontStyle.Regular, lc, ContentAlignment.MiddleRight);
        txtPwd = AddBox(fx, y, fw, true);

        y += step;
        AddLabel(Str.S("k27"), lx, y, lw, 26, 9F, FontStyle.Regular, lc, ContentAlignment.MiddleRight);
        txtPwd2 = AddBox(fx, y, fw, true);

        y += step;
        AddLabel(Str.S("k28"), lx, y, lw, 26, 9F, FontStyle.Regular, lc, ContentAlignment.MiddleRight);
        txtAuth = AddBox(fx, y, fw, true);

        y += step;
        AddLabel(Str.S("k29"), lx, y, lw, 26, 9F, FontStyle.Regular, lc, ContentAlignment.MiddleRight);
        txtAuth2 = AddBox(fx, y, fw, true);

        y += step;
        AddLabel(Str.S("k30"), lx, y, lw, 26, 9F, FontStyle.Regular, lc, ContentAlignment.MiddleRight);
        txtHint = AddBox(fx, y, fw, false);

        y += step;
        AddLabel(Str.S("k31"), lx, y, lw, 26, 9F, FontStyle.Regular, lc, ContentAlignment.MiddleRight);
        txtHotkey = AddBox(fx, y, 60, false);
        txtHotkey.MaxLength = 1;
        txtHotkey.Text = "L";
        txtHotkey.TextAlign = HorizontalAlignment.Center;
        txtHotkey.CharacterCasing = CharacterCasing.Upper;
        txtHotkey.ImeMode = ImeMode.Disable;
        txtHotkey.TextChanged += new EventHandler(OnHotkeyChanged);
        lblHotkeyHint = AddLabel("", fx + 70, y, 282, 26, 8.5F, FontStyle.Regular,
                                 Color.FromArgb(120, 128, 142), ContentAlignment.MiddleLeft);

        lblFinal = AddLabel("", 28, 406, 504, 46, 8.5F, FontStyle.Regular,
                            Color.FromArgb(120, 128, 142), ContentAlignment.MiddleLeft);

        chkLink = new CheckBox();
        chkLink.Text = Str.S("k32");
        chkLink.Checked = true;
        chkLink.AutoSize = false;
        chkLink.Location = new Point(S(fx), S(456));
        chkLink.Size = new Size(S(320), S(24));
        chkLink.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        chkLink.ForeColor = lc;
        chkLink.BackColor = Color.Transparent;
        chkLink.CheckedChanged += new EventHandler(OnLinkChanged);
        pageInstall.Controls.Add(chkLink);

        AddLabel(Str.S("k33"),
                 28, 484, 504, 32, 8.5F, FontStyle.Regular, Color.FromArgb(192, 57, 43), ContentAlignment.TopLeft);

        AddLabel(Str.S("k71"),
                 28, 518, 504, 34, 8.5F, FontStyle.Regular, Color.FromArgb(176, 96, 0), ContentAlignment.TopLeft);

        lblError = AddLabel("", 28, 552, 504, 22, 9F, FontStyle.Regular, Color.FromArgb(192, 57, 43), ContentAlignment.MiddleLeft);

        AddLabel("@Conste11ation117　2026.10.14", 28, 580, 300, 26, 8.5F, FontStyle.Regular,
                 Color.FromArgb(150, 158, 170), ContentAlignment.MiddleLeft);

        btnInstall = new Button();
        btnInstall.Text = Str.S("k34");
        btnInstall.Location = new Point(S(352), S(578));
        btnInstall.Size = new Size(S(88), S(30));
        btnInstall.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        btnInstall.Click += new EventHandler(OnInstall);
        pageInstall.Controls.Add(btnInstall);

        Button btnCancel = new Button();
        btnCancel.Text = Str.S("k70");
        btnCancel.Location = new Point(S(448), S(578));
        btnCancel.Size = new Size(S(84), S(30));
        btnCancel.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        btnCancel.Click += new EventHandler(OnBack);   // 不关窗，回欢迎页
        // 注意：这个窗是用 Application.Run 打开的（非模态），只设 DialogResult 不会关窗，
        // 必须自己挂一个 Click。Esc 走 CancelButton，也会点到同一个处理函数。
        // 早期修「取消没反应」时挂的那个 OnCancel 已经不需要了：现在这个按钮是「上一页」
        pageInstall.Controls.Add(btnCancel);

        AcceptButton = btnInstall;
        CancelButton = btnCancel;

        // 本机装过的话，把上一次设的快捷键回填出来，免得用户以为没设过
        if (CAScreenGuardInstaller.AlreadyInstalled())
        {
            string oldHk = CAScreenGuardInstaller.InstalledHotkey();
            if (oldHk != null) { txtHotkey.Text = CAScreenGuardInstaller.IsHotkeyKey(oldHk) ? oldHk.Trim().ToUpperInvariant() : ""; }
        }

        UpdateFinalPath();
        UpdateHotkeyHint();
        ApplyLanguage();
        ShowPage(false);
        ActiveControl = txtPwd;
    }

    void OnCancel(object sender, EventArgs e) { Close(); }

    void UpdateHotkeyHint()
    {
        if (!chkLink.Checked) { lblHotkeyHint.Text = Str.S("k36"); return; }
        string k = txtHotkey.Text.Trim();
        if (k.Length == 0) { lblHotkeyHint.Text = Str.S("k37"); return; }
        lblHotkeyHint.Text = Str.S("k38") + k.ToUpperInvariant() + Str.S("k39");
    }

    void OnHotkeyChanged(object sender, EventArgs e) { Fail(""); UpdateHotkeyHint(); }

    void OnLinkChanged(object sender, EventArgs e) { Fail(""); UpdateHotkeyHint(); UpdateFinalPath(); }

    void UpdateFinalPath()
    {
        string baseDir = txtDir.Text.Trim().Trim('"');
        if (baseDir.Length == 0) { lblFinal.Text = Str.S("k40"); return; }
        string full;
        try { full = Path.Combine(Path.GetFullPath(baseDir), CAScreenGuardInstaller.SubFolderName); }
        catch { lblFinal.Text = Str.S("k41"); return; }
        if (Directory.Exists(full)) { lblFinal.Text = Str.S("k42") + full + Str.S("k43"); return; }
        string note = "";
        if (CAScreenGuardInstaller.AlreadyInstalled()) { note = Str.S("k44"); }
        lblFinal.Text = Str.S("k45") + full + note;
    }

    void OnDirChanged(object sender, EventArgs e) { Fail(""); UpdateFinalPath(); }

    static Bitmap LoadAppIconBitmap(int size)
    {
        try
        {
            byte[] ico = Convert.FromBase64String(CAScreenGuardInstaller.PAYLOAD_ICO);
            int count = BitConverter.ToUInt16(ico, 4);
            int bestOff = -1, bestW = -1;
            for (int i = 0; i < count; i++)
            {
                int off = 6 + i * 16;
                int w = (ico[off] == 0) ? 256 : ico[off];
                if (w > bestW) { bestW = w; bestOff = off; }
            }
            if (bestOff < 0) { return null; }
            int len = BitConverter.ToInt32(ico, bestOff + 8);
            int pos = BitConverter.ToInt32(ico, bestOff + 12);
            if (pos + len > ico.Length) { return null; }
            byte[] frame = new byte[len];
            Array.Copy(ico, pos, frame, 0, len);
            using (MemoryStream ms = new MemoryStream(frame))
            {
                using (Bitmap src = new Bitmap(ms))
                {
                    return new Bitmap(src, size, size);
                }
            }
        }
        catch { }
        return null;
    }
    void BuildWelcome()
    {
        PictureBox pic = new PictureBox();
        pic.SizeMode = PictureBoxSizeMode.Zoom;
        pic.Size = new Size(S(76), S(76));
        pic.Location = new Point(S(30), S(28));
        try {
            Icon ic = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            Bitmap _big = LoadAppIconBitmap(S(76));
            if (_big != null) { pic.Image = _big; }
            else if (ic != null) { pic.Image = new Bitmap(ic.ToBitmap(), S(76), S(76)); }
        } catch { }
        pageWelcome.Controls.Add(pic);

        lblWelcome = new Label();
        lblWelcome.AutoSize = false;
        lblWelcome.Font = new Font(UIFont, 24F, FontStyle.Bold, GraphicsUnit.Point);
        lblWelcome.ForeColor = Color.FromArgb(27, 35, 48);
        lblWelcome.TextAlign = ContentAlignment.MiddleLeft;
        lblWelcome.Location = new Point(S(128), S(32));
        lblWelcome.Size = new Size(S(400), S(48));
        pageWelcome.Controls.Add(lblWelcome);

        lblAuthor = new Label();
        lblAuthor.AutoSize = false;
        lblAuthor.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        lblAuthor.ForeColor = Color.FromArgb(110, 118, 130);
        lblAuthor.TextAlign = ContentAlignment.MiddleLeft;
        lblAuthor.Location = new Point(S(130), S(84));
        lblAuthor.Size = new Size(S(424), S(26));
        pageWelcome.Controls.Add(lblAuthor);

        lblIntro = new Label();
        lblIntro.AutoSize = false;
        lblIntro.Font = new Font(UIFont, 9F, FontStyle.Regular, GraphicsUnit.Point);
        lblIntro.ForeColor = Color.FromArgb(58, 66, 80);
        lblIntro.TextAlign = ContentAlignment.TopLeft;
        lblIntro.Location = new Point(S(30), S(120));
        lblIntro.Size = new Size(S(500), S(62));
        pageWelcome.Controls.Add(lblIntro);

        lblAv = new Label();
        lblAv.AutoSize = false;
        lblAv.Font = new Font(UIFont, 8.5F, FontStyle.Regular, GraphicsUnit.Point);
        lblAv.ForeColor = Color.FromArgb(96, 100, 108);   // 正常颜色，不做警告红
        lblAv.TextAlign = ContentAlignment.TopLeft;
        lblAv.Location = new Point(S(30), S(190));
        lblAv.Size = new Size(S(500), S(64));
        pageWelcome.Controls.Add(lblAv);

        lnkReadme = new LinkLabel();
        lnkReadme.AutoSize = false;
        lnkReadme.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        lnkReadme.LinkColor = Color.FromArgb(0, 102, 204);
        lnkReadme.TextAlign = ContentAlignment.MiddleLeft;
        lnkReadme.Location = new Point(S(30), S(254));
        lnkReadme.Size = new Size(S(500), S(26));
        lnkReadme.LinkClicked += new LinkLabelLinkClickedEventHandler(OnReadme);
        pageWelcome.Controls.Add(lnkReadme);

        lblLang = new Label();
        lblLang.AutoSize = false;
        lblLang.Font = new Font(UIFont, 9F, FontStyle.Regular, GraphicsUnit.Point);
        lblLang.ForeColor = Color.FromArgb(70, 78, 92);
        lblLang.TextAlign = ContentAlignment.MiddleLeft;
        lblLang.Location = new Point(S(30), S(292));
        lblLang.Size = new Size(S(100), S(26));
        pageWelcome.Controls.Add(lblLang);

        cboLang = new ComboBox();
        cboLang.DropDownStyle = ComboBoxStyle.DropDownList;
        cboLang.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        cboLang.Location = new Point(S(146), S(292));
        cboLang.Size = new Size(S(150), S(26));
        cboLang.Items.Add("简体中文");
        cboLang.Items.Add("English");
        cboLang.SelectedIndex = (Str.Lang == "en") ? 1 : 0;
        cboLang.SelectedIndexChanged += new EventHandler(OnLangChanged);
        pageWelcome.Controls.Add(cboLang);

        Button btnNext = new Button();
        btnNext.Name = "btnNext";
        btnNext.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        btnNext.Location = new Point(S(352), S(292));
        btnNext.Size = new Size(S(88), S(30));
        btnNext.Click += new EventHandler(OnNext);
        pageWelcome.Controls.Add(btnNext);

        Button btnQuit = new Button();
        btnQuit.Name = "btnQuit";
        btnQuit.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        btnQuit.DialogResult = DialogResult.Cancel;
        // 这个窗体是 Application.Run 打开的（非模态），只设 DialogResult 不会关窗，
        // 必须自己挂 Click —— 和当初安装页那个「取消」是同一个坑
        btnQuit.Click += new EventHandler(OnCancel);
        btnQuit.Location = new Point(S(448), S(292));
        btnQuit.Size = new Size(S(84), S(30));
        pageWelcome.Controls.Add(btnQuit);
    }

    void ShowPage(bool install)
    {
        pageWelcome.Visible = !install;
        pageInstall.Visible = install;
        ClientSize = install ? new Size(S(560), S(620)) : new Size(S(560), S(352));
        if (install) { AcceptButton = btnInstall; CancelButton = null; }
        else { AcceptButton = FindButton("btnNext", pageWelcome); CancelButton = FindButton("btnQuit", pageWelcome); }
    }

    Button FindButton(string name, Control parent)
    {
        foreach (Control c in parent.Controls) { Button b = c as Button; if (b != null && b.Name == name) { return b; } }
        return null;
    }

    void OnNext(object sender, EventArgs e) { ShowPage(true); if (txtPwd != null) { ActiveControl = txtPwd; } }

    void OnBack(object sender, EventArgs e) { ShowPage(false); }

    void OnLangChanged(object sender, EventArgs e)
    {
        // 语言变了就把向导整体重开一遍（此时还没填任何东西，重开最干净、也不会出现半中半英）
        Str.Lang = (cboLang.SelectedIndex == 1) ? "en" : "zh";
        DialogResult = DialogResult.Retry;
        Close();
    }

    void ApplyLanguage()
    {
        lblWelcome.Text = Str.S("k69");
        lblAuthor.Text = "@Conste11ation117　·　CAScreenGuard " + CAScreenGuardInstaller.AppVersion + "　·　MIT License";
        lblIntro.Text = Str.S("k68");
        lblAv.Text = Str.S("k64");
        lnkReadme.Text = Str.S("k65");
        lblLang.Text = Str.S("k66");
        Button bn = FindButton("btnNext", pageWelcome);
        if (bn != null) { bn.Text = Str.S("k67"); }
        Button bq = FindButton("btnQuit", pageWelcome);
        if (bq != null) { bq.Text = Str.S("k35"); }
    }

    void OnReadme(object sender, LinkLabelLinkClickedEventArgs e)
    {
        try {
            string dir = Path.GetDirectoryName(Application.ExecutablePath);
            string[] names = new string[] { (Str.Lang == "en") ? "README.md" : "README.zh-CN.md", "README.md", "README.zh-CN.md" };
            foreach (string n in names) {
                string f = Path.Combine(dir, n);
                if (File.Exists(f)) { Process.Start(new ProcessStartInfo(f) { UseShellExecute = true }); return; }
            }
            MessageBox.Show(Str.S("k68"), CAScreenGuardInstaller.AppName + " " + CAScreenGuardInstaller.AppVersion, MessageBoxButtons.OK, MessageBoxIcon.Information);
        } catch { }
    }

    // 出错走 Fail（红字），等待/进行中走 Status（绿字）：同一个状态行，颜色区分性质
    void Fail(string msg) { lblError.ForeColor = Color.FromArgb(192, 57, 43); lblError.Text = msg; }

    void Status(string msg)
    {
        lblError.ForeColor = Color.FromArgb(22, 138, 72);
        lblError.Text = msg;
        lblError.Update();   // 安装是同步跑的，不立刻重画的话这条提示根本来不及显示
    }

    void OnBrowse(object sender, EventArgs e)
    {
        using (FolderBrowserDialog d = new FolderBrowserDialog())
        {
            d.Description = Str.S("k46");
            d.ShowNewFolderButton = true;
            string cur = txtDir.Text.Trim();
            if (Directory.Exists(cur)) { d.SelectedPath = cur; }
            if (d.ShowDialog(this) == DialogResult.OK) { txtDir.Text = d.SelectedPath; }
        }
        Fail("");
    }

    void OnInstall(object sender, EventArgs e)
    {
        Fail("");
        string dir = txtDir.Text.Trim().Trim('"');
        string pwd = txtPwd.Text;
        string auth = txtAuth.Text.Trim();
        string hint = txtHint.Text.Trim();

        if (dir.Length == 0) { Fail(Str.S("k47")); txtDir.Focus(); return; }
        if (pwd.Length < 4) { Fail(Str.S("k48")); txtPwd.Focus(); return; }
        if (!CAScreenGuardInstaller.IsPlainAscii(pwd)) { Fail(Str.S("k49")); txtPwd.Focus(); return; }
        if (!String.Equals(pwd, txtPwd2.Text, StringComparison.Ordinal)) { Fail(Str.S("k50")); txtPwd2.Focus(); return; }
        if (auth.Length < 6) { Fail(Str.S("k51")); txtAuth.Focus(); return; }
        if (!CAScreenGuardInstaller.IsPlainAscii(auth)) { Fail(Str.S("k52")); txtAuth.Focus(); return; }
        if (!String.Equals(auth, txtAuth2.Text.Trim(), StringComparison.Ordinal)) { Fail(Str.S("k53")); txtAuth2.Focus(); return; }
        if (String.Equals(auth, pwd, StringComparison.Ordinal)) { Fail(Str.S("k54")); txtAuth.Focus(); return; }
        if (hint.Length == 0) { Fail(Str.S("k55")); txtHint.Focus(); return; }

        string hotkey = txtHotkey.Text.Trim();
        if (chkLink.Checked && hotkey.Length > 0 && !CAScreenGuardInstaller.IsHotkeyKey(hotkey))
        {
            Fail(Str.S("k56"));
            txtHotkey.Focus();
            return;
        }
        if (!chkLink.Checked) { hotkey = ""; }

        string full;
        try { full = Path.GetFullPath(dir); }
        catch { Fail(Str.S("k57")); txtDir.Focus(); return; }

        // 真正的安装目录 = 选定的位置 + 「CAScreenGuard-当天日期」；已存在就拒绝，保证每次都装在干净的唯一位置
        string target = Path.Combine(full, CAScreenGuardInstaller.SubFolderName);
        if (Directory.Exists(target))
        {
            Fail(Str.S("k58") + CAScreenGuardInstaller.SubFolderName + Str.S("k59"));
            UpdateFinalPath();
            txtDir.Focus();
            return;
        }

        string msg;
        Cursor = Cursors.WaitCursor;
        Status(Str.S("k72"));
        try { msg = CAScreenGuardInstaller.Install(full, pwd, auth, hint, chkLink.Checked, hotkey); }
        catch (UnauthorizedAccessException) { Cursor = Cursors.Default; Fail(Str.S("k60")); return; }
        catch (IOException ex) { Cursor = Cursors.Default; Fail(Str.S("k61") + ex.Message); return; }
        catch (Exception ex) { Cursor = Cursors.Default; Fail(Str.S("k62") + ex.Message); return; }
        Cursor = Cursors.Default;

        MessageBox.Show(this, msg, Str.S("k63") + CAScreenGuardInstaller.AppName + " " + CAScreenGuardInstaller.AppVersion, MessageBoxButtons.OK, MessageBoxIcon.Information);
        DialogResult = DialogResult.OK;
        Close();
    }
}
