# Resize a photo for the FNAI LAB website (Windows PowerShell).
# - Fixes phone photos that would otherwise appear sideways (EXIF orientation).
# - Shrinks so the longest side is at most -MaxSide pixels (never enlarges).
# - Saves JPEG at quality 85 (or PNG if -Out ends in .png).
#
# Usage (from the website folder):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .claude/scripts/resize-image.ps1 -In "C:\path\photo.jpg" -Out "assets/news/kcc2026-1.jpg" -MaxSide 1600
#
# HEIC/HEIF (iPhone) files cannot be read here: ask for a JPG/PNG copy instead.
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$MaxSide = 1600
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$inPath = (Resolve-Path -LiteralPath $In).Path
if ($inPath -match '\.(heic|heif)$') { throw "HEIC/HEIF photos are not supported. Please export the photo as JPG first." }
$outPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out))
if ($inPath -eq $outPath) { throw "Input and output are the same file. Use a different -Out path." }
$outDir = Split-Path $outPath
if (-not (Test-Path -LiteralPath $outDir)) { throw "Output folder does not exist: $outDir" }

$src = [System.Drawing.Image]::FromFile($inPath)
try {
    # 0x0112 = EXIF Orientation
    if ($src.PropertyIdList -contains 0x0112) {
        $o = [BitConverter]::ToUInt16($src.GetPropertyItem(0x0112).Value, 0)
        $flip = switch ($o) {
            2 { 'RotateNoneFlipX' } 3 { 'Rotate180FlipNone' } 4 { 'Rotate180FlipX' }
            5 { 'Rotate90FlipX' }   6 { 'Rotate90FlipNone' }  7 { 'Rotate270FlipX' }
            8 { 'Rotate270FlipNone' } default { $null }
        }
        if ($flip) { $src.RotateFlip([System.Drawing.RotateFlipType]::$flip) }
    }
    $w = $src.Width; $h = $src.Height
    $scale = [Math]::Min(1.0, $MaxSide / [double][Math]::Max($w, $h))
    $nw = [int][Math]::Round($w * $scale); $nh = [int][Math]::Round($h * $scale)

    $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        if ($outPath -notmatch '\.png$') { $g.Clear([System.Drawing.Color]::White) }  # JPEG has no transparency
        $g.DrawImage($src, 0, 0, $nw, $nh)
    } finally { $g.Dispose() }

    if ($outPath -match '\.png$') {
        $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } else {
        $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $q = [long]85
        $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $q)
        $bmp.Save($outPath, $enc, $params)
    }
    $bmp.Dispose()
} finally { $src.Dispose() }

$kb = [int]((Get-Item -LiteralPath $outPath).Length / 1KB)
Write-Output ("Saved {0} ({1}x{2}, {3} KB)" -f $Out, $nw, $nh, $kb)
