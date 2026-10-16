#CAScreenGuard builder by Conste11ation117
# 打包脚本：把「主脚本 + 两个 C# 源文件 + 图标」嵌进安装器，编译成单文件、无控制台、带图标的 exe
#
# 源（要读、要改的是这几份，都带注释）：
#   CAScreenGuard-demo.ps1   主脚本
#   ScreenLockEarly.cs       原生调用：DPI 感知 / 隐藏控制台
#   ScreenLockNative.cs      原生调用：关屏 / 键盘钩子 / 置顶 / 空闲计时
#   CAScreenGuard.ico        图标
#   Installer.cs             安装器自己的 C#
#
# 产物：
#   CAScreenGuard.ps1        由 demo 自动生成：去掉所有注释和空行（发布版；打包用的是它）
#   CAScreenGuard-Setup.exe  安装器
#
# 用法：powershell -File build-setup.ps1

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }
$leaf = 'CAScreenGuard'
$utf8bom = New-Object System.Text.UTF8Encoding($true)

$demoPath = Join-Path $root ($leaf + '-demo.ps1')
$ps1Path = Join-Path $root ($leaf + '.ps1')
$icoPath = Join-Path $root ($leaf + '.ico')
$earlyPath = Join-Path $root 'ScreenLockEarly.cs'
$nativePath = Join-Path $root 'ScreenLockNative.cs'
$instCsPath = Join-Path $root 'Installer.cs'
$licensePath = Join-Path $root 'LICENSE'
$outExe = Join-Path $root ($leaf + '-Setup.exe')

foreach ($f in @($demoPath, $icoPath, $earlyPath, $nativePath, $instCsPath, $licensePath)) {
    if (-not (Test-Path -LiteralPath $f)) { throw ('缺少源文件：' + $f) }
}

# ---------------- 0. 行尾与 BOM 自检 ----------------
# 这些脚本必须带 UTF-8 BOM，否则 PowerShell 会按 ANSI 读，中文全变乱码（踩过好几次）。
# 行尾统一成 CRLF。缺 BOM 就直接补上，不因为这种小事卡住打包。
foreach ($f in @($demoPath, $earlyPath, $nativePath, $instCsPath)) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $i = 0
    while (($i + 2) -lt $bytes.Length -and $bytes[$i] -eq 0xEF -and $bytes[$i + 1] -eq 0xBB -and $bytes[$i + 2] -eq 0xBF) { $i += 3 }
    $body = New-Object byte[] ($bytes.Length - $i)
    [Array]::Copy($bytes, $i, $body, 0, $body.Length)
    # 严格解码：不是合法 UTF-8 就当场报错。用带替换字符的宽松解码会把源文件
    # 就地写坏（中文变成 U+FFFD 再也回不来），而这一步正是要"补 BOM"，很容易被忽视。
    $strict = New-Object System.Text.UTF8Encoding($false, $true)
    try { $text = $strict.GetString($body) }
    catch { throw ('源文件不是合法的 UTF-8（可能是 ANSI/GBK）：' + $f + '。先转成 UTF-8 再打包，不要让它被就地改坏。') }
    $text = ($text -split "`r?`n") -join "`r`n"
    $bodyOut = [System.Text.Encoding]::UTF8.GetBytes($text)
    $fixed = New-Object byte[] ($bodyOut.Length + 3)
    [Array]::Copy([byte[]](0xEF, 0xBB, 0xBF), 0, $fixed, 0, 3)
    [Array]::Copy($bodyOut, 0, $fixed, 3, $bodyOut.Length)
    if ($i -ne 3 -or $fixed.Length -ne $bytes.Length) {
        [System.IO.File]::WriteAllBytes($f, $fixed)
        Write-Host ('  ' + (Split-Path -Leaf $f) + '：BOM/行尾已归一化（原有 ' + ($i / 3) + ' 个 BOM）')
    }
}

# ---------------- 去注释：PowerShell ----------------
# 走语法树找注释，所以字符串里的 # 、here-string 里的内容都不会被误伤
function Remove-PsComments {
    param([string]$Text)
    $tokens = $null; $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) { throw ('源脚本有语法错误，先修好再打包：' + $errors[0].Message) }
    $cuts = New-Object System.Collections.Generic.List[int[]]
    foreach ($tk in $tokens) {
        if ($tk.Kind -ne [System.Management.Automation.Language.TokenKind]::Comment) { continue }
        if ($tk.Text -cmatch '^#Requires\s') { continue }     # #Requires 是声明，必须留（大小写敏感）
        $cuts.Add(@($tk.Extent.StartOffset, $tk.Extent.EndOffset))
    }
    $sb = New-Object System.Text.StringBuilder($Text)
    for ($i = $cuts.Count - 1; $i -ge 0; $i--) {
        [void]$sb.Remove($cuts[$i][0], $cuts[$i][1] - $cuts[$i][0])
    }
    # 这里刻意不再做"删空行 + 去行尾空白"：那一步是按行处理的，不认识 token，
    # 会把 here-string / 逐字字符串里的空行和行尾空格一起吃掉 —— 字符串内容被静默改短，
    # 而后面那两道 ParseFile / csc 复查都查不出这种语义损坏。
    # 注释已经删干净了（这才是防破解真正需要的），多留几个空行不影响什么。
    return ($sb.ToString().TrimEnd([char[]]"`r`n") + "`r`n")
}

# ---------------- 去注释：C# ----------------
# 逐字符扫描，只认"代码里"的 // 和 /* */；字符串和字符字面量里的不动
function Remove-CsComments {
    param([string]$Text)
    $sb = New-Object System.Text.StringBuilder
    $i = 0; $n = $Text.Length
    $inLine = $false; $inBlock = $false; $inStr = $false; $inChar = $false; $verbatim = $false
    while ($i -lt $n) {
        $c = $Text[$i]
        $c2 = if ($i + 1 -lt $n) { $Text[$i + 1] } else { [char]0 }
        if ($inLine) {
            # 行注释只吃掉注释文字，CRLF 必须完整留下：只补 LF 
            # 产物就不是"全 CRLF"了（以前靠后面那道按行归一化遮着，那道已经去掉）
            if ($c -eq "`r" -and $c2 -eq "`n") { $inLine = $false; [void]$sb.Append($c); [void]$sb.Append($c2); $i += 2; continue }
            if ($c -eq "`n") { $inLine = $false; [void]$sb.Append($c) }
            $i++; continue
        }
        if ($inBlock) {
            if ($c -eq '*' -and $c2 -eq '/') { $inBlock = $false; $i += 2; continue }
            # 保留块注释里的换行，否则会把注释两侧的代码拼成一行，
            # 极端情况下还会把记号粘在一起（int/**/y 变成 inty）
            if ($c -eq "`r" -and $c2 -eq "`n") { [void]$sb.Append($c); [void]$sb.Append($c2); $i += 2; continue }
            if ($c -eq "`n") { [void]$sb.Append($c) }
            $i++; continue
        }
        if ($inStr) {
            [void]$sb.Append($c)
            if ($verbatim) {
                if ($c -eq '"') { if ($c2 -eq '"') { [void]$sb.Append($c2); $i++ } else { $inStr = $false; $verbatim = $false } }
            }
            elseif ($c -eq '\') { if ($i + 1 -lt $n) { [void]$sb.Append($c2); $i++ } }
            elseif ($c -eq '"') { $inStr = $false }
            $i++; continue
        }
        if ($inChar) {
            [void]$sb.Append($c)
            if ($c -eq '\') { if ($i + 1 -lt $n) { [void]$sb.Append($c2); $i++ } }
            elseif ($c -eq "'") { $inChar = $false }
            $i++; continue
        }
        if ($c -eq '/' -and $c2 -eq '/') { $inLine = $true; $i += 2; continue }
        if ($c -eq '/' -and $c2 -eq '*') { $inBlock = $true; $i += 2; continue }
        if ($c -eq '@' -and $c2 -eq '"') { [void]$sb.Append('@"'); $inStr = $true; $verbatim = $true; $i += 2; continue }
        if ($c -eq '"') { $inStr = $true; [void]$sb.Append($c); $i++; continue }
        if ($c -eq "'") { $inChar = $true; [void]$sb.Append($c); $i++; continue }
        [void]$sb.Append($c); $i++
    }
    # 这里刻意不再做"删空行 + 去行尾空白"：那一步是按行处理的，不认识 token，
    # 会把 here-string / 逐字字符串里的空行和行尾空格一起吃掉 —— 字符串内容被静默改短，
    # 而后面那两道 ParseFile / csc 复查都查不出这种语义损坏。
    # 注释已经删干净了（这才是防破解真正需要的），多留几个空行不影响什么。
    return ($sb.ToString().TrimEnd([char[]]"`r`n") + "`r`n")
}

# ---------------- 1. 生成无注释的主脚本 ----------------
$demoText = [System.IO.File]::ReadAllText($demoPath, [System.Text.Encoding]::UTF8)
$cleanPs1 = Remove-PsComments -Text $demoText
[System.IO.File]::WriteAllText($ps1Path, $cleanPs1, $utf8bom)
$errs = $null; $tk2 = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($ps1Path, [ref]$tk2, [ref]$errs)
if ($errs -and $errs.Count -gt 0) { throw ('生成的主脚本语法不对：' + $errs[0].Message) }
$cmt = @($tk2 | Where-Object { $_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment })
Write-Host ('主脚本：' + $demoText.Length + ' 字符 -> ' + $cleanPs1.Length + ' 字符，剩余注释 ' + $cmt.Count + ' 处（只应剩 #Requires）')

# ---------------- 2. 生成无注释的 C# ----------------
# csc.exe 处理不了含中文的参数路径，所以整条编译链都在一个纯 ASCII 的中转目录里跑。
# 如果用户名是中文，%TEMP% 就带中文，这里必须换地方，否则编译会以很难懂的方式失败。
function Test-AsciiPath([string]$p) {
    if ([string]::IsNullOrEmpty($p)) { return $false }
    foreach ($ch in $p.ToCharArray()) { if ([int][char]$ch -gt 126) { return $false } }
    return $true
}
$buildDir = $null
foreach ($cand in @((Join-Path $env:TEMP 'cg_build'), (Join-Path $env:SystemRoot 'Temp\cg_build'))) {
    if (-not (Test-AsciiPath $cand)) { continue }
    try { if (-not (Test-Path -LiteralPath $cand)) { New-Item -ItemType Directory -Path $cand -Force | Out-Null } } catch { continue }
    $buildDir = $cand
    break
}
if (-not $buildDir) { throw 'ERROR: 找不到一个纯 ASCII 的临时目录来编译（csc 处理不了中文路径）。请设置 TEMP 到一个全英文路径。' }
Write-Host ('  编译中转目录：' + $buildDir)
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
$cleanEarlyPath = Join-Path $buildDir 'ScreenLockEarly.cs'
$cleanNativePath = Join-Path $buildDir 'ScreenLockNative.cs'
foreach ($pair in @(@($earlyPath, $cleanEarlyPath), @($nativePath, $cleanNativePath))) {
    $src = [System.IO.File]::ReadAllText($pair[0], [System.Text.Encoding]::UTF8)
    $out = Remove-CsComments -Text $src
    [System.IO.File]::WriteAllText($pair[1], $out, $utf8bom)
    Write-Host ('  ' + (Split-Path -Leaf $pair[0]) + '：' + $src.Length + ' 字符 -> ' + $out.Length + ' 字符')
}

# 去完注释的 C# 必须还能编译
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path -LiteralPath $csc)) { throw 'ERROR: csc.exe not found' }
$fw = Split-Path -Parent $csc
$refArg = '/r:' + (Join-Path $fw 'System.dll')
foreach ($f in @($cleanEarlyPath, $cleanNativePath)) {
    $chkOut = '/out:' + (Join-Path $buildDir 'chk.dll')
    & $csc @('/nologo', '/target:library', $chkOut, $refArg, $f)
    if ($LASTEXITCODE -ne 0) { throw ('去注释后编译失败：' + $f) }
}
Write-Host '  C# 去注释后编译检查：通过'

# ---------------- 3. 打包载荷 ----------------
# 按“字节”读进来（保住 BOM 与 CRLF），编码成 base64；安装时原样落到安装目录
$b64Ps1 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ps1Path))
$b64Ico = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($icoPath))
$b64Early = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($cleanEarlyPath))
$b64Native = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($cleanNativePath))
# LICENSE 按原始字节嵌进去（不做行尾归一化）：许可文本要在副本里和仓库里逐字节一致
$b64License = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($licensePath))

$cs = [System.IO.File]::ReadAllText($instCsPath, [System.Text.Encoding]::UTF8)
$cs = $cs.Replace('{PAYLOAD_PS1}', $b64Ps1).Replace('{PAYLOAD_ICO}', $b64Ico)
$cs = $cs.Replace('{PAYLOAD_EARLY}', $b64Early).Replace('{PAYLOAD_NATIVE}', $b64Native)
$cs = $cs.Replace('{PAYLOAD_LICENSE}', $b64License)
$csPath = Join-Path $buildDir 'Installer.cs'
[System.IO.File]::WriteAllText($csPath, $cs, $utf8bom)
Write-Host ('安装器源码：' + (Get-Item -LiteralPath $csPath).Length + ' 字节')

# ---------------- 4. 编译 ----------------
# 全程在 ASCII 路径下编译（csc 处理不了中文路径参数），编完再拷回工程目录
$icoAscii = Join-Path $buildDir 'payload.ico'
Copy-Item -LiteralPath $icoPath -Destination $icoAscii -Force
$outTmp = Join-Path $buildDir ($leaf + 'Setup.exe')
# 注意：PowerShell 里逗号的优先级高于加号，'/r:' + 路径 这种必须先用变量接住，
# 否则会被并成一个参数（表现为 /r: 缺少文件规范）
$refSystem = '/r:' + (Join-Path $fw 'System.dll')
$refDrawing = '/r:' + (Join-Path $fw 'System.Drawing.dll')
$refForms = '/r:' + (Join-Path $fw 'System.Windows.Forms.dll')
$refMscor = '/r:' + (Join-Path $fw 'mscorlib.dll')
$common = @('/nologo', '/target:winexe', '/optimize+', '/platform:anycpu', $refSystem, $refDrawing, $refForms, $refMscor)
$iconArg = '/win32icon:' + $icoAscii
$outArg = '/out:' + $outTmp

if (Test-Path -LiteralPath $outTmp) { Remove-Item -LiteralPath $outTmp -Force }
& $csc ($common + @($iconArg, $outArg, $csPath))
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outTmp)) {
    Write-Host '带图标编译失败，改用无图标重试'
    & $csc ($common + @($outArg, $csPath))
    if ($LASTEXITCODE -ne 0) { throw ('ERROR: compile failed (no-icon retry, exit ' + $LASTEXITCODE + ')') }
}
if (-not (Test-Path -LiteralPath $outTmp)) { throw 'ERROR: compile failed' }
Copy-Item -LiteralPath $outTmp -Destination $outExe -Force
Write-Host ('OK: ' + $outExe + '   ' + (Get-Item -LiteralPath $outExe).Length + ' bytes')
