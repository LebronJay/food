const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const imagesDir = path.join(__dirname, 'images');
const optimizedDir = path.join(__dirname, 'images-optimized');

// 创建优化后的目录
if (!fs.existsSync(optimizedDir)) {
    fs.mkdirSync(optimizedDir);
}

// 获取所有图片文件
const imageFiles = fs.readdirSync(imagesDir)
    .filter(file => /\.(jpg|jpeg|png|gif)$/i.test(file));

console.log(`找到 ${imageFiles.length} 张图片需要优化...\n`);

let totalOriginalSize = 0;
let totalOptimizedSize = 0;
let processedCount = 0;

async function optimizeImage(filename) {
    const inputPath = path.join(imagesDir, filename);
    
    // 输出为 webp 格式（更高效的格式）
    const outputFilename = filename.replace(/\.(jpg|jpeg|png|gif)$/i, '.webp');
    const outputPath = path.join(optimizedDir, outputFilename);

    try {
        const inputStats = fs.statSync(inputPath);
        totalOriginalSize += inputStats.size;

        await sharp(inputPath)
            .resize(800, null, { 
                withoutEnlargement: true,
                fit: 'inside'
            }) // 最大宽度 800px，保持比例
            .webp({ 
                quality: 80,
                effort: 6 // 压缩级别 0-6，6 是最高
            })
            .toFile(outputPath);

        const outputStats = fs.statSync(outputPath);
        totalOptimizedSize += outputStats.size;
        
        const reduction = ((1 - outputStats.size / inputStats.size) * 100).toFixed(1);
        
        console.log(`✓ ${filename}`);
        console.log(`  原始: ${(inputStats.size / 1024).toFixed(2)} KB`);
        console.log(`  优化: ${(outputStats.size / 1024).toFixed(2)} KB (减小 ${reduction}%)\n`);
        
        processedCount++;
        return { filename, originalSize: inputStats.size, optimizedSize: outputStats.size };
    } catch (error) {
        console.error(`✗ 处理 ${filename} 时出错:`, error.message);
        return null;
    }
}

async function main() {
    console.log('开始优化图片...\n');
    console.log('=' .repeat(50) + '\n');

    // 并发处理所有图片（限制并发数为 5）
    const batchSize = 5;
    for (let i = 0; i < imageFiles.length; i += batchSize) {
        const batch = imageFiles.slice(i, i + batchSize);
        await Promise.all(batch.map(optimizeImage));
    }

    console.log('=' .repeat(50));
    console.log('\n📊 优化完成！');
    console.log(`处理图片数: ${processedCount}`);
    console.log(`原始总大小: ${(totalOriginalSize / 1024 / 1024).toFixed(2)} MB`);
    console.log(`优化后大小: ${(totalOptimizedSize / 1024 / 1024).toFixed(2)} MB`);
    console.log(`总体积减小: ${((1 - totalOptimizedSize / totalOriginalSize) * 100).toFixed(1)}%`);
    console.log(`\n优化后的图片保存在: images-optimized/ 目录`);
}

main().catch(console.error);