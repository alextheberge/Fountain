//
//  FountainTextMeasuring.swift
//
//  Phase 8.5 — abstract screenplay line height measurement for ``FNPaginator`` (Apple implementation
//  in **FountainHTML**; pure-Swift pitch model here for tests and non-AppKit hosts).
//

import Foundation

/// Measures wrapped screenplay text height in **points-equivalent integer** space (same units as ``FNPaginator`` widths).
public protocol FountainTextMeasuring: Sendable {
    /// Vertical step per layout line (typically the nominal font point size, e.g. 12 for Courier 12).
    var layoutLineHeight: Int { get }

    /// Total height in the same integer units as ``layoutLineHeight`` (e.g. `lineCount * layoutLineHeight`).
    func heightForString(_ string: String, maxWidth: Int) -> Int
}

/// Courier-like monospaced wrap using `maxWidth / (fontSize * 0.6)` characters per line — matches ``FNPaginator``’s coarse pitch.
public struct CourierPitchMonospaceTextMeasurer: FountainTextMeasuring, Sendable {
    private let fontSize: Double
    private let charWidthRatio: Double

    public init(fontSizePoints: Double = 12, averageCharWidthToFontSize: Double = 0.6) {
        self.fontSize = fontSizePoints
        self.charWidthRatio = averageCharWidthToFontSize
    }

    public var layoutLineHeight: Int { Int(fontSize) }

    public func heightForString(_ string: String, maxWidth: Int) -> Int {
        let lh = max(1, layoutLineHeight)
        let maxChars = max(10, Int(Double(maxWidth) / (fontSize * charWidthRatio)))
        var lineCount = 0
        for paragraph in string.components(separatedBy: "\n") {
            if paragraph.isEmpty {
                lineCount += 1
                continue
            }
            var remaining = paragraph.count
            while remaining > 0 {
                remaining -= min(remaining, maxChars)
                lineCount += 1
            }
        }
        if lineCount == 0 { lineCount = 1 }
        return lineCount * lh
    }
}
