//
//  FountainPDFWriter.swift
//
//  Courier screenplay PDF via CoreGraphics + CoreText (Phase 8 / Next-Gen spec §4).
//  **WebAssembly:** ``FountainPDFWriter`` is unavailable (throws ``FountainStubRendererError``); use plaintext / JSON / FDX on wasm32.
//

import Foundation

#if arch(wasm32)

/// PDF export is not available when compiling **FountainCore** for WebAssembly.
public struct FountainPDFWriter: FountainScriptRendering, Sendable {
    public init() {}

    public func render(_ script: FNScript) throws -> String {
        throw FountainStubRendererError.notImplemented("FountainPDFWriter (not available on WebAssembly)")
    }
}

#else

import CoreGraphics
import CoreText

/// Errors from ``FountainPDFWriter/renderPDFData(_:)``.
public enum FountainPDFExportError: Error, Equatable, Sendable {
    case cannotCreatePDFConsumer
    case cannotCreatePDFContext
}

/// Renders ``FNScript`` to a **US Letter** PDF using Courier 12pt.
///
/// ``FountainScriptRendering/render(_:)`` returns **base64**-encoded PDF bytes because the protocol
/// surface is `String`. Use ``renderPDFData(_:)`` when you need `Data` directly.
public struct FountainPDFWriter: FountainScriptRendering, Sendable {
    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let marginLeft: CGFloat = 72
    private static let marginRight: CGFloat = 72
    private static let marginTop: CGFloat = 72
    private static let marginBottom: CGFloat = 72
    private static let fontSize: CGFloat = 12
    private static let lineSpacing: CGFloat = 2

    public init() {}

    /// Base64-encoded PDF (decode with `Data(base64Encoded:)`).
    public func render(_ script: FNScript) throws -> String {
        let data = try renderPDFData(script)
        return data.base64EncodedString()
    }

    public func renderPDFData(_ script: FNScript) throws -> Data {
        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData) else {
            throw FountainPDFExportError.cannotCreatePDFConsumer
        }
        var mediaBox = CGRect(x: 0, y: 0, width: Self.pageWidth, height: Self.pageHeight)
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw FountainPDFExportError.cannotCreatePDFContext
        }

        let font = CTFontCreateWithName("Courier" as CFString, Self.fontSize, nil)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let black = CGColor(colorSpace: colorSpace, components: [0, 1])!

        ctx.beginPDFPage(nil)
        ctx.translateBy(x: 0, y: Self.pageHeight)
        ctx.scaleBy(x: 1, y: -1)

        var y: CGFloat = Self.marginTop
        let textWidth = Self.pageWidth - Self.marginLeft - Self.marginRight
        let maxY = Self.pageHeight - Self.marginBottom

        func newPage() {
            ctx.endPDFPage()
            ctx.beginPDFPage(nil)
            ctx.translateBy(x: 0, y: Self.pageHeight)
            ctx.scaleBy(x: 1, y: -1)
            y = Self.marginTop
        }

        func drawParagraph(_ string: String, indent: CGFloat) {
            let lines = Self.wrappedLines(string, maxChars: Self.monoCharsPerLine(forWidth: textWidth - indent))
            for line in lines {
                let lineHeight = Self.lineHeight(font: font) + Self.lineSpacing
                if y + lineHeight > maxY {
                    newPage()
                }
                let x = Self.marginLeft + indent
                let attrs: [CFString: Any] = [
                    kCTFontAttributeName: font,
                    kCTForegroundColorAttributeName: black,
                ]
                let attr = CFAttributedStringCreate(nil, line as CFString, attrs as CFDictionary)!
                let ctLine = CTLineCreateWithAttributedString(attr)
                ctx.textPosition = CGPoint(x: x, y: y)
                CTLineDraw(ctLine, ctx)
                y += lineHeight
            }
        }

        for block in script.titlePage {
            for (_, values) in block {
                for line in values where !line.isEmpty {
                    drawParagraph(line, indent: 0)
                }
            }
        }

        for element in script.elements {
            if element.elementText.range(of: #"^\s*$"#, options: .regularExpression) != nil,
               element.elementType != "Page Break" {
                continue
            }
            let text = pdfDisplayText(for: element, script: script)
            let indent = Self.indent(for: element.elementType)
            switch element.elementType {
            case "Transition":
                drawParagraph(text, indent: 0)
            default:
                drawParagraph(text, indent: indent)
            }
        }

        ctx.endPDFPage()
        ctx.closePDF()
        return mutableData as Data
    }

    private static func monoCharsPerLine(forWidth width: CGFloat) -> Int {
        max(10, Int(width / (fontSize * 0.6)))
    }

    private static func lineHeight(font: CTFont) -> CGFloat {
        CTFontGetAscent(font) + CTFontGetDescent(font) + CTFontGetLeading(font)
    }

    private static func wrappedLines(_ s: String, maxChars: Int) -> [String] {
        var result: [String] = []
        for chunk in s.components(separatedBy: "\n") {
            var line = chunk
            while line.count > maxChars {
                let idx = line.index(line.startIndex, offsetBy: maxChars)
                result.append(String(line[..<idx]))
                line = String(line[idx...])
            }
            if !line.isEmpty || chunk == "\n" {
                result.append(line)
            }
        }
        if result.isEmpty { result.append("") }
        return result
    }

    private static func indent(for type: String) -> CGFloat {
        switch type {
        case "Scene Heading", "Transition": return 0
        case "Character": return 180
        case "Parenthetical": return 162
        case "Dialogue": return 144
        case "Lyrics": return 144
        default: return 0
        }
    }

    private func pdfDisplayText(for element: FNElement, script: FNScript) -> String {
        var text = element.elementText
        switch element.elementType {
        case "Scene Heading":
            if !script.suppressSceneNumbers, let n = element.sceneNumber, !n.isEmpty,
               !text.contains("#\(n)#") {
                text = "\(text) #\(n)#"
            }
        case "Character":
            text = text.replacingOccurrences(of: #"^\s*@\s*"#, with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: #"\s*\^\s*$"#, with: "", options: .regularExpression)
        case "Lyrics":
            text = text.replacingOccurrences(of: #"^\s*~\s*"#, with: "", options: .regularExpression)
        case "Action":
            text = text.replacingOccurrences(of: #"^\s*!\s*"#, with: "", options: .regularExpression)
        default:
            break
        }
        return text
    }
}

#endif
