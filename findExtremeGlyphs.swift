#!/usr/bin/swift

import Foundation
import CoreText
import CoreGraphics
import AppKit

// Helper function to get available fonts on the system
func getAvailableFonts() -> [String] {
    return CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
}

class GlyphHeightAnalyzer {
    private(set) var fontName: String
    let fontSize: CGFloat
    let fontURL: URL?
    
    init(fontName: String, fontSize: CGFloat = 24.0, fontURL: URL? = nil) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontURL = fontURL
    }
    
    // Extract font name from the font file
    private func extractFontName(from fontURL: URL) -> String? {
        do {
            let fontData = try Data(contentsOf: fontURL)
            guard let fontDescriptor = CTFontManagerCreateFontDescriptorFromData(fontData as CFData) else {
                return nil
            }
            
            let font = CTFontCreateWithFontDescriptor(fontDescriptor, 0.0, nil)
            
            if let familyName = CTFontCopyFamilyName(font) as String? {
                return familyName
            }
            
            return nil
        } catch {
            print("Error reading font file: \(error)")
            return nil
        }
    }
    
    // Download and register font from URL
    private func downloadAndRegisterFont() -> Bool {
        guard let fontURL = fontURL else {
            return false
        }
        
        // Create a temporary directory for downloaded fonts if it doesn't exist
        let tempFontDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptFontViewer/fonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempFontDir, withIntermediateDirectories: true)
        
        // Generate a unique filename for the downloaded font
        let fontFileName = fontURL.lastPathComponent
        let localFontURL = tempFontDir.appendingPathComponent(fontFileName)
        
        do {
            // Download the font file
            let fontData = try Data(contentsOf: fontURL)
            try fontData.write(to: localFontURL)
            
            // Register the font with the system
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(localFontURL as CFURL, .process, &error) {
                if let error = error?.takeRetainedValue() {
                    print("Error registering font: \(error)")
                    try? FileManager.default.removeItem(at: localFontURL)
                    return false
                }
            }
            
            // Extract the actual font name from the file
            if let extractedFontName = extractFontName(from: localFontURL) {
                self.fontName = extractedFontName
                print("Using font name from file: \(extractedFontName)")
            }
            
            return true
        } catch {
            print("Error downloading or saving font: \(error)")
            return false
        }
    }
    
    // Get precise glyph bounds for a character
    private func getGlyphBounds(for char: Character, with font: CTFont) -> CGRect {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font
        ]
        let attributedString = NSAttributedString(string: String(char), attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        return CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    }
    
    // Find the glyphs with highest ascender and lowest descender
    func findExtremeGlyphs(characterSet: String? = nil) -> (topMost: (character: Character, height: CGFloat), bottomMost: (character: Character, depth: CGFloat))? {
        // Register font if URL provided
        if let _ = fontURL {
            guard downloadAndRegisterFont() else {
                print("Failed to register font")
                return nil
            }
        }
        
        // Create font
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        
        // Default character set if none provided
        let chars = characterSet ?? "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:'\",.<>?/~`"
        
        var highestAscender: CGFloat = 0
        var topChar: Character = " "
        var lowestDescender: CGFloat = 0
        var bottomChar: Character = " "
        
        // Analyze each character
        for char in chars {
            let bounds = getGlyphBounds(for: char, with: font)
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
            
            // Print details for each character
            print(String(format: "Char: '%@' - Above baseline: %.2f, Below baseline: %.2f (Bounds height: %.2f, Y origin: %.2f)",
                       String(char), ascenderHeight, descenderDepth, bounds.height, bounds.origin.y))
        }
        
        return ((topChar, highestAscender), (bottomChar, lowestDescender))
    }
}

// Parse command line arguments
var fontName = "Helvetica"
var fontSize: CGFloat = 24.0
var fontURL: URL? = nil
var customChars: String? = nil

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
        if argIndex + 1 < CommandLine.arguments.count,
           let url = URL(string: CommandLine.arguments[argIndex + 1]) {
            fontURL = url
            argIndex += 2
        } else {
            print("Error: Missing or invalid URL after \(arg)")
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
    case "--chars", "-c":
        if argIndex + 1 < CommandLine.arguments.count {
            customChars = CommandLine.arguments[argIndex + 1]
            argIndex += 2
        } else {
            print("Error: Missing characters after \(arg)")
            exit(1)
        }
    case "--list-fonts", "-l":
        print("Available fonts on your system:")
        getAvailableFonts().sorted().forEach { print("  \($0)") }
        exit(0)
    case "--help", "-h":
        print("""
        Usage: FindHighestGlyph [options]
        
        Options:
          -f, --font NAME     Specify the font name (default: Helvetica)
          -u, --font-url URL  Specify a URL to download and register the font
          -s, --size SIZE     Specify the font size in points (default: 24.0)
          -c, --chars CHARS   Specify custom characters to analyze
          -l, --list-fonts    List all available fonts on the system
          -h, --help         Show this help message
        
        Examples:
          ./FindHighestGlyph.swift -f "Zapfino"
          ./FindHighestGlyph.swift -f "Helvetica" -s 36 -c "ABCDEF123"
          ./FindHighestGlyph.swift -u "https://example.com/font.ttf" -s 48
        """)
        exit(0)
    default:
        print("Unknown option: \(arg)")
        exit(1)
    }
}

// Create analyzer and find extreme glyphs
let analyzer = GlyphHeightAnalyzer(fontName: fontName, fontSize: fontSize, fontURL: fontURL)
if let (topMost, bottomMost) = analyzer.findExtremeGlyphs(characterSet: customChars) {
    print("\nResults for font '\(fontName)' at \(fontSize)pt:")
    print(String(format: "Top-most glyph: '%@' extends %.2f points above baseline", String(topMost.character), topMost.height))
    print(String(format: "Bottom-most glyph: '%@' extends %.2f points below baseline", String(bottomMost.character), bottomMost.depth))
    
    // Print command to generate PDF
    print("\nTo generate a PDF visualization with these characters, run:")
    print("./ScriptFontViewer.swift -u \"\(fontURL?.absoluteString ?? "")\" -s \(fontSize) -t \"\(topMost.character)Hello\(bottomMost.character)World\" -p")
} else {
    print("Failed to analyze font")
    exit(1)
}