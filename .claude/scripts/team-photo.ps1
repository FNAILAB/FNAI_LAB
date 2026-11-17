# Team photo tool for the FNAI LAB website (Windows PowerShell). Used by the /team-photo skill.
# Every team card photo is saved in ONE standard so all cards look the same:
#   900 x 900 px square JPEG; the head (top of hair to chin) fills 62% of the height;
#   10% space above the hair; the face is centred left-right.
#
# Modes (run from the website folder):
#   inspect : make an upright copy with a 10% grid so you can read off where the head is.
#     powershell -NoProfile -ExecutionPolicy Bypass -File .claude/scripts/team-photo.ps1 -Mode inspect -In "<original>"
#   crop    : cut the standard square. HeadTop / Chin / CenterX are fractions (0-1) of the UPRIGHT photo, read from the grid.
#     ... -Mode crop -In "<original>" -Out "assets/team/<slug>.jpg" -HeadTop 0.12 -Chin 0.43 -CenterX 0.50 [-PlainBackground]
#     -PlainBackground: only for plain studio/ID backgrounds - lets the square extend past the left/right/top edges,
#     filled with the background colour (never past the bottom).
#   sheet   : put several team photos side by side with guide lines, to compare them.
#     ... -Mode sheet -Photos "assets/team/a.jpg","assets/team/b.jpg"
# inspect and sheet write only to a temporary folder (never into the website).
param(
    [Parameter(Mandatory = $true)][ValidateSet('inspect', 'crop', 'sheet')][string]$Mode,
    [string]$In,
    [string]$Out,
    [double]$HeadTop = -1,
    [double]$Chin = -1,
    [double]$CenterX = -1,
    [string[]]$Photos,
    [switch]$PlainBackground
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# The standard (keep in sync with team-photo.py and the skill).
$OUT_SIZE = 900
$HEAD_FRACTION = 0.62    # head height / frame height
$TOP_MARGIN = 0.10       # space above the hair / frame height

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) 'fnai-team-photo'
if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir | Out-Null }

function Open-Upright([string]$path) {
    $full = (Resolve-Path -LiteralPath $path).Path
    if ($full -match '\.(heic|heif)$') { throw "HEIC/HEIF photos are not supported. Please export the photo as JPG first." }
    $img = [System.Drawing.Image]::FromFile($full)
    if ($img.PropertyIdList -contains 0x0112) {
        $o = [BitConverter]::ToUInt16($img.GetPropertyItem(0x0112).Value, 0)
        $flip = switch ($o) { 2 { 'RotateNoneFlipX' } 3 { 'Rotate180FlipNone' } 4 { 'Rotate180FlipX' } 5 { 'Rotate90FlipX' }
                              6 { 'Rotate90FlipNone' } 7 { 'Rotate270FlipX' } 8 { 'Rotate270FlipNone' } default { $null } }
        if ($flip) { $img.RotateFlip([System.Drawing.RotateFlipType]::$flip) }
    }
    return $img
}

function Save-Jpeg($bmp, [string]$path) {
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $p = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $q = [long]88
    $p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $q)
    $bmp.Save($path, $enc, $p)
}

function New-Graphics($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $g
}

if ($Mode -eq 'inspect') {
    if (-not $In) { throw "-In is required" }
    $img = Open-Upright $In
    try {
        $scale = [Math]::Min(1.0, 1000.0 / [Math]::Max($img.Width, $img.Height))
        $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        $g = New-Graphics $bmp
        $g.DrawImage($img, 0, 0, $w, $h)
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 255, 0, 0)), 1
        $font = New-Object System.Drawing.Font 'Arial', 11, ([System.Drawing.FontStyle]::Bold)
        $bg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(170, 255, 255, 255))
        for ($i = 1; $i -lt 10; $i++) {
            $x = [int]($w * $i / 10); $y = [int]($h * $i / 10)
            $g.DrawLine($pen, $x, 0, $x, $h); $g.DrawLine($pen, 0, $y, $w, $y)
            $g.FillRectangle($bg, 2, $y - 9, 30, 17); $g.DrawString(("{0:0.0}" -f ($i / 10)), $font, [System.Drawing.Brushes]::Red, 3, $y - 9)
            $g.FillRectangle($bg, $x - 14, 2, 30, 17); $g.DrawString(("{0:0.0}" -f ($i / 10)), $font, [System.Drawing.Brushes]::Red, $x - 13, 2)
        }
        $g.Dispose()
        $name = [System.IO.Path]::GetFileNameWithoutExtension($In) -replace '[^A-Za-z0-9_-]', '_'
        $outPath = Join-Path $tmpDir ("inspect-$name-" + (Get-Date -Format "HHmmss") + "-" + (Get-Random -Maximum 99999) + ".jpg")
        Save-Jpeg $bmp $outPath
        $bmp.Dispose()
        Write-Output ("Upright photo is {0}x{1} px. Grid copy: {2}" -f $img.Width, $img.Height, $outPath)
        Write-Output "Read off (as fractions 0-1): HeadTop = top of hair, Chin = bottom of chin, CenterX = middle of the face (nose)."
    } finally { $img.Dispose() }
    exit 0
}

if ($Mode -eq 'crop') {
    if (-not $In -or -not $Out) { throw "-In and -Out are required" }
    foreach ($v in @(@('HeadTop', $HeadTop), @('Chin', $Chin), @('CenterX', $CenterX))) {
        if ($v[1] -lt 0 -or $v[1] -gt 1) { throw "-$($v[0]) must be a fraction between 0 and 1 (read it from the inspect grid)" }
    }
    if ($Chin -le $HeadTop) { throw "-Chin must be below -HeadTop (a larger number)" }
    $outFull = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out))
    if ((Resolve-Path -LiteralPath $In).Path -eq $outFull) { throw "Input and output are the same file. Crop from the original photo instead." }
    if ($outFull -notmatch '\\assets\\team\\[a-z0-9]+(-[a-z0-9]+)*\.jpg$') { throw "-Out must be assets/team/<slug>.jpg (lowercase letters, digits, hyphens)" }

    $img = Open-Upright $In
    try {
        $W = $img.Width; $H = $img.Height
        $topPx = $HeadTop * $H
        $headPx = ($Chin - $HeadTop) * $H
        $S = $headPx / $HEAD_FRACTION                       # square side that gives the standard head size
        # Never go below the bottom of the photo (that would cut the shoulders off with a flat band).
        $S = [Math]::Min($S, ($H - $topPx) / (1 - $TOP_MARGIN))
        # Without -PlainBackground the square must stay inside the photo (no added background).
        if (-not $PlainBackground) { $S = [Math]::Min($S, [Math]::Min($W, $H)) }
        $limited = (($headPx / $S) -gt ($HEAD_FRACTION + 0.04))   # head clearly bigger than the standard
        $x0 = $CenterX * $W - $S / 2
        $y0 = $topPx - $TOP_MARGIN * $S
        if ($PlainBackground) {
            # Allowed to extend past the left/right/top edges (filled with the background colour), never past the bottom.
            if ($S -le $W) { $x0 = [Math]::Max(0, [Math]::Min($W - $S, $x0)) }
            $y0 = [Math]::Min($H - $S, $y0)
        } else {
            $x0 = [Math]::Max(0, [Math]::Min($W - $S, $x0))
            $y0 = [Math]::Max(0, [Math]::Min($H - $S, $y0))
        }

        # Background colour = average of small patches in the two top corners of the photo.
        $bmpSrc = New-Object System.Drawing.Bitmap($img)
        $r = 0; $gg = 0; $b = 0; $n = 0
        $patch = [Math]::Max(2, [int]([Math]::Min($W, $H) * 0.03))
        foreach ($cx in @(0, ($W - $patch))) { for ($yy = 0; $yy -lt $patch; $yy += 2) { for ($xx = $cx; $xx -lt $cx + $patch; $xx += 2) {
            $c = $bmpSrc.GetPixel($xx, $yy); $r += $c.R; $gg += $c.G; $b += $c.B; $n++ } } }
        $bmpSrc.Dispose()
        $bgColor = [System.Drawing.Color]::FromArgb([int]($r / $n), [int]($gg / $n), [int]($b / $n))

        $bmp = New-Object System.Drawing.Bitmap($OUT_SIZE, $OUT_SIZE)
        $g = New-Graphics $bmp
        $g.Clear($bgColor)
        # Map the source square [x0, x0+S] x [y0, y0+S] onto the output; parts outside the photo stay background.
        $k = $OUT_SIZE / $S
        $dest = New-Object System.Drawing.RectangleF ([float](-$x0 * $k)), ([float](-$y0 * $k)), ([float]($W * $k)), ([float]($H * $k))
        $attr = New-Object System.Drawing.Imaging.ImageAttributes
        $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)   # avoids a thin dark seam at the photo edge
        $g.DrawImage($img, [System.Drawing.Rectangle]::Round($dest), 0, 0, $W, $H, [System.Drawing.GraphicsUnit]::Pixel, $attr)
        $g.Dispose()
        Save-Jpeg $bmp $outFull
        $bmp.Dispose()

        # Where the head actually ended up (the standard is: top 14%, head 50%, centre 50%).
        $topPct = ($HeadTop * $H - $y0) / $S * 100
        $chinPct = ($Chin * $H - $y0) / $S * 100
        $cxPct = ($CenterX * $W - $x0) / $S * 100
        $kb = [int]((Get-Item -LiteralPath $outFull).Length / 1KB)
        Write-Output ("Saved {0} ({1}x{1}, {2} KB). Head: top {3:0}% / chin {4:0}% / centre {5:0}%  (standard: 10% / 72% / 50%)" -f $Out, $OUT_SIZE, $kb, $topPct, $chinPct, $cxPct)
        if ($limited) { Write-Output "NOTE: the photo is too tightly framed to reach the standard; the head is clearly larger than the standard 62%. If the background is plain (studio/ID photo), run again with -PlainBackground. Ask for a wider photo if it looks too big next to the others." }
        if ([Math]::Abs($topPct - 10) -gt 4 -or [Math]::Abs($cxPct - 50) -gt 6) { Write-Output "NOTE: the face could not be placed at the standard position (it is near the photo's edge). Check the comparison sheet; a wider photo may be needed." }
        if ([Math]::Min($W, $H) -lt 500 -or $S -lt 450) { Write-Output "NOTE: the source photo is small; the result may look blurry. A larger photo is better." }
    } finally { $img.Dispose() }
    exit 0
}

if ($Mode -eq 'sheet') {
    $Photos = @($Photos | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (-not $Photos -or $Photos.Count -lt 1) { throw "-Photos needs at least one file" }
    $cell = 220; $pad = 10; $label = 22
    $cols = [Math]::Min(6, $Photos.Count); $rows = [Math]::Ceiling($Photos.Count / $cols)
    $bmp = New-Object System.Drawing.Bitmap (($cell + $pad) * $cols + $pad), (($cell + $pad + $label) * $rows + $pad)
    $g = New-Graphics $bmp
    $g.Clear([System.Drawing.Color]::White)
    $font = New-Object System.Drawing.Font 'Arial', 9
    $guide = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160, 255, 0, 0)), 1
    $guide.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    $k = 0
    foreach ($p in $Photos) {
        $x = $pad + ($k % $cols) * ($cell + $pad); $y = $pad + [Math]::Floor($k / $cols) * ($cell + $pad + $label)
        $img = Open-Upright $p
        try {
            # Show exactly what the card shows: a centred square (cards crop to 1:1).
            $s = [Math]::Min($img.Width, $img.Height)
            $sx = ($img.Width - $s) / 2; $sy = ($img.Height - $s) * 0.25
            $g.DrawImage($img, (New-Object System.Drawing.RectangleF $x, $y, $cell, $cell), (New-Object System.Drawing.RectangleF ([float]$sx), ([float]$sy), ([float]$s), ([float]$s)), [System.Drawing.GraphicsUnit]::Pixel)
        } finally { $img.Dispose() }
        foreach ($f in @($TOP_MARGIN, ($TOP_MARGIN + $HEAD_FRACTION))) { $gy = $y + [int]($cell * $f); $g.DrawLine($guide, $x, $gy, $x + $cell, $gy) }
        $g.DrawLine($guide, $x + $cell / 2, $y, $x + $cell / 2, $y + $cell)
        $g.DrawString([System.IO.Path]::GetFileName($p), $font, [System.Drawing.Brushes]::Black, $x, $y + $cell + 3)
        $k++
    }
    $g.Dispose()
    $outPath = Join-Path $tmpDir ("sheet-" + (Get-Date -Format "HHmmss") + "-" + (Get-Random -Maximum 99999) + ".jpg")
    Save-Jpeg $bmp $outPath
    $bmp.Dispose()
    Write-Output "Comparison sheet: $outPath"
    Write-Output "Red dashed lines = the standard: top of hair on the upper line, chin on the lower line, nose on the vertical line."
    exit 0
}
