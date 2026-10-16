# 生成 CAScreenGuard.ico
# 画风参考 JetBrains 产品图标：两张倾斜的彩色圆角方块叠着，中间压一个黑色方块，
# 里面两个大字母 + 下面一行小字。
#   ≥64px：黑方块里是「SG」+ 产品名 CAScreenGuard（JetBrains Mono）
#   <64px ：产品名会糊成一团，改用参考图里那根白色短横线
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }
$out = Join-Path $root 'CAScreenGuard.ico'
$tmp = $env:TEMP

$COLOR_BACK  = [System.Drawing.Color]::FromArgb(255, 47, 168, 248)    # 青蓝
$COLOR_FRONT = [System.Drawing.Color]::FromArgb(255, 124, 77, 255)    # 紫
$FONT_MAIN   = 'JetBrains Mono'  # 两个大字母（用户要求与产品名统一用 JetBrains Mono）
$FONT_NAME   = 'JetBrains Mono'  # 产品名（装了就等宽，没装自动回退）
$COLOR_NAME  = [System.Drawing.Color]::FromArgb(255, 135, 206, 235)   # 产品名：天蓝
$COLOR_LOCK  = [System.Drawing.Color]::FromArgb(255, 168, 174, 186)   # 锁：灰

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

function Draw-Key([System.Drawing.Graphics]$g, [float]$f, [float]$bx, [float]$side) {
    # 钥匙画在「SG」右侧那一竖条里：细杆朝上，底部是一个圆角握柄（不用圆环，圆环太占视觉空间），
    # 杆的上半段右侧开两枚齿。
    $pad = $f * 0.030
    $rx = $bx + $side * 0.585 + $pad
    $ry = $bx + $pad
    $rw = ($bx + $side) - $pad - $rx
    $rh = ($f * 0.560) - $pad - $ry
    if ($rw -le 0 -or $rh -le 0) { return }
    $cx = $rx + $rw / 2
    $brush = New-Object System.Drawing.SolidBrush $COLOR_LOCK

    # 握柄：底部一块近方形圆角矩形 + 中间一个方形小孔（不是圆环：圆环占地方且小尺寸下糊成一团）
    $hh = $rw * 0.52
    $hw = $rw * 0.74
    $hy = $ry + $rh - $hh
    $head = New-RoundRect ([float]($cx - $hw / 2)) ([float]$hy) ([float]$hw) ([float]$hh) ([float]($hh * 0.26))
    $g.FillPath($brush, $head)
    $holeS = $hh * 0.46
    $hole = New-RoundRect ([float]($cx - $holeS / 2)) ([float]($hy + ($hh - $holeS) / 2)) ([float]$holeS) ([float]$holeS) ([float]($holeS * 0.26))
    # 孔用"挖空"的方式画：孔的底色就是内层黑方块
    $g.FillPath([System.Drawing.Brushes]::Black, $hole)
    $hole.Dispose()

    # 杆：从握柄上沿一路伸到顶端，顶端再收一个圆角（止于握柄，别压住握柄上的孔）
    $sw = $rw * 0.22
    $top = $ry + $sw * 0.5
    $bottom = $hy + $hh * 0.12
    $body = New-RoundRect ([float]($cx - $sw / 2)) ([float]($top - $sw * 0.5)) ([float]$sw) ([float]($bottom - $top + $sw)) ([float]($sw * 0.48))
    $g.FillPath($brush, $body)

    # 齿：杆右侧两枚，越往上越短（读起来像钥匙而不是梳子）
    $t1 = New-RoundRect ([float]($cx + $sw * 0.30)) ([float]($ry + $rh * 0.17)) ([float]($sw * 0.95)) ([float]($sw * 0.52)) ([float]($sw * 0.16))
    $t2 = New-RoundRect ([float]($cx + $sw * 0.30)) ([float]($ry + $rh * 0.36)) ([float]($sw * 0.62)) ([float]($sw * 0.44)) ([float]($sw * 0.14))
    $g.FillPath($brush, $t1)
    $g.FillPath($brush, $t2)
    $t1.Dispose(); $t2.Dispose(); $head.Dispose(); $body.Dispose(); $brush.Dispose()
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
    $black = New-RoundRect $bx $by $side $side ($f * 0.022)
    $g.FillPath([System.Drawing.Brushes]::Black, $black)

    # ---- 两个大字母 + 产品名：都靠左上角排 ----
    $sfCenter = New-Object System.Drawing.StringFormat
    $sfCenter.Alignment = [System.Drawing.StringAlignment]::Center
    $sfCenter.LineAlignment = [System.Drawing.StringAlignment]::Near
    $sfLeft = New-Object System.Drawing.StringFormat
    $sfLeft.Alignment = [System.Drawing.StringAlignment]::Near
    $sfLeft.LineAlignment = [System.Drawing.StringAlignment]::Near
    $pad = $f * 0.042
    $x0 = $bx + $pad

    $sgSize = $f * 0.250
    $fontSG = New-Object System.Drawing.Font($FONT_NAME, [float]$sgSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $rectSG = New-Object System.Drawing.RectangleF $x0, ($by + $pad - $f * 0.018), ($side - $pad * 2), ($f * 0.40)
    $g.DrawString('SG', $fontSG, [System.Drawing.Brushes]::White, $rectSG, $sfLeft)
    $fontSG.Dispose()

    if (-not $Small) {
        # 产品名：JetBrains Mono，放在参考图里那根横线的位置（黑方块下三分之一处）
        $nameSize = $f * 0.058
        $fontName = New-Object System.Drawing.Font($FONT_NAME, [float]$nameSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
        $rectName = New-Object System.Drawing.RectangleF $bx, ($f * 0.620), $side, ($f * 0.14)
        $nameBrush = New-Object System.Drawing.SolidBrush $COLOR_NAME
        $g.DrawString('CAScreenGuard', $fontName, $nameBrush, $rectName, $sfCenter)
        $nameBrush.Dispose()
        $fontName.Dispose()
        Draw-Key $g $f $bx $side
    }
    else {
        # 小尺寸：用参考图里那根白色短横线代替产品名
        $barW = $f * 0.28
        $barH = [Math]::Max([float]($f * 0.052), 1.0)
        $bar = New-RoundRect (($f - $barW) / 2) ($f * 0.665) $barW $barH ([Math]::Min($barH / 2, $f * 0.02))
        $g.FillPath([System.Drawing.Brushes]::White, $bar)
        $bar.Dispose()
        Draw-Key $g $f $bx $side
    }

    $black.Dispose(); $sfLeft.Dispose(); $sfCenter.Dispose(); $g.Dispose()
    return $bmp
}

# 两版底图：大字版（带产品名）给 128/256 用；小图版（只带短横线）给更小的尺寸缩着用
$masterBig = Draw-Icon 256
$masterSmall = Draw-Icon 256 -Small
$masterBig.Save((Join-Path $tmp 'cg_icon_256.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$masterSmall.Save((Join-Path $tmp 'cg_icon_256_small.png'), [System.Drawing.Imaging.ImageFormat]::Png)

function Get-Frame([int]$s) {
    if ($s -ge 128) { return (Draw-Icon $s) }
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
