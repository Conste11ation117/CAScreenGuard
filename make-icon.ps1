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
    # 用户指定的矩形：左边贴着 G 的右侧，上边界与右边界就是黑方块的边，下边界落在产品名那条线上。
    # 钥匙朝上放：钥匙头（圆环）在矩形底部，杆一路伸到矩形顶部，齿开在上半段的右侧。
    $pad = $f * 0.030
    $rx = $bx + $side * 0.585 + $pad
    $ry = $bx + $pad
    $rw = ($bx + $side) - $pad - $rx
    $rh = ($f * 0.560) - $pad - $ry
    if ($rw -le 0 -or $rh -le 0) { return }
    $cx = $rx + $rw / 2
    $brush = New-Object System.Drawing.SolidBrush $COLOR_LOCK
    # 钥匙头：圆环（中间挖空），放在底部
    $R = [Math]::Min([float]($rw * 0.50), [float]($rh * 0.30))
    $cy = $ry + $rh - $R
    $g.FillEllipse($brush, [float]($cx - $R), [float]($cy - $R), [float]($R * 2), [float]($R * 2))
    $hole = $R * 0.40
    $g.FillEllipse([System.Drawing.Brushes]::Black, [float]($cx - $hole), [float]($cy - $hole), [float]($hole * 2), [float]($hole * 2))
    # 杆：从钥匙头往上伸到矩形顶部
    $sw = $R * 0.46
    $top = $ry
    $bottom = $cy - $R * 0.55
    $body = New-RoundRect ([float]($cx - $sw / 2)) ([float]$top) ([float]$sw) ([float]($bottom - $top)) ([float]($sw * 0.30))
    $g.FillPath($brush, $body)
    # 齿：杆右侧两枚，开在靠上的位置（这样钥匙是"朝上"的）
    $t1 = New-RoundRect ([float]($cx + $sw * 0.30)) ([float]($ry + $rh * 0.155)) ([float]($sw * 0.85)) ([float]($sw * 0.52)) ([float]($sw * 0.16))
    $t2 = New-RoundRect ([float]($cx + $sw * 0.30)) ([float]($ry + $rh * 0.305)) ([float]($sw * 0.60)) ([float]($sw * 0.48)) ([float]($sw * 0.14))
    $g.FillPath($brush, $t1)
    $g.FillPath($brush, $t2)
    $t1.Dispose(); $t2.Dispose(); $body.Dispose(); $brush.Dispose()
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
$pngs = @()
foreach ($s in $sizes) {
    $b = Get-Frame $s
    $b.Save((Join-Path $tmp ('cg_icon_' + $s + '.png')), [System.Drawing.Imaging.ImageFormat]::Png)
    $ms = New-Object System.IO.MemoryStream
    $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngs += , $ms.ToArray()
    $b.Dispose(); $ms.Dispose()
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
    $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Flush(); $bw.Close(); $fs.Close()
Write-Host ('生成：' + $out + '   ' + (Get-Item -LiteralPath $out).Length + ' 字节   ' + ($sizes -join '/'))
