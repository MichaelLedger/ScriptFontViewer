#!/usr/bin/swift

import Foundation
import CoreText
import CoreGraphics
import AppKit

// Helper function to get available fonts on the system
func getAvailableFonts() -> [String] {
    return CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
}

// Function to get exact pixel bounds for a specific font and text
func getExactPixelBounds(fontName: String, fontSize: CGFloat, text: String) -> CGRect {
    // Create font with specified name and size
    let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
    
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
    
    return bounds
}

// Function that provides the most accurate glyph bounds
func getPreciseGlyphBounds(fontName: String, fontSize: CGFloat, text: String) -> CGRect {
    // Create the font
    let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
    
    // Create attributes
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    
    // Get the line
    let line = CTLineCreateWithAttributedString(attributedString)
    
    // Get the typographic bounds (conventional metrics)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    
    // Get the bounding box that encompasses all glyphs including overhangs
    let glyphBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    
    // Return the most accurate bounds
    return CGRect(
        x: glyphBounds.origin.x,
        y: glyphBounds.origin.y,
        width: max(width, glyphBounds.width),
        height: glyphBounds.height
    )
}

// Command line argument parsing
var fontName = "Zapfino" // Default script font
var fontSize: CGFloat = 24.0
var text = "Hello, Script Font!"
var listFonts = false

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
    case "--size", "-s":
        if argIndex + 1 < CommandLine.arguments.count, 
           let size = Double(CommandLine.arguments[argIndex + 1]) {
            fontSize = CGFloat(size)
            argIndex += 2
        } else {
            print("Error: Missing or invalid font size after \(arg)")
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
    case "--help", "-h":
        print("""
        Usage: ScriptFontBounds [options]
        
        Options:
          -f, --font NAME     Specify the font name (default: Zapfino)
          -s, --size SIZE     Specify the font size in points (default: 24.0)
          -t, --text TEXT     Specify the text to measure (default: "Hello, Script Font!")
          -l, --list-fonts    List all available fonts on the system
          -h, --help          Show this help message
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

// Get the bounds using both methods
let standardBounds = getExactPixelBounds(fontName: fontName, fontSize: fontSize, text: text)
let preciseBounds = getPreciseGlyphBounds(fontName: fontName, fontSize: fontSize, text: text)

// Print the results
print("\nText: \"\(text)\"")
print("Font: \(fontName) at \(fontSize)pt")
print("\nStandard bounds (using CTFramesetterCreateFrame):")
print("Width: \(standardBounds.width) points, Height: \(standardBounds.height) points")

print("\nPrecise glyph bounds (accounting for overhangs):")
print("Origin X: \(preciseBounds.origin.x), Origin Y: \(preciseBounds.origin.y)")
print("Width: \(preciseBounds.width) points, Height: \(preciseBounds.height) points")

// Font details
let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
let ascent = CTFontGetAscent(font)
let descent = CTFontGetDescent(font)
let leading = CTFontGetLeading(font)
let capHeight = CTFontGetCapHeight(font)
let xHeight = CTFontGetXHeight(font)

print("\nFont metrics:")
print("Ascent: \(ascent) points")
print("Descent: \(descent) points")
print("Leading: \(leading) points")
print("Cap Height: \(capHeight) points")
print("x-Height: \(xHeight) points")
print("Line Height: \(ascent + descent + leading) points") 