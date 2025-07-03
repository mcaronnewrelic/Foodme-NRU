#!/usr/bin/env node

/**
 * Bundle Analysis Script for FoodMe Angular App
 * This script helps analyze and optimize bundle sizes
 */

const fs = require('fs');
const path = require('path');

function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function analyzeDistFolder() {
  const distPath = path.join(__dirname, 'dist', 'browser');
  
  if (!fs.existsSync(distPath)) {
    console.log('❌ No dist/browser folder found. Run "npm run build" first.');
    return;
  }

  console.log('📊 FoodMe Bundle Analysis');
  console.log('========================\n');

  const files = fs.readdirSync(distPath);
  let totalSize = 0;
  let initialBundleSize = 0;
  let jsSize = 0;
  let cssSize = 0;
  let assetSize = 0;

  // Define what constitutes the initial bundle (loaded immediately)
  const initialBundlePatterns = [
    /^main-.*\.js$/,
    /^chunk-[A-Z0-9]+\.js$/, // Main chunks
    /^styles-.*\.css$/
  ];

  const isImageAsset = (filename) => /\.(png|jpg|jpeg|gif|svg|ico)$/i.test(filename);
  const isInitialBundle = (filename) => initialBundlePatterns.some(pattern => pattern.test(filename));

  const fileAnalysis = files
    .filter(file => {
      const filePath = path.join(distPath, file);
      return fs.statSync(filePath).isFile();
    })
    .map(file => {
      const filePath = path.join(distPath, file);
      const stats = fs.statSync(filePath);
      const size = stats.size;
      totalSize += size;

      const category = isImageAsset(file) ? 'asset' : 
                      file.endsWith('.js') ? 'js' : 
                      file.endsWith('.css') ? 'css' : 'other';

      if (category === 'js') jsSize += size;
      if (category === 'css') cssSize += size;
      if (category === 'asset') assetSize += size;

      if (isInitialBundle(file)) {
        initialBundleSize += size;
      }

      return {
        name: file,
        size: size,
        formatted: formatBytes(size),
        category: category,
        isInitial: isInitialBundle(file)
      };
    }).sort((a, b) => b.size - a.size);

  console.log('📁 Initial Bundle Files (loaded immediately):');
  fileAnalysis
    .filter(file => file.isInitial)
    .forEach(file => {
      const icon = file.category === 'js' ? '📄' : file.category === 'css' ? '🎨' : '📎';
      console.log(`  ${icon} ${file.name.padEnd(30)} ${file.formatted.padStart(10)}`);
    });

  console.log('\n📁 Lazy-loaded chunks:');
  fileAnalysis
    .filter(file => file.category === 'js' && !file.isInitial)
    .forEach(file => {
      console.log(`  📄 ${file.name.padEnd(30)} ${file.formatted.padStart(10)}`);
    });

  console.log('\n📁 Assets (loaded on-demand):');
  fileAnalysis
    .filter(file => file.category === 'asset')
    .slice(0, 5) // Show top 5 largest assets
    .forEach(file => {
      console.log(`  🖼️  ${file.name.padEnd(30)} ${file.formatted.padStart(10)}`);
    });

  if (fileAnalysis.filter(file => file.category === 'asset').length > 5) {
    const remainingAssets = fileAnalysis.filter(file => file.category === 'asset').length - 5;
    console.log(`  ... and ${remainingAssets} more asset files`);
  }

  console.log('\n📈 Bundle Size Summary:');
  console.log(`  Initial Bundle:    ${formatBytes(initialBundleSize)} (what users download first)`);
  console.log(`  JavaScript Total:  ${formatBytes(jsSize)}`);
  console.log(`  CSS Total:         ${formatBytes(cssSize)}`);
  console.log(`  Assets Total:      ${formatBytes(assetSize)}`);
  console.log(`  Grand Total:       ${formatBytes(totalSize)}`);
  
  // Budget analysis based on initial bundle
  const initialBudget = 600 * 1024; // 600 KB
  const budgetUsage = (initialBundleSize / initialBudget) * 100;
  
  console.log(`\n🎯 Budget Analysis (Initial Bundle Only):`);
  console.log(`  Budget Limit:      ${formatBytes(initialBudget)}`);
  console.log(`  Initial Usage:     ${budgetUsage.toFixed(1)}%`);
  
  if (budgetUsage > 100) {
    console.log(`  ⚠️  Over budget by ${formatBytes(initialBundleSize - initialBudget)}`);
  } else {
    console.log(`  ✅ Under budget by ${formatBytes(initialBudget - initialBundleSize)}`);
  }

  console.log('\n💡 Optimization Tips:');
  if (cssSize > 200 * 1024) {
    console.log('  • Consider using PurgeCSS to remove unused Bootstrap classes');
  }
  if (assetSize > 500 * 1024) {
    console.log('  • Optimize images (use WebP format, compress images)');
    console.log('  • Consider lazy loading images');
  }
  if (initialBundleSize < initialBudget * 0.8) {
    console.log('  • Great job! Your initial bundle is well optimized');
  }
  console.log('  • Use compression (gzip/brotli) on your server for ~70% size reduction');
  console.log('  • Consider implementing service worker caching');
}

if (require.main === module) {
  analyzeDistFolder();
}

module.exports = { analyzeDistFolder, formatBytes };
