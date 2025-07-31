const imagemagick = require('imagemagick');
const { createCanvas, registerFont } = require('canvas');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const path = require('path');
const fs = require('fs');

// Parse command line arguments
const argv = yargs(hideBin(process.argv))
  .option('font', {
    alias: 'f',
    description: 'Font file path',
    type: 'string',
    demandOption: true
  })
  .option('size', {
    alias: 's',
    description: 'Font size in points',
    type: 'number',
    default: 24
  })
  .option('text', {
    alias: 't',
    description: 'Text to render',
    type: 'string',
    default: 'Hello World'
  })
  .option('tracking', {
    alias: 'k',
    description: 'Tracking value in points',
    type: 'number',
    default: 0
  })
  .option('output', {
    alias: 'o',
    description: 'Output PDF path',
    type: 'string'
  })
  .help()
  .argv;

// Function to create PDF visualization
function createPDFVisualization(fontPath, fontSize, text, tracking, outputPath) {
  // Find extreme glyphs
  const extremeGlyphs = findExtremeGlyphs(fontPath, fontSize, text);
  
  // Create temporary canvas for measurements with size proportional to font size
  const canvasWidth = Math.max(2000, fontSize * 20); // Ensure enough width for measurements
  const canvasHeight = Math.max(2000, fontSize); // Ensure enough height for ascenders/descenders
  const canvas = createCanvas(canvasWidth, canvasHeight);
  const ctx = canvas.getContext('2d');
  const fontFamily = path.basename(fontPath, path.extname(fontPath));
  
  // Register and set font
  registerFont(fontPath, { family: fontFamily });
  console.log(`fontPath:${fontPath}\nfontFamily:${fontFamily}\nfontSize:${fontSize}px\ntracking:${tracking}`)
  ctx.font = `${fontSize}px "${fontFamily}"`;

  const dpi = 60;//清晰度
  const density = 300;
  const pixelsPerInch = 50;
  let metricsScale = dpi * 0.6; //0.6 is magic number for now.
  console.log(`metricsScale:${metricsScale}`);
  let pointSize = fontSize / pixelsPerInch;
  console.log(`pointSize: ${pointSize}`);
  let scaledPointSize = pointSize*pixelsPerInch/4;//pointSize*metricsScale;
  console.log(`scaledPointSize: ${scaledPointSize}`);
  
  // Get text metrics for each character to find true bounds
  let totalWidth = 0;
  let maxAscent = 0;
  let maxDescent = 0;

  // First pass: measure each character
  console.log('\nCharacter Metrics:');
  console.log('Char | Raw Ascent | Raw Descent | Scaled Ascent | Scaled Descent | Width');
  console.log('-'.repeat(80));
  
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    const metrics = ctx.measureText(char);
    const rawAscent = Math.abs(metrics.actualBoundingBoxAscent);
    const rawDescent = Math.abs(metrics.actualBoundingBoxDescent);
    
    // Scale metrics by font size
    const scaledAscent = rawAscent * metricsScale;
    const scaledDescent = rawDescent * metricsScale;
    
    console.log(`${char.padEnd(4)} | ${rawAscent.toFixed(2).padEnd(10)} | ${rawDescent.toFixed(2).padEnd(10)} | ${scaledAscent.toFixed(2).padEnd(12)} | ${scaledDescent.toFixed(2).padEnd(12)} | ${metrics.width.toFixed(2)}`);
    
    maxAscent = Math.max(maxAscent, scaledAscent);
    maxDescent = Math.max(maxDescent, scaledDescent);
    totalWidth += metrics.width * metricsScale;
  }
  
  console.log('-'.repeat(80));
  console.log(`Max Ascent: ${maxAscent.toFixed(2)}`);
  console.log(`Max Descent: ${maxDescent.toFixed(2)}`);
  console.log(`Total Width: ${totalWidth.toFixed(2)}`);
  
  // Add tracking to total width
  totalWidth += (text.length - 1) * tracking;

  totalWidth = Math.max(totalWidth, fontSize * 4)
  
  // Calculate dimensions for the PDF
  const leading = fontSize * 4;
  const topPadding = fontSize / 4.0;
  const padding = fontSize;
  const infoHeight = pointSize * dpi * pixelsPerInch / 2;
  const width = Math.ceil(totalWidth + padding * 2 + leading);
  
  // Calculate height based on actual text metrics plus info section
  const textHeight = maxAscent + maxDescent;
  const height = Math.ceil(textHeight + padding + infoHeight);
  
  // Position text near top of page with just enough space for ascenders
  const baselineY = maxAscent + topPadding;

  // Generate PDF using ImageMagick
  const commands = [
    // Set high resolution and quality
    '-density', `${dpi*pixelsPerInch}`,
    // '-quality', '100',
    
    // Create base canvas with white background
    '-size', `${width}x${height}`,
    'xc:white',
    
    // Draw baseline
    '-stroke', 'black',
    '-strokewidth', '1',
    '-draw', `line ${padding},${baselineY} ${width-padding},${baselineY}`,
    
    // Draw text
    '-font', fontPath,
    '-pointsize', `${scaledPointSize}`,
    '-fill', 'blue',
    '-stroke', 'none',
    '-kerning', tracking.toString(),
    '-annotate', `+${padding+leading}+${baselineY}`, text,
    
    // Draw metrics lines
    '-stroke', 'blue',
    '-strokewidth', '0.5',
    '-fill', 'none',
    // Ascent line
    '-draw', `line ${padding},${baselineY-maxAscent} ${width-padding},${baselineY-maxAscent}`,
    // Descent line
    '-draw', `line ${padding},${baselineY+maxDescent} ${width-padding},${baselineY+maxDescent}`,
    
    // Switch to system font for metrics information
    '-font', 'Helvetica',
    // Reset kerning to zero
    '-kerning', '0',
    
    // Add metrics text at the bottom
    '-pointsize', `${pointSize/4.0}`,
    '-fill', 'black',
    '-stroke', 'none',
    '-gravity', 'NorthWest',
    '-annotate', `+${padding}+${height-infoHeight+topPadding+padding*2}`,
    `Font: ${fontFamily} at ${fontSize}pt\n` +
    `Text: "${text}"\n` +
    `Tracking: ${tracking}pt\n\n` +
    `Extreme Characters:\n` +
    `• Top-most glyph: '${extremeGlyphs.topMost.character}'\nextends ${maxAscent/metricsScale.toFixed(2)} points above baseline\n` +
    `• Bottom-most glyph: '${extremeGlyphs.bottomMost.character}'\nextends ${maxDescent/metricsScale.toFixed(2)} points below baseline\n\n` +
    `Metrics:\n` +
    `• Ascent: ${maxAscent/metricsScale.toFixed(2)} points\n` +
    `• Descent: ${maxDescent/metricsScale.toFixed(2)} points\n` +
    `• Total height: ${((maxAscent + maxDescent)/metricsScale).toFixed(2)} points`,
    
    // Add labels for lines
    '-pointsize', `${pointSize/8.0}`,
    '-fill', 'blue',
    '-annotate', `+${padding}+${baselineY-maxAscent}`, 'ascent',
    '-annotate', `+${padding}+${baselineY}`, 'baseline',
    '-annotate', `+${padding}+${baselineY+maxDescent}`, 'descent',
    
    // Save as PDF with high resolution
    '-units', 'PixelsPerInch',
    '-density', `${pixelsPerInch}`,
    outputPath
  ];

  return new Promise((resolve, reject) => {
    imagemagick.convert(commands, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });
}

// Function to find extreme glyphs (highest ascender and lowest descender)
function findExtremeGlyphs(fontPath, fontSize, entryTxt) {
  // Create canvas with size proportional to font size
  const canvasWidth = Math.max(2000, fontSize * 20);
  const canvasHeight = Math.max(2000, fontSize * 10);
  const canvas = createCanvas(canvasWidth, canvasHeight);
  const ctx = canvas.getContext('2d');
  
  // Register and set font
  const fontFamily = path.basename(fontPath, path.extname(fontPath));
  registerFont(fontPath, { family: fontFamily });
  ctx.font = `${fontSize}px "${fontFamily}"`;
  
  let chars = entryTxt;
  if (entryTxt.length == 0) {
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  }
  let highestAscender = 0;
  let topChar = '';
  let lowestDescender = 0;
  let bottomChar = '';
  
  for (const char of chars) {
    const metrics = ctx.measureText(char);
    const ascent = Math.abs(metrics.actualBoundingBoxAscent);
    const descent = Math.abs(metrics.actualBoundingBoxDescent);
    
    if (ascent > highestAscender) {
      highestAscender = ascent;
      topChar = char;
    }
    
    if (descent > lowestDescender) {
      lowestDescender = descent;
      bottomChar = char;
    }
  }
  
  return {
    topMost: { character: topChar, height: highestAscender },
    bottomMost: { character: bottomChar, depth: lowestDescender }
  };
}

// Main execution
async function main() {
  try {
    // Generate default output path if not provided
    if (!argv.output) {
      const fontName = path.basename(argv.font, path.extname(argv.font));
      argv.output = `${fontName}_${argv.size}pt_tracking${argv.tracking}pt.pdf`;
    }

    // Create PDF visualization
    await createPDFVisualization(
      argv.font,
      argv.size,
      argv.text,
      argv.tracking,
      argv.output
    );

    console.log(`PDF visualization created at: ${argv.output}`);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main(); 