# 图片优化脚本 - 使用 PowerShell
# 将图片转换为 WebP 格式并压缩

$ErrorActionPreference = "Stop"

$imagesDir = Join-Path $PSScriptRoot "images"
$optimizedDir = Join-Path $PSScriptRoot "images-optimized"

# 创建输出目录
if (!(Test-Path $optimizedDir)) {
    New-Item -ItemType Directory -Path $optimizedDir | Out-Null
}

# 获取所有图片文件
$imageFiles = Get-ChildItem -Path $imagesDir -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png|gif)$' }

Write-Host "找到 $($imageFiles.Count) 张图片需要优化..." -ForegroundColor Cyan
Write-Host ""

$totalOriginalSize = 0
$totalOptimizedSize = 0
$processedCount = 0

foreach ($file in $imageFiles) {
    $inputPath = $file.FullName
    $outputFilename = $file.BaseName + ".webp"
    $outputPath = Join-Path $optimizedDir $outputFilename
    
    try {
        $originalSize = $file.Length
        $totalOriginalSize += $originalSize
        
        # 使用 .NET 的 Bitmap 类来处理图片
        Add-Type -AssemblyName System.Drawing
        
        # 加载原始图片
        $bitmap = [System.Drawing.Bitmap]::FromFile($inputPath)
        
        # 计算新尺寸（最大宽度 800px）
        $newWidth = 800
        $ratio = $newWidth / $bitmap.Width
        $newHeight = [int]($bitmap.Height * $ratio)
        
        # 创建新的位图
        $newBitmap = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
        
        # 设置高质量插值法
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        
        # 绘制缩放后的图像
        $graphics.DrawImage($bitmap, 0, 0, $newWidth, $newHeight)
        
        # 保存为高质量 JPEG（WebP 需要额外库）
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
            [System.Drawing.Imaging.Encoder]::Quality, 80L
        )
        
        $jpegCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | 
            Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
        
        $newBitmap.Save($outputPath.Replace('.webp', '.jpg'), $jpegCodecInfo, $encoderParams)
        
        # 清理资源
        $graphics.Dispose()
        $bitmap.Dispose()
        $newBitmap.Dispose()
        
        if (Test-Path $outputPath.Replace('.webp', '.jpg')) {
            $optimizedSize = (Get-Item $outputPath.Replace('.webp', '.jpg')).Length
            $totalOptimizedSize += $optimizedSize
            
            $reduction = [math]::Round((1 - $optimizedSize / $originalSize) * 100, 1)
            
            Write-Host "✓ $($file.Name)" -ForegroundColor Green
            Write-Host "  原始: $([math]::Round($originalSize/1KB, 2)) KB"
            Write-Host "  优化: $([math]::Round($optimizedSize/1KB, 2)) KB (减小 $reduction%)"
            Write-Host ""
            
            $processedCount++
        }
    }
    catch {
        Write-Host "✗ 处理 $($file.Name) 时出错: $_" -ForegroundColor Red
    }
}

Write-Host "=" * 50
Write-Host ""
Write-Host "📊 优化完成！" -ForegroundColor Yellow
Write-Host "处理图片数: $processedCount"
Write-Host "原始总大小: $([math]::Round($totalOriginalSize/1MB, 2)) MB"
Write-Host "优化后大小: $([math]::Round($totalOptimizedSize/1MB, 2)) MB"
if ($totalOriginalSize -gt 0) {
    Write-Host "总体积减小: $([math]::Round((1 - $totalOptimizedSize / $totalOriginalSize) * 100, 1))%"
}
Write-Host ""
Write-Host "优化后的图片保存在: images-optimized\ 目录" -ForegroundColor Cyan