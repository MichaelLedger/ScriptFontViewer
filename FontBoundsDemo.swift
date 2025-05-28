import Foundation
import CoreText
import CoreGraphics

func getExactPixelBoundsForFont(fontName: String, fontSize: CGFloat, text: String) -> CGRect {
    // Create font with specified name and size
    guard let font = CTFontCreateWithName(fontName as CFString, fontSize, nil) else {
        print("Failed to create font: \(fontName)")
        return .zero
    }
    
    // Create attributes dictionary with the font
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font
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
    
    // For more precise bounds, we can also get line origin points
    var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
    CTFrameGetLineOrigins(frame, CFRange(location: 0, length: lines.count), &lineOrigins)
    
    // Alternatively, for even more precise bounds, you can use CoreText glyph runs
    // This gets the exact pixel bounds including any overhanging parts of glyphs
    
    return bounds
}

// Example usage
let fontName = "Zapfino" // A script font
let fontSize: CGFloat = 24.0
let text = "Hello, Script Font!"

let bounds = getExactPixelBoundsForFont(fontName: fontName, fontSize: fontSize, text: text)
print("Exact pixel bounds for '\(text)' in \(fontName) at \(fontSize)pt:")
print("Width: \(bounds.width), Height: \(bounds.height)")

// For a more comprehensive approach that handles overhanging glyphs better:
func getDetailedBoundsForFont(fontName: String, fontSize: CGFloat, text: String) -> CGRect {
    // Create the font
    guard let font = CTFontCreateWithName(fontName as CFString, fontSize, nil) else {
        return .zero
    }
    
    // Create attributes
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    
    // Get the exact bounds using CoreText layout
    let line = CTLineCreateWithAttributedString(attributedString)
    
    // Get the typographic bounds
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    
    // Get the bounding box that encompasses all glyphs
    let glyphBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    
    // The height is typically ascent + descent, but for accuracy, we use the glyph bounds height
    return CGRect(
        x: glyphBounds.origin.x,
        y: glyphBounds.origin.y,
        width: max(width, glyphBounds.width),
        height: glyphBounds.height
    )
}

// Try the more detailed approach
let detailedBounds = getDetailedBoundsForFont(fontName: fontName, fontSize: fontSize, text: text)
print("\nDetailed bounds (including overhanging glyphs):")
print("X: \(detailedBounds.origin.x), Y: \(detailedBounds.origin.y), Width: \(detailedBounds.width), Height: \(detailedBounds.height)")