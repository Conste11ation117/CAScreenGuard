#Requires -Version 5.1
<#
  CAScreenGuard by Conste11ation117
  ==========================================================================
  它做什么：运行后立刻关闭显示器（只关屏：不休眠、不锁定、保持系统唤醒），
            并在最上层盖一层全屏黑色遮罩挡住桌面内容。
            只有输入正确的解锁密码，才会恢复屏幕并退出本脚本。

  怎么启动：运行安装程序（CAScreenGuard-Setup.exe）装好之后，双击桌面上的「CAScreenGuard」快捷方式即可
            （不会闪出终端窗口）。解锁密码与授权码都在安装向导里设置。

  文件构成：CAScreenGuard.ps1（本脚本）+ ScreenLockEarly.cs + ScreenLockNative.cs（原生调用的 C# 源码）
            + CAScreenGuard.ico，四个文件必须放在同一个目录里 —— 脚本运行时会 Add-Type 加载那两个 .cs。
            安装程序会把这四份一起放进安装目录，不用手工处理。

  熄屏后可以按什么（锁屏界面上也写着）：
        任意键 / 移动鼠标        → 点亮屏幕、显示密码框（桌面内容始终被遮住）
        输入解锁密码 + Enter     → 解锁：恢复屏幕并退出
        Ctrl + Backspace         → 清空已输入内容（Ctrl + U 同效）
        Esc                      → 立刻再次熄屏（已输入内容会保留）
        无操作 25 秒             → 自动再次熄屏（已输入内容会保留）
        Ctrl + Shift + Alt + E   → 打开「修改解锁密码」，需要输入授权码

  密码怎么存：解锁密码与授权码都只保存「加盐哈希」（PBKDF2），不保存明文。
            配置文件 .cascreenguard.config.json 是隐藏文件，与脚本放在同一目录；
            同时在注册表和 %APPDATA%\CAScreenGuard 里各存一份「外部凭证」。
            授权码一经安装定版、不能再改，是「忘记解锁密码」时唯一的凭据；
            界面上只显示安装时写的「授权码提示」（提示是明文，别把密码本身写进去）。

  配置文件被动过怎么办：配置文件里带一段 HMAC 摘要，密钥在外部凭证里。
            一旦文件被删除、或者内容被改动，脚本会明确报警并且拒绝直接开锁，
            要求先用授权码确认身份，再设一个新的解锁密码。

  忘记解锁密码怎么办：按 Ctrl + Shift + Alt + E → 输入授权码 → 设一个新的解锁密码。

  锁屏期间还会吞掉 Win / Alt+Tab / Alt+Esc / Ctrl+Esc，免得有人用开始菜单、
        窗口缩略图、Win+G 看到你的桌面内容；其余按键一律放行。

  命令行选项：-ResetPassword   直接打开「修改解锁密码」（需要当前授权码；这一次不熄屏）
              -SelfTest        自检：不改动显示器电源，只验证脚本与界面是否正常

  边界说明：本脚本以当前用户权限运行，用来「无人值守时防止别人随手翻看屏幕」。
            它不锁定 Windows 会话（后台任务照常运行），也不是不可绕过的安全边界。
#>

[CmdletBinding()]
param(
    # 重设解锁密码
    [switch]$ResetPassword,
    # 熄屏界面多久无人操作后自动再次熄屏（秒）
    [ValidateRange(5, 600)][int]$IdleBlankSeconds = 25,
    # 自检模式：不改动显示器电源，只验证脚本与界面能否正常工作
    [switch]$SelfTest,
    # 只显示版本与作者，然后退出
    [switch]$Ver,
    # 界面语言：auto = 跟随外部凭证里安装时选的，其次跟随系统；也可以强制 zh / en
    [ValidateSet('auto', 'zh', 'en')][string]$Lang = 'auto'
)

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------ 界面语言
# 显示在所有弹出窗口标题里的版本号
$script:AppVersion = 'V1.0.1'
if ($Ver) {
    Write-Host ('CAScreenGuard ' + $script:AppVersion)
    Write-Host '作者 / Author : @Conste11ation117'
    Write-Host '许可 / License: MIT'
    exit 0
}
# 两种语言的界面文案都在这里，T '键' 取当前语言的文本。
# 语言优先级：-Lang 参数 > 外部凭证里记的（安装时选的） > 系统界面语言。
# 注意：脚本作用域里 $script:Lang 和参数 $Lang 是同一个变量，下面一赋值就会把参数冲掉，
# 所以必须先把参数抄到 $script:LangArg 里存着，否则 -Lang 参数和安装时选的语言都会失效。
$script:LangArg = [string]$Lang
$script:Lang = 'zh'
try {
    $ui = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    if ($ui -notlike 'zh*') { $script:Lang = 'en' }
} catch { }
$script:T = @{
    zh = @{
        k01 = "CAScreenGuard 缺少必需的文件：`n`n"
        k02 = "`n`n脚本、两个 .cs 和图标必须放在同一个目录里。请重新运行安装程序。"
        k03 = 'CAScreenGuard ' + $script:AppVersion + ' · 文件不完整'
        k04 = 'CAScreenGuard ' + $script:AppVersion + ' · 发生错误'
        k05 = '无法保存密码配置。'
        k06 = "密码错误次数较多，请等待 {0} 秒后再试"
        k08 = "密码不正确，请等待 {0} 秒后重试"
        k09 = '密码不正确，请重新输入'
        k10 = '本机没有可用的授权码，无法修改解锁密码。请重新运行安装程序。'
        k11 = '（未设置提示）'
        k12 = 'CAScreenGuard ' + $script:AppVersion + ' · 修改解锁密码'
        k13 = '修改解锁密码'
        k14 = "为确认是你本人，需要先输入授权码。（区分大小写）`n授权码提示：{0}"
        k15 = '授权码'
        k16 = '新解锁密码（至少 4 位，只用英文/数字/符号）'
        k17 = '确认新密码'
        k18 = '保存'
        k19 = '取消'
        k21 = '新密码至少需要 4 个字符。'
        k22 = '新密码只能用英文、数字和符号，不能用空格和中文。'
        k23 = '两次输入的新密码不一致，请重新输入。'
        k24 = '保存失败：'
        k25 = '解锁密码已更新：请用新密码解锁'
        k26 = '授权码连续错误 3 次，已取消修改'
        k27 = '本机没有可用的授权码，无法修改解锁密码'
        k28 = '（没有留下提示）'
        k29 = 'CAScreenGuard ' + $script:AppVersion + ' · 配置需要重建'
        k30 = '保存解锁密码的文件不见了，或者被动过'
        k31 = "这多半不是意外：文件要么被删除、要么被改写，原来的解锁密码已经作废。`n"
        k32 = "在确认是你本人之前，CAScreenGuard 不会重新开始 —— 免得有人趁这个机会换掉解锁密码。`n"
        k33 = "请用授权码确认身份，然后设一个新的解锁密码。`n"
        k34 = "授权码提示：{0}（区分大小写）"
        k35 = '授权码'
        k36 = '新解锁密码（至少 4 位，只用英文/数字/符号）'
        k37 = '确认新解锁密码'
        k38 = '确认并继续'
        k39 = '退出'
        k42 = '新密码至少需要 4 个字符。'
        k43 = '新密码只能用英文、数字和符号，不能用空格和中文。'
        k44 = '两次输入的新密码不一致，请重新输入。'
        k45 = '保存失败：'
        k46 = 'CAScreenGuard 已经在运行中，无需重复启动。'
        k47 = "本机还没有装过 CAScreenGuard。`n`n请先运行安装程序（CAScreenGuard-Setup.exe）：解锁密码和授权码都在安装向导里设置，装好后用桌面上的快捷方式启动。"
        k48 = "本机缺少 CAScreenGuard 的凭证，没法核实这份配置是谁写的。`n`n为了不让人趁这个机会换掉解锁密码，这次不会启动屏锁。`n请重新运行安装程序（先卸载，再安装）。"
        k49 = 'CAScreenGuard ' + $script:AppVersion + ' · 配置无法核实'
        k50 = '你取消了重建，所以这次不会启动屏锁。'
        k51 = '授权码连续输错 3 次，所以这次不会启动屏锁。'
        k52 = "解锁密码没有重建成功。`n`n"
        k53 = 'CAScreenGuard ' + $script:AppVersion + ' · 配置需要重建'
        k54 = '息屏保护中'
        k55 = '输入解锁密码，按 Enter 恢复屏幕'
        k56 = 'Enter 解锁　·　Ctrl+Backspace 清空　·　Esc 立即息屏　·　Ctrl+Shift+Alt+E 修改密码'
        k57 = '屏幕熄灭时，系统与后台任务仍在运行，请注意电量管理。'
        k58 = 'CAScreenGuard ' + $script:AppVersion + ' · 发生错误'
        k59 = "如果您确信没有记错授权码，则应该考虑这是否是一次有预谋的攻击。"
        k75 = "您先前收到过配置被动过的通知，且授权码连续输错：请立刻修改电脑密码、运行最新的杀毒软件，并检查您物理工作环境的安全性。重新安装本软件可以解决当前状态。"
        k60 = "CAScreenGuard " + $script:AppVersion + " · 上次没有正常结束"
        k61 = "上次息屏锁没有正常退出，但留下了崩溃日志：`n{0}`n`n这是软件自己出错退出的，不是被人关机。请把这份日志和复现步骤一起反馈。`n`n顺便检查一下电源设置：睡眠 / 休眠 / 合盖 如果设得太激进，也会在锁屏期间把它打断。"
        k62 = "上次息屏锁没有正常退出，也没有留下崩溃日志。`n`n也就是说它不是自己崩的：可能是有人按了电源键、用 Ctrl+Alt+Del 注销或关机，或者直接结束了进程。`n`n如果你刚刚回到工位、并没有重启电脑就看到这条消息，请立刻修改电脑密码、运行最新的杀毒软件、检查你物理工作环境的安全性，然后重新安装本软件。`n`n也请顺便检查电源设置：睡眠 / 休眠 / 合盖 如果设得太激进，也会在锁屏期间把它打断。"
        k63 = "已禁止输入密码"
        k64 = "请使用物理按键关机，或使用 Ctrl+Alt+Del 呼出安全界面关机"
        k65 = "已禁止输入授权码"
        k66 = "CAScreenGuard " + $script:AppVersion
        k67 = "这条封禁已经写进本机记录：关闭或重新打开本程序都不会解除，只有重新安装才能恢复。"
    }
    en = @{
        k01 = "CAScreenGuard is missing required files:`n`n"
        k02 = "`n`nThe script, both .cs files and the icon must live in the same folder. Please run the installer again."
        k03 = "CAScreenGuard " + $script:AppVersion + " · Incomplete files"
        k04 = "CAScreenGuard " + $script:AppVersion + " · Error"
        k05 = "Could not save the password configuration."
        k06 = "Too many wrong passwords. Please wait {0} seconds and try again."
        k08 = "Wrong password. Please wait {0} seconds and try again."
        k09 = "Wrong password, please try again"
        k10 = "No usable authorization code on this machine, so the unlock password cannot be changed. Please run the installer again."
        k11 = "(no hint set)"
        k12 = "CAScreenGuard " + $script:AppVersion + " · Change unlock password"
        k13 = "Change unlock password"
        k14 = "To confirm it is really you, enter the authorization code first. (case-sensitive)`nAuthorization hint: {0}"
        k15 = "Authorization code"
        k16 = "New unlock password (at least 4 chars, ASCII only)"
        k17 = "Confirm new password"
        k18 = "Save"
        k19 = "Cancel"
        k21 = "The new password needs at least 4 characters."
        k22 = "The new password may only use ASCII letters, digits and symbols — no spaces, no non-ASCII."
        k23 = "The two new passwords do not match, please retype."
        k24 = "Saving failed: "
        k25 = "Unlock password updated: use the new one to unlock"
        k26 = "Wrong authorization code 3 times, change cancelled"
        k27 = "No usable authorization code, the unlock password cannot be changed"
        k28 = "(no hint was saved)"
        k29 = "CAScreenGuard " + $script:AppVersion + " · Configuration needs to be rebuilt"
        k30 = "Unlock password file is gone or modified"
        k31 = "This is most likely not an accident: the file was either deleted or rewritten, so the old unlock password no longer counts.`n"
        k32 = "CAScreenGuard will not start over until it knows it is you — otherwise someone could swap the unlock password right here.`n"
        k33 = "Confirm with the authorization code, then set a new unlock password.`n"
        k34 = "Authorization hint: {0} (case-sensitive)"
        k35 = "Authorization code"
        k36 = "New unlock password (at least 4 chars, ASCII only)"
        k37 = "Confirm the new unlock password"
        k38 = "Continue"
        k39 = "Quit"
        k42 = "The new password needs at least 4 characters."
        k43 = "The new password may only use ASCII letters, digits and symbols — no spaces, no non-ASCII."
        k44 = "The two new passwords do not match, please retype."
        k45 = "Saving failed: "
        k46 = "CAScreenGuard is already running, no need to start it twice."
        k47 = "CAScreenGuard has not been installed on this machine yet.`n`nPlease run the installer first (CAScreenGuard-Setup.exe): the unlock password and the authorization code are set in the setup wizard, then start it from the desktop shortcut."
        k48 = "This machine is missing CAScreenGuard credentials, so this configuration cannot be trusted.`n`nTo keep someone from swapping the unlock password right now, the screen lock will not start.`nPlease run the installer again (uninstall first, then install)."
        k49 = "CAScreenGuard " + $script:AppVersion + " · Configuration cannot be verified"
        k50 = "You cancelled the rebuild, so the screen lock will not start."
        k51 = "3 wrong authorization codes, so the screen lock will not start."
        k52 = "The unlock password was not rebuilt.`n`n"
        k53 = "CAScreenGuard " + $script:AppVersion + " · Configuration needs to be rebuilt"
        k54 = "Screen protected"
        k55 = "Type your unlock password and press Enter to restore the screen"
        k56 = "Enter unlock · Ctrl+Backspace clear · Esc blank now · Ctrl+Shift+Alt+E change password"
        k57 = "The screen is off, but the system and background tasks keep running — mind your battery."
        k58 = "CAScreenGuard " + $script:AppVersion + " · Error"
        k59 = "If you are sure you did not mistype the authorization code, consider whether this is a deliberate attack."
        k75 = "You were already told that the configuration file had been tampered with, and the authorization code was then mistyped three times: change your Windows password now, run a fully updated antivirus scan and check the physical safety of your workspace. Reinstalling this software will resolve the current state."
        k60 = "CAScreenGuard " + $script:AppVersion + " · The last session did not end cleanly"
        k61 = "The last lock session did not exit cleanly, but it left a crash log:`n{0}`n`nSo the software itself failed — this was not someone shutting the machine down. Please report that log together with the steps that led to it.`n`nWhile you are here, check your power settings: aggressive sleep / hibernate / lid-close actions can also interrupt the lock."
        k62 = "The last lock session did not exit cleanly, and it left no crash log.`n`nSo it did not crash by itself: someone may have pressed the power button, signed out or shut down via Ctrl+Alt+Del, or simply killed the process.`n`nIf you have just come back to your desk and did NOT restart the computer before seeing this, change your Windows password now, run a fully updated antivirus scan, check the physical safety of your workspace, and then reinstall this software.`n`nAlso check your power settings: aggressive sleep / hibernate / lid-close actions can interrupt the lock too."
        k63 = "Password entry is disabled"
        k64 = "Power off using the physical power button, or press Ctrl+Alt+Del and shut down from the security screen"
        k65 = "Authorization code entry is disabled"
        k66 = "CAScreenGuard " + $script:AppVersion
        k67 = "This block has been recorded on this machine: closing or reopening the program will not lift it — only reinstalling can."
    }
}
function T {
    param([string]$Key)
    $t = $script:T[$script:Lang]
    if ($t -and $t.ContainsKey($Key)) { return $t[$Key] }
    return $script:T['zh'][$Key]
}
# ------------------------------------------------------------------ 依赖的 C# 源文件
# 原生调用写在同目录的两个 .cs 里（ScreenLockEarly.cs / ScreenLockNative.cs）。
# 安装程序会把「脚本 + 两个 .cs + 图标」一起放进安装目录，所以这里按脚本所在目录找。
$script:ScriptDir = $PSScriptRoot
if (-not $script:ScriptDir) {
    try { $script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path } catch { }
}
$csEarly = Join-Path $script:ScriptDir 'ScreenLockEarly.cs'
$csNative = Join-Path $script:ScriptDir 'ScreenLockNative.cs'
$missingFiles = @()
foreach ($f in @($csEarly, $csNative)) {
    if (-not (Test-Path -LiteralPath $f)) { $missingFiles += (Split-Path -Leaf $f) }
}
if ($missingFiles.Count -gt 0) {
    $missMsg = (T 'k01') + ($missingFiles -join "`n") +
    (T 'k02')
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($missMsg, (T 'k03'), 'OK', 'Error') | Out-Null
    }
    catch { }
    Write-Host $missMsg
    exit 1
}

# ------------------------------------------------------------------ 启动最早期
# 1) 声明 DPI 感知：不声明的话，在被缩放的屏幕上（例如 175%）整个窗口会被系统位图拉伸，
#    表现就是"字非常糊"。必须在创建任何窗口之前调用。
# 2) 隐藏控制台：只有当"这个控制台里只有我们自己一个进程"（= 双击 / 快捷方式启动）时才隐藏；
#    如果旁边还有父 shell（你是在终端里手动运行），绝不动你的终端。
if (-not ('ScreenLockEarly' -as [type])) {
    # 这一步在 trap 定义之前、控制台也可能已被隐藏：编译失败必须弹窗，否则双击就是"什么都没发生"
    try { Add-Type -Path $csEarly }
    catch {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, (T 'k04'), 'OK', 'Error') | Out-Null
        } catch { }
        exit 1
    }
}
$dpiOk = $false
try { $dpiOk = [ScreenLockEarly]::SetProcessDpiAwarenessContext([IntPtr]::new(-4)) } catch { }
if (-not $dpiOk) { try { [void][ScreenLockEarly]::SetProcessDPIAware() } catch { } }
try {
    $consoleHandle = [ScreenLockEarly]::GetConsoleWindow()
    if ($consoleHandle -ne [IntPtr]::Zero) {
        $consoleProcs = New-Object uint32[] 8
        $consoleCount = [ScreenLockEarly]::GetConsoleProcessList($consoleProcs, 8)
        if ($consoleCount -le 1) { [void][ScreenLockEarly]::ShowWindow($consoleHandle, 0) }
    }
}
catch { }

# ------------------------------------------------------------------ 依赖程序集
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try { [System.Windows.Forms.Application]::EnableVisualStyles() } catch { }

# ------------------------------------------------------------------ 原生调用
if (-not ('ScreenLockNative' -as [type])) {
    # 同上：失败要可见，不能静默退出
    try { Add-Type -Path $csNative }
    catch {
        try {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, (T 'k04'), 'OK', 'Error') | Out-Null
        } catch { }
        exit 1
    }
}

# ==================================================================
#  运行状态：判断"上一次息屏是不是正常结束的"
#  锁屏开始时写一个标记文件，解锁退出时删掉它；下次启动如果还看到它，
#  就说明上一次没走正常退出这条路。崩溃会另外留下日志 ——
#  有日志 = 软件自己出问题；没日志 = 被人关机 / 注销 / 杀进程 / 断电。
# ==================================================================
$script:StateDir = Join-Path $env:LOCALAPPDATA 'CAScreenGuard'
$script:FlagPath = Join-Path $script:StateDir 'running.flag'
# 改屏保设置之前，把系统原来的值落一份盘：进程被强杀/断电时 finally 不会跑，
# 只存在内存里的"原值"就丢了，下次启动读到的会是被我们改成 0 的那个值 —— 屏保就永久关着。
$script:PresavePath = Join-Path $script:StateDir 'screen-saver-original.json'

function Get-LastCrashLog {
    param([datetime]$NotBefore)
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { return $null }
        $logs = Get-ChildItem -LiteralPath $script:StateDir -Filter 'crash-*.log' -File -ErrorAction SilentlyContinue
        if ($NotBefore -gt [datetime]::MinValue) {
            $logs = $logs | Where-Object { $_.LastWriteTime -ge $NotBefore.AddSeconds(-5) }
        }
        $f = $logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($f) { return $f.FullName }
    } catch { }
    return $null
}

function New-RunningFlag {
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        # 注意：不能写成 @(...) 再用 -join —— PowerShell 里逗号优先级高于加号，
        # 那几个元素会被加号串成一个字符串（用空格连接），标记文件就成了一整行
        $info = 'started=' + (Get-Date).ToString('s') + "`r`n" +
                'user=' + $env:USERNAME + "`r`n" +
                'computer=' + $env:COMPUTERNAME + "`r`n" +
                'pid=' + $PID
        [System.IO.File]::WriteAllText($script:FlagPath, $info, (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Remove-RunningFlag {
    try { if (Test-Path -LiteralPath $script:FlagPath) { Remove-Item -LiteralPath $script:FlagPath -Force } } catch { }
}

function Write-CrashLog {
    param($ErrorRecord, [string]$Where)
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        $path = Join-Path $script:StateDir ('crash-' + (Get-Date).ToString('yyyyMMdd-HHmmss') + '.log')
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('CAScreenGuard crash log')
        [void]$sb.AppendLine('time    : ' + (Get-Date).ToString('s'))
        [void]$sb.AppendLine('where   : ' + $Where)
        [void]$sb.AppendLine('user    : ' + $env:USERNAME + ' @ ' + $env:COMPUTERNAME)
        [void]$sb.AppendLine('pid     : ' + $PID)
        [void]$sb.AppendLine('lang    : ' + $script:Lang)
        [void]$sb.AppendLine('powershell : ' + $PSVersionTable.PSVersion.ToString())
        [void]$sb.AppendLine('os      : ' + [System.Environment]::OSVersion.VersionString)
        [void]$sb.AppendLine('')
        if ($ErrorRecord) {
            [void]$sb.AppendLine('message : ' + $ErrorRecord.Exception.Message)
            [void]$sb.AppendLine('type    : ' + $ErrorRecord.Exception.GetType().FullName)
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('stack   :')
            [void]$sb.AppendLine($ErrorRecord.ScriptStackTrace)
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('detail  :')
            [void]$sb.AppendLine(($ErrorRecord | Out-String))
        }
        [System.IO.File]::WriteAllText($path, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
        # 只留最近 10 份，别把状态目录塞满
        Get-ChildItem -LiteralPath $script:StateDir -Filter 'crash-*.log' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 | Remove-Item -Force -ErrorAction SilentlyContinue
        return $path
    } catch { return $null }
}

function Write-TickError {
    # 定时器里抛的异常：不能弹窗（会打断遮罩上的操作），也不能写进 crash-*.log
    # （那会被下次启动当成"软件崩了"报警）。单独落一个 tick-errors.log。
    # 只在"错误内容变了"时写一次，否则 250ms 一条会把盘写满。
    param([string]$Message)
    try {
        if ([string]::IsNullOrEmpty($Message)) { return }
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        $path = Join-Path $script:StateDir 'tick-errors.log'
        if (Test-Path -LiteralPath $path) {
            if ((Get-Item -LiteralPath $path -Force).Length -gt 65536) {
                [System.IO.File]::WriteAllText($path, '', (New-Object System.Text.UTF8Encoding($false)))
            }
        }
        [System.IO.File]::AppendAllText($path,
            ((Get-Date).ToString('s') + '  ' + $Message + "`r`n"),
            (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Test-PreviousSession {
    # 上一次没正常结束就返回一个对象（含开始时间与崩溃日志路径），正常结束返回 $null
    if (-not (Test-Path -LiteralPath $script:FlagPath)) { return $null }
    $res = [pscustomobject]@{ started = ''; crashLog = $null; flagTime = [datetime]::MinValue }
    try {
        $res.flagTime = (Get-Item -LiteralPath $script:FlagPath -Force).LastWriteTime
        $m = [regex]::Match([System.IO.File]::ReadAllText($script:FlagPath), 'started=([^\r\n]+)')
        if ($m.Success) { $res.started = $m.Groups[1].Value }
    } catch { }
    $res.crashLog = Get-LastCrashLog -NotBefore $res.flagTime
    return $res
}

# ------------------------------------------------------------------ 兜底错误出口
# 双击/快捷方式启动时控制台已被隐藏，未捕获的错误必须弹窗，
# 否则用户看到的是"双击了，什么都没发生"。
trap {
    try { $null = Write-CrashLog -ErrorRecord $_ -Where 'trap' } catch { }
    try {
        $message = "$($_.Exception.Message)`r`n`r`n$($_.InvocationInfo.PositionMessage)"
        [System.Windows.Forms.MessageBox]::Show($message, (T 'k04'), 'OK', 'Error') | Out-Null
    }
    catch { }
    exit 1
}

# ------------------------------------------------------------------ 状态与常量
$script:LastTickError = ''
$script:Scale = 1.0             # 屏幕缩放比（DPI/96）：把布局按 DPI 放大，字才不糊也不小
try { $dpiNow = [ScreenLockEarly]::GetDpiForSystem(); if ($dpiNow -gt 0) { $script:Scale = $dpiNow / 96.0 } } catch { }
$script:DlgOpen = $false          # 「修改密码」窗口开着时，暂停止顶与抢焦点
# 解锁密码与授权码都由安装程序预置：授权码一经安装即定版，脚本这边只负责改解锁密码。
# 它们的加盐哈希存在配置文件里（提示是明文，方便你自己想起授权码）。
$script:ConfigFileName = '.cascreenguard.config.json'
$script:ConfigPath = $null           # 实际读到的那一份配置的路径
$script:ConfigRaw = $null           # 那一份配置的原文（校验摘要必须用原文）
$script:IdleBlankMs = [int]$IdleBlankSeconds * 1000
$script:AllowClose = $false          # 允许关闭遮罩窗口（解锁 / 紧急退出）
$script:State = 'Away'          # Away=屏幕熄灭 / Prompt=等待输入
$script:BlankTick = [uint32]0       # 熄屏那一刻的「最后一次输入」时间戳
$script:LastBlankSent = [datetime]::MinValue
$script:FailCount = 0
$script:TxtLockedOut     = $false          # 密码连错太多次 -> 禁止继续输入，只能关机
$script:AuthLockedOut   = $false          # 授权码连错 3 次 -> 本次会话内禁止再输
$script:CooldownActive = $false
$script:CooldownUntil = [datetime]::MinValue
$script:OrigScreenSaver = $null
$script:OrigScreenSaverReg = $null
$script:Restored = $false
$script:SelfTestLog = New-Object System.Collections.Generic.List[string]
$script:SelfTestFailed = $false
$script:SelfTestStep = 0

# 配置文件的查找顺序：安装目录（外部凭证里记着）→ 脚本所在目录。
# 把安装目录放在第一位，是为了让"桌面上的这一份脚本"和"装好的那一份"读写同一份配置，
# 不会各自生成一份、互相打架。
$script:ConfigCandidates = New-Object System.Collections.Generic.List[string]
$script:StoreRegPath = 'HKCU:\Software\CAScreenGuard'
try {
    $instDir = (Get-ItemProperty -LiteralPath $script:StoreRegPath -Name 'InstallDir' -ErrorAction Stop).InstallDir
    if ($instDir) { [void]$script:ConfigCandidates.Add((Join-Path $instDir $script:ConfigFileName)) }
}
catch { }
if ($script:ScriptDir) {
    [void]$script:ConfigCandidates.Add((Join-Path $script:ScriptDir $script:ConfigFileName))
}

# 语言：命令行 -Lang 优先；否则看外部凭证里安装时选的那个；都没有就用系统语言（上面已按系统语言定过初值）
if ($script:LangArg -eq 'zh' -or $script:LangArg -eq 'en') {
    $script:Lang = $script:LangArg
} else {
    try {
        $langSaved = (Get-ItemProperty -LiteralPath $script:StoreRegPath -Name 'Lang' -ErrorAction Stop).Lang
        if ($langSaved -eq 'zh' -or $langSaved -eq 'en') { $script:Lang = $langSaved }
    } catch { }
}

# ------------------------------------------------------------------ 小工具
function Invoke-Sound {
    param([string]$Kind)
    try {
        switch ($Kind) {
            'error' { [System.Media.SystemSounds]::Hand.Play() }
            'warn' { [System.Media.SystemSounds]::Exclamation.Play() }
            'ok' { [System.Media.SystemSounds]::Asterisk.Play() }
        }
    }
    catch { }
}

function Show-ErrorMsg {
    param([string]$Text)
    $script:TxtError.Text = $Text
    if (-not $script:TxtError.Visible) { $script:TxtError.Visible = $true }
}

function Hide-ErrorMsg {
    if ($script:TxtError -and $script:TxtError.Visible) { $script:TxtError.Visible = $false }
}

function Set-AuthLockedUI {
    # 授权码连错 3 次：底部挂红色警告 + 把对话框里所有输入都锁掉，只留"退出/取消"
    # -Permanent：这次封禁是落盘的，重启程序也不会解除，所以在警告里说清楚
    param($Dlg, $Tip, [switch]$Permanent)
    try {
        $body = (T 'k59')
        # 「配置遭篡改」那一段只在"配置需要重建"这条路上说 ——
        # 正常的改密码窗口里配置根本没被动过，说这个是凭空恐吓
        if ($Permanent) { $body += "`r`n" + (T 'k75') }
        $body += "`r`n`r`n" + (T 'k65')
        if ($Permanent) { $body += "`r`n" + (T 'k67') }
        $Tip.Text = $body + "`r`n" + (T 'k64')
        $Tip.ForeColor = [System.Drawing.Color]::FromArgb(192, 57, 43)
        $k = $script:Scale
        if ($k -lt 1) { $k = 1 }
        # 高度按实际文字量算，别再写死：中英文长度差得远，写死就会把最后几行裁掉
        $need = [System.Windows.Forms.TextRenderer]::MeasureText(
            $Tip.Text, $Tip.Font,
            (New-Object System.Drawing.Size([Math]::Max(60, $Tip.Width - [int](8 * $k)), 4000)),
            [System.Windows.Forms.TextFormatFlags]::WordBreak).Height + [int](12 * $k)
        $Tip.SetBounds($Tip.Left, $Tip.Top, $Tip.Width, $need)
        # 窗口得长到"提示框底边 + 余量"
        $wantH = $Tip.Top + $need + [int](18 * $k)
        if ($Dlg.ClientSize.Height -lt $wantH) {
            $Dlg.ClientSize = New-Object System.Drawing.Size($Dlg.ClientSize.Width, $wantH)
        }
        # 授权码都连错 3 次了：锁屏那个密码框也一起禁掉，和密码连错 8 次同等待遇
        $script:TxtLockedOut = $true
        try { $script:Txt.Enabled = $false } catch { }
        try { $script:LockNotice.Visible = $true } catch { }
        foreach ($c in $Dlg.Controls) {
            if ($c -is [System.Windows.Forms.TextBox]) { $c.Enabled = $false; $c.Text = '' }
            elseif ($c -is [System.Windows.Forms.Button] -and $c.Text -ne (T 'k19') -and $c.Text -ne (T 'k39')) {
                $c.Enabled = $false
                $c.BackColor = [System.Drawing.Color]::FromArgb(214, 216, 220)
                $c.ForeColor = [System.Drawing.Color]::FromArgb(150, 152, 156)
            }
        }
    } catch { }
}

function Test-AuthCode {
    # 授权码校验：与加盐哈希比对；没有授权码就一律拒绝。
    # -Source 指定拿哪一份来比对（配置被删/被改时，只能信外部凭证里那一份）。
    param([string]$Code, $Source)
    try {
        if ($null -eq $Source) { $Source = $script:Config }
        if (-not $Source -or -not $Source.authHash) { return $false }
        $code = $Code.Trim()
        if ([string]::IsNullOrEmpty($code)) { return $false }
        $iterations = 120000
        if ($Source.authIterations) { $iterations = [int]$Source.authIterations }
        $salt = [Convert]::FromBase64String($Source.authSalt)
        $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($code, $salt, $iterations)
        $actual = $derive.GetBytes(32)
        $expect = [Convert]::FromBase64String($Source.authHash)
        if ($actual.Length -ne $expect.Length) { return $false }
        $diff = 0
        for ($i = 0; $i -lt $actual.Length; $i++) { $diff = $diff -bor ($actual[$i] -bxor $expect[$i]) }
        return ($diff -eq 0)
    }
    catch { return $false }
}

function Test-PlainAscii {
    # 解锁密码只收半角可见字符：英文、数字、符号。空格和中文都不收 ——
    # 因为解锁界面的输入框是不让调中文输入法的，收下中文等于给自己挖坑。
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $false }
    foreach ($ch in $Text.ToCharArray()) {
        $code = [int][char]$ch
        if (($code -lt 33) -or ($code -gt 126)) { return $false }
    }
    return $true
}

# ------------------------------------------------------------------ 密码存取
function Read-PasswordConfig {
    # 读配置的同时记下"是哪一份、原文是什么"：校验摘要必须用原文，
    # 不能重新序列化一遍（转义规则不同就会让两边算出的摘要对不上）。
    $script:ConfigPath = $null
    $script:ConfigRaw = $null
    foreach ($path in $script:ConfigCandidates) {
        if (-not $path) { continue }
        if (-not (Test-Path -LiteralPath $path)) { continue }
        try {
            $json = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
            $cfg = $json | ConvertFrom-Json
            if ($cfg.salt -and $cfg.hash -and $cfg.iterations) {
                $script:ConfigPath = $path
                $script:ConfigRaw = $json
                return $cfg
            }
        }
        catch { }
    }
    return $null
}

function Save-PasswordConfig {
    # 写入时把 marker 一起算好：摘要 = 对"把 marker 的值清空后的原文"做 HMAC-SHA256。
    # 顺序必须是：先按空 marker 生成正文 → 算摘要 → 再把值填回去。
    # 这样校验时只要把值清空就能一字不差地还原。安装器用的是同一条规则。
    param($Record, $Store)
    $empty = '"marker":""'
    $body = [pscustomobject]@{
        version        = $Record.version
        algorithm      = $Record.algorithm
        iterations     = $Record.iterations
        salt           = $Record.salt
        hash           = $Record.hash
        authIterations = $Record.authIterations
        authSalt       = $Record.authSalt
        authHash       = $Record.authHash
        authHint       = $Record.authHint
        created        = $Record.created
        marker         = ''
    }
    $text = $body | ConvertTo-Json -Compress -Depth 4
    if ($null -eq $Store) { $Store = Read-IntegrityStore }
    if ($Store -and $Store.markerKey -and $text.Contains($empty)) {
        $text = $text.Replace($empty, ('"marker":"' + (Get-ConfigMarker -Text $text -KeyB64 $Store.markerKey) + '"'))
    }
    foreach ($path in $script:ConfigCandidates) {
        if (-not $path) { continue }
        try {
            $dir = Split-Path -Parent $path
            if ($dir -and -not (Test-Path -LiteralPath $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            # 注意：这个文件是隐藏的。Windows 下用 FileMode.Create 覆盖一个带 Hidden 属性的
            # 文件会直接 Access Denied，所以写之前必须先去掉隐藏属性，写完再设回去。
            if (Test-Path -LiteralPath $path) {
                try { (Get-Item -LiteralPath $path -Force).Attributes = [System.IO.FileAttributes]::Normal } catch { }
            }
            [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
            try { (Get-Item -LiteralPath $path -Force).Attributes = [System.IO.FileAttributes]::Hidden } catch { }
            $script:ConfigPath = $path
            $script:ConfigRaw = $text
            return $path
        }
        catch { }
    }
    throw (T 'k05')
}

function New-PasswordRecord {
    # 授权码由安装程序定版，这里只负责解锁密码：授权码那几个字段原样抄过来，绝不重设。
    param([string]$Password, $Auth)
    if ($null -eq $Auth) { $Auth = Read-IntegrityStore }
    if ($null -eq $Auth) { $Auth = $script:Config }
    $salt = New-Object byte[] 16
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($salt) } finally { $rng.Dispose() }
    $iterations = 120000
    $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Password, $salt, $iterations)
    $hash = $derive.GetBytes(32)

    $authSaltB64 = ''
    $authHashB64 = ''
    $authIterations = 120000
    $authHintText = ''
    if ($Auth) {
        if ($Auth.authSalt) { $authSaltB64 = [string]$Auth.authSalt }
        if ($Auth.authHash) { $authHashB64 = [string]$Auth.authHash }
        if ($Auth.authIterations) { $authIterations = [int]$Auth.authIterations }
        if ($Auth.authHint) { $authHintText = [string]$Auth.authHint }
    }

    return [pscustomobject]@{
        version        = 2
        algorithm      = 'PBKDF2-SHA1'
        iterations     = $iterations
        salt           = [Convert]::ToBase64String($salt)
        hash           = [Convert]::ToBase64String($hash)
        authIterations = $authIterations
        authSalt       = $authSaltB64
        authHash       = $authHashB64
        authHint       = $authHintText
        created        = (Get-Date).ToString('s')
        marker         = ''
    }
}

function Test-PasswordRecord {
    param([string]$Password, $Record)
    try {
        $salt = [Convert]::FromBase64String($Record.salt)
        $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Password, $salt, [int]$Record.iterations)
        $actual = $derive.GetBytes(32)
        $expect = [Convert]::FromBase64String($Record.hash)
        if ($actual.Length -ne $expect.Length) { return $false }
        $diff = 0
        for ($i = 0; $i -lt $actual.Length; $i++) { $diff = $diff -bor ($actual[$i] -bxor $expect[$i]) }
        return ($diff -eq 0)
    }
    catch { return $false }
}

# ==================================================================
#  配置完整性层：外部凭证（注册表 + APPDATA 副本）+ HMAC 摘要标记
#  配置由安装程序预置，脚本这边只负责"它有没有被动过"。
#  摘要规则：把配置原文里 marker 的值清空，再对这段原文做 HMAC-SHA256。
#  （必须用原文，不能重新序列化：JSON 转义规则的差异会让两边算出来的值对不上。）
#  说明：这是"让篡改可见 + 防随手动"，不是密码学意义上的不可篡改 —— 同账户的攻击者
#        如果把注册表和副本一起清掉，就会退化成"从来没装过"（纯用户态方案的极限）。
# ==================================================================
$script:StoreRegPath = 'HKCU:\Software\CAScreenGuard'
$script:StoreMirrorPath = Join-Path (Join-Path $env:APPDATA 'CAScreenGuard') 'store.json'

function Get-ConfigCanonical {
    # 把原文里 marker 的值清空 —— 和安装器用的是同一条规则
    param([string]$Text)
    return [regex]::Replace($Text, '"marker":"[^"]*"', '"marker":""')
}

function Get-ConfigMarker {
    param([string]$Text, [string]$KeyB64)
    $key = [Convert]::FromBase64String($KeyB64)
    $hmac = [System.Security.Cryptography.HMACSHA256]::new($key)
    try {
        $data = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return [Convert]::ToBase64String($hmac.ComputeHash($data))
    } finally { $hmac.Dispose() }
}

function Read-IntegrityStore {
    # 先看注册表，再看 APPDATA 副本；两处都没有 -> $null（= 从没装过）
    try {
        if (Test-Path -LiteralPath $script:StoreRegPath) {
            $v = Get-ItemProperty -LiteralPath $script:StoreRegPath -ErrorAction Stop
            if ($v.Token -and $v.MarkerKey) {
                return [pscustomobject]@{
                    token          = $v.Token
                    markerKey      = $v.MarkerKey
                    authSalt       = $v.AuthSalt
                    authHash       = $v.AuthHash
                    authIterations = $v.AuthIterations
                    authHint       = $v.AuthHint
                    provisioned    = $v.Provisioned
                }
            }
        }
    }
    catch { }
    try {
        if (Test-Path -LiteralPath $script:StoreMirrorPath) {
            $j = [System.IO.File]::ReadAllText($script:StoreMirrorPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            if ($j.token -and $j.markerKey) { return $j }
        }
    }
    catch { }
    return $null
}

# ------------------------------------------------------------------ 授权码永久封禁
# 和"另一个窗口连错 3 次"不同：配置被动过的那条路上，三次输不对授权码就当作有预谋的尝试，
# 封禁要落盘 —— 注册表和 APPDATA 各记一份，重启程序照样禁止输入，只有重新安装才能清掉。
# 只在两处都写不进去时才退化成"本次运行内禁止"。
$script:AuthBanRegName = 'AuthBan'
$script:AuthBanMirrorPath = Join-Path (Join-Path $env:APPDATA 'CAScreenGuard') 'authban.txt'

function Test-AuthBanned {
    try {
        $v = Get-ItemProperty -LiteralPath $script:StoreRegPath -ErrorAction Stop
        if ($v.AuthBan) { return $true }
    }
    catch { }
    try { if (Test-Path -LiteralPath $script:AuthBanMirrorPath) { return $true } } catch { }
    return $false
}

function Set-AuthBanned {
    $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    try {
        if (-not (Test-Path -LiteralPath $script:StoreRegPath)) { New-Item -Path $script:StoreRegPath -Force | Out-Null }
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name $script:AuthBanRegName -Value $stamp -PropertyType String -Force | Out-Null
    }
    catch { }
    try {
        $dir = Split-Path -Parent $script:AuthBanMirrorPath
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($script:AuthBanMirrorPath, $stamp, (New-Object System.Text.UTF8Encoding($false)))
    }
    catch { }
}

# 启动时先把落盘的封禁读出来：上次在"配置被改"那个窗口里连错 3 次留下的记录，
# 重开程序照样算数 —— 否则重启一次就能再试三次。
$script:AuthBanned = Test-AuthBanned
if ($script:AuthBanned) { $script:AuthLockedOut = $true }

function Write-IntegrityStore {
    param($Store)
    $json = $Store | ConvertTo-Json -Compress -Depth 4
    $ok = $false
    try {
        if (-not (Test-Path -LiteralPath $script:StoreRegPath)) { New-Item -Path $script:StoreRegPath -Force | Out-Null }
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'Token' -Value $Store.token -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'MarkerKey' -Value $Store.markerKey -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthSalt' -Value ([string]$Store.authSalt) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthHash' -Value ([string]$Store.authHash) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthIterations' -Value ([string]$Store.authIterations) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthHint' -Value ([string]$Store.authHint) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'Provisioned' -Value ([string]$Store.provisioned) -PropertyType String -Force | Out-Null
        $ok = $true
    }
    catch { }
    try {
        $dir = Split-Path -Parent $script:StoreMirrorPath
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($script:StoreMirrorPath, $json, (New-Object System.Text.UTF8Encoding($false)))
        $ok = $true
    }
    catch { }
    return $ok
}

function New-IntegrityStore {
    $raw = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($raw) } finally { $rng.Dispose() }
    return [pscustomobject]@{
        token          = [guid]::NewGuid().ToString('N')
        markerKey      = [Convert]::ToBase64String($raw)
        authSalt       = ''
        authHash       = ''
        authIterations = ''
        authHint       = ''
        provisioned    = (Get-Date).ToString('s')
    }
}

function Test-ConfigIntegrity {
    # 判定：fresh=从没装过 / ok=正常 / deleted=外部凭证还在但配置没了 /
    #       modified=配置被动过（没有标记、或摘要对不上）/ unprovable=有配置却没有外部凭证
    param($ConfigRecord, [string]$RawText)
    $store = Read-IntegrityStore
    if ($null -eq $store) {
        if ($null -eq $ConfigRecord) { return 'fresh' }
        return 'unprovable'
    }
    if ($null -eq $ConfigRecord) { return 'deleted' }
    if (-not $ConfigRecord.marker) { return 'modified' }
    if ([string]::IsNullOrEmpty($RawText)) { return 'modified' }
    $canonical = Get-ConfigCanonical -Text $RawText
    # -cne 而不是 -ne：PowerShell 的比较默认不区分大小写，而 base64 的大小写是有意义的
    if ((Get-ConfigMarker -Text $canonical -KeyB64 $store.markerKey) -cne $ConfigRecord.marker) { return 'modified' }
    return 'ok'
}

# ------------------------------------------------------------------ 息屏 / 解锁逻辑
function Invoke-GoDark {
    # 立刻再次熄屏；已输入的内容按设计保留（只有 Ctrl+Backspace 会清空）
    $script:State = 'Away'
    $script:BlankTick = [ScreenLockNative]::GetLastInputTick()
    $script:LastBlankSent = Get-Date
    [ScreenLockNative]::MonitorOff()
}

function Update-CooldownMessage {
    if (-not $script:CooldownActive) { return }
    $now = Get-Date
    if ($now -lt $script:CooldownUntil) {
        $left = [int][Math]::Ceiling(($script:CooldownUntil - $now).TotalSeconds)
        if ($left -lt 1) { $left = 1 }
        Show-ErrorMsg ((T 'k06') -f $left)
    }
    else {
        $script:CooldownActive = $false
        Hide-ErrorMsg
    }
}

function Invoke-SubmitAttempt {
    if ($script:AllowClose) { return }
    if ($script:TxtLockedOut) { return }        # 已经封禁了，什么都不做

    $now = Get-Date
    if ($script:CooldownActive -and $now -lt $script:CooldownUntil) {
        $left = [Math]::Max(1, [int][Math]::Ceiling(($script:CooldownUntil - $now).TotalSeconds))
        Show-ErrorMsg ((T 'k06') -f $left)
        Invoke-Sound 'warn'
        return
    }

    $typed = $script:Txt.Text
    if ([string]::IsNullOrEmpty($typed)) { return }   # 空回车忽略，避免误操作

    if (Test-PasswordRecord -Password $typed -Record $script:Config) {
        $script:FailCount = 0
        $script:AllowClose = $true
        [ScreenLockNative]::MonitorOn()
        $script:Timer.Stop()
        $script:Form.Close()
        return
    }

    # 密码错误：清空输入 + 提示 + 声音反馈；连续错误则给出递增的短暂冷却
    $script:FailCount++
    # 连错 8 次：不再给任何输入机会，只留"关机"这一条路
    if ($script:FailCount -ge 8) {
        $script:TxtLockedOut = $true
        $script:CooldownActive = $false
        try { $script:Txt.Enabled = $false } catch { }
        Hide-ErrorMsg
        try { $script:LockNotice.Visible = $true } catch { }
        Invoke-Sound 'error'
        return
    }
    $script:Txt.Clear()
    Invoke-Sound 'error'
    $wait = 0
    if ($script:FailCount -ge 3) {
        $wait = [int][Math]::Min(30, 3 * [Math]::Pow(2, $script:FailCount - 3))
    }
    if ($wait -gt 0) {
        $script:CooldownUntil = (Get-Date).AddSeconds($wait)
        $script:CooldownActive = $true
        Show-ErrorMsg ((T 'k08') -f $wait)
    }
    else {
        Show-ErrorMsg (T 'k09')
    }
}

function Invoke-GuardTick {
    try {
        if ($script:AllowClose) { return }
        $now = Get-Date
        $idle = [uint32][ScreenLockNative]::GetIdleMilliseconds()

        if ($script:State -eq 'Away') {
            if ([ScreenLockNative]::GetLastInputTick() -ne $script:BlankTick) {
                # 有新的输入 → 显示器已被系统点亮，进入等待输入状态
                $script:State = 'Prompt'
                $script:LastBlankSent = [datetime]::MinValue
            }
            elseif ((($now - $script:LastBlankSent).TotalSeconds -ge 10) -and ($idle -ge 3000)) {
                # 兜底：仍处于无人操作状态，却被人/程序点亮了屏幕，再熄一次
                $script:BlankTick = [ScreenLockNative]::GetLastInputTick()
                $script:LastBlankSent = $now
                [ScreenLockNative]::MonitorOff()
            }
        }
        else {
            if (($idle -ge $script:IdleBlankMs) -and (-not $script:DlgOpen)) { Invoke-GoDark }
        }

        Update-CooldownMessage

        # 「修改密码」窗口开着时，不抢焦点也不压顶，否则会盖住用户的对话框
        if (-not $script:DlgOpen) {
            # 遮罩必须一直压在最前：任何状态都要做，否则别的顶层窗口会盖在遮罩之上露出桌面内容。
            # 只有"有人在场"（刚有输入，$idle 很小）时才额外把前台抢回来，
            # 避免无谓地跟别的线程较劲（AttachThreadInput 在极端情况下会互相等待）。
            [ScreenLockNative]::ReassertTopMost($script:Form.Handle)
            if (($idle -lt 2000) -and ([ScreenLockNative]::ForegroundWindow -ne $script:Form.Handle)) {
                [ScreenLockNative]::ForceForeground($script:Form.Handle)
            }
            if ($script:Txt.Enabled -and (-not $script:Txt.Focused)) { $null = $script:Txt.Focus() }
        }
    }
    catch {
        # 只有"错误内容变了"才落盘：定时器 250ms 一次，不能每次都写
        $msg = $_.Exception.Message
        if ($msg -ne $script:LastTickError) {
            $script:LastTickError = $msg
            Write-TickError -Message $msg
        }
    }
}

# ------------------------------------------------------------------ 系统状态
function Restore-PendingScreenSaverSave {
    # 上一次要是被强杀/断电结束的，屏保设置会停在"被我们关掉"的状态，而原值只在这份文件里。
    # 先把系统恢复成原样，再走正常流程 —— 否则这次读到的"原值"就是那个 0，屏保会永久关着。
    try {
        if (-not (Test-Path -LiteralPath $script:PresavePath)) { return }
        $saved = [System.IO.File]::ReadAllText($script:PresavePath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($null -ne $saved.reg) {
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -Value $saved.reg -ErrorAction SilentlyContinue
        }
        if ($null -ne $saved.spi) { [ScreenLockNative]::SetScreenSaverActive(([int]$saved.spi) -ne 0) }
        Remove-Item -LiteralPath $script:PresavePath -Force -ErrorAction SilentlyContinue
    } catch { }
}

function Save-ScreenSaverPrerestore {
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        $o = [pscustomobject]@{
            reg     = $script:OrigScreenSaverReg
            spi     = $script:OrigScreenSaver
            savedAt = (Get-Date).ToString('s')
        }
        [System.IO.File]::WriteAllText($script:PresavePath, ($o | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Initialize-SystemState {
    Restore-PendingScreenSaverSave          # 先补上一次没还原掉的
    try { $script:OrigScreenSaver = [ScreenLockNative]::GetScreenSaverActive() } catch { $script:OrigScreenSaver = $null }
    try {
        $script:OrigScreenSaverReg = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -ErrorAction Stop).ScreenSaveActive
    }
    catch { $script:OrigScreenSaverReg = $null }
    Save-ScreenSaverPrerestore              # 改之前先把原值落盘
    try { [ScreenLockNative]::SetScreenSaverActive($false) } catch { }
    try { [ScreenLockNative]::KeepSystemAwake() } catch { }
    # 锁屏期间吞掉 Win / Alt+Tab / Alt+Esc / Ctrl+Esc，堵住开始菜单、窗口缩略图等视觉泄露
    try { $null = [ScreenLockNative]::InstallKeyboardHook() } catch { }
    try { [ScreenLockNative]::BlockSystemKeys = $true } catch { }
}

function Restore-SystemState {
    if ($script:Restored) { return }
    $script:Restored = $true
    # 先把键盘还回去：解锁后要立刻能正常用 Win / Alt+Tab
    try { [ScreenLockNative]::BlockSystemKeys = $false } catch { }
    try { [ScreenLockNative]::RemoveKeyboardHook() } catch { }
    # 窗口此时可能已经销毁：先清空投递目标（退回广播兜底），确保屏幕一定亮回来
    try { [ScreenLockNative]::TargetWindow = [IntPtr]::Zero } catch { }
    Remove-RunningFlag                        # 走到这儿说明是正常退出
    try { [ScreenLockNative]::MonitorOn() } catch { }
    # 边泵消息边等：点亮请求现在发给我们自己的窗口，阻塞式等待会让它没人处理
    try {
        $deadline = (Get-Date).AddSeconds(1.2)
        while ((Get-Date) -lt $deadline) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 40
        }
    }
    catch { }
    try {
        if ($null -ne $script:OrigScreenSaver) {
            [ScreenLockNative]::SetScreenSaverActive(([int]$script:OrigScreenSaver) -ne 0)
        }
    }
    catch { }
    try {
        if ($null -ne $script:OrigScreenSaverReg) {
            $current = $null
            try {
                $current = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -ErrorAction Stop).ScreenSaveActive
            }
            catch { }
            if ("$current" -ne "$($script:OrigScreenSaverReg)") {
                Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -Value $script:OrigScreenSaverReg -ErrorAction SilentlyContinue
            }
        }
    }
    catch { }
    try { Remove-Item -LiteralPath $script:PresavePath -Force -ErrorAction SilentlyContinue } catch { }
    try { [ScreenLockNative]::ReleaseKeepAwake() } catch { }
}

# ==================================================================
#  修改解锁密码（Ctrl+Shift+Alt+E）：需要授权码（首次运行时由你自己设置）
# ==================================================================
function Show-ChangePasswordDialog {
    # 返回值：'ok' = 已保存新密码 / 'cancel' = 用户取消 / 'toomany' = 授权码错太多次 / 'noauth' = 本机还没设授权码
    $family = 'Microsoft YaHei UI'
    $script:CpwResult = 'cancel'
    $script:CpwAuthFails = 0
    $script:CpwErr = $null

    # 没设过授权码（例如沿用了旧配置）：直接告诉用户怎么办，不让他白试
    if (-not $script:Config -or -not $script:Config.authHash) {
        [System.Windows.Forms.MessageBox]::Show((T 'k10'), 'CAScreenGuard', 'OK', 'Warning') | Out-Null
        return 'noauth'
    }
    $hintText = (T 'k11')
    if ($script:Config.authHint) { $hintText = $script:Config.authHint }

    $script:CpwDlg = New-Object System.Windows.Forms.Form
    $script:CpwDlg.Text = (T 'k12')
    $script:CpwDlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $script:CpwDlg.MaximizeBox = $false
    $script:CpwDlg.MinimizeBox = $false
    $script:CpwDlg.TopMost = $true
    $script:CpwDlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $script:CpwDlg.ClientSize = New-Object System.Drawing.Size(520, 392)
    $script:CpwDlg.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 251)
    $script:CpwDlg.Font = New-Object System.Drawing.Font($family, [float]9)
    try {
        $icoFile = Join-Path $script:ScriptDir 'CAScreenGuard.ico'
        if (Test-Path -LiteralPath $icoFile) { $script:CpwDlg.Icon = New-Object System.Drawing.Icon($icoFile, 32, 32) }
    }
    catch { }

    $head = New-Object System.Windows.Forms.Label
    $head.AutoSize = $false
    $head.Text = (T 'k13')
    $head.Font = New-Object System.Drawing.Font($family, [float]15, [System.Drawing.FontStyle]::Bold)
    $head.ForeColor = [System.Drawing.Color]::FromArgb(28, 28, 32)
    $head.SetBounds(24, 18, 472, 34)
    $script:CpwDlg.Controls.Add($head)

    $desc = New-Object System.Windows.Forms.Label
    $desc.AutoSize = $false
    $desc.Text = ((T 'k14') -f $hintText)
    $desc.ForeColor = [System.Drawing.Color]::FromArgb(96, 100, 108)
    $desc.SetBounds(24, 52, 472, 42)
    $script:CpwDlg.Controls.Add($desc)

    $lb0 = New-Object System.Windows.Forms.Label
    $lb0.AutoSize = $false
    $lb0.Text = (T 'k15')
    $lb0.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb0.SetBounds(24, 102, 472, 20)
    $script:CpwDlg.Controls.Add($lb0)

    $script:CpwAuth = New-Object System.Windows.Forms.TextBox
    $script:CpwAuth.PasswordChar = [char]0x25CF
    $script:CpwAuth.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:CpwAuth.MaxLength = 128
    $script:CpwAuth.SetBounds(24, 124, 472, 26)
    $script:CpwDlg.Controls.Add($script:CpwAuth)

    $lb1 = New-Object System.Windows.Forms.Label
    $lb1.AutoSize = $false
    $lb1.Text = (T 'k16')
    $lb1.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb1.SetBounds(24, 162, 472, 20)
    $script:CpwDlg.Controls.Add($lb1)

    $script:CpwPwd1 = New-Object System.Windows.Forms.TextBox
    $script:CpwPwd1.PasswordChar = [char]0x25CF
    $script:CpwPwd1.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:CpwPwd1.MaxLength = 128
    $script:CpwPwd1.SetBounds(24, 184, 472, 26)
    $script:CpwDlg.Controls.Add($script:CpwPwd1)

    $lb2 = New-Object System.Windows.Forms.Label
    $lb2.AutoSize = $false
    $lb2.Text = (T 'k17')
    $lb2.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb2.SetBounds(24, 222, 472, 20)
    $script:CpwDlg.Controls.Add($lb2)

    $script:CpwPwd2 = New-Object System.Windows.Forms.TextBox
    $script:CpwPwd2.PasswordChar = [char]0x25CF
    $script:CpwPwd2.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:CpwPwd2.MaxLength = 128
    $script:CpwPwd2.SetBounds(24, 244, 472, 26)
    $script:CpwDlg.Controls.Add($script:CpwPwd2)

    $err = New-Object System.Windows.Forms.Label
    $err.AutoSize = $false
    $err.ForeColor = [System.Drawing.Color]::FromArgb(206, 55, 55)
    $err.SetBounds(24, 280, 472, 20)
    $err.Visible = $false
    $script:CpwErr = $err
    $script:CpwDlg.Controls.Add($err)

    $save = New-Object System.Windows.Forms.Button
    $save.Text = (T 'k18')
    $save.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $save.FlatAppearance.BorderSize = 0
    $save.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $save.ForeColor = [System.Drawing.Color]::White
    $save.Font = New-Object System.Drawing.Font($family, [float]10)
    $save.SetBounds(312, 324, 88, 32)
    $script:CpwDlg.Controls.Add($save)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = (T 'k19')
    $cancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancel.FlatAppearance.BorderSize = 0
    $cancel.BackColor = [System.Drawing.Color]::FromArgb(232, 233, 237)
    $cancel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 44)
    $cancel.Font = New-Object System.Drawing.Font($family, [float]10)
    $cancel.SetBounds(416, 324, 88, 32)
    $script:CpwDlg.Controls.Add($cancel)

    # 底部这行平时是空的；授权码连错 3 次时挂上红色警告（和重建窗口同一套做法）
    $script:CpwTip = New-Object System.Windows.Forms.Label
    $script:CpwTip.AutoSize = $false
    $script:CpwTip.Text = ''
    $script:CpwTip.ForeColor = [System.Drawing.Color]::FromArgb(150, 154, 160)
    $script:CpwTip.Font = New-Object System.Drawing.Font($family, [float]8.5)
    $script:CpwTip.SetBounds(24, 366, 480, 116)
    $script:CpwDlg.Controls.Add($script:CpwTip)

    $script:CpwDlg.AcceptButton = $save
    $script:CpwDlg.CancelButton = $cancel
    $script:CpwDlg.Add_Shown({ $null = $script:CpwAuth.Focus() })
    if ($script:AuthLockedOut) { Set-AuthLockedUI -Dlg $script:CpwDlg -Tip $script:CpwTip -Permanent:$script:AuthBanned }

    $save.Add_Click({
            if (-not (Test-AuthCode $script:CpwAuth.Text)) {
                $script:CpwAuthFails++
                if ($script:CpwAuthFails -ge 3) {
                    $script:CpwAuthFails = 0
                    $script:AuthLockedOut = $true
                    $script:CpwResult = 'toomany'   # 让外层能区分"被封禁"和"用户主动取消"
                    Set-AuthLockedUI -Dlg $script:CpwDlg -Tip $script:CpwTip -Permanent:$script:AuthBanned
                    return
                }
                # 输错授权码不给任何提示：既不确认"你猜的这个不对"，也不告诉还剩几次机会
                $script:CpwErr.Visible = $false
                $script:CpwAuth.Clear()
                $null = $script:CpwAuth.Focus()
                return
            }
            $a = $script:CpwPwd1.Text
            $b = $script:CpwPwd2.Text
            if ($a.Length -lt 4) {
                $script:CpwErr.Text = (T 'k21')
                $script:CpwErr.Visible = $true
                $null = $script:CpwPwd1.Focus()
                return
            }
            if (-not (Test-PlainAscii $a)) {
                $script:CpwErr.Text = (T 'k22')
                $script:CpwErr.Visible = $true
                $null = $script:CpwPwd1.Focus()
                return
            }
            if ($a -cne $b) {
                $script:CpwErr.Text = (T 'k23')
                $script:CpwErr.Visible = $true
                $script:CpwPwd2.Clear()
                $null = $script:CpwPwd2.Focus()
                return
            }
            try {
                $record = New-PasswordRecord -Password $a
                $null = Save-PasswordConfig -Record $record
                $script:Config = $record
                $script:CpwResult = 'ok'
            }
            catch {
                $script:CpwErr.Text = (T 'k24') + $_.Exception.Message
                $script:CpwErr.Visible = $true
                return
            }
            $script:CpwDlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
        })
    $cancel.Add_Click({
            # 刚被封禁时保留 'toomany'，别被关窗动作覆盖成 "cancel"（否则外层提示会说成"你取消了"）
            if ($script:CpwResult -ne 'toomany') { $script:CpwResult = 'cancel' }
            $script:CpwDlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        })
    $script:CpwAuth.Add_TextChanged({ if ($script:CpwErr.Visible) { $script:CpwErr.Visible = $false } })
    $script:CpwPwd1.Add_TextChanged({ if ($script:CpwErr.Visible) { $script:CpwErr.Visible = $false } })
    $script:CpwPwd2.Add_TextChanged({ if ($script:CpwErr.Visible) { $script:CpwErr.Visible = $false } })

    # 按 DPI 放大整套布局，然后把字号设回点数值（声明 DPI 感知后必须做，
    # 否则控件会显得过小；而字体是点单位，本来就会随 DPI 变大，不能被二次放大）。
    if ($script:Scale -gt 1.01) {
        $script:CpwDlg.Scale((New-Object System.Drawing.SizeF([float]$script:Scale, [float]$script:Scale)))
        $script:CpwDlg.Font = New-Object System.Drawing.Font($family, [float]9)
        $head.Font = New-Object System.Drawing.Font($family, [float]15, [System.Drawing.FontStyle]::Bold)
        $desc.Font = New-Object System.Drawing.Font($family, [float]9)
        $save.Font = New-Object System.Drawing.Font($family, [float]10)
        $cancel.Font = New-Object System.Drawing.Font($family, [float]10)
    }

    $null = $script:CpwDlg.ShowDialog()
    try { $script:CpwDlg.Dispose() } catch { }
    $script:CpwDlg = $null
    $script:CpwAuth = $null
    $script:CpwTip = $null
    $script:CpwPwd1 = $null
    $script:CpwPwd2 = $null
    $script:CpwErr = $null
    return $script:CpwResult
}

function Invoke-ChangePasswordFlow {
    if ($script:DlgOpen) { return }
    $script:DlgOpen = $true
    $outcome = 'cancel'
    try { $outcome = Show-ChangePasswordDialog } catch { $outcome = 'cancel' }
    $script:DlgOpen = $false
    try { if ($script:Txt.Enabled) { $null = $script:Txt.Focus() } } catch { }
    # 注意：这里不能用 MessageBox —— 遮罩是 topmost，弹窗会被它盖住，
    # 用户只会看到"点了没反应"。回执直接写在锁屏界面自己的提示行上（永远可见）。
    if ($outcome -eq 'ok') {
        try { $script:Txt.Clear() } catch { }
        Show-ErrorMsg (T 'k25')
    }
    elseif ($outcome -eq 'toomany') {
        Show-ErrorMsg (T 'k26')
    }
    elseif ($outcome -eq 'noauth') {
        Show-ErrorMsg (T 'k27')
    }
}

# ==================================================================
#  配置重建对话框：配置文件被删除 / 被改动时，用授权码确认身份，再重设解锁密码
# ==================================================================

function Show-RebuildDialog {
    # 返回值：'ok' = 已重设新密码 / 'cancel' = 用户放弃 / 'toomany' = 授权码错太多次
    # 说明：事件处理脚本块看不到函数内的局部变量，所以对话框里
    #       会被事件用到的控件统一放进 $script: 作用域。
    $family = 'Microsoft YaHei UI'
    $script:DlgErr = $null
    $script:DlgFails = 0
    $script:DlgResult = 'cancel'
    # 配置文件本身就不可信了，只能拿外部凭证（注册表 / APPDATA 副本）里那一份来比对授权码
    $script:DlgStore = Read-IntegrityStore
    $hintText = (T 'k28')
    if ($script:DlgStore -and $script:DlgStore.authHint) { $hintText = $script:DlgStore.authHint }

    $script:Dlg = New-Object System.Windows.Forms.Form
    $script:Dlg.Text = (T 'k29')
    $script:Dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $script:Dlg.MaximizeBox = $false
    $script:Dlg.MinimizeBox = $false
    $script:Dlg.TopMost = $true
    $script:Dlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $script:Dlg.ClientSize = New-Object System.Drawing.Size(484, 456)
    $script:Dlg.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 251)
    $script:Dlg.Font = New-Object System.Drawing.Font($family, [float]9)
    try {
        $icoFile = Join-Path $script:ScriptDir 'CAScreenGuard.ico'
        if (Test-Path -LiteralPath $icoFile) { $script:Dlg.Icon = New-Object System.Drawing.Icon($icoFile, 32, 32) }
    }
    catch { }

    $head = New-Object System.Windows.Forms.Label
    $head.AutoSize = $false
    $head.Text = (T 'k30')
    # 英文标题比中文长得多，字号降一档才不会折行被截掉
    $headPt = 15
    if ($script:Lang -eq 'en') { $headPt = 13 }
    $head.Font = New-Object System.Drawing.Font($family, [float]$headPt, [System.Drawing.FontStyle]::Bold)
    $head.ForeColor = [System.Drawing.Color]::FromArgb(192, 57, 43)
    $head.SetBounds(24, 16, 436, 34)
    $script:Dlg.Controls.Add($head)

    $desc = New-Object System.Windows.Forms.Label
    $desc.AutoSize = $false
    $desc.Text = ((T 'k31') +
        (T 'k32') +
        (T 'k33') +
        (T 'k34') -f $hintText)
    $desc.ForeColor = [System.Drawing.Color]::FromArgb(192, 57, 43)
    $desc.SetBounds(24, 52, 436, 92)
    $script:Dlg.Controls.Add($desc)

    $lbCur = New-Object System.Windows.Forms.Label
    $lbCur.AutoSize = $false
    $lbCur.Text = (T 'k35')
    $lbCur.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lbCur.SetBounds(24, 152, 436, 20)
    $script:Dlg.Controls.Add($lbCur)

    $script:DlgCurAuth = New-Object System.Windows.Forms.TextBox
    $script:DlgCurAuth.PasswordChar = [char]0x25CF
    $script:DlgCurAuth.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:DlgCurAuth.MaxLength = 128
    $script:DlgCurAuth.SetBounds(24, 174, 436, 26)
    $script:Dlg.Controls.Add($script:DlgCurAuth)

    $lb1 = New-Object System.Windows.Forms.Label
    $lb1.AutoSize = $false
    $lb1.Text = (T 'k36')
    $lb1.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb1.SetBounds(24, 210, 436, 20)
    $script:Dlg.Controls.Add($lb1)

    $script:DlgPwd1 = New-Object System.Windows.Forms.TextBox
    $script:DlgPwd1.PasswordChar = [char]0x25CF
    $script:DlgPwd1.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:DlgPwd1.MaxLength = 128
    $script:DlgPwd1.SetBounds(24, 232, 436, 26)
    $script:Dlg.Controls.Add($script:DlgPwd1)

    $lb2 = New-Object System.Windows.Forms.Label
    $lb2.AutoSize = $false
    $lb2.Text = (T 'k37')
    $lb2.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb2.SetBounds(24, 268, 436, 20)
    $script:Dlg.Controls.Add($lb2)

    $script:DlgPwd2 = New-Object System.Windows.Forms.TextBox
    $script:DlgPwd2.PasswordChar = [char]0x25CF
    $script:DlgPwd2.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:DlgPwd2.MaxLength = 128
    $script:DlgPwd2.SetBounds(24, 290, 436, 26)
    $script:Dlg.Controls.Add($script:DlgPwd2)

    $err = New-Object System.Windows.Forms.Label
    $err.AutoSize = $false
    $err.ForeColor = [System.Drawing.Color]::FromArgb(206, 55, 55)
    $err.SetBounds(24, 322, 436, 20)
    $err.Visible = $false
    $script:DlgErr = $err
    $script:Dlg.Controls.Add($err)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = (T 'k38')
    $ok.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ok.FlatAppearance.BorderSize = 0
    $ok.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $ok.ForeColor = [System.Drawing.Color]::White
    $ok.Font = New-Object System.Drawing.Font($family, [float]10)
    $ok.SetBounds(240, 352, 136, 32)
    $script:Dlg.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = (T 'k39')
    $cancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancel.FlatAppearance.BorderSize = 0
    $cancel.BackColor = [System.Drawing.Color]::FromArgb(232, 233, 237)
    $cancel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 44)
    $cancel.Font = New-Object System.Drawing.Font($family, [float]10)
    $cancel.SetBounds(384, 352, 96, 32)
    $script:Dlg.Controls.Add($cancel)

    $tip = New-Object System.Windows.Forms.Label
    $tip.AutoSize = $false
    $tip.Text = ''
    $tip.ForeColor = [System.Drawing.Color]::FromArgb(150, 154, 160)
    $tip.Font = New-Object System.Drawing.Font($family, [float]8.5)
    $tip.SetBounds(24, 398, 436, 36)
    $script:Dlg.Controls.Add($tip)

    $script:Dlg.AcceptButton = $ok
    $script:Dlg.CancelButton = $cancel
    $script:Dlg.Add_Shown({ $null = $script:DlgCurAuth.Focus() })
    if ($script:AuthLockedOut) { Set-AuthLockedUI -Dlg $script:Dlg -Tip $tip -Permanent:$script:AuthBanned }

    $ok.Add_Click({
            if (-not (Test-AuthCode -Code $script:DlgCurAuth.Text -Source $script:DlgStore)) {
                $script:DlgFails++
                if ($script:DlgFails -ge 3) {
                    # 配置被动过 + 三次输不对授权码：按"有预谋的攻击"处理。
                    # 这里和另一个窗口不同 —— 封禁要落盘，重启程序、重新打开这个窗口都不再接受输入。
                    $script:DlgFails = 0
                    $script:AuthLockedOut = $true
                    $script:DlgResult = 'toomany'   # 同上：让外层给出"连错 3 次"的提示，而不是"你取消了"
                    Set-AuthBanned
                    $script:AuthBanned = $true
                    Set-AuthLockedUI -Dlg $script:Dlg -Tip $tip -Permanent
                    return
                }
                # 输错授权码不给任何提示
                $script:DlgErr.Visible = $false
                $script:DlgCurAuth.Clear()
                $null = $script:DlgCurAuth.Focus()
                return
            }
            $a = $script:DlgPwd1.Text
            $b = $script:DlgPwd2.Text
            if ($a.Length -lt 4) {
                $script:DlgErr.Text = (T 'k42')
                $script:DlgErr.Visible = $true
                $null = $script:DlgPwd1.Focus()
                return
            }
            if (-not (Test-PlainAscii $a)) {
                $script:DlgErr.Text = (T 'k43')
                $script:DlgErr.Visible = $true
                $null = $script:DlgPwd1.Focus()
                return
            }
            if ($a -cne $b) {
                $script:DlgErr.Text = (T 'k44')
                $script:DlgErr.Visible = $true
                $script:DlgPwd2.Clear()
                $null = $script:DlgPwd2.Focus()
                return
            }
            try {
                $record = New-PasswordRecord -Password $a -Auth $script:DlgStore
                $null = Save-PasswordConfig -Record $record -Store $script:DlgStore
                $script:Config = $record
                $script:DlgResult = 'ok'
            }
            catch {
                $script:DlgErr.Text = (T 'k45') + $_.Exception.Message
                $script:DlgErr.Visible = $true
                return
            }
            $script:Dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
        })
    $cancel.Add_Click({
            if ($script:DlgResult -ne 'toomany') { $script:DlgResult = 'cancel' }
            $script:Dlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        })

    $script:DlgCurAuth.Add_TextChanged({ if ($script:DlgErr.Visible) { $script:DlgErr.Visible = $false } })
    $script:DlgPwd1.Add_TextChanged({ if ($script:DlgErr.Visible) { $script:DlgErr.Visible = $false } })
    $script:DlgPwd2.Add_TextChanged({ if ($script:DlgErr.Visible) { $script:DlgErr.Visible = $false } })

    # 同主遮罩：按 DPI 放大布局，再重设字号（原因见主遮罩处的说明）
    if ($script:Scale -gt 1.01) {
        $script:Dlg.Scale((New-Object System.Drawing.SizeF([float]$script:Scale, [float]$script:Scale)))
        $script:Dlg.Font = New-Object System.Drawing.Font($family, [float]9)
        $head.Font = New-Object System.Drawing.Font($family, [float]15, [System.Drawing.FontStyle]::Bold)
        $desc.Font = New-Object System.Drawing.Font($family, [float]9)
        $ok.Font = New-Object System.Drawing.Font($family, [float]10)
        $cancel.Font = New-Object System.Drawing.Font($family, [float]10)
        $tip.Font = New-Object System.Drawing.Font($family, [float]8.5)
    }

    $result = $script:Dlg.ShowDialog()
    try { $script:Dlg.Dispose() } catch { }
    $script:Dlg = $null
    $script:DlgCurAuth = $null
    $script:DlgPwd1 = $null
    $script:DlgPwd2 = $null
    $script:DlgErr = $null
    $script:DlgStore = $null
    return $script:DlgResult
}

# ==================================================================
#  启动准备：控制台、单实例、密码
# ==================================================================
if (-not $SelfTest) {
    # 控制台窗口已经在脚本最早期处理过（见开头"启动最早期"）

    # 单实例：避免两个遮罩互相打架
    $script:Mutex = New-Object System.Threading.Mutex($false, 'Local\CAScreenGuard.SingleInstance')
    $hasMutex = $false
    try { $hasMutex = $script:Mutex.WaitOne(0) }
    catch [System.Threading.AbandonedMutexException] { $hasMutex = $true }   # 上次被强杀留下的锁，按"可用"处理
    catch { $hasMutex = $false }
    if (-not $hasMutex) {
        # 已经有一份在跑了：只留一句提示就走。
        # 注意别把下面的"上次没正常结束"检查卷进这一支 —— 那样正常启动时它永远不会执行，
        # 而"已有实例"时又会误报（标记文件正是隔壁那一份自己建的）。
        [System.Windows.Forms.MessageBox]::Show((T 'k46'), (T 'k66')) | Out-Null
        exit 0
    }

    # 上一次是不是没正常结束？报告完就把旧标记清掉，免得每次启动都翻旧账
    $prev = Test-PreviousSession
    Remove-RunningFlag
    if ($prev) {
        if ($prev.crashLog) {
            [System.Windows.Forms.MessageBox]::Show(((T 'k61') -f $prev.crashLog), (T 'k60'), 'OK', 'Warning') | Out-Null
        }
        else {
            [System.Windows.Forms.MessageBox]::Show((T 'k62'), (T 'k60'), 'OK', 'Warning') | Out-Null
        }
    }

    # 配置只能由安装程序预置。先判定它有没有被动过，再决定能不能开锁 ——
    # 「配置文件被删掉 / 被改过」从"悄悄变成首次运行"改成了一件必须当场处理的事。
    $script:AutoReset = [bool]$ResetPassword
    $script:Config = Read-PasswordConfig
    $integrity = Test-ConfigIntegrity -ConfigRecord $script:Config -RawText $script:ConfigRaw

    if ($integrity -ne 'ok') {
        if ($integrity -eq 'fresh') {
            [System.Windows.Forms.MessageBox]::Show(
                (T 'k47'),
                'CAScreenGuard', 'OK', 'Information') | Out-Null
            exit 0
        }
        elseif ($integrity -eq 'unprovable') {
            [System.Windows.Forms.MessageBox]::Show(
                (T 'k48'),
                (T 'k49'), 'OK', 'Warning') | Out-Null
            exit 0
        }
        else {
            # deleted / modified：配置文件被删掉或者被改过
            $outcome = Show-RebuildDialog
            if ($outcome -ne 'ok') {
                $note = (T 'k50')
                if ($outcome -eq 'toomany') { $note = (T 'k51') }
                [System.Windows.Forms.MessageBox]::Show(
                    (T 'k52') + $note,
                    (T 'k53'), 'OK', 'Warning') | Out-Null
                exit 0
            }
        }
    }
}
else {
    # 自检：使用内存中的测试密码，不读写真实配置
    $script:Config = New-PasswordRecord -Password 'selftest-dummy-pw'
}

# ==================================================================
#  主界面（全屏黑色遮罩 + 密码框）
# ==================================================================
$family = 'Microsoft YaHei UI'
$cardW = 580
$cardH = 352                          # 底部要留出封禁提示两行的位置

$script:Form = New-Object System.Windows.Forms.Form
$script:Form.Text = 'CAScreenGuard'
$script:Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$script:Form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$script:Form.Bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
$script:Form.TopMost = $true
$script:Form.ShowInTaskbar = $false
$script:Form.KeyPreview = $true
$script:Form.BackColor = [System.Drawing.Color]::Black
$script:Form.ImeMode = [System.Windows.Forms.ImeMode]::Disable

$card = New-Object System.Windows.Forms.Panel
$card.Size = New-Object System.Drawing.Size($cardW, $cardH)
$card.BackColor = [System.Drawing.Color]::FromArgb(13, 13, 15)
$primary = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$cardX = [int](($primary.X + ($primary.Width - $cardW) / 2) - $script:Form.Bounds.X)
$cardY = [int](($primary.Y + ($primary.Height - $cardH) / 2) - $script:Form.Bounds.Y)
$card.Location = New-Object System.Drawing.Point($cardX, $cardY)
$script:Form.Controls.Add($card)

$title = New-Object System.Windows.Forms.Label
$title.AutoSize = $false
$title.Text = (T 'k54')
$title.Font = New-Object System.Drawing.Font($family, [float]22, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(242, 242, 244)
$title.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$title.SetBounds(0, 40, $cardW, 52)
$card.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.AutoSize = $false
$subtitle.Text = (T 'k55')
$subtitle.Font = New-Object System.Drawing.Font($family, [float]10.5)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(152, 158, 166)
$subtitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$subtitle.SetBounds(0, 96, $cardW, 26)
$card.Controls.Add($subtitle)

$boxW = 400
$boxH = 52
$box = New-Object System.Windows.Forms.Panel
$box.Size = New-Object System.Drawing.Size($boxW, $boxH)
$box.Location = New-Object System.Drawing.Point([int](($cardW - $boxW) / 2), 142)
$box.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 30)
$card.Controls.Add($box)

$script:Txt = New-Object System.Windows.Forms.TextBox
$script:Txt.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$script:Txt.Font = New-Object System.Drawing.Font($family, [float]17)
$script:Txt.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 30)
$script:Txt.ForeColor = [System.Drawing.Color]::White
$script:Txt.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
$script:Txt.PasswordChar = [char]0x25CF
$script:Txt.ImeMode = [System.Windows.Forms.ImeMode]::Disable
$script:Txt.MaxLength = 128
$script:Txt.SetBounds(12, 9, $boxW - 24, 26)
$box.Controls.Add($script:Txt)

$script:TxtError = New-Object System.Windows.Forms.Label
$script:TxtError.AutoSize = $false
$script:TxtError.Font = New-Object System.Drawing.Font($family, [float]10)
$script:TxtError.ForeColor = [System.Drawing.Color]::FromArgb(255, 110, 110)
$script:TxtError.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:TxtError.SetBounds(0, 206, $cardW, 24)
$script:TxtError.Visible = $false
$card.Controls.Add($script:TxtError)

$footer1 = New-Object System.Windows.Forms.Label
$footer1.AutoSize = $false
$footer1.Text = (T 'k56')
# 英文这行比中文长得多，字号降一档才压得进一行
$script:FooterPt = 9.5
if ($script:Lang -eq 'en') { $script:FooterPt = 8.5 }
$footer1.Font = New-Object System.Drawing.Font($family, [float]$script:FooterPt)
$footer1.ForeColor = [System.Drawing.Color]::FromArgb(128, 134, 142)
$footer1.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$footer1.SetBounds(0, 242, $cardW, 22)
$card.Controls.Add($footer1)

$footer2 = New-Object System.Windows.Forms.Label
$footer2.AutoSize = $false
$footer2.Text = (T 'k57')
$footer2.Font = New-Object System.Drawing.Font($family, [float]9)
$footer2.ForeColor = [System.Drawing.Color]::FromArgb(86, 92, 100)
$footer2.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

# 密码连错 8 次后才显示：封禁说明 + 只能关机
$script:LockNotice = New-Object System.Windows.Forms.Label
$script:LockNotice.AutoSize = $false
$script:LockNotice.Font = New-Object System.Drawing.Font($family, [float]10)
$script:LockNotice.ForeColor = [System.Drawing.Color]::FromArgb(255, 96, 96)
$script:LockNotice.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:LockNotice.Text = (T 'k63') + "`r`n" + (T 'k64')
$script:LockNotice.SetBounds(0, 292, $cardW, 52)
$script:LockNotice.Visible = $false
$card.Controls.Add($script:LockNotice)
$footer2.SetBounds(0, 266, $cardW, 22)
$card.Controls.Add($footer2)

# 按 DPI 放大整套布局，然后把字号设回点数值：
# 声明 DPI 感知后，控件的坐标/尺寸需要跟着 DPI 放大（否则在高缩放屏上会显得很小）；
# 而字体是点单位、本来就会随 DPI 变大，所以必须在缩放之后重新设一遍字号，否则会被二次放大。
if ($script:Scale -gt 1.01) {
    $script:Form.Scale((New-Object System.Drawing.SizeF([float]$script:Scale, [float]$script:Scale)))
    $script:Form.Bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
    # Scale() 会把卡片带着一起按比例挪位，这里按"已经放大的尺寸"把它重新摆回主屏正中
    $primaryNow = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $card.Left = [int]($primaryNow.X + ($primaryNow.Width - $card.Width) / 2) - $script:Form.Bounds.X
    $card.Top = [int]($primaryNow.Y + ($primaryNow.Height - $card.Height) / 2) - $script:Form.Bounds.Y
    $title.Font = New-Object System.Drawing.Font($family, [float]22, [System.Drawing.FontStyle]::Bold)
    $subtitle.Font = New-Object System.Drawing.Font($family, [float]10.5)
    $script:Txt.Font = New-Object System.Drawing.Font($family, [float]17)
    $script:TxtError.Font = New-Object System.Drawing.Font($family, [float]10)
    $footer1.Font = New-Object System.Drawing.Font($family, [float]$script:FooterPt)
    $footer2.Font = New-Object System.Drawing.Font($family, [float]9)
    $script:LockNotice.Font = New-Object System.Drawing.Font($family, [float]10)
}

# ------------------------------------------------------------------ 事件绑定
$script:Form.Add_Shown({
        try { [ScreenLockNative]::DisableIme($script:Txt.Handle) } catch { }
        if ($script:Txt.Enabled) { $null = $script:Txt.Focus() }
    })

$script:Form.Add_Activated({
        if ($script:Txt.Enabled) { $null = $script:Txt.Focus() }
    })

$script:Form.Add_FormClosing({
        param($sender, $e)
        if (-not $script:AllowClose) { $e.Cancel = $true }
    })

$script:Form.Add_KeyDown({
        param($sender, $e)
        # Alt+F4 不予理会
        if ($e.Alt -and ($e.KeyCode -eq [System.Windows.Forms.Keys]::F4)) {
            $e.SuppressKeyPress = $true
            return
        }
        # Ctrl+Shift+Alt+E：打开「修改解锁密码」（需要授权码）。不再直接退出脚本。
        if ($e.Control -and $e.Alt -and $e.Shift -and ($e.KeyCode -eq [System.Windows.Forms.Keys]::E)) {
            $e.SuppressKeyPress = $true
            Invoke-ChangePasswordFlow
            return
        }
    })

# 输入框万一没有焦点：把字符直接补进去，避免"打字没反应"
$script:Form.Add_KeyPress({
        param($sender, $e)
        if ($script:Txt.Enabled -and -not $script:Txt.Focused -and $e.KeyChar -and ([int]$e.KeyChar -ge 32)) {
            $script:Txt.AppendText([string]$e.KeyChar)
            $e.Handled = $true
        }
    })

$script:Txt.Add_KeyDown({
        param($sender, $e)
        $code = $e.KeyCode

        if ($e.Control -and (($code -eq [System.Windows.Forms.Keys]::Back) -or ($code -eq [System.Windows.Forms.Keys]::U))) {
            # 一键清空（沿用终端 / 命令行的习惯）
            $e.SuppressKeyPress = $true
            $sender.Clear()
            Hide-ErrorMsg
            return
        }
        if ($code -eq [System.Windows.Forms.Keys]::Escape) {
            # 立即再次熄屏；输入内容保留
            $e.SuppressKeyPress = $true
            Invoke-GoDark
            return
        }
        if ($code -eq [System.Windows.Forms.Keys]::Enter) {
            $e.SuppressKeyPress = $true
            Invoke-SubmitAttempt
            return
        }
    })

$script:Txt.Add_TextChanged({
        if ($script:CooldownActive) { return }
        Hide-ErrorMsg
    })

# ------------------------------------------------------------------ 定时器
$script:Timer = New-Object System.Windows.Forms.Timer
$script:Timer.Interval = 250
if ($SelfTest) {
    $script:Timer.Interval = 500
    $script:Timer.Add_Tick({ Invoke-SelfTestTick })
}
else {
    $script:Timer.Add_Tick({ Invoke-GuardTick })
}

# ------------------------------------------------------------------ 自检
function Add-SelfTestResult {
    param([bool]$Ok, [string]$Name, [string]$Detail)
    $tag = 'PASS'
    if (-not $Ok) { $tag = 'FAIL'; $script:SelfTestFailed = $true }
    $script:SelfTestLog.Add(("[{0}] {1}：{2}" -f $tag, $Name, $Detail))
}

function Invoke-SelfTestTick {
    try {
        switch ($script:SelfTestStep) {
            0 {
                $b = $script:Form.Bounds
                Add-SelfTestResult (($b.Width -ge $primary.Width) -and ($b.Height -ge $primary.Height)) '遮罩尺寸' ("{0}x{1}" -f $b.Width, $b.Height)
                Add-SelfTestResult ($script:Form.Controls.Count -ge 1) '界面构建' ("控件数 {0}" -f $script:Form.Controls.Count)
                $tickNow = [ScreenLockNative]::GetLastInputTick()
                # GetLastInputTick 失败时返回 uint.MaxValue，所以 0 和 MaxValue 都不算"拿到了有效 tick"
                Add-SelfTestResult (($tickNow -ne 0) -and ($tickNow -ne [uint32]::MaxValue)) '输入空闲接口' ("tick={0}, idle={1}ms" -f $tickNow, [ScreenLockNative]::GetIdleMilliseconds())
                $script:Txt.Text = 'wrong-password'
                Invoke-SubmitAttempt
                Add-SelfTestResult (($script:Txt.Text.Length -eq 0) -and $script:TxtError.Visible -and ($script:FailCount -eq 1)) '错误密码处理' ("已清空输入、显示提示、计数={0}" -f $script:FailCount)
            }
            1 {
                $script:Txt.Text = 'selftest-dummy-pw'
                Invoke-SubmitAttempt
                Add-SelfTestResult ($script:AllowClose -and (-not $script:Form.Visible)) '正确密码解锁' ("AllowClose={0}, 窗口可见={1}" -f $script:AllowClose, $script:Form.Visible)
            }
            2 {
                Add-SelfTestResult (-not $script:Form.Visible) '窗口已关闭' '（走到这一步说明解锁没有生效）'
                if ($script:Form.Visible) {
                    $script:AllowClose = $true
                    $script:Form.Close()
                }
                $script:Timer.Stop()
            }
        }
        $script:SelfTestStep++
    }
    catch {
        $script:SelfTestLog.Add('[FAIL] 自检异常：' + $_.Exception.Message)
        $script:SelfTestFailed = $true
        $script:AllowClose = $true
        try { $script:Form.Close() } catch { }
    }
}

if ($SelfTest) {
    $tmpDir = Join-Path $env:TEMP ('ScreenLockSelfTest_' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        $savedCandidates = $script:ConfigCandidates
        $script:ConfigCandidates = New-Object System.Collections.Generic.List[string]
        [void]$script:ConfigCandidates.Add((Join-Path $tmpDir '.screenlock.config.json'))
        $null = Save-PasswordConfig -Record $script:Config
        $reloaded = Read-PasswordConfig
        Add-SelfTestResult (($null -ne $reloaded) -and (Test-PasswordRecord -Password 'selftest-dummy-pw' -Record $reloaded)) '配置文件读写' "目录 $tmpDir"
        Add-SelfTestResult (-not (Test-PasswordRecord -Password 'wrong' -Record $script:Config)) '错误密码不会被接受' 'PBKDF2 校验'

        # 完整性层闭环：标记 → 校验通过 → 改一个字节 → 判定为被动过 → 删掉 → 判定为消失
        $savedReg = $script:StoreRegPath
        $savedMirror = $script:StoreMirrorPath
        $script:StoreRegPath = 'HKCU:\Software\CAScreenGuardSelfTest'
        $script:StoreMirrorPath = Join-Path $tmpDir 'store.json'
        try {
            $fake = New-IntegrityStore
            $null = Write-IntegrityStore -Store $fake
            $rec = New-PasswordRecord -Password 'selftest-dummy-pw' -Auth $fake
            $null = Save-PasswordConfig -Record $rec -Store $fake
            $reread = Read-PasswordConfig
            $v1 = Test-ConfigIntegrity -ConfigRecord $reread -RawText $script:ConfigRaw
            (Get-Item -LiteralPath $script:ConfigPath -Force).Attributes = [System.IO.FileAttributes]::Normal
            [System.IO.File]::WriteAllText($script:ConfigPath, ($script:ConfigRaw.Replace('"created"', '"createdX"')), (New-Object System.Text.UTF8Encoding($false)))
            $tampered = Read-PasswordConfig
            $v2 = Test-ConfigIntegrity -ConfigRecord $tampered -RawText $script:ConfigRaw
            Remove-Item -LiteralPath $script:ConfigPath -Force
            $v3 = Test-ConfigIntegrity -ConfigRecord (Read-PasswordConfig) -RawText $null
            Add-SelfTestResult (($v1 -eq 'ok') -and ($v2 -eq 'modified') -and ($v3 -eq 'deleted')) '配置完整性判定' ("正常={0} / 被改={1} / 被删={2}" -f $v1, $v2, $v3)
        }
        catch {
            Add-SelfTestResult $false '配置完整性判定' $_.Exception.Message
        }
        finally {
            $script:StoreRegPath = $savedReg
            $script:StoreMirrorPath = $savedMirror
            Remove-Item -LiteralPath 'HKCU:\Software\CAScreenGuardSelfTest' -Recurse -Force -ErrorAction SilentlyContinue
        }

        $script:ConfigCandidates = $savedCandidates
    }
    catch {
        Add-SelfTestResult $false '配置文件读写' $_.Exception.Message
    }
    finally {
        Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ==================================================================
#  运行
# ==================================================================
try {
    if (-not $SelfTest) { Initialize-SystemState }

    $script:Form.Show()
    # 关屏/亮屏只投递给我们自己这一个窗口（广播会被每个顶层窗口各处理一份 → 屏幕抖动）
    [ScreenLockNative]::TargetWindow = $script:Form.Handle
    if (-not $SelfTest) { New-RunningFlag }   # 正常退出时会删掉它；下次还看到就说明这次没正常结束
    if (-not $SelfTest) {
        if ($script:AutoReset) {
            # -ResetPassword：这次是专门来改密码的，不熄屏，直接把修改窗口摆出来
            $script:State = 'Prompt'
        }
        else {
            [ScreenLockNative]::MonitorOff()
            $script:State = 'Away'
            $script:BlankTick = [ScreenLockNative]::GetLastInputTick()
            $script:LastBlankSent = Get-Date
        }
    }
    else {
        $script:State = 'Prompt'
    }

    if ($script:AutoReset -and -not $SelfTest) { Invoke-ChangePasswordFlow }

    $script:Timer.Start()
    [System.Windows.Forms.Application]::Run($script:Form)
}
catch {
    $msg = $_.Exception.Message

    if (-not $SelfTest) { $null = Write-CrashLog -ErrorRecord $_ -Where 'run' }
    try { $script:SelfTestFailed = $true } catch { }
    try {
        [System.Windows.Forms.MessageBox]::Show($msg, (T 'k58'), 'OK', 'Error') | Out-Null
    }
    catch { }
}
finally {
    $script:AllowClose = $true
    try { $script:Timer.Stop() } catch { }
    try { $script:Form.Dispose() } catch { }
    Restore-SystemState        # 无论哪种模式都收尾：点亮屏幕 + 恢复屏保/唤醒设置
    if ($SelfTest) {
        Write-Host ''
        Write-Host '================ CAScreenGuard 自检结果 ================'
        foreach ($line in $script:SelfTestLog) { Write-Host $line }
        Write-Host '================================================'
        if ($script:SelfTestFailed) {
            Write-Host '结论：存在失败项。'
            exit 1
        }
        else {
            Write-Host '结论：全部通过。（本模式未改动显示器电源）'
            exit 0
        }
    }
}
