@echo off
chcp 65001 >nul
echo ============================================
echo   中华美食谱 - 图片批量优化工具
echo ============================================
echo.

set "images_dir=images"
set "optimized_dir=images-optimized"

if not exist "%optimized_dir%" mkdir "%optimized_dir%"

echo 正在扫描图片文件...
echo.

:: 使用 PowerShell 进行图片处理
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$ErrorActionPreference = 'Stop'; ^
Add-Type -AssemblyName System.Drawing; ^
$files = Get-ChildItem -Path '%images_dir%' -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png)$' }; ^
$total = $files.Count; $current = 0; ^
$origSize = 0; $optSize = 0; ^
foreach ($file in $files) { ^
    $current++; ^
    Write-Host \"[$current/$total] 处理: $($file.Name)\" -ForegroundColor Cyan; ^
    try { ^
        $img = [System.Drawing.Bitmap]::FromFile($file.FullName); ^
        $origSize += $file.Length; ^
        $newWidth = 800; ^
        if ($img.Width -gt $newWidth) { ^
            $ratio = $newWidth / $img.Width; ^
            $newHeight = [int]($img.Height * $ratio); ^
        } else { ^
            $newHeight = $img.Height; ^
            $newWidth = $img.Width; ^
        } ^
        $newImg = New-Object System.Drawing.Bitmap($newWidth, $newHeight); ^
        $graphics = [System.Drawing.Graphics]::FromImage($newImg); ^
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; ^
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality; ^
        $graphics.DrawImage($img, 0, 0, $newWidth, $newHeight); ^
        $ep = New-Object System.Drawing.Imaging.EncoderParameters(1); ^
        $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 80L); ^
        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1; ^
        $outFile = Join-Path '%optimized_dir%' ($file.BaseName + '_opt.jpg'); ^
        $newImg.Save($outFile, $jpegCodec, $ep); ^
        $optSize += (Get-Item $outFile).Length; ^
        $reduction = [math]::Round((1 - (Get-Item $outFile).Length / $file.Length) * 100, 1); ^
        Write-Host \"  ✓ 原始: $([math]::Round($file.Length/1KB, 2)) KB -> 优化: $([math]::Round((Get-Item $outFile).Length/1KB, 2)) KB (减小 $reduction%%)\" -ForegroundColor Green; ^
        $graphics.Dispose(); $img.Dispose(); $newImg.Dispose(); ^
    } catch { ^
        Write-Host \"  ✗ 错误: $_\" -ForegroundColor Red; ^
    } ^
}; ^
Write-Host ''; ^
Write-Host '========================================'; ^
Write-Host '📊 优化完成！' -ForegroundColor Yellow; ^
Write-Host \"总图片数: $total\"; ^
Write-Host (\"原始大小: {0:N2} MB\" -f ($origSize/1MB)); ^
Write-Host (\"优化后大小: {0:N2} MB\" -f ($optSize/1MB)); ^
if ($origSize -gt 0) { Write-Host (\"总体减小: {0:N1}%%\" -f ((1-$optSize/$origSize)*100)) }; ^
Write-Host ''; ^
Write-Host '优化后图片保存在: images-optimized\ 目录' -ForegroundColor Cyan"

echo.
echo ============================================
echo   提示：如果需要进一步压缩为 WebP 格式，
echo   请安装 sharp 库后运行: node optimize-images.js
echo ============================================
pause