#!/usr/bin/swift

import Foundation
import CoreText
import CoreGraphics
import AppKit

// Helper function to get available fonts on the system
func getAvailableFonts() -> [String] {
    return CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
}

// Helper function to find extreme glyphs
func findExtremeGlyphs(fontName: String, fontSize: CGFloat, fontURL: URL?) -> (topMost: (character: Character, height: CGFloat), bottomMost: (character: Character, depth: CGFloat))? {
    let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:'\",.<>?/~`"
    let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
    
    var highestAscender: CGFloat = 0
    var topChar: Character = " "
    var lowestDescender: CGFloat = 0
    var bottomChar: Character = " "
    
    for char in chars {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font
        ]
        let attributedString = NSAttributedString(string: String(char), attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        
        let ascenderHeight = bounds.origin.y + bounds.height  // Distance above baseline
        let descenderDepth = -bounds.origin.y  // Distance below baseline (positive value)
        
        if ascenderHeight > highestAscender {
            highestAscender = ascenderHeight
            topChar = char
        }
        
        if descenderDepth > lowestDescender {
            lowestDescender = descenderDepth
            bottomChar = char
        }
    }
    
    return ((topChar, highestAscender), (bottomChar, lowestDescender))
}

// Class for handling font metrics and rendering
class FontMetricsHandler {
    private(set) var fontName: String
    let fontSize: CGFloat
    private(set) var text: String
    let tracking: CGFloat
    let fontURL: URL?
    private var extremeGlyphs: (topMost: (character: Character, height: CGFloat), bottomMost: (character: Character, depth: CGFloat))?
    
    init(fontName: String, fontSize: CGFloat, text: String, tracking: CGFloat = 0.0, fontURL: URL? = nil) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.text = text
        self.tracking = tracking
        self.fontURL = fontURL
    }
    
    // Extract font name from the font file
    private func extractFontName(from fontURL: URL) -> String? {
        do {
            let fontData = try Data(contentsOf: fontURL)
            guard let fontDescriptor = CTFontManagerCreateFontDescriptorFromData(fontData as CFData) else {
                print("Failed to create font descriptor from data")
                return nil
            }
            
            let font = CTFontCreateWithFontDescriptor(fontDescriptor, 0.0, nil)
            
            // Print all available font names for debugging
            print("\nFont name attributes found in file:")
            
            if let familyName = CTFontCopyFamilyName(font) as String? {
                print("Family name: \(familyName)")
            }
            
            if let fullName = CTFontCopyFullName(font) as String? {
                print("Full name: \(fullName)")
            }
            
            if let displayName = CTFontCopyDisplayName(font) as String? {
                print("Display name: \(displayName)")
            }
            
            if let postScriptName = CTFontCopyPostScriptName(font) as String? {
                print("PostScript name: \(postScriptName)")
            }
            
            // Get font traits
            let traits = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontTraitsAttribute) as? [String: Any]
            if let traits = traits {
                print("Font traits: \(traits)")
            }
            
            // Try to get the most appropriate name
            // First try family name as it's usually what we want for display
            if let familyName = CTFontCopyFamilyName(font) as String? {
                return familyName
            }
            
            // Then try display name
            if let displayName = CTFontCopyDisplayName(font) as String? {
                return displayName
            }
            
            // Finally fall back to PostScript name
            if let postScriptName = CTFontCopyPostScriptName(font) as String? {
                return postScriptName
            }
            
            return nil
        } catch {
            print("Error reading font file: \(error)")
            return nil
        }
    }
    
    // Check if the font is registered in the system
    func isFontRegistered() -> Bool {
        let availableFonts = getAvailableFonts()
        // Check both the exact name and without the "-Regular" suffix
        let baseFontName = fontName.replacingOccurrences(of: "-Regular", with: "")
        return availableFonts.contains(fontName) || availableFonts.contains(baseFontName)
    }
    
    // Download and register font from URL
    func downloadAndRegisterFont() -> Bool {
        guard let fontURL = fontURL else {
            print("No font URL provided")
            return false
        }
        
        // Create a temporary directory for downloaded fonts if it doesn't exist
        let tempFontDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptFontViewer/fonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempFontDir, withIntermediateDirectories: true)
        
        // Generate a unique filename for the downloaded font
        let fontFileName = fontURL.lastPathComponent
        let localFontURL = tempFontDir.appendingPathComponent(fontFileName)
        
        // Download the font file
        do {
            let fontData = try Data(contentsOf: fontURL)
            try fontData.write(to: localFontURL)
            
            // Extract the actual font name from the file
            if let extractedFontName = extractFontName(from: localFontURL) {
                self.fontName = extractedFontName
                print("Using font name from file: \(extractedFontName)")
            } else {
                print("Warning: Could not extract font name from file, using provided name: \(fontName)")
            }
            
            // Register the font with the system
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(localFontURL as CFURL, .process, &error) {
                if let error = error?.takeRetainedValue() {
                    print("Error registering font: \(error)")
                    try? FileManager.default.removeItem(at: localFontURL)
                    return false
                }
            }
            
            // Verify the font was registered successfully
            if isFontRegistered() {
                // Update the font name to the base name if that's what's registered
                let baseFontName = fontName.replacingOccurrences(of: "-Regular", with: "")
                if !getAvailableFonts().contains(fontName) && getAvailableFonts().contains(baseFontName) {
                    self.fontName = baseFontName
                }
                print("Successfully registered font: \(fontName)")
                return true
            } else {
                print("Font registration verification failed")
                print("Available fonts after registration attempt:")
                getAvailableFonts().sorted().forEach { print("  \($0)") }
                try? FileManager.default.removeItem(at: localFontURL)
                return false
            }
            
        } catch {
            print("Error downloading or saving font: \(error)")
            return false
        }
    }

    // find extreme glyphs and update text
    func autoAppendExtremeCharacters() {
        self.extremeGlyphs = findExtremeGlyphs(fontName: self.fontName, fontSize: fontSize, fontURL: fontURL)
        if let extremes = self.extremeGlyphs {
            let (topMost, bottomMost) = extremes
            
            // Create a set of characters to add
            var charsToAdd = Set<Character>()
            
            // Check if top-most character is not in the text
            if !text.contains(topMost.character) {
                charsToAdd.insert(topMost.character)
            }
            
            // Check if bottom-most character is not in the text
            if !text.contains(bottomMost.character) {
                charsToAdd.insert(bottomMost.character)
            }
            
            // If we have characters to add, append them with a separator
            if !charsToAdd.isEmpty {
                let separator = " | "
                self.text = text + separator + String(charsToAdd)
            }
        }
    }
    
    // Get precise glyph bounds that include overhanging parts
    func getPreciseGlyphBounds() -> CGRect {
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        
        // Create attributes with the font and tracking
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .tracking: tracking
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Get the line
        let line = CTLineCreateWithAttributedString(attributedString)
        
        // Get the bounding box that encompasses all glyphs including overhangs
        let glyphBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        
        return glyphBounds
    }
    
    // Get standard bounds using CTFramesetterCreateFrame
    func getStandardBounds() -> CGRect {
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        
        // Create attributes dictionary with the font and tracking
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .tracking: tracking
        ]
        
        // Create attributed string with the text and font
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Create a framesetter with the attributed string
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        
        // Determine the frame size needed for the text
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: attributedString.length),
            nil,
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            nil
        )
        
        // Create a path with the determined size
        let path = CGPath(rect: CGRect(origin: .zero, size: suggestedSize), transform: nil)
        
        // Create a frame with the path
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attributedString.length), path, nil)
        
        // Get the lines from the frame
        guard let lines = CTFrameGetLines(frame) as? [CTLine] else {
            print("Failed to get lines from frame")
            return .zero
        }
        
        // Calculate the exact bounds of all lines combined
        var bounds = CGRect.zero
        
        for line in lines {
            // Get the typographic bounds of the line
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            
            // Update the bounds
            let lineHeight = ascent + descent + leading
            if bounds.width < width {
                bounds.size.width = width
            }
            bounds.size.height += lineHeight
        }
        
        return bounds
    }
    
    // Get font metrics
    func getFontMetrics() -> [String: CGFloat] {
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        
        let ascent = CTFontGetAscent(font)
        let descent = CTFontGetDescent(font)
        let leading = CTFontGetLeading(font)
        let capHeight = CTFontGetCapHeight(font)
        let xHeight = CTFontGetXHeight(font)
        let lineHeight = ascent + descent + leading
        
        return [
            "ascent": ascent,
            "descent": descent,
            "leading": leading,
            "capHeight": capHeight,
            "xHeight": xHeight,
            "lineHeight": lineHeight
        ]
    }
    
    // Create a PDF visualization
    func createPDFVisualization(outputPath: String) -> Bool {
        // Check if font is registered
        guard isFontRegistered() else {
            print("Error: Font '\(fontName)' is not registered in the system")
            return false
        }
        
        // Get the bounds
        let standardBounds = getStandardBounds()
        let preciseBounds = getPreciseGlyphBounds()
        let metrics = getFontMetrics()
        
        // Print analysis results
        print("\nAnalyzing font '\(fontName)' at \(fontSize)pt:")
        print("\nInput text: \"\(text)\"")
        print("Tracking: \(tracking) points")
        
        if let (topMost, bottomMost) = extremeGlyphs {
            print("\nExtreme characters:")
            print(String(format: "• Top-most glyph: '%@' extends %.2f points above baseline", String(topMost.character), topMost.height))
            print(String(format: "• Bottom-most glyph: '%@' extends %.2f points below baseline", String(bottomMost.character), bottomMost.depth))
        }
        
        print("\nBounds measurements:")
        print("• Standard bounds (CTFramesetterCreateFrame):")
        print(String(format: "  Width: %.2f points, Height: %.2f points", standardBounds.width, standardBounds.height))
        
        print("\n• Precise glyph bounds (with overhangs):")
        print(String(format: "  Origin: (%.2f, %.2f)", preciseBounds.origin.x, preciseBounds.origin.y))
        print(String(format: "  Size: %.2f × %.2f points", preciseBounds.width, preciseBounds.height))
        
        print("\nFont metrics:")
        print(String(format: "• Ascent: %.2f points", metrics["ascent"] ?? 0))
        print(String(format: "• Descent: %.2f points", metrics["descent"] ?? 0))
        print(String(format: "• Leading: %.2f points", metrics["leading"] ?? 0))
        print(String(format: "• Cap Height: %.2f points", metrics["capHeight"] ?? 0))
        print(String(format: "• x-Height: %.2f points", metrics["xHeight"] ?? 0))
        print(String(format: "• Line Height: %.2f points", metrics["lineHeight"] ?? 0))

        // Create and position the info text first
        let infoFont = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let infoAttributes: [NSAttributedString.Key: Any] = [.font: infoFont]
        
        // Create informational text with extreme glyph information
        let infoText = """
        Font: \(fontName) at \(fontSize)pt
        Text: "\(text)"
        Tracking: \(String(format: "%.2f", tracking)) points
        
        Extreme Characters:
        Top-most glyph: '\(extremeGlyphs?.topMost.character ?? " ")' extends \(String(format: "%.2f", extremeGlyphs?.topMost.height ?? 0)) points above baseline
        Bottom-most glyph: '\(extremeGlyphs?.bottomMost.character ?? " ")' extends \(String(format: "%.2f", extremeGlyphs?.bottomMost.depth ?? 0)) points below baseline
        
        Precise Glyph Bounds (blue)
        Standard Bounds (green)
        
        Precise Glyph Bounds:
          Origin: (\(String(format: "%.2f", preciseBounds.origin.x)), \(String(format: "%.2f", preciseBounds.origin.y)))
          Size: \(String(format: "%.2f", preciseBounds.width)) × \(String(format: "%.2f", preciseBounds.height)) points
        
        Standard Bounds (CTFramesetterCreateFrame):
          Origin: (\(String(format: "%.2f", standardBounds.origin.x)), \(String(format: "%.2f", standardBounds.origin.y)))
          Size: \(String(format: "%.2f", standardBounds.width)) × \(String(format: "%.2f", standardBounds.height)) points
        
        Font Metrics:
          Ascent: \(String(format: "%.2f", metrics["ascent"] ?? 0)) points
          Descent: \(String(format: "%.2f", metrics["descent"] ?? 0)) points
          Leading: \(String(format: "%.2f", metrics["leading"] ?? 0)) points
          Cap Height: \(String(format: "%.2f", metrics["capHeight"] ?? 0)) points
          x-Height: \(String(format: "%.2f", metrics["xHeight"] ?? 0)) points
          Line Height: \(String(format: "%.2f", metrics["lineHeight"] ?? 0)) points
        """
        
        let infoFramesetter = CTFramesetterCreateWithAttributedString(NSAttributedString(string: infoText, attributes: infoAttributes))
        
        let padding: CGFloat = 10

        var maxWidth = max(preciseBounds.width, standardBounds.width) // More padding

        let labelMaxWidth: CGFloat = 50
        let lineExtension: CGFloat = 0
        let labelOffset: CGFloat = 10 // Increased offset for better visibility
        let lineOriginX: CGFloat = labelOffset + labelMaxWidth + labelOffset
        maxWidth += lineOriginX

        let pageWidth = maxWidth + (padding * 2)

        // Calculate the size needed for the info text
        let suggestedInfoSize = CTFramesetterSuggestFrameSizeWithConstraints(
            infoFramesetter,
            CFRange(location: 0, length: infoText.count),
            nil,
            CGSize(width: pageWidth - (padding * 2), height: CGFloat.greatestFiniteMagnitude),
            nil
        )

        print("suggestedInfoSize:\(suggestedInfoSize)")

        // legend text with colored squares frame
        let legendInfoHeight: CGFloat = 40

        // Find the maximum bounds to use for the visualization
        var maxHeight = max(preciseBounds.height, standardBounds.height, metrics["lineHeight"] ?? 0)
        maxHeight += padding + suggestedInfoSize.height + legendInfoHeight

        // Add padding around the text for better visibility
        let pageHeight = maxHeight + (padding * 2) // Reduced vertical space
        
        // Create a PDF context
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        guard let pdfContext = CGContext(consumer: CGDataConsumer(data: pdfData as CFMutableData)!, mediaBox: &mediaBox, nil) else {
            print("Failed to create PDF context")
            return false
        }
        
        // Begin a new PDF page
        pdfContext.beginPage(mediaBox: &mediaBox)
        
        // Draw a light gray background for the entire page
        pdfContext.setFillColor(CGColor(gray: 0.95, alpha: 1.0))
        pdfContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        // Define baseline y position for visualization (in PDF coordinates, bottom-up)
        let baselineY = pageHeight - (metrics["ascent"] ?? 0) - padding
        
        // Draw the visualization components
        // ---- Draw the precise glyph bounds rectangle (blue) ----
        pdfContext.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 0.3))
        pdfContext.setStrokeColor(CGColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.8))
        pdfContext.setLineWidth(0.5)
        
        let preciseRect = CGRect(
            x: lineOriginX + preciseBounds.origin.x,
            y: baselineY + preciseBounds.origin.y,
            width: preciseBounds.width,
            height: preciseBounds.height
        )
        pdfContext.addRect(preciseRect)
        pdfContext.drawPath(using: CGPathDrawingMode.fillStroke)
        
        // ---- Draw the standard bounds rectangle (green) ----
        pdfContext.setFillColor(CGColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 0.3))
        pdfContext.setStrokeColor(CGColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.8))
        
        let standardRect = CGRect(
            x: lineOriginX,
            y: baselineY + metrics["ascent"]! - standardBounds.height,
            width: standardBounds.width,
            height: standardBounds.height
        )
        pdfContext.addRect(standardRect)
        pdfContext.drawPath(using: CGPathDrawingMode.fillStroke)
        
        // ---- Draw text baseline and metrics lines ----
        pdfContext.setStrokeColor(CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.8))
        pdfContext.setLineWidth(0.5)
        
        // Baseline
        pdfContext.move(to: CGPoint(x: lineOriginX - lineExtension, y: baselineY))
        pdfContext.addLine(to: CGPoint(x: lineOriginX + maxWidth + lineExtension, y: baselineY))
        
        // Ascent line
        let ascentY = baselineY + metrics["ascent"]!
        pdfContext.move(to: CGPoint(x: lineOriginX - lineExtension, y: ascentY))
        pdfContext.addLine(to: CGPoint(x: lineOriginX + maxWidth + lineExtension, y: ascentY))
        
        // Descent line
        let descentY = baselineY - metrics["descent"]!
        pdfContext.move(to: CGPoint(x: lineOriginX - lineExtension, y: descentY))
        pdfContext.addLine(to: CGPoint(x: lineOriginX + maxWidth + lineExtension, y: descentY))
        
        // Leading line
        let leadingY = descentY - metrics["leading"]!
        pdfContext.move(to: CGPoint(x: lineOriginX - lineExtension, y: leadingY))
        pdfContext.addLine(to: CGPoint(x: lineOriginX + maxWidth + lineExtension, y: leadingY))
        
        // Cap height line
        let capHeightY = baselineY + metrics["capHeight"]!
        pdfContext.move(to: CGPoint(x: lineOriginX - lineExtension, y: capHeightY))
        pdfContext.addLine(to: CGPoint(x: lineOriginX + maxWidth + lineExtension, y: capHeightY))
        
        // x-Height line
        let xHeightY = baselineY + metrics["xHeight"]!
        pdfContext.move(to: CGPoint(x: lineOriginX - lineExtension, y: xHeightY))
        pdfContext.addLine(to: CGPoint(x: lineOriginX + maxWidth + lineExtension, y: xHeightY))
        
        pdfContext.drawPath(using: CGPathDrawingMode.stroke)
        
        // ---- Draw line labels ----
        let labelFont = CTFontCreateWithName("Helvetica" as CFString, 8, nil)
        
        // Function to draw a label
        func drawLabel(_ text: String, at point: CGPoint) {
            let attributes: [NSAttributedString.Key: Any] = [.font: labelFont]
            let string = NSAttributedString(string: text, attributes: attributes)
            let line = CTLineCreateWithAttributedString(string)
            
            pdfContext.textPosition = point
            CTLineDraw(line, pdfContext)
        }
        
        // Draw labels with increased distance from the left edge
        drawLabel("Baseline", at: CGPoint(x: padding - labelOffset, y: baselineY - 5))
        drawLabel("Ascent", at: CGPoint(x: padding - labelOffset, y: ascentY - 5 + 2))
        drawLabel("Descent", at: CGPoint(x: padding - labelOffset, y: descentY - 5 + 5))
        drawLabel("Leading", at: CGPoint(x: padding - labelOffset, y: leadingY - 5))
        drawLabel("Cap Height", at: CGPoint(x: padding - labelOffset, y: capHeightY - 5))
        drawLabel("x-Height", at: CGPoint(x: padding - labelOffset, y: xHeightY - 5 + 2))
        
        // Draw a legend for the rectangles
        // drawLabel("Precise Glyph Bounds (blue)", at: CGPoint(x: padding, y: 100))
        // drawLabel("Standard Bounds (green)", at: CGPoint(x: padding + 200, y: 100))
        
        // ---- Draw the text ----
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        
        // Create attributed string with colored extreme characters
        let attributedString = NSMutableAttributedString(string: text)
        
        // Base attributes for all text
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .tracking: tracking
        ]
        attributedString.addAttributes(baseAttributes, range: NSRange(location: 0, length: text.count))
        
        // Highlight extreme characters in the text
        if let (topMost, bottomMost) = extremeGlyphs {
            // Find and highlight top-most character (red)
            if let topRange = text.range(of: String(topMost.character)) {
                let nsRange = NSRange(topRange, in: text)
                attributedString.addAttribute(.foregroundColor, value: CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), range: nsRange)
            }
            
            // Find and highlight bottom-most character (blue)
            if let bottomRange = text.range(of: String(bottomMost.character)) {
                let nsRange = NSRange(bottomRange, in: text)
                attributedString.addAttribute(.foregroundColor, value: CGColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), range: nsRange)
            }
        }
        
        let line = CTLineCreateWithAttributedString(attributedString)
        
        // Save the graphics state
        pdfContext.saveGState()
        
        // Move to the position for drawing text (at the baseline)
        pdfContext.textPosition = CGPoint(x: lineOriginX, y: baselineY)
        
        // Draw the text
        CTLineDraw(line, pdfContext)
        
        // Restore the graphics state
        pdfContext.restoreGState()
        
        // Add a legend for the colored characters
        let legendFont = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let legendAttributes: [NSAttributedString.Key: Any] = [.font: legendFont]
        
        if let (topMost, bottomMost) = extremeGlyphs {
            // Create legend text with colored squares
            pdfContext.setFillColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
            pdfContext.fill(CGRect(x: padding, y: suggestedInfoSize.height + 20, width: 10, height: 10))
            
            let topLegend = NSAttributedString(string: " - Top-most character '\(topMost.character)'", attributes: legendAttributes)
            let topLine = CTLineCreateWithAttributedString(topLegend)
            pdfContext.textPosition = CGPoint(x: padding + 12, y: suggestedInfoSize.height + 20)
            CTLineDraw(topLine, pdfContext)
            
            pdfContext.setFillColor(CGColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
            pdfContext.fill(CGRect(x: padding, y: suggestedInfoSize.height + 35, width: 10, height: 10))
            
            let bottomLegend = NSAttributedString(string: " - Bottom-most character '\(bottomMost.character)'", attributes: legendAttributes)
            let bottomLine = CTLineCreateWithAttributedString(bottomLegend)
            pdfContext.textPosition = CGPoint(x: padding + 12, y: suggestedInfoSize.height + 35)
            CTLineDraw(bottomLine, pdfContext)
        }
        
        // ---- Draw origin point ----
        pdfContext.setStrokeColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        pdfContext.setLineWidth(1.0)
        
        // Horizontal axis (X) - red
        pdfContext.move(to: CGPoint(x: lineOriginX - 5, y: baselineY))
        pdfContext.addLine(to: CGPoint(x: lineOriginX + 5, y: baselineY))
        
        // Vertical axis (Y) - red
        pdfContext.move(to: CGPoint(x: lineOriginX, y: baselineY - 5))
        pdfContext.addLine(to: CGPoint(x: lineOriginX, y: baselineY + 5))
        
        pdfContext.drawPath(using: CGPathDrawingMode.stroke)
        
        // Position the info text at the leading line
        print("leadingY:\(leadingY)")
        let infoY: CGFloat = padding
        let infoPath = CGPath(rect: CGRect(x: padding, y: infoY, width: pageWidth - (padding * 2), height: suggestedInfoSize.height), transform: nil)
        let infoFrame = CTFramesetterCreateFrame(infoFramesetter, CFRange(location: 0, length: infoText.count), infoPath, nil)
        
        // Draw the info text last to ensure it's on top
        CTFrameDraw(infoFrame, pdfContext)
        
        // End the PDF page and close the PDF context
        pdfContext.endPage()
        pdfContext.closePDF()
        
        // Write the PDF data to file
        do {
            try pdfData.write(toFile: outputPath, options: .atomic)
            print("PDF created successfully at: \(outputPath)")
            return true
        } catch {
            print("Failed to write PDF: \(error)")
            return false
        }
    }
}

// MARK: - Command line argument parsing

var fontName = "Zapfino" // Default script font
var fontSize: CGFloat = 24.0
var text = "Hello World"
var tracking: CGFloat = 0.0
var listFonts = false
var generatePDF = false
var outputPath = ""
var fontURL: URL? = nil

// Process command-line arguments
var argIndex = 1
while argIndex < CommandLine.arguments.count {
    let arg = CommandLine.arguments[argIndex]
    
    switch arg {
    case "--font", "-f":
        if argIndex + 1 < CommandLine.arguments.count {
            fontName = CommandLine.arguments[argIndex + 1]
            argIndex += 2
        } else {
            print("Error: Missing font name after \(arg)")
            exit(1)
        }
    case "--font-url", "-u":
        if argIndex + 1 < CommandLine.arguments.count {
            if let url = URL(string: CommandLine.arguments[argIndex + 1]) {
                fontURL = url
                argIndex += 2
            } else {
                print("Error: Invalid URL format after \(arg)")
                exit(1)
            }
        } else {
            print("Error: Missing URL after \(arg)")
            exit(1)
        }
    case "--size", "-s":
        if argIndex + 1 < CommandLine.arguments.count, 
           let size = Double(CommandLine.arguments[argIndex + 1]) {
            fontSize = CGFloat(size)
            argIndex += 2
        } else {
            print("Error: Missing or invalid font size after \(arg)")
            exit(1)
        }
    case "--tracking", "-k":
        if argIndex + 1 < CommandLine.arguments.count,
           let trackingValue = Double(CommandLine.arguments[argIndex + 1]) {
            tracking = CGFloat(trackingValue)
            argIndex += 2
        } else {
            print("Error: Missing or invalid tracking value after \(arg)")
            exit(1)
        }
    case "--text", "-t":
        if argIndex + 1 < CommandLine.arguments.count {
            text = CommandLine.arguments[argIndex + 1]
            argIndex += 2
        } else {
            print("Error: Missing text after \(arg)")
            exit(1)
        }
    case "--list-fonts", "-l":
        listFonts = true
        argIndex += 1
    case "--pdf", "-p":
        generatePDF = true
        argIndex += 1
    case "--output", "-o":
        if argIndex + 1 < CommandLine.arguments.count {
            outputPath = CommandLine.arguments[argIndex + 1]
            argIndex += 2
        } else {
            print("Error: Missing output path after \(arg)")
            exit(1)
        }
    case "--help", "-h":
        print("""
        Usage: ScriptFontViewer [options]
        
        Options:
          -f, --font NAME     Specify the font name (optional if --font-url is provided)
          -u, --font-url URL  Specify a URL to download and register the font
          -s, --size SIZE     Specify the font size in points (default: 24.0)
          -k, --tracking VAL  Specify the tracking value in points (default: 0.0)
          -t, --text TEXT     Specify the text to measure (default: "Hello World")
          -l, --list-fonts    List all available fonts on the system
          -p, --pdf           Generate a PDF visualization
          -o, --output PATH   Specify the output PDF path (default: ./fontname_size.pdf)
          -h, --help          Show this help message
        
        Note: When --font-url is provided, the font name will be extracted from the font file,
              and any provided font name will be ignored.
        """)
        exit(0)
    default:
        print("Unknown option: \(arg)")
        exit(1)
    }
}

// If list fonts flag is set, show available fonts and exit
if listFonts {
    print("Available fonts on your system:")
    getAvailableFonts().sorted().forEach { print("  \($0)") }
    exit(0)
}

// Create the handler with a default font name if URL is provided
let handler = FontMetricsHandler(
    fontName: fontURL != nil ? "Temporary Font Name" : fontName,
    fontSize: fontSize,
    text: text,
    tracking: tracking,
    fontURL: fontURL
)

// Check if font is registered or needs to be downloaded
if !handler.isFontRegistered() {
    if let _ = fontURL {
        // Try to download and register the font
        if !handler.downloadAndRegisterFont() {
            print("Failed to download and register font")
            print("Use --list-fonts (-l) to see available fonts")
            exit(1)
        }
    } else {
        print("Error: Font '\(fontName)' is not registered in the system")
        print("Use --list-fonts (-l) to see available fonts or provide a font URL with --font-url")
        exit(1)
    }
}

handler.autoAppendExtremeCharacters()

// Generate output path if not specified
if generatePDF && outputPath.isEmpty {
    outputPath = "\(FileManager.default.currentDirectoryPath)/\(handler.fontName.replacingOccurrences(of: " ", with: "_"))_\(fontSize)pt_tracking\(tracking)pt.pdf"
}

// Get the bounds using both methods
let standardBounds = handler.getStandardBounds()
let preciseBounds = handler.getPreciseGlyphBounds()
let metrics = handler.getFontMetrics()

// Print the results
print("\nText: \"\(text)\"")
print("Font: \(handler.fontName) at \(fontSize)pt")
print("Tracking: \(tracking) points")

print("\nStandard bounds (using CTFramesetterCreateFrame):")
print("Width: \(standardBounds.width) points, Height: \(standardBounds.height) points")

print("\nPrecise glyph bounds (accounting for overhangs):")
print("Origin X: \(preciseBounds.origin.x), Origin Y: \(preciseBounds.origin.y)")
print("Width: \(preciseBounds.width) points, Height: \(preciseBounds.height) points")

print("\nFont metrics:")
print("Ascent: \(metrics["ascent"] ?? 0) points")
print("Descent: \(metrics["descent"] ?? 0) points")
print("Leading: \(metrics["leading"] ?? 0) points")
print("Cap Height: \(metrics["capHeight"] ?? 0) points")
print("x-Height: \(metrics["xHeight"] ?? 0) points")
print("Line Height: \(metrics["lineHeight"] ?? 0) points")

// Generate PDF if requested
if generatePDF {
    let success = handler.createPDFVisualization(outputPath: outputPath)
    
    if success {
        print("\nPDF visualization created at: \(outputPath)")
    }
} 