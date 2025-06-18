# ScriptFont Viewer

A Swift-based tool for visualizing font metrics and bounds. This tool creates detailed PDF visualizations of font characteristics including precise glyph bounds, standard bounds, and various font metrics.

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
Visualizes font metrics and bounds by generating detailed PDF files. The visualization includes information about characters that extend furthest above and below the baseline.

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
  -p, --pdf          Generate a PDF visualization
  -o, --output PATH   Specify the output PDF path (default: ./fontname_sizept_trackingNpt.pdf)
  -h, --help         Show this help message

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

# Custom output path
./ScriptFontViewer.swift -f "Zapfino" -t "Hello" -p -o "my_font.pdf"

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

The tool generates a PDF file containing:
1. The rendered text using the specified font and settings
2. Visual indicators for all font metrics
3. Bounding boxes showing both standard and precise glyph bounds
4. Detailed measurements and metrics information
5. Information about characters that extend furthest above and below the baseline

The PDF filename is automatically generated based on the font name, size, and tracking values unless an output path is specified with `-o`.

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

### PDF Generation
- Light gray background (0.95)
- Metric lines in gray (0.7)
- Bounds rectangles with semi-transparent fill
- 8pt Helvetica for labels
- Origin point marked in red

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
