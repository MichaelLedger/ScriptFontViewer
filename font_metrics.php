<?php

class FontMetricsAnalyzer {
    private $fontPath;
    private $fontSize;
    private $draw;
    private $imagick;

    public function __construct($fontPath, $fontSize = 24) {
        if (!extension_loaded('imagick')) {
            throw new Exception("Imagick extension is required. Please install php-imagick first.");
        }

        $this->fontPath = $fontPath;
        $this->fontSize = $fontSize;
        
        // Verify font exists
        if (!file_exists($fontPath)) {
            throw new Exception("Font file not found: $fontPath");
        }
        
        // Initialize Imagick objects
        $this->imagick = new Imagick();
        $this->draw = new ImagickDraw();
        $this->draw->setFont($fontPath);
        $this->draw->setFontSize($fontSize);
    }

    /**
     * Get precise glyph bounds for a string of text
     */
    public function getGlyphBounds($text,$print) {
        // Get font metrics using Imagick
        $metrics = $this->imagick->queryFontMetrics($this->draw, $text);

        if ($print == true) {
            // Print all font metrics values
            echo "\nFont Metrics Details:\n";
            echo "--------------------\n";
            foreach ($metrics as $key => $value) {
                if ($key === 'boundingBox') {
                    echo sprintf("%-20s: x1=%.2f, y1=%.2f, x2=%.2f, y2=%.2f\n",
                        $key,
                        $value['x1'],
                        $value['y1'],
                        $value['x2'],
                        $value['y2']
                    );
                } else {
                    echo sprintf("%-20s: %.2f\n", $key, $value);
                }
            }
            echo "--------------------\n";
        }
        
        // Extract the metrics we need
        $width = $metrics['textWidth'];
        $height = $metrics['textHeight'];
        $ascender = $metrics['ascender'];
        $descender = abs($metrics['descender']);
        $boundingBox = $metrics['boundingBox'];
        
        return [
            'width' => (float)$width,
            'height' => (float)$height,
            'ascender' => (float)$ascender,
            'descender' => (float)$descender,
            'boundingBox' => $boundingBox
        ];
    }

    /**
     * Find characters with extreme metrics (highest ascender and lowest descender)
     */
    public function findExtremeGlyphs($characterSet = null) {
        if ($characterSet === null) {
            $characterSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:'\",.<>?/~`";
        }

        $highestAscender = ['char' => '', 'height' => 0];
        $lowestDescender = ['char' => '', 'depth' => 0];

        echo "--------------------\n";

        foreach (str_split($characterSet) as $char) {
            $metrics = $this->getGlyphBounds($char, false);
            
            $ascenderHeight = abs($metrics['boundingBox']['y2']);
            $descenderDepth = abs($metrics['boundingBox']['y1']);
            
            if ($ascenderHeight > $highestAscender['height']) {
                $highestAscender = [
                    'char' => $char,
                    'height' => $ascenderHeight
                ];
            }
            
            if ($descenderDepth > $lowestDescender['depth']) {
                $lowestDescender = [
                    'char' => $char,
                    'depth' => $descenderDepth
                ];
            }

            printf(
                "Char: '%s' - Above baseline: %.2f, Below baseline: %.2f\n",
                $char,
                $metrics['boundingBox']['y2'],
                -$metrics['boundingBox']['y1']
            );
        }

        echo "--------------------\n";

        return [
            'topMost' => $highestAscender,
            'bottomMost' => $lowestDescender
        ];
    }

    /**
     * Get comprehensive font metrics for a text string
     */
    public function getFontMetrics($text) {
        $metrics = $this->getGlyphBounds($text, false);
        
        return [
            'text' => $text,
            'fontSize' => $this->fontSize,
            'fontName' => basename($this->fontPath),
            'metrics' => [
                'ascender' => $metrics['ascender'],
                'descender' => $metrics['descender'],
                'textWidth' => $metrics['width'],
                'textHeight' => $metrics['height'],
                'boundingBox' => $metrics['boundingBox']
            ]
        ];
    }

    /**
     * Visualize text with its metrics as an image
     */
    public function visualizeTextMetrics($text, $outputPath = null) {
        $metrics = $this->getGlyphBounds($text, true);
        
        // Calculate total height from bounding box
        $boundingBoxHeight = abs($metrics['boundingBox']['y2'] - $metrics['boundingBox']['y1']);
        
        // Create visualization using Imagick
        $padding = 0;
        $width = (int)ceil($metrics['width'] + ($padding * 2));
        $height = (int)ceil($boundingBoxHeight + ($padding * 2));
        
        // $dpi = 100;
        // $width *= 3;
        // $height *= 3;

        // Create base image with transparent background
        $image = new Imagick();
        $image->newImage($width, $height, 'transparent');
        $image->setImageFormat('png'); // Ensure PNG format to support transparency
        
        // Enable anti-aliasing and set high quality rendering
        // $image->setResolution($dpi, $dpi); // Set high DPI
        $image->setImageCompressionQuality(100);
        $image->setImageBackgroundColor('transparent');
        $image->setImageAlphaChannel(Imagick::ALPHACHANNEL_ACTIVATE);//clear background color

        echo "DrawImage: width({$width}), height:({$height}))";
        
        // Create drawing object for lines
        $draw = $this->draw;//new ImagickDraw();

        // Calculate vertical positions
        $baselineY = $padding + $metrics['boundingBox']['y2'];
        
        // Draw text with improved quality
        $draw->setFont($this->fontPath);
        $draw->setFontSize($this->fontSize);
        $draw->setFillColor('black');
        $draw->setTextAntialias(true);
        $draw->setTextKerning(0); // Ensure proper character spacing
        $draw->setTextInterwordSpacing(0); // Ensure proper word spacing
        $draw->setStrokeAntialias(true);
        $draw->annotation($padding, $baselineY, $text);
        
        // Draw baseline (black)
        $draw->setFillColor('none');
        $draw->setStrokeColor('black');
        $draw->setStrokeWidth(0.5);
        $draw->setStrokeAntialias(true);
        $draw->line(
            $padding,
            $baselineY,
            $width - $padding,
            $baselineY
        );
        
        // Draw ascender line (red)
        $draw->setStrokeColor('red');
        $draw->line(
            $padding,
            $baselineY - abs($metrics['ascender']),
            $width - $padding,
            $baselineY - abs($metrics['ascender'])
        );
        
        // Draw descender line (red)
        $draw->line(
            $padding,
            $baselineY + abs($metrics['descender']),
            $width - $padding,
            $baselineY + abs($metrics['descender'])
        );
        
        $draw->setStrokeWidth(1.0);
        // Draw bounding box lines (green)
        $draw->setStrokeColor('green');
        // Max Y point (below baseline)
        $draw->line(
            $padding,
            $baselineY - $metrics['boundingBox']['y1']-1.0,
            $width - $padding,
            $baselineY - $metrics['boundingBox']['y1']-1.0
        );
        // Min Y point (above baseline)
        $draw->line(
            $padding,
            $baselineY - $metrics['boundingBox']['y2'],
            $width - $padding,
            $baselineY - $metrics['boundingBox']['y2']
        );
        
        // Apply drawing to image
        $image->drawImage($draw);
        
        // Save image
        $outputPath = $outputPath ?: 'text_metrics.png';
        $image->writeImage($outputPath);
        
        return $outputPath;
    }
}

// Command line interface
if (php_sapi_name() === 'cli') {
    $options = getopt('f:s:t:c:h', [
        'font:',
        'size:',
        'text:',
        'chars:',
        'help'
    ]);

    if (isset($options['h']) || isset($options['help'])) {
        echo <<<HELP
Usage: php font_metrics.php [options]

Options:
  -f, --font FONT_PATH   Path to the font file (required)
  -s, --size SIZE        Font size in points (default: 24)
  -t, --text TEXT        Text to analyze
  -c, --chars CHARS      Custom character set for extreme glyph analysis
  -h, --help            Show this help message

Examples:
  php font_metrics.php -f fonts/adelia.ttf -s 36 -t "Hello World"
  php font_metrics.php -f fonts/adelia.ttf -c "ABCDEF123"

HELP;
        exit(0);
    }

    $fontPath = $options['f'] ?? $options['font'] ?? null;
    if (!$fontPath) {
        die("Error: Font path is required (-f or --font)\n");
    }

    $fontSize = (float)($options['s'] ?? $options['size'] ?? 24);
    
    try {
        $analyzer = new FontMetricsAnalyzer($fontPath, $fontSize);

        if (isset($options['t']) || isset($options['text'])) {
            $text = $options['t'] ?? $options['text'];
        }
        if ($text === null) {//fallback
            $text = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:'\",.<>?/~`";
        }
        
        // Analyze text
        $metrics = $analyzer->getFontMetrics($text);
        echo "\nMetrics for text: \"$text\"\n";
        echo "Font: {$metrics['fontName']} at {$metrics['fontSize']}pt\n";
        echo "Width: {$metrics['metrics']['textWidth']} points\n";
        echo "Height: {$metrics['metrics']['textHeight']} points\n";
        echo "Ascender: {$metrics['metrics']['ascender']} points\n";
        echo "Descender: {$metrics['metrics']['descender']} points\n";
        
        // Generate visualization
        $outputPath = "imagick_text_metrics.png";
        $analyzer->visualizeTextMetrics($text, $outputPath);
        echo "\nVisualization saved to: $outputPath\n";
        
        // Find extreme glyphs if character set provided
        $chars = $text;
        $extremes = $analyzer->findExtremeGlyphs($chars);
        
        echo "\nExtreme glyphs:\n";
        echo "Top-most glyph: '{$extremes['topMost']['char']}' extends {$extremes['topMost']['height']} points above baseline\n";
        echo "Bottom-most glyph: '{$extremes['bottomMost']['char']}' extends {$extremes['bottomMost']['depth']} points below baseline\n";
        
    } catch (Exception $e) {
        die("Error: " . $e->getMessage() . "\n");
    }
}
?>