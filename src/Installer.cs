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
        { "k60", "没有权限写入安装需要的位置。请换一个文件夹，或者用默认位置（就在你自己的用户目录下）。若换位置也一样，多半是杀毒软件或「受控文件夹访问」在拦截。底层错误：{0}" },
        { "k61", "写入安装文件时出错：" },
        { "k62", "安装失败：" },
        { "k63", "安装 " },
        { "k64", "注意：部分杀毒软件可能对本程序报警。已实测：360 会给出提示但不会判定为病毒，Windows Defender 完全放行。如果你信任本软件，建议把它加入杀毒软件的信任目录／白名单，否则安装或运行时可能被拦截。" },
        { "k65", "查看说明文档（README）" },
        { "k66", "界面语言" },
        { "k67", "下一步" },
        { "k95", "（程序文件与注册表都已备份；双击 registry-backup.reg 即可还原注册表）" },
        { "k80", "检测到本机已安装 " },
        { "k81", "\n\n升级只替换程序文件：解锁密码、授权码、提示、快捷键、桌面快捷方式全部保留。继续吗？" },
        { "k83", "注册表里有安装登记，但没有记下安装目录，无法安全升级。" },
        { "k84", "登记里的安装目录已经不存在了：\n" },
        { "k85", "这个目录看起来不是 CAScreenGuard 的安装目录，不敢动它：\n" },
        { "k86", "安装目录里找不到配置文件，升级可能导致凭据丢失，已停止：\n" },
        { "k87", "CAScreenGuard 正在运行（或上次没有正常退出）。请先解锁并退出，再运行这个安装包。" },
        { "k88", "（注意：旧文件备份失败，回滚副本可能不完整。）\n" },
        { "k89", "已升级到 " },
        { "k90", "。\n\n安装位置：" },
        { "k91", "\n\n解锁密码与授权码保持不变。" },
        { "k92", "旧版本" },
        { "k93", "升级失败：" },
        { "k94", "\n\n为保护现有凭据，本次没有做任何修改。要重装的话，请先在「设置 → 应用」里卸载 CAScreenGuard。" },
        { "k68", "CAScreenGuard 只关显示器（不休眠、不锁会话、保持系统唤醒），在最上层盖一层全屏遮罩挡住桌面内容；输对解锁密码才会恢复。它是视觉遮挡，不是安全边界，详见 README。\n\n获取新版本：github.com/Conste11ation117/CAScreenGuard/releases" },
        { "k96", "可选：DeepSeek Harness用户安装插件：dsh-get-session-status可获得本软件的完整体验：锁屏左上角会显示 agent 是在跑还是在等你。" },
        { "k69", "欢迎" },
        { "k70", "上一页" },
        { "k71", "请只使用本程序提供的卸载程序卸载，不要使用第三方管理程序卸载，否则可能导致系统关键组件缺失。" },
        { "k72", "正在安装：可能需要 3~10 秒，请耐心等待，不要关闭这个窗口。" },
        { "k73", "」。\n\n" },
        { "k74", "\n\n提示：有项目没能删掉（可能被杀软或权限拦住），外部凭证可能仍有残留。" },
        { "k75", "以管理员身份重试" },
        { "k76", "关闭" },
        { "k77", "这个位置需要管理员权限才能写。点「以管理员身份重试」之后会弹出 Windows 授权提示（UAC）；同意后安装会继续，并且把安装目录的写权限授给你当前这个账户 —— 以后程序自己写配置和日志就不用再提权。" },
        { "k78", "已经用管理员权限试过一次，还是没能写入：\n" },
        { "k79", "没有拿到管理员授权（在 UAC 提示上选了「否」），安装没有继续。" },    };
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
        { "k60", "No permission to write where the installer needs to. Pick another folder, or use the default location inside your own user profile. If every folder fails the same way it is almost always antivirus or Defender Controlled folder access. Underlying error: {0}" },
        { "k61", "Error while writing the installation files: " },
        { "k62", "Installation failed: " },
        { "k63", "Install " },
        { "k64", "Note: some antivirus products may warn about this program. Measured: 360 shows a prompt but does not classify it as a virus; Windows Defender passes it completely. If you trust this software, add it to your antivirus whitelist — otherwise the installer or the program may be blocked." },
        { "k65", "Open the README" },
        { "k66", "Language" },
        { "k67", "Next" },
        { "k95", " (program files and registry both backed up; double-click registry-backup.reg to restore the registry)" },
        { "k80", "An existing install was found: " },
        { "k81", "\n\nUpgrading replaces the program files only: the unlock password, authorization code, hint, hotkey and desktop shortcut all stay. Continue?" },
        { "k83", "There is an install registration, but no install folder recorded, so it cannot be upgraded safely." },
        { "k84", "The recorded install folder no longer exists:\n" },
        { "k85", "This folder does not look like a CAScreenGuard install, so it will not be touched:\n" },
        { "k86", "No configuration file in the install folder; upgrading could lose the credentials, so it stopped:\n" },
        { "k87", "CAScreenGuard is running (or it did not exit cleanly last time). Unlock and quit it first, then run this installer again." },
        { "k88", "(Note: backing up the old files failed, so the rollback copy may be incomplete.)\n" },
        { "k89", "Upgraded to " },
        { "k90", ".\n\nInstall location: " },
        { "k91", "\n\nThe unlock password and authorization code are unchanged." },
        { "k92", "an older version" },
        { "k93", "Upgrade failed: " },
        { "k94", "\n\nNothing was modified this time, to protect the existing credentials. To reinstall, uninstall CAScreenGuard from Settings > Apps first." },
        { "k68", "CAScreenGuard turns the monitor off (no sleep, no session lock, the machine stays awake) and covers the desktop with a full-screen mask; only the unlock password brings it back. It is a visual barrier, not a security boundary. See the README.\n\nNew versions: github.com/Conste11ation117/CAScreenGuard/releases" },
        { "k96", "Optional: DeepSeek Harness users can install the plugin dsh-get-session-status for the complete experience - the lock screen then shows whether the agent is working or waiting for you." },
        { "k69", "Welcome" },
        { "k70", "Back" },
        { "k71", "Please uninstall only with the uninstaller provided by this program. Do not remove it with third-party uninstall managers, or key system components may end up missing." },
        { "k72", "Installing: this may take 3-10 seconds. Please wait and do not close this window." },
        { "k73", "\u201d.\n\n" },
        { "k74", "\n\nNote: some items could not be removed (antivirus or permissions). External credentials may still be left behind." },
        { "k75", "Retry as administrator" },
        { "k76", "Close" },
        { "k77", "This location needs administrator rights. After you choose \u201cRetry as administrator\u201d Windows shows its permission prompt (UAC); once you approve, the installation continues and write access to the installation folder is granted to your current account \u2014 so the program can write its own configuration and logs later without elevation." },
        { "k78", "Tried again with administrator rights, but the location still could not be written to:\n" },
        { "k79", "Administrator permission was not granted (you chose \u201cNo\u201d in the UAC prompt), so the installation did not continue." },    };
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
    // MIT 要求"版权声明与许可声明随软件副本一起提供"：装出来的目录里必须有一份 LICENSE。
    // 光在 README 里链一下不算 —— 发布版脚本被去掉了注释、两个 .cs 本来就没有版权头，
    // 安装目录里等于什么声明都没有，这是个实打实的许可合规缺口。
    const string PAYLOAD_LICENSE = "{PAYLOAD_LICENSE}";

    internal const string ScriptLeaf = "CAScreenGuard.ps1";
    internal const string IconLeaf = "CAScreenGuard.ico";
    internal const string EarlyLeaf = "ScreenLockEarly.cs";
    internal const string NativeLeaf = "ScreenLockNative.cs";
    internal const string LicenseLeaf = "LICENSE";
    internal const string LnkLeaf = "CAScreenGuard.lnk";
    internal const string AppName = "CAScreenGuard";
    internal const string AppVersion = "V3.1.1";
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

    static bool PayloadsLookSane()
    {
        // 忘了跑 build-setup.ps1 就直接拿 csc 编的话，四个占位符还是字面量：编译能过，
        // 到 Convert.FromBase64String 才炸，用户看到的是一句莫名其妙的 Base-64 报错。
        string[] ps = new string[] { PAYLOAD_PS1, PAYLOAD_ICO, PAYLOAD_EARLY, PAYLOAD_NATIVE, PAYLOAD_LICENSE };
        foreach (string s in ps)
        {
            if (s == null || s.Length < 64 || s.IndexOf('{') >= 0) { return false; }
        }
        return true;
    }

    // 静默安装也走一遍和向导相同的输入校验。不校验的话，
    // `setup.exe /silent <dir> "" "" ""` 会装出一个"回车即解锁"的空密码配置，而且没有任何提示。
    static string ValidateSilentInputs(string dir, string pwd, string auth, string hint, bool wantHotkey, string hotkey)
    {
        if (dir == null || dir.Trim().Length == 0) { return Str.S("k47"); }
        if (pwd == null || pwd.Length < 4) { return Str.S("k48"); }
        if (!IsPlainAscii(pwd)) { return Str.S("k49"); }
        if (auth == null || auth.Trim().Length < 6) { return Str.S("k51"); }
        if (!IsPlainAscii(auth.Trim())) { return Str.S("k52"); }
        if (string.Equals(auth.Trim(), pwd, StringComparison.Ordinal)) { return Str.S("k54"); }
        if (hint == null || hint.Trim().Length == 0) { return Str.S("k55"); }
        if (wantHotkey && hotkey != null && hotkey.Trim().Length > 0 && !IsHotkeyKey(hotkey)) { return Str.S("k56"); }
        return null;
    }

    [STAThread]
    public static void Main(string[] args)
    {
        try { SetProcessDPIAware(); } catch { }
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        // 界面语言的初值只在这里定一次（构造函数里再 Detect 会覆盖掉用户的选择）
        Str.Detect();

        try
        {
            // 提权助手模式：安装器以管理员身份被自己拉起来过一次，只做"建目录 + 授权"这件事。
            // 放在最前面，而且不弹任何界面 —— 用户看到的只是 UAC 那一下。
            // 升级入口：本机装过且能就地升级 → 一句问话，只换程序文件，凭据一个字节都不动。
            // 用户选"不"就直接退出 —— 绝不能落进下面的向导，那条路会走 Install 的"重装=清凭据"。
            if (args.Length == 0 || (args.Length == 1 && args[0].Equals("/upgrade", StringComparison.OrdinalIgnoreCase)))
            {
                string upDir, upWhy;
                if (CanUpgrade(out upDir, out upWhy))
                {
                    string oldVer = InstalledVersion();
                    if (string.IsNullOrEmpty(oldVer)) { oldVer = Str.S("k92"); }
                    string q = Str.S("k80") + oldVer + "\n" + upDir + "\n\n" + Str.S("k81");
                    if (MessageBox.Show(q, AppName + " " + AppVersion, MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                    {
                        string upMsg;
                        try { upMsg = DoUpgrade(upDir); }
                        catch (Exception upEx) { upMsg = Str.S("k93") + upEx.Message; }
                        MessageBox.Show(upMsg, AppName + " " + AppVersion, MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    return;
                }
                if (!string.IsNullOrEmpty(upWhy))
                {
                    MessageBox.Show(upWhy + Str.S("k94"), AppName + " " + AppVersion, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
            }            if (args.Length >= 3 && args[0].Equals("/prepare-dir", StringComparison.OrdinalIgnoreCase))
            {
                Environment.Exit(PrepareDirElevated(args[1], args[2]));
                return;
            }
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
                if (!PayloadsLookSane()) { msg = "ERROR: installer payload is missing - build with build-setup.ps1"; }
                else if (args.Length >= 5)
                {
                    bool link = !(args.Length > 5 && args[5].Equals("nolink", StringComparison.OrdinalIgnoreCase));
                    string hk = (args.Length > 6) ? args[6] : "";
                    msg = ValidateSilentInputs(args[1], args[2], args[3], args[4], link, hk);
                    if (msg == null)
                    {
                        try { msg = Install(args[1], args[2], args[3], args[4], link, hk); }
                        catch (Exception ex) { msg = "ERROR: " + ex.ToString(); }
                    }
                }
                else { msg = Str.S("k01"); }
                try { File.WriteAllText(Path.Combine(Path.GetTempPath(), "sg_setup_silent.log"), msg, new UTF8Encoding(false)); } catch { }
                return;
            }
            if (!PayloadsLookSane())
            {
                MessageBox.Show("ERROR: installer payload is missing - build with build-setup.ps1",
                                AppName + " " + AppVersion, MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            while (true) {
                SetupForm sf = new SetupForm();
                Application.Run(sf);
                if (sf.DialogResult != DialogResult.Retry) { break; }
            }
        }
        catch (Exception ex)
        {
            // 向导路径里任何漏网的异常都别让用户看到 .NET 的原始错误框，也不要静默退出
            try { MessageBox.Show(ex.Message, AppName + " " + AppVersion, MessageBoxButtons.OK, MessageBoxIcon.Error); } catch { }
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

    // ---------- 升级 ----------
    // "装过"不等于"能升级"：目录可能被挪走、配置可能被删、程序可能还开着。
    // 这几种情况一律只报原因、不动手 —— 唯一不能丢的是配置与外部凭证。
    internal static string InstalledVersion()
    {
        try
        {
            using (RegistryKey k = Registry.CurrentUser.OpenSubKey(StoreKey))
            {
                if (k != null) { object v = k.GetValue("Version"); return (v == null) ? null : v.ToString(); }
            }
        }
        catch { }
        return null;
    }

    internal static bool CanUpgrade(out string dir, out string why)
    {
        dir = null; why = null;
        if (!AlreadyInstalled()) { return false; }          // 干净机器：why 留空，正常走全新安装
        string oldDir = InstalledDir();
        if (string.IsNullOrEmpty(oldDir)) { why = Str.S("k83"); return false; }
        if (!Directory.Exists(oldDir)) { why = Str.S("k84") + oldDir; return false; }
        if (!LooksLikeOurInstall(oldDir)) { why = Str.S("k85") + oldDir; return false; }
        if (!File.Exists(Path.Combine(oldDir, CfgLeaf))) { why = Str.S("k86") + oldDir; return false; }
        try { if (File.Exists(Path.Combine(MirrorDir, "running.flag"))) { why = Str.S("k87"); return false; } }
        catch { }
        dir = oldDir;
        return true;
    }

    // 就地升级：只替换程序文件，配置/凭证/语言/快捷键/镜像/封禁记录/快捷方式全都原样留着。
    // 刻意**不调用** RemoveExternalCredentials、DeleteFolderTree、RemoveShortcut —— 一次都不。
    internal static string DoUpgrade(string dir)
    {
        string backup = Path.Combine(dir, "backup-" + DateTime.Now.ToString("yyyyMMdd-HHmmss"));
        string backupNote = "";
        try
        {
            Directory.CreateDirectory(backup);
            try { WriteRegistryBackup(backup); } catch { }   // 先存注册表，再存文件
            foreach (string leaf in new string[] { ScriptLeaf, IconLeaf, EarlyLeaf, NativeLeaf, LicenseLeaf, "uninstall.exe" })
            {
                string src = Path.Combine(dir, leaf);
                if (File.Exists(src)) { File.Copy(src, Path.Combine(backup, leaf), true); }
            }
        }
        catch { backupNote = Str.S("k88"); }

        // 先写 .new 再替换：中途失败时旧文件还在，不会留下半截脚本
        WritePayloadAtomic(dir, ScriptLeaf, PAYLOAD_PS1);
        WritePayloadAtomic(dir, IconLeaf, PAYLOAD_ICO);
        WritePayloadAtomic(dir, EarlyLeaf, PAYLOAD_EARLY);
        WritePayloadAtomic(dir, NativeLeaf, PAYLOAD_NATIVE);
        WritePayloadAtomic(dir, LicenseLeaf, PAYLOAD_LICENSE);

        string uninst = Path.Combine(dir, "uninstall.exe");
        try { File.Copy(Application.ExecutablePath, uninst, true); } catch { }

        // 只补一个 Version；Token/MarkerKey/AuthSalt/AuthHash/Provisioned/Lang/Hotkey 原样保留
        using (RegistryKey k = Registry.CurrentUser.CreateSubKey(StoreKey)) { k.SetValue("Version", AppVersion); }
        try
        {
            using (RegistryKey u = Registry.CurrentUser.CreateSubKey(UninstallKey))
            {
                u.SetValue("DisplayVersion", AppVersion.TrimStart('V'));
                u.SetValue("InstallLocation", dir);
                u.SetValue("DisplayIcon", uninst);
                u.SetValue("UninstallString", "\"" + uninst + "\" /uninstall");
            }
        }
        catch { }

        return Str.S("k89") + AppVersion + Str.S("k90") + dir + "\n" + backup + Str.S("k95") + "\n\n" + backupNote + Str.S("k91");
    }

    // 把两棵注册表键导成标准 .reg：双击即可还原。Token/AuthHash/AuthSalt/MarkerKey 这些
    // 凭证全在注册表里，只备份程序文件是不够的 —— 升级前必须留一份。
    static void WriteRegistryBackup(string dir)
    {
        StringBuilder sb = new StringBuilder();
        sb.AppendLine("Windows Registry Editor Version 5.00");
        AppendRegKey(sb, StoreKey);
        AppendRegKey(sb, UninstallKey);
        File.WriteAllText(Path.Combine(dir, "registry-backup.reg"), sb.ToString(), new UnicodeEncoding(false, true));
    }

    static void AppendRegKey(StringBuilder sb, string path)
    {
        sb.AppendLine();
        sb.AppendLine("[HKEY_CURRENT_USER\\" + path + "]");
        using (RegistryKey k = Registry.CurrentUser.OpenSubKey(path))
        {
            if (k == null) { return; }
            foreach (string name in k.GetValueNames())
            {
                if (string.IsNullOrEmpty(name)) { continue; }
                object v = k.GetValue(name);
                if (k.GetValueKind(name) == RegistryValueKind.DWord)
                {
                    sb.AppendLine("\"" + name + "\"=dword:" + Convert.ToInt64(v).ToString("x8"));
                }
                else
                {
                    string s = (v == null) ? "" : v.ToString();
                    sb.AppendLine("\"" + name + "\"=" + "\"" + s.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"");
                }
            }
        }
    }
    static void WritePayloadAtomic(string dir, string leaf, string payloadB64)
    {
        string target = Path.Combine(dir, leaf);
        string temp = target + ".new";
        File.WriteAllBytes(temp, Convert.FromBase64String(payloadB64));
        if (File.Exists(target))
        {
            try { File.Replace(temp, target, null); return; } catch { }
            try { File.Delete(target); } catch { }
        }
        if (File.Exists(temp)) { File.Move(temp, target); }
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
            // 目录自身带只读/隐藏属性时，Directory.Delete(recursive) 一样会失败；
            // 失败又会被上层判成"删不掉 → 程序还在运行"，把用户引到错误方向
            foreach (string d in Directory.GetDirectories(dir, "*", SearchOption.AllDirectories))
            {
                try { File.SetAttributes(d, FileAttributes.Normal); } catch { }
            }
            Directory.Delete(dir, true);
        }
        catch { }
        return !Directory.Exists(dir);
    }

    // 程序运行时在 %LOCALAPPDATA%\CAScreenGuard 下放标记文件、崩溃日志与屏保原值。
    // 路径必须和脚本里的 $script:StateDir 一致 —— 这里以前多写了一层 "state"，
    // 结果卸载时删的是个从不存在的目录，真正的运行现场一份都没被清掉。
    internal static string StateDir
    {
        get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CAScreenGuard"); }
    }

    // 只删运行现场的那几个文件，绝不整树删 StateDir ——
    // 用默认安装位置时 StateDir 正是安装目录的上一层，整树删会把安装目录一起端掉。
    static void RemoveStateFiles()
    {
        try
        {
            if (!Directory.Exists(StateDir)) { return; }
            foreach (string f in new string[] { "running.flag", "screen-saver-original.json", "tick-errors.log" })
            {
                try
                {
                    string p = Path.Combine(StateDir, f);
                    if (File.Exists(p)) { File.SetAttributes(p, FileAttributes.Normal); File.Delete(p); }
                }
                catch { }
            }
            foreach (string p in Directory.GetFiles(StateDir, "crash-*.log"))
            {
                try { File.SetAttributes(p, FileAttributes.Normal); File.Delete(p); } catch { }
            }
        }
        catch { }
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
    // dirPreparedByUs：提权助手刚替我们建好目录、并把写权限授给了当前用户，这一次要认下它
    public static string Install(string baseDir, string lockPwd, string authCode, string authHint, bool createLink, string hotkeyKey)
    {
        return Install(baseDir, lockPwd, authCode, authHint, createLink, hotkeyKey, false);
    }

    public static string Install(string baseDir, string lockPwd, string authCode, string authHint, bool createLink, string hotkeyKey, bool dirPreparedByUs)
    {
        string dir = Path.Combine(baseDir, SubFolderName);
        // 顺序有讲究：**先确认新位置能用，再销毁旧安装**。
        // 反过来的话，用户把位置换到一个已经有同名文件夹、或者根本没权限写的地方时，
        // 旧安装的注册表与 APPDATA 镜像（授权码哈希唯一的家）已经被删掉，新安装又失败 ——
        // 授权码将永久找不回来，改密码与"配置重建"两条路一起废。
        if (Directory.Exists(dir))
        {
            // 提权助手建完目录会留下一个空目录，这是唯一允许"接管"的情况，而且只认空目录 ——
            // 里面有东西就说明不是我们刚建的，照旧报"已经有同名的了"。
            bool adopt = dirPreparedByUs && Directory.GetFileSystemEntries(dir).Length == 0;
            if (!adopt) { return Str.S("k04") + dir + Str.S("k05"); }
        }
        try
        {
            Directory.CreateDirectory(dir);
            // 不要在这里写探针文件（例如 .write-probe）：杀软和 Windows Defender 的
            // "受控文件夹访问"专门拦这种可疑名字，探针被拦就会被当成"没权限"而劝退 ——
            // 而那个位置其实是能写的。用户看到的现象就是"无论装到哪里都说没有权限"。
            // 权限判定只留 Directory.CreateDirectory 这一处（它抛就说明真写不进去）。
        }
        catch
        {
            try { Directory.Delete(dir, true); } catch { }
            throw;
        }
        // 本机装过就直接重装：把上一次那一整套（程序、配置、整个文件夹）端掉
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
            RemoveExternalCredentials();
            // 上一版的桌面快捷方式也要清掉：它指向的是旧目录，留着就会变成一个点了没反应的图标
            RemoveShortcut();
        }
        try
        {
            File.WriteAllBytes(Path.Combine(dir, ScriptLeaf), Convert.FromBase64String(PAYLOAD_PS1));
            File.WriteAllBytes(Path.Combine(dir, IconLeaf), Convert.FromBase64String(PAYLOAD_ICO));
            // 脚本运行时要 Add-Type 加载这两个 C# 源文件，必须和脚本放在一起
            File.WriteAllBytes(Path.Combine(dir, EarlyLeaf), Convert.FromBase64String(PAYLOAD_EARLY));
            File.WriteAllBytes(Path.Combine(dir, NativeLeaf), Convert.FromBase64String(PAYLOAD_NATIVE));
            // MIT 的通知义务：版权与许可声明要跟着副本走，README 里链一下不算。
            // 所以每一份安装都在安装目录里落一份 LICENSE（原样字节，不改行尾）。
            File.WriteAllBytes(Path.Combine(dir, LicenseLeaf), Convert.FromBase64String(PAYLOAD_LICENSE));
        }
        catch
        {
            // 落地失败（杀软把脚本拦下来、磁盘满……）：把刚建的这个文件夹清掉再抛。
            // 留着的话，用户再点安装只会看到「已经有 CAScreenGuard-当天日期 了」，
            // 而那一次其实什么都没装上。
            try { Directory.Delete(dir, true); } catch { }
            throw;
        }

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
            k.SetValue("Version", AppVersion);
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
        // 重新安装 = 全新的开始：连"授权码永久封禁"一起清掉。
        // 这里只删封禁记录 —— 注册表刚写好、副本刚写完，不能整块走 RemoveExternalCredentials。
        try { string ban = Path.Combine(MirrorDir, "authban.txt"); if (File.Exists(ban)) { File.Delete(ban); } } catch { }

        string lnkNote;
        // 快捷键也写进快捷方式的说明里：鼠标停在桌面图标上就能看到，不用翻设置
        string desc = AppName + Str.S("k06");
        string hkDesc = HotkeyText(hotkeyKey);
        if (hkDesc.Length > 0) { desc = desc + " (" + hkDesc + ")"; }
        if (createLink)
        {
            CreateShortcut(Path.Combine(DesktopDir, LnkLeaf), Path.Combine(SystemDir, "conhost.exe"),
                "--headless powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + Path.Combine(dir, ScriptLeaf) + "\"",
                dir, Path.Combine(dir, IconLeaf), desc, hotkeyKey);
            if (hkDesc.Length > 0) { lnkNote = Str.S("k07") + AppName + Str.S("k08") + hkDesc + Str.S("k09"); }
            else { lnkNote = Str.S("k10") + AppName + Str.S("k73"); }
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
            u.SetValue("DisplayVersion", AppVersion.TrimStart('V'));
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
    // 删掉"外部凭证"那几样：注册表里的两棵树 + APPDATA 副本 + 授权码封禁记录。
    // 安装（重装前清理）和卸载走的是同一套，收在一处免得两边改漏。
    // 返回 true 表示有东西没删干净（调用方据此提示用户"可能还有残留"）
    static bool RemoveExternalCredentials()
    {
        bool leftovers = false;
        try { Registry.CurrentUser.DeleteSubKeyTree(StoreKey, false); } catch { }
        try { Registry.CurrentUser.DeleteSubKeyTree(UninstallKey, false); } catch { }
        try { if (File.Exists(MirrorPath)) { File.Delete(MirrorPath); } } catch { leftovers = true; }
        try { string ban = Path.Combine(MirrorDir, "authban.txt"); if (File.Exists(ban)) { File.Delete(ban); } } catch { leftovers = true; }
        try { string mdir = MirrorDir; if (Directory.Exists(mdir) && Directory.GetFileSystemEntries(mdir).Length == 0) { Directory.Delete(mdir); } } catch { }
        return leftovers;
    }

    // 删桌面快捷方式；删完要通知资源管理器，否则它注册的全局快捷键会一直残留到注销/重启。
    // 返回 false 表示没删干净（装的时候也用它清理上一版的快捷方式，那种情况不关心返回值）。
    static bool RemoveShortcut()
    {
        try
        {
            string lnk = Path.Combine(DesktopDir, LnkLeaf);
            if (File.Exists(lnk))
            {
                File.Delete(lnk);
                NotifyShell(lnk);
            }
            return true;
        }
        catch { return false; }
    }

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
        bool leftovers = false;
        leftovers = RemoveExternalCredentials();
        // 快捷方式删不掉同样算残留；删掉后要通知资源管理器，
        // 否则它注册的全局快捷键会一直残留到注销/重启
        if (!RemoveShortcut()) { leftovers = true; }
        string msg = Str.S("k16");
        if (leftovers) { msg += Str.S("k74"); }
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
            // 程序运行时留下的现场（running.flag / crash-*.log / tick-errors.log / 屏保原值）也清掉
            RemoveStateFiles();
            // 上一层（用户挑的安装位置）空了就删；里面还有别的东西则绝不碰。
            // 这里曾经按"是不是我们建的"加过一道条件，结果父目录彻底删不掉了 —— 回退成按空判定。
            RemoveIfEmpty(Path.GetDirectoryName(dir.TrimEnd('\\')));
            ScheduleFolderDelete(dir, true);
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
    static void ScheduleFolderDelete(string dir, bool alsoParent)
    {
        try
        {
            string exeDir = Path.GetDirectoryName(Path.GetFullPath(Application.ExecutablePath));
            if (string.IsNullOrEmpty(exeDir) || string.IsNullOrEmpty(dir)) { return; }
            if (!Path.GetFullPath(dir).TrimEnd('\\').Equals(exeDir.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase)) { return; }
            string sys = Environment.GetFolderPath(Environment.SpecialFolder.System);
            // 等 2 秒再动手，而且失败要重试：uninstall.exe 自己还占着目录时 rd 会失败，
            // "失败就算了"的结果就是留下一个空文件夹，用户会以为没卸干净。
            string cmd = "/c ping -n 3 127.0.0.1 >nul & for /L %i in (1,1,8) do @(rd /s /q \"" + Path.GetFullPath(dir).TrimEnd('\\') + "\"";
            if (alsoParent) { cmd += " & rd /q \"" + Path.GetDirectoryName(Path.GetFullPath(dir).TrimEnd('\\')) + "\""; }
            cmd += " & ping -n 2 127.0.0.1 >nul)";
            ProcessStartInfo psi = new ProcessStartInfo(Path.Combine(sys, "cmd.exe"), cmd);
            psi.CreateNoWindow = true;
            psi.UseShellExecute = false;
            psi.WorkingDirectory = sys;
            Process.Start(psi);
        }
        catch { }
    }

    // ---------- 提权助手（只建目录 + 授权，永远不接触密码） ----------
    // 用户在 C:\Program Files 这类位置装的时候，安装器自己是写不进去的。
    // 做法：再拉一个自己的副本、以管理员身份跑一次这一段，让它只干"建好那个目录、
    // 把写权限授给发起安装的那个账户"；然后没提权的这一边接着往里装。
    // 这么拆的三个好处：密码/授权码永远不会出现在命令行（命令行是别的进程能读到的）；
    // 提权的那半边代码小、只碰目录权限，不碰密码和配置；装完的文件所有者是你自己，
    // 以后程序写配置、日志、卸载都不需要再提权。
    internal static string CurrentUserSid()
    {
        try { return System.Security.Principal.WindowsIdentity.GetCurrent().User.Value; }
        catch { return ""; }
    }

    // SID 只允许 S-1-5-21-... 这种形状：它会被拼进 icacls 的命令行，不能带引号空格等杂字符
    static bool LooksLikeSid(string s)
    {
        if (string.IsNullOrEmpty(s) || s.Length < 5) { return false; }
        if (s[0] != 'S' || s[1] != '-') { return false; }
        for (int i = 2; i < s.Length; i++)
        {
            if (!char.IsDigit(s[i]) && s[i] != '-') { return false; }
        }
        return true;
    }

    // 提权那一侧的执行体。返回：0=成功，1223=用户在 UAC 上点了「否」，其余非 0=失败。
    // 只认本程序自己的「CAScreenGuard-日期」目录名，免得这个开关被当成"给任意目录授权"的工具。
    internal static int PrepareDirElevated(string dir, string sid)
    {
        // 每一步的失败都留一行现场：这个进程一闪就退，没有日志就无从查起
        if (string.IsNullOrEmpty(dir) || !Path.IsPathRooted(dir)) { WritePrepareLog(dir, sid, 1, "路径不是绝对路径"); return 1; }
        string clean = dir.TrimEnd('\\');
        string leaf = Path.GetFileName(clean);
        if (string.IsNullOrEmpty(leaf) || !leaf.StartsWith(AppName + "-", StringComparison.OrdinalIgnoreCase)) { WritePrepareLog(clean, sid, 2, "目录名不是 CAScreenGuard- 开头"); return 2; }
        if (string.IsNullOrEmpty(Path.GetDirectoryName(clean))) { WritePrepareLog(clean, sid, 3, "拒绝操作盘根"); return 3; }   // 别去动盘根
        if (!LooksLikeSid(sid)) { WritePrepareLog(clean, sid, 4, "SID 形状不对"); return 4; }
        try { Directory.CreateDirectory(clean); }
        catch (Exception ex) { WritePrepareLog(clean, sid, 5, "建目录失败：" + ex.GetType().Name + " " + ex.Message); return 5; }
        return GrantWrite(clean, sid) ? 0 : 6;
    }

    // icacls "目录" /grant *SID:(OI)(CI)M —— 用 SID 授权，不受账户显示名/语言影响
    static bool GrantWrite(string dir, string sid)
    {
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "icacls.exe"));
            psi.Arguments = "\"" + dir + "\" /grant *" + sid + ":(OI)(CI)M";
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            // 不把子进程的输出读掉的话，管道写满了 icacls 会卡住不退出
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            using (Process p = Process.Start(psi))
            {
                p.StandardOutput.ReadToEnd();
                string err = p.StandardError.ReadToEnd();
                if (!p.WaitForExit(60000)) { try { p.Kill(); } catch { } return false; }
                if (p.ExitCode == 0) { return true; }
                WritePrepareLog(dir, sid, p.ExitCode, err);
                return false;
            }
        }
        catch (Exception ex) { WritePrepareLog(dir, sid, -1, ex.Message); return false; }
    }

    // 提权那一步失败时留个现场：它自己的窗口一闪就没了，没有这个文件就无从查起
    static void WritePrepareLog(string dir, string sid, int code, string detail)
    {
        try
        {
            string path = Path.Combine(Path.GetTempPath(), "sg_prepare_dir.log");
            File.AppendAllText(path, DateTime.Now.ToString("s") + "  dir=" + dir + "  sid=" + sid +
                               "  code=" + code + "\n" + detail + "\n\n", new UTF8Encoding(false));
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
    Label lblWelcome, lblAuthor, lblIntro, lblPlugin, lblAv, lblLang;
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

        // 语言初值由 Main 里的 Str.Detect() 定，这里绝不能再 Detect 一次 ——
        // 「切换语言 → 重开向导」会走这个构造函数，再 Detect 就会用系统语言把用户的选择覆盖掉，
        // 非中文系统上永远切不到中文。
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
            // 优先用嵌在安装包里的那张 256 图标（清晰），取不到才退回 exe 自己的图标。
            // Icon 是一次性的：用完必须 Dispose（.ToBitmap() 出来的那份交给 PictureBox 托管）。
            Bitmap _big = LoadAppIconBitmap(S(76));
            if (_big != null) { pic.Image = _big; }
            else {
                using (Icon ic = Icon.ExtractAssociatedIcon(Application.ExecutablePath))
                {
                    if (ic != null) { pic.Image = new Bitmap(ic.ToBitmap(), S(76), S(76)); }
                }
            }
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
        lblIntro.Location = new Point(S(30), S(118));
        lblIntro.Size = new Size(S(500), S(80));
        pageWelcome.Controls.Add(lblIntro);

        // 配套插件提示：只有首次安装会看到这个页面（升级走另一条路，不进向导）
        lblPlugin = new Label();
        lblPlugin.AutoSize = false;
        lblPlugin.Font = new Font(UIFont, 8.5F, FontStyle.Regular, GraphicsUnit.Point);
        lblPlugin.ForeColor = Color.FromArgb(70, 78, 92);
        lblPlugin.TextAlign = ContentAlignment.TopLeft;
        lblPlugin.Location = new Point(S(30), S(202));
        lblPlugin.Size = new Size(S(500), S(48));
        pageWelcome.Controls.Add(lblPlugin);

        lblAv = new Label();
        lblAv.AutoSize = false;
        lblAv.Font = new Font(UIFont, 8.5F, FontStyle.Regular, GraphicsUnit.Point);
        lblAv.ForeColor = Color.FromArgb(96, 100, 108);   // 正常颜色，不做警告红
        lblAv.TextAlign = ContentAlignment.TopLeft;
        lblAv.Location = new Point(S(30), S(254));
        lblAv.Size = new Size(S(500), S(62));
        pageWelcome.Controls.Add(lblAv);

        lnkReadme = new LinkLabel();
        lnkReadme.AutoSize = false;
        lnkReadme.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        lnkReadme.LinkColor = Color.FromArgb(0, 102, 204);
        lnkReadme.TextAlign = ContentAlignment.MiddleLeft;
        lnkReadme.Location = new Point(S(30), S(320));
        lnkReadme.Size = new Size(S(500), S(26));
        lnkReadme.LinkClicked += new LinkLabelLinkClickedEventHandler(OnReadme);
        pageWelcome.Controls.Add(lnkReadme);

        lblLang = new Label();
        lblLang.AutoSize = false;
        lblLang.Font = new Font(UIFont, 9F, FontStyle.Regular, GraphicsUnit.Point);
        lblLang.ForeColor = Color.FromArgb(70, 78, 92);
        lblLang.TextAlign = ContentAlignment.MiddleLeft;
        lblLang.Location = new Point(S(30), S(350));
        lblLang.Size = new Size(S(100), S(26));
        pageWelcome.Controls.Add(lblLang);

        cboLang = new ComboBox();
        cboLang.DropDownStyle = ComboBoxStyle.DropDownList;
        cboLang.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        cboLang.Location = new Point(S(146), S(350));
        cboLang.Size = new Size(S(150), S(26));
        cboLang.Items.Add("简体中文");
        cboLang.Items.Add("English");
        cboLang.SelectedIndex = (Str.Lang == "en") ? 1 : 0;
        cboLang.SelectedIndexChanged += new EventHandler(OnLangChanged);
        pageWelcome.Controls.Add(cboLang);

        Button btnNext = new Button();
        btnNext.Name = "btnNext";
        btnNext.Font = new Font(UIFont, 9.5F, FontStyle.Regular, GraphicsUnit.Point);
        btnNext.Location = new Point(S(352), S(350));
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
        btnQuit.Location = new Point(S(448), S(350));
        btnQuit.Size = new Size(S(84), S(30));
        pageWelcome.Controls.Add(btnQuit);
    }

    void ShowPage(bool install)
    {
        pageWelcome.Visible = !install;
        pageInstall.Visible = install;
        ClientSize = install ? new Size(S(560), S(620)) : new Size(S(560), S(404));
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
        lblPlugin.Text = Str.S("k96");
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

    // 安装本身失败（不是表单校验）走这里。状态行只有 504px 宽，而 k60 正文量出来就有 931px：
    // 超出的部分被控件直接裁掉，而"底层错误"恰恰在最后 —— 用户看到的就是一句半截话，
    // 反馈不出任何有用信息。所以照旧写状态行，另外再弹一个对话框把整段显示出来（里面能选中复制）。
    // 需要提权时这个对话框会多给一个带盾牌的「以管理员身份重试」，用户点了才返回 true。
    bool ShowFailure(string msg, bool offerElevate)
    {
        Fail(msg);
        using (FailureForm f = new FailureForm(msg, offerElevate))
        {
            f.ShowDialog(this);
            return f.Retry;
        }
    }

    // 跑一次安装，把结果翻译成人能看的话。canElevate 只在"没权限"这一种失败上为 true。
    bool TryInstall(string baseDir, string pwd, string auth, string hint, bool link, string hotkey, bool dirPrepared,
                    out string msg, out string failure, out bool canElevate)
    {
        msg = ""; failure = ""; canElevate = false;
        try
        {
            msg = CAScreenGuardInstaller.Install(baseDir, pwd, auth, hint, link, hotkey, dirPrepared);
            return true;
        }
        catch (UnauthorizedAccessException ex) { canElevate = true; failure = String.Format(Str.S("k60"), Describe(ex)); }
        catch (IOException ex) { failure = Str.S("k61") + Describe(ex); }
        catch (Exception ex) { failure = Str.S("k62") + Describe(ex); }
        return false;
    }

    // 拉一个自己的副本、以管理员身份跑 /prepare-dir：让它建好安装目录并把写权限授给我。
    // 返回 0=成功；1223=用户在 UAC 上点了「否」；其它=失败。密码不进命令行，这里只传目录和 SID。
    int ElevatePrepareDir(string dir)
    {
        ProcessStartInfo psi = new ProcessStartInfo(Application.ExecutablePath);
        psi.Arguments = "/prepare-dir \"" + dir + "\" " + CAScreenGuardInstaller.CurrentUserSid();
        psi.UseShellExecute = true;      // 只有走 ShellExecute 才能带 runas
        psi.Verb = "runas";
        try
        {
            using (Process p = Process.Start(psi))
            {
                if (!p.WaitForExit(180000)) { try { p.Kill(); } catch { } return 9; }
                return p.ExitCode;
            }
        }
        catch (System.ComponentModel.Win32Exception wex) { return wex.NativeErrorCode; }   // 1223 = 用户拒绝
        catch { return 9; }
    }

    // 异常的类型名和 HResult 一定在，ex.Message 却可能为空（个别异常不给说明文字）。
    // 只打 Message 的话，用户看到的是"底层错误："后面什么都没有 —— 连往哪查都无从下手。
    static string Describe(Exception ex)
    {
        string head = ex.GetType().Name + " 0x" + ex.HResult.ToString("X8");
        if (string.IsNullOrEmpty(ex.Message)) { return head; }
        return head + "：" + ex.Message;
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

        string msg = "";
        string failure = "";
        bool canElevate = false;
        bool ok;
        Cursor = Cursors.WaitCursor;
        // Install 在 UI 线程上同步跑 3~10 秒，期间窗口会被系统标记"未响应"，先禁掉免得被反复点
        btnInstall.Enabled = false;
        btnInstall.Refresh();
        Status(Str.S("k72"));
        try
        {
            ok = TryInstall(full, pwd, auth, hint, chkLink.Checked, hotkey, false, out msg, out failure, out canElevate);
            if (!ok)
            {
                // 写不进去 → 问一句要不要以管理员身份再来一次（盾牌按钮）；别的失败就只是报告
                if (canElevate)
                {
                    if (ShowFailure(failure, true))
                    {
                        int rc = ElevatePrepareDir(target);
                        if (rc == 1223) { failure = Str.S("k79"); }
                        else if (rc != 0) { failure = Str.S("k78") + failure; }
                        else
                        {
                            Status(Str.S("k72"));
                            ok = TryInstall(full, pwd, auth, hint, chkLink.Checked, hotkey, true, out msg, out failure, out canElevate);
                            if (!ok) { failure = Str.S("k78") + failure; }
                        }
                        if (!ok) { ShowFailure(failure, false); }
                    }
                }
                else { ShowFailure(failure, false); }
            }
        }
        finally
        {
            Cursor = Cursors.Default;
            btnInstall.Enabled = true;
        }
        if (!ok) { return; }

        MessageBox.Show(this, msg, Str.S("k63") + CAScreenGuardInstaller.AppName + " " + CAScreenGuardInstaller.AppVersion, MessageBoxButtons.OK, MessageBoxIcon.Information);
        DialogResult = DialogResult.OK;
        Close();
    }
}

// ---------- 失败详情对话框 ----------
// 为什么不用 MessageBox：它的文字不能选中复制，长文本也照样被裁；而这里要显示的那段
// 恰恰是用户唯一能反馈给我们的东西。所以用只读多行文本框把整段摊开，需要提权时再补一个盾牌按钮。
public class FailureForm : Form
{
    public bool Retry;
    float s = 1F;
    int S(int v) { return (int)Math.Round(v * (double)s); }

    public FailureForm(string msg, bool offerElevate)
    {
        AutoScaleMode = AutoScaleMode.None;
        using (Graphics g = CreateGraphics()) { s = g.DpiX / 96F; }
        if (s < 1F) { s = 1F; }

        Text = CAScreenGuardInstaller.AppName + " " + CAScreenGuardInstaller.AppVersion;
        Font = new Font("Microsoft YaHei UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.CenterParent;
        int h = offerElevate ? 286 : 232;
        ClientSize = new Size(S(560), S(h));

        int top = 16;
        if (offerElevate)
        {
            PictureBox pic = new PictureBox();
            pic.Image = SystemIcons.Shield.ToBitmap();
            pic.SizeMode = PictureBoxSizeMode.AutoSize;
            pic.Location = new Point(S(20), S(top));
            pic.BackColor = Color.Transparent;
            Controls.Add(pic);
        }

        TextBox txt = new TextBox();
        txt.Multiline = true;
        txt.ReadOnly = true;
        txt.WordWrap = true;
        txt.ScrollBars = ScrollBars.Vertical;
        txt.BackColor = Color.White;
        txt.BorderStyle = BorderStyle.FixedSingle;
        txt.Text = msg;
        txt.Location = new Point(S(offerElevate ? 66 : 20), S(top));
        txt.Size = new Size(S(offerElevate ? 474 : 520), S(152));
        Controls.Add(txt);

        if (offerElevate)
        {
            Label hint = new Label();
            hint.Text = Str.S("k77");
            hint.AutoSize = false;
            hint.Location = new Point(S(20), S(178));
            hint.Size = new Size(S(520), S(52));
            hint.ForeColor = Color.FromArgb(60, 68, 80);
            hint.BackColor = Color.Transparent;
            Controls.Add(hint);
        }

        Button btnRetry = null;
        if (offerElevate)
        {
            btnRetry = new Button();
            btnRetry.Text = Str.S("k75");
            btnRetry.Location = new Point(S(316), S(offerElevate ? 238 : 190));
            btnRetry.Size = new Size(S(134), S(30));
            btnRetry.Click += new EventHandler(OnRetry);
            Controls.Add(btnRetry);
        }

        Button btnClose = new Button();
        btnClose.Text = Str.S("k76");
        btnClose.Location = new Point(S(offerElevate ? 458 : 456), S(offerElevate ? 238 : 190));
        btnClose.Size = new Size(S(82), S(30));
        btnClose.Click += new EventHandler(OnClose);
        Controls.Add(btnClose);

        // 默认键给「关闭」：回车不该顺手把 UAC 拉起来
        CancelButton = btnClose;
        AcceptButton = btnClose;
        // 这里刻意不设 ActiveControl：试过让焦点落在「关闭」上，避开只读文本框一拿到焦点就整段全选
        // 的难看样子，结果构造函数直接把进程搞崩了（反射探针里 OnInstall 没返回、窗口 0x0 就消失）。
        // 全选其实也不算坏事 —— 用户点一下框子就能 Ctrl+C 把整段错误发给作者。
    }

    void OnRetry(object sender, EventArgs e)
    {
        Retry = true;
        DialogResult = DialogResult.OK;
        Close();
    }

    void OnClose(object sender, EventArgs e)
    {
        Retry = false;
        DialogResult = DialogResult.Cancel;
        Close();
    }
}
