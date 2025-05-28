import Foundation
import CoreText
import CoreGraphics
import AppKit

// This example shows how to use the precise font metrics to render text with proper bounds

class FontRenderer {
    let fontName: String
    let fontSize: CGFloat
    let text: String
    
    init(fontName: String, fontSize: CGFloat, text: String) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.text = text
    }
    
    // Get precise glyph bounds that include overhanging parts
    func getPreciseGlyphBounds() -> CGRect {
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        
        // Create attributes with the font
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Get the line
        let line = CTLineCreateWithAttributedString(attributedString)
        
        // Get the bounding box that encompasses all glyphs including overhangs
        let glyphBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        
        // For more accurate bounds that handle script fonts better, we can also use:
        // var ascent: CGFloat = 0
        // var descent: CGFloat = 0
        // var leading: CGFloat = 0
        // let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        
        return glyphBounds
    }
    
    // Create a PDF containing the text with visual indicators for the bounds
    func createPDFWithBounds(outputPath: String) -> Bool {
        // Get the precise bounds
        let bounds = getPreciseGlyphBounds()
        
        // Add padding around the text for better visibility
        let padding: CGFloat = 20
        let pageWidth = bounds.width + (padding * 2)
        let pageHeight = bounds.height + (padding * 2)
        
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
        
        // Draw the actual bounds rectangle in light blue
        pdfContext.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0))
        pdfContext.setStrokeColor(CGColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0))
        pdfContext.setLineWidth(0.5)
        
        let boundsRect = CGRect(
            x: padding + bounds.origin.x,
            y: padding - bounds.origin.y - bounds.height, // Flip Y for PDF coordinates
            width: bounds.width,
            height: bounds.height
        )
        pdfContext.addRect(boundsRect)
        pdfContext.drawPath(using: CGPathDrawingMode.fillStroke)
        
        // Create the attributed string with the font
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Draw the text
        let line = CTLineCreateWithAttributedString(attributedString)
        
        // Save the graphics state
        pdfContext.saveGState()
        
        // Move to the position for drawing text
        // We need to position the text at the correct location within the bounds rectangle
        pdfContext.textPosition = CGPoint(
            x: padding,
            y: padding
        )
        
        // Draw the text
        CTLineDraw(line, pdfContext)
        
        // Restore the graphics state
        pdfContext.restoreGState()
        
        // Draw axes (origin point)
        pdfContext.setStrokeColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        pdfContext.setLineWidth(1.0)
        
        // Horizontal axis (X) - red
        pdfContext.move(to: CGPoint(x: padding - 10, y: padding))
        pdfContext.addLine(to: CGPoint(x: padding + 10, y: padding))
        
        // Vertical axis (Y) - red
        pdfContext.move(to: CGPoint(x: padding, y: padding - 10))
        pdfContext.addLine(to: CGPoint(x: padding, y: padding + 10))
        
        pdfContext.drawPath(using: CGPathDrawingMode.stroke)
        
        // Add some additional information
        let infoFont = CTFontCreateWithName("Helvetica" as CFString, 8, nil)
        let infoAttributes: [NSAttributedString.Key: Any] = [.font: infoFont]
        
        // Create informational text
        let infoText = """
        Font: \(fontName) at \(fontSize)pt
        Text: "\(text)"
        Bounds Origin: (\(bounds.origin.x), \(bounds.origin.y))
        Bounds Size: \(bounds.width) × \(bounds.height)
        """
        
        let infoAttributedString = NSAttributedString(string: infoText, attributes: infoAttributes)
        let infoLine = CTLineCreateWithAttributedString(infoAttributedString)
        
        // Position for info text
        pdfContext.textPosition = CGPoint(x: 5, y: pageHeight - 40)
        
        // Draw the info text
        CTLineDraw(infoLine, pdfContext)
        
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

// Example usage
let fontName = "Apple Chancery" // Changed from Zapfino
let fontSize: CGFloat = 24.0
let text = "Hello World"

let renderer = FontRenderer(fontName: fontName, fontSize: fontSize, text: text)

// Get current directory
let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath
let outputPath = "\(currentPath)/\(fontName)_\(Int(fontSize))pt.pdf"

// Create the PDF
let success = renderer.createPDFWithBounds(outputPath: outputPath)

if success {
    print("PDF created with bounds visualization at: \(outputPath)")
} else {
    print("Failed to create PDF")
} 