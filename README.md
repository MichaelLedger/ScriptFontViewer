# ScriptFont Viewer

A Swift-based tool for visualizing font metrics and bounds. This tool creates detailed PDF and PNG visualizations of font characteristics including precise glyph bounds, standard bounds, and various font metrics.

![preview](/preview.png)

## Note of the author
$${\color{red}All \space script \space fonts \space are \space ONLY \space for \space PERSONAL \space USE. \space NO \space COMMERCIAL \space USE \space ALLOWED!}$$
$${\color{red}You \space are \space requires \space a \space license \space for \space PROMOTIONAL \space or \space COMMERCIAL \space use.}$$

## Free Script Fonts Download Center
[DaFont - Download fonts](https://www.dafont.com)
[DaFont | Adelia Font Preview](https://www.dafont.com/adelia-3.font)
[DaFont | Adelia Font Download](https://dl.dafont.com/dl/?f=adelia_3)

## [View and print fonts on your Mac in Font Book](https://support.apple.com/en-uz/guide/font-book/fntbk1001/mac)

<p>You can select a font, then click the Info button <img src="https://help.apple.com/assets/65D69D493593D0EF840ADCFB/65D69D4A5BC27E542105EC4C/en_US/974db3c051f6ac0adaddf1e2fec1001e.png" alt="" height="30" width="30" originalimagename="SharedGlobalArt/IL_InfoCircle.png"> in the toolbar to see details about the font, such as language support, the manufacturer, and the location of the font file on your Mac.</p>

## Tools

### ScriptFontViewer.swift
Visualizes font metrics and bounds by generating detailed PDF or PNG files. The visualization includes information about characters that extend furthest above and below the baseline.

### findExtremeGlyphs.swift
Standalone tool to analyze fonts and find characters that extend furthest above and below the baseline.

## Features

### Font Support
- System fonts
- Remote font loading via URL
- Automatic font name detection from font files
- Font registration for the current process

### Visualization Components
- Text rendering at the top of the page
- Adjustable character spacing (tracking)
- Metric lines with labels:
  - Baseline
  - Ascent
  - Descent
  - Leading
  - Cap Height
  - x-Height
- Bounds visualization:
  - Blue rectangle: Precise glyph bounds (including overhangs)
  - Green rectangle: Standard bounds

### Layout
- Compact and clear visualization with:
  - Text positioned at the top
  - Labels aligned on the left side (8pt Helvetica)
  - Fixed label width (50pt) for consistent alignment
  - Minimal line extensions (no overhang)
  - Information text at the bottom
- Origin point marked in red at the baseline

### Measurements Display
- Detailed metrics information including:
  - Precise glyph bounds (origin and size)
  - Standard bounds (origin and size)
  - Font metrics (ascent, descent, leading, cap height, x-height)
  - Line height calculation
  - Extreme glyph information (characters extending furthest above and below baseline)

## Usage

### ScriptFontViewer
```bash
./ScriptFontViewer.swift [options]

Options:
  -f, --font NAME     Specify the font name (optional if --font-url is provided)
  -u, --font-url URL  Specify a URL to download and register the font
  -s, --size SIZE     Specify the font size in points (default: 24.0)
  -k, --tracking VAL  Specify the tracking value in points (default: 0.0)
  -t, --text TEXT     Specify the text to measure (default: "Hello World")
  -l, --list-fonts    List all available fonts on the system
  -p, --pdf           Generate a PDF visualization
  --png              Generate a PNG visualization
  --scale SCALE      Scale factor for PNG output (default: 2.0, higher is better quality)
  -o, --output PATH   Specify the output path (default: ./fontname_sizept_trackingNpt.{pdf|png})
  -h, --help          Show this help message

Note: When --font-url is provided, the font name will be extracted from the font file,
      and any provided font name will be ignored.
```

### findExtremeGlyphs
```bash
./findExtremeGlyphs.swift [options]

Options:
  -f, --font NAME     Specify the font name (default: Helvetica)
  -u, --font-url URL  Specify a URL to download and register the font
  -s, --size SIZE     Specify the font size in points (default: 24.0)
  -c, --chars CHARS   Specify custom characters to analyze
  -l, --list-fonts    List all available fonts on the system
  -h, --help         Show this help message

Examples:
  ./findExtremeGlyphs.swift -f "Zapfino"
  ./findExtremeGlyphs.swift -f "Helvetica" -s 36 -c "ABCDEF123"
  ./findExtremeGlyphs.swift -u "https://example.com/font.ttf" -s 48
```

## Examples

### Frequently used samples
```bash
./ScriptFontViewer.swift -f "PosterBodoni It BT" -s 24 -t "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789你" -p

swift ScriptFontViewer.swift -f "Times New Roman" -s 10.0 -t 'We love you!' -k 1.6 -p 

./ScriptFontViewer.swift -u "https://github.com/MichaelLedger/ScriptFontViewer/raw/refs/heads/main/fonts/adelia.otf" -s 32 -t "Beautiful Writing" -k 4.0 -p

./ScriptFontViewer.swift -u "https://cdn.freeprintsapp.com/fonts/SebastianBobbyAltSlanted.ttf" -s 32 -t "Beautiful Writing" -p

./ScriptFontViewer.swift -u "https://cdn.freeprintsapp.com/fonts/SebastianBobbyAltSlanted.ttf" -s 48 -t "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789你" -p

swift ScriptFontViewer.swift -f "MadinaScript" -s 24.0 -t "Hello World" -p
```

### Using System Fonts
```bash
# List available fonts
./ScriptFontViewer.swift --list-fonts

# Basic usage with system font
./ScriptFontViewer.swift -f "Zapfino" -t "Hello World" -p

# Custom size and tracking
./ScriptFontViewer.swift -f "Zapfino" -s 36 -k 2.0 -t "Spaced Out" -p

# Custom output path (PDF)
./ScriptFontViewer.swift -f "Zapfino" -t "Hello" -p -o "my_font.pdf"

# Generate PNG output
./ScriptFontViewer.swift -f "Zapfino" -t "Hello" --png

# High-quality PNG with custom scale factor
./ScriptFontViewer.swift -f "Zapfino" -t "Hello" --png --scale 4.0

# Complete character set with custom tracking
# Generates: MadinaScript_32pt_tracking2pt.pdf
./ScriptFontViewer.swift -f "MadinaScript" -s 32 -t "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789你" -k 2.0 -p
```

### Using Remote Fonts
```bash
swift ScriptFontViewer.swift -u "https://cdn.freeprintsapp.com/fonts/SebastianBobbyAltSlanted.ttf" -s 32 -k 1.5 -t "Beautiful Writing" -p

# Download and use a remote font (font name will be extracted automatically)
./ScriptFontViewer.swift -u "https://cdn.freeprintsapp.com/fonts/Sacramento-Regular.ttf" -t "Hello Script" -p

# Remote font with custom size and tracking
./ScriptFontViewer.swift \
  -u "https://cdn.freeprintsapp.com/fonts/Sacramento-Regular.ttf" \
  -s 48 \
  -k 1.5 \
  -t "Beautiful Writing" \
  -p

# Remote font with custom output path
./ScriptFontViewer.swift \
  -u "https://cdn.freeprintsapp.com/fonts/Sacramento-Regular.ttf" \
  -t "Custom Path" \
  -p \
  -o "sacramento_demo.pdf"
```

## Output

The tool generates a PDF or PNG file containing:
1. The rendered text using the specified font and settings
2. Visual indicators for all font metrics
3. Bounding boxes showing both standard and precise glyph bounds
4. Detailed measurements and metrics information
5. Information about characters that extend furthest above and below the baseline

The output filename is automatically generated based on the font name, size, and tracking values unless an output path is specified with `-o`. The file extension (.pdf or .png) is determined by the chosen output format.

## Notes

- Font URLs must point to valid font files (TTF, OTF, etc.)
- Downloaded fonts are registered only for the current process
- Font metrics are rendered in points (1/72 inch)
- The tool handles font variants (e.g., "-Regular" suffix) automatically
- When using remote fonts, the font name is extracted from the font file itself

## Technical Details

### Tracking (Character Spacing)
Tracking adjusts the uniform spacing between all characters in text:
- Positive tracking (> 0) increases space between characters
  - Useful for: 
    - Creating airy, expanded layouts
    - Improving readability at small sizes
    - Achieving specific stylistic effects
- Negative tracking (< 0) decreases space between characters
  - Useful for:
    - Tightening text to save space
    - Creating more compact layouts
    - Adjusting specific font pairs that appear too loose
    - Fixing gaps in script fonts that appear disconnected
- Zero tracking (0) uses the font's default spacing

Note: Be careful with negative tracking as it can affect readability if too tight. Script fonts often benefit from slight negative tracking to maintain their connected appearance.

### Layout Calculations
- Page layout uses fixed padding (10pt)
- Label area: 50pt width
- Line origin starts after labels with 10pt offset
- Baseline position calculated from top of page minus ascent
- Information text positioned at the bottom with proper padding

### Font Metrics
The tool measures and displays:
- Standard bounds using CTFramesetterCreateFrame
- Precise glyph bounds using CTLineGetBoundsWithOptions
- Font metrics using CT* functions (CTFontGetAscent, etc.)

### Output Generation
- Light gray background (0.95)
- Metric lines in gray (0.7)
- Bounds rectangles with semi-transparent fill
- 8pt Helvetica for labels
- Origin point marked in red

#### PDF-specific
- Vector graphics for infinite resolution
- Compact file size
- Perfect for print and high-quality reproduction

#### PNG-specific
- Raster graphics with configurable scale factor
- Scale factor determines output quality:
  - 1.0: Standard resolution (1x)
  - 2.0: Retina display quality (2x, default)
  - 4.0: Ultra-high quality for zooming or large displays
- Larger scale factors produce sharper text and lines but increase file size
- Ideal for web use, presentations, and documentation

## Requirements

- macOS (uses CoreText and CoreGraphics)
- Swift 5.0 or later

## Installation

1. Clone the repository
2. Ensure the Swift files have execute permissions:
   ```bash
   chmod +x ScriptFontViewer.swift
   ```

## Use Cases

- Font development and testing
- Understanding script font rendering behavior
- Debugging text layout issues
- Analyzing font metrics and bounds
- Comparing different script fonts

## Notes

- The tools are particularly useful for script fonts where standard bounds might not accurately represent the visual appearance
- Precise glyph bounds can reveal overhanging parts that might be clipped in standard layout
- The visualization helps understand how the font metrics relate to the actual rendered glyphs 

## JavaScript Implementation by ImageMagick

An alternative implementation using Node.js and ImageMagick is also available, providing similar functionality in a cross-platform manner.

### Prerequisites
- Node.js 14+ installed
- ImageMagick installed on your system
  - Mac: `brew install imagemagick`
  - Linux: `sudo apt-get install imagemagick`
  - Windows: Download from [ImageMagick website](https://imagemagick.org/script/download.php)

### Installation
```bash
npm install
```

### Usage
```bash
node index.js --font <font-path> [options]

Options:
  -f, --font         Path to the font file (OTF/TTF)
  -s, --size         Font size in points (default: 24)
  -t, --text         Text to render (default: "Hello World")
  -k, --tracking     Tracking value in points (default: 0)
  -o, --output       Output PDF path (default: fontname_size_tracking.pdf)
```

### Examples
```bash
# Basic usage
node index.js --font ./fonts/MyScript.ttf

# Custom text and size
node index.js --font ./fonts/MyScript.ttf --size 48 --text "Sample Text"

# With tracking and custom output
node index.js --font ./fonts/MyScript.ttf --size 32 --text "Spaced Out" --tracking 2 --output preview.pdf
```

### Examples usually used
```
node index.js --font ./fonts/SofiaProSoft-Regular.ttf --size 32 --text "Spaced Out" --tracking 2 --output preview-magic.pdf

./ScriptFontViewer.swift -f "Sofia Pro Soft" -s 32 -t "Spaced Out" -k 2 -p -o preview-swift.pdf
```

### Implementation Notes
- Uses node-canvas for font measurements
- ImageMagick for PDF generation
- Local font files only (no remote font loading)
- Cross-platform compatible
- Provides similar metrics visualization to the Swift version
 
## PHP Implementation by ImageMagick

A PHP version of the font metrics analyzer is also available, providing similar functionality using the ImageMagick extension.

### Prerequisites

On mac M2 I installed it via brew on top of my php install.
As described here: [Install PHP's Imagick Extension on macOS](https://matthewsetter.com/install-php-imagick-extension-macos/)

- PHP 7.4+ installed
- ImageMagick PHP extension installed
  - Mac: 
    ```bash
    brew install php
    brew install imagemagick
    brew install pkg-config
    sudo pecl install imagick
    ```
  - Linux:
    ```bash
    sudo apt-get install php-imagick
    ```
  - Windows: Follow the [ImageMagick PHP installation guide](https://mlocati.github.io/articles/php-windows-imagick.html)

### Features
- Font metrics analysis (ascender, descender, width, height)
- Extreme glyph detection (highest/lowest characters)
- Visual metrics representation
- PNG output with metric lines
- Command-line interface

### Usage
```bash
php font_metrics.php [options]

Options:
  -f, --font FONT_PATH   Path to the font file (required)
  -s, --size SIZE        Font size in points (default: 24)
  -t, --text TEXT        Text to analyze
  -c, --chars CHARS      Custom character set for extreme glyph analysis
  -h, --help            Show this help message
```

### Examples
```bash
# Basic font metrics analysis
php font_metrics.php -f fonts/adelia.ttf -s 36 -t "Hello World"

# Find extreme glyphs in a custom character set
php font_metrics.php -f fonts/adelia.ttf -c "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Analyze specific text with custom size
php font_metrics.php -f fonts/SofiaProSoft-Regular.ttf -s 48 -t "Beautiful Writing"
```

### Usually Samples
```
➜  ScriptFontViewer git:(main) ✗ php font_metrics.php -f fonts/adelia.ttf -s 36 -t 'Hello, good luck!'                  

Metrics for text: "Hello, good luck!"
Font: adelia.ttf at 36pt
Width: 353 points
Height: 36 points
Ascender: 27 points
Descender: 9 points

Font Metrics Details:
--------------------
characterWidth      : 36.00
characterHeight     : 36.00
ascender            : 27.00
descender           : -9.00
textWidth           : 353.00
textHeight          : 36.00
maxHorizontalAdvance: 154.00
boundingBox         : x1=-5.69, y1=-27.73, x2=46.44, y2=44.31
originX             : 353.00
originY             : 0.00
--------------------
DrawImage: width(353), height:(73))
Visualization saved to: imagick_text_metrics.png
--------------------
Char: 'H' - Above baseline: 44.31, Below baseline: 21.19
Char: 'e' - Above baseline: 16.30, Below baseline: 0.14
Char: 'l' - Above baseline: 38.42, Below baseline: 11.23
Char: 'l' - Above baseline: 38.42, Below baseline: 11.23
Char: 'o' - Above baseline: 14.48, Below baseline: 0.14
Char: ',' - Above baseline: 6.05, Below baseline: 0.83
Char: ' ' - Above baseline: 0.28, Below baseline: 0.14
Char: 'g' - Above baseline: 16.50, Below baseline: 27.73
Char: 'o' - Above baseline: 14.48, Below baseline: 0.14
Char: 'o' - Above baseline: 14.48, Below baseline: 0.14
Char: 'd' - Above baseline: 39.88, Below baseline: 18.28
Char: ' ' - Above baseline: 0.28, Below baseline: 0.14
Char: 'l' - Above baseline: 38.42, Below baseline: 11.23
Char: 'u' - Above baseline: 15.50, Below baseline: 0.14
Char: 'c' - Above baseline: 17.00, Below baseline: 0.14
Char: 'k' - Above baseline: 38.06, Below baseline: 18.97
Char: '!' - Above baseline: 40.27, Below baseline: 1.28
--------------------

Extreme glyphs:
Top-most glyph: 'H' extends 44.3125 points above baseline
Bottom-most glyph: 'g' extends 27.734375 points below baseline
```

### Compare with Swift Rendering
```
➜  ScriptFontViewer git:(main) ✗  ./ScriptFontViewer.swift --font "adelia" --size 36 --text 'Hello, good luck!' --png --scale 4.0

Text: "Hello, good luck!"
Font: adelia at 36.0pt
Tracking: 0.0 points

Standard bounds (using CTFramesetterCreateFrame):
Width: 344.84399999999994 points, Height: 36.000072956085205 points

Precise glyph bounds (accounting for overhangs):
Origin X: -2.052, Origin Y: -28.583999999999996
Width: 343.33200000000005 points, Height: 74.412 points

Font metrics:
Ascent: 27.0000547170639 points
Descent: 9.000018239021301 points
Leading: 0.0 points
Cap Height: 45.467999999999996 points
x-Height: 16.235999999999997 points
Line Height: 36.000072956085205 points
PNG created successfully at: /Users/xxx/Downloads/ScriptFontViewer/adelia_36.0pt_tracking0.0pt.png

PNG visualization created at: /Users/xxx/Downloads/ScriptFontViewer/adelia_36.0pt_tracking0.0pt.png
```

### Implementation Notes
- Uses ImageMagick's font metrics capabilities
- Provides visual representation with metric lines
- Supports TTF/OTF fonts
- Outputs PNG format for visualizations
- Cross-platform compatible

### [boundingBox](https://www.php.net/manual/en/imagick.queryfontmetrics.php)
- This returns an associative array describing the four points (x1, y1, x2, y2) of a rectangle that contain the character. These values are relative to the origin (i.e. the coordinates of where you are drawing the character within an image). **The returned rectangle is very accurate and encloses all parts of the printed character completely - but the boundingBox only works on single characters.** It will not give accurate figures for multiple characters (in my experience anyway). When drawing a box you need to ADD "x" values to the origin and SUBTRACT "y" values from the origin. You cannot rely on the boundingBox for the SPACE character. It returns a boundingBox of (0,0,0,0).  textWidth (see above) comes in handy here.

### PHP Warning:  Module "imagick" is already loaded in Unknown on line 0
```
grep -i "imagick" /opt/homebrew/etc/php/8.4/php.ini
extension="imagick.so"
extension=imagick.so
```
I found the issue! The Imagick extension is being loaded twice in the php.ini file.

Let's fix this by removing one of the duplicate entries:

`sudo sed -i '' '/^extension="imagick.so"$/d' /opt/homebrew/etc/php/8.4/php.ini`

### Reference
[imagemagick - text](https://imagemagick.org/Usage/text/)
[imagemagick - command-line-options](https://imagemagick.org/script/command-line-options.php?#font)
[imagemagick - draw](https://usage.imagemagick.org/draw/)
