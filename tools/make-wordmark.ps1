# 生成「CAScreenGuard」字标 PNG（JetBrains Mono Bold），供主脚本以 base64 内嵌。
#
# 为什么预渲染成图：产品只带 4 个文件 + LICENSE，不想要求用户去装 JetBrains Mono；
# 运行时也不用解析字形，遮罩重绘时只贴一张图。
#
# 用法：powershell -File make-wordmark.ps1 [-FontPath <ttf>] [-Text CAScreenGuard] [-PixelSize 80]
param(
    [string]$FontPath = 'C:\FontBackup\JetBrainsMono-Bold.ttf',
    [string]$Text = 'CAScreenGuard',
    [int]$PixelSize = 80,
    [string]$OutFile = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not $OutFile) { $OutFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'src\assets\CAScreenGuard-wordmark.png' }
if (-not (Test-Path -LiteralPath $FontPath)) {
    throw ('找不到字体文件：' + $FontPath + '。可以从 JetBrains 官网下载 JetBrains Mono（OFL 许可）后指定 -FontPath。')
}

$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile($FontPath)
$fam = $pfc.Families[0]
$font = New-Object System.Drawing.Font($fam, [float]$PixelSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

$probe = New-Object System.Drawing.Bitmap 1, 1
$pg = [System.Drawing.Graphics]::FromImage($probe)
$pg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$sz = $pg.MeasureString($Text, $font)
$pg.Dispose(); $probe.Dispose()

$w = [int][math]::Ceiling($sz.Width)
$h = [int][math]::Ceiling($sz.Height)
$bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Transparent)
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(242, 242, 244))
# 左右各留 2px：抗锯齿边缘落在画布外会被裁掉
$g.DrawString($Text, $font, $brush, [float]2, [float]2)
$g.Dispose(); $brush.Dispose()

$bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host ('已生成 ' + $OutFile + '  ' + $w + 'x' + $h + '，字体族：' + $fam.Name)
Write-Host '把它换成 base64 填进 src\CAScreenGuard.ps1 的 $script:WordmarkB64（分片写，每行 96 字符即可）：'
Write-Host ('  ' + [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($OutFile)).Substring(0, 32) + '...')
