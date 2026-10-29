# 生成 CAScreenGuard.ico
# 画风参考 JetBrains 产品图标：两张倾斜的彩色圆角方块叠着，中间压一个黑色方块。
#   黑方块里只放居中的「SG」两个大字母 —— 其余元素（产品名、钥匙）在小尺寸下都会糊成一团，
#   索性去掉，让图标在 16px 也能一眼认出来。
#   ≥48px：黑方块里是居中的「SG」（JetBrains Mono，没装则回退系统中文字体里的等宽字体）
#   <48px ：两个字母已经看不清了，改用一根短横线
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }
$out = Join-Path (Join-Path $root 'src\assets') 'CAScreenGuard.ico'
$tmp = $env:TEMP

$COLOR_BACK  = [System.Drawing.Color]::FromArgb(255, 47, 168, 248)    # 青蓝
$COLOR_FRONT = [System.Drawing.Color]::FromArgb(255, 124, 77, 255)    # 紫

# 字体：优先 JetBrains Mono，没装就退回系统自带的等宽字体
function Test-FontInstalled([string]$Name) {
    foreach ($f in [System.Drawing.FontFamily]::Families) { if ($f.Name -eq $Name) { return $true } }
    return $false
}
$FONT_MAIN = 'Segoe UI'
foreach ($cand in @('JetBrains Mono', 'Cascadia Mono', 'Consolas', 'Lucida Console')) {
    if (Test-FontInstalled $cand) { $FONT_MAIN = $cand; break }
}
Write-Host ('  使用字体：' + $FONT_MAIN)

function New-RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Draw-Icon([int]$S, [switch]$Small) {
    $bmp = New-Object System.Drawing.Bitmap($S, $S, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)
    $f = [float]$S

    # ---- 两张倾斜的彩块 ----
    $layerSize = $f * 0.80
    $radius = $f * 0.185
    $tilt = -10.0
    foreach ($layer in @(
        @{ cx = 0.435 * $f; cy = 0.435 * $f; color = $COLOR_BACK },
        @{ cx = 0.565 * $f; cy = 0.565 * $f; color = $COLOR_FRONT })) {
        $path = New-RoundRect (-$layerSize / 2) (-$layerSize / 2) $layerSize $layerSize $radius
        $mtx = New-Object System.Drawing.Drawing2D.Matrix
        $mtx.RotateAt($tilt, (New-Object System.Drawing.PointF(0, 0)))
        $mtx.Translate($layer.cx, $layer.cy)
        $path.Transform($mtx)
        $brush = New-Object System.Drawing.SolidBrush $layer.color
        $g.FillPath($brush, $path)
        $brush.Dispose(); $path.Dispose(); $mtx.Dispose()
    }

    # ---- 中间的黑色方块（不倾斜，和参考图一致）----
    $side = $f * 0.62
    $bx = ($f - $side) / 2
    $by = ($f - $side) / 2
    $black = New-RoundRect $bx $by $side $side ($f * 0.055)
    $g.FillPath([System.Drawing.Brushes]::Black, $black)

    $sfMiddle = New-Object System.Drawing.StringFormat
    $sfMiddle.Alignment = [System.Drawing.StringAlignment]::Center
    $sfMiddle.LineAlignment = [System.Drawing.StringAlignment]::Center

    if (-not $Small) {
        # 两个大字母：水平垂直都居中，撑满黑方块
        $sgSize = $f * 0.30
        $fontSG = New-Object System.Drawing.Font($FONT_MAIN, [float]$sgSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $rectSG = New-Object System.Drawing.RectangleF $bx, $by, $side, $side
        $g.DrawString('SG', $fontSG, [System.Drawing.Brushes]::White, $rectSG, $sfMiddle)
        $fontSG.Dispose()
    }
    else {
        # 小尺寸：两个字母已经看不清，用一根短横线代替
        $barW = $f * 0.34
        $barH = [Math]::Max([float]($f * 0.055), 1.0)
        $bar = New-RoundRect (($f - $barW) / 2) (($f - $barH) / 2) $barW $barH ([Math]::Min($barH / 2, $f * 0.02))
        $g.FillPath([System.Drawing.Brushes]::White, $bar)
        $bar.Dispose()
    }

    $black.Dispose(); $sfMiddle.Dispose(); $g.Dispose()
    return $bmp
}

# 两版底图：大字版（居中 SG）给 48/64/128/256 用；小图版（一根短横线）给更小的尺寸缩着用
$masterBig = Draw-Icon 256
$masterSmall = Draw-Icon 256 -Small
$masterBig.Save((Join-Path $tmp 'cg_icon_256.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$masterSmall.Save((Join-Path $tmp 'cg_icon_256_small.png'), [System.Drawing.Imaging.ImageFormat]::Png)

function Get-Frame([int]$s) {
    if ($s -ge 48) { return (Draw-Icon $s) }
    $b = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($masterSmall, (New-Object System.Drawing.Rectangle(0, 0, $s, $s)))
    $g.Dispose()
    return $b
}

$sizes = @(16, 24, 32, 48, 64, 128, 256)

# 帧格式：256 用 PNG（省体积，资源管理器认），更小的尺寸用标准 BMP 帧。
# 原因：System.Drawing.Icon（.NET / GDI）读不了 PNG 压缩帧 —— 会解出一团彩色噪点，
# 表现为脚本里那些窗体标题栏图标全变雪花。BMP 帧虽然大一点，但所有老工具都认。
function Get-IcoFrame([System.Drawing.Bitmap]$Bmp, [bool]$UsePng) {
    if ($UsePng) {
        $ms = New-Object System.IO.MemoryStream
        $Bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $bytes = $ms.ToArray()
        $ms.Dispose()
        return , $bytes
    }
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    # BITMAPINFOHEADER：高度要写两倍（XOR 位图 + AND 掩码）
    $bw.Write([uint32]40)
    $bw.Write([int32]$Bmp.Width)
    $bw.Write([int32]($Bmp.Height * 2))
    $bw.Write([uint16]1)
    $bw.Write([uint16]32)
    $bw.Write([uint32]0)
    $bw.Write([uint32]($Bmp.Width * $Bmp.Height * 4))
    $bw.Write([int32]0); $bw.Write([int32]0); $bw.Write([uint32]0); $bw.Write([uint32]0)
    for ($y = $Bmp.Height - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $Bmp.Width; $x++) {
            $c = $Bmp.GetPixel($x, $y)
            $bw.Write([byte]$c.B); $bw.Write([byte]$c.G); $bw.Write([byte]$c.R); $bw.Write([byte]$c.A)
        }
    }
    # AND 掩码：1bpp，每行补齐到 4 字节；全 0 = 透明度交给 alpha 通道
    $rowBytes = [int]([Math]::Ceiling($Bmp.Width / 32.0) * 4)
    $zero = New-Object byte[] $rowBytes
    for ($y = 0; $y -lt $Bmp.Height; $y++) { $bw.Write($zero, 0, $rowBytes) }
    $bw.Flush()
    $bytes = $ms.ToArray()
    $bw.Dispose(); $ms.Dispose()
    return , $bytes
}

$frames = @()
foreach ($s in $sizes) {
    $b = Get-Frame $s
    $b.Save((Join-Path $tmp ('cg_icon_' + $s + '.png')), [System.Drawing.Imaging.ImageFormat]::Png)
    $frames += , (Get-IcoFrame $b ($s -ge 256))
    $b.Dispose()
}
$masterBig.Dispose(); $masterSmall.Dispose()

$fs = [System.IO.File]::Create($out)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $d = [byte]$(if ($s -ge 256) { 0 } else { $s })
    $bw.Write($d); $bw.Write($d); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]$frames[$i].Length); $bw.Write([uint32]$offset)
    $offset += $frames[$i].Length
}
foreach ($p in $frames) { $bw.Write($p) }
$bw.Flush(); $bw.Close(); $fs.Close()
Write-Host ('生成：' + $out + '   ' + (Get-Item -LiteralPath $out).Length + ' 字节   ' + ($sizes -join '/'))
