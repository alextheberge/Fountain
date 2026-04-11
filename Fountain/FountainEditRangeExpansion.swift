//
//  FountainEditRangeExpansion.swift
//
//  Phase 9.5 — UTF-16 edit ranges expanded to full logical lines, then to coarse structural anchors
//  (blank lines and scene-heading-shaped lines) for future chunked re-parse. See
//  ``FNScript/parseIncremental(newText:editedUTF16Range:parser:)``.
//

import Foundation

/// Utilities for expanding UTF-16 edit ranges in a **Fountain source** string.
public enum FountainEditRangeExpansion: Sendable {
    /// Expands a UTF-16 half-open range so the result covers every **line** (per `NSString` / `NSText`
    /// line-breaking rules) that intersects the original range.
    public static func expandToFullLineUTF16Range(_ utf16Range: Range<Int>, in string: String) -> Range<Int> {
        let ns = string as NSString
        let len = ns.length
        guard len > 0 else { return 0..<0 }

        let lo = min(max(utf16Range.lowerBound, 0), len)
        let hi = min(max(utf16Range.upperBound, lo), len)

        func lineBounds(atUTF16 loc: Int) -> (start: Int, end: Int) {
            let loc = min(max(loc, 0), len - 1)
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            ns.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: loc, length: 0))
            return (lineStart, lineEnd)
        }

        if lo == len, hi == len {
            let b = lineBounds(atUTF16: len - 1)
            return b.start..<b.end
        }

        let bLo = lineBounds(atUTF16: min(lo, len - 1))
        let endCharIndex: Int =
            if hi > lo {
                min(hi - 1, len - 1)
            } else {
                min(lo, len - 1)
            }
        let bHi = lineBounds(atUTF16: max(0, endCharIndex))
        let start = min(bLo.start, bHi.start)
        let end = max(bLo.end, bHi.end)
        return start..<end
    }

    /// First expands with ``expandToFullLineUTF16Range(_:in:)``, then grows the UTF-16 span **line-wise**
    /// until the line **above** the span begins with a structural anchor (blank line or scene-heading-shaped
    /// text) or the start of the document is reached, and the line **below** the span ends before a structural
    /// anchor or the end of the document is reached.
    ///
    /// This is a **heuristic** for invalidation windows (not a full Fountain parse): forced slugs (`.INT. …`)
    /// count as scene-shaped; body lines that merely contain “INT.” mid-sentence may false-positive.
    public static func expandToStructuralAnchorUTF16Range(_ utf16Range: Range<Int>, in string: String) -> Range<Int> {
        let full = expandToFullLineUTF16Range(utf16Range, in: string)
        let ns = string as NSString
        let len = ns.length
        guard len > 0 else { return 0..<0 }

        var lineRanges: [NSRange] = []
        var scan = 0
        while scan < len {
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            ns.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: scan, length: 0))
            lineRanges.append(NSRange(location: lineStart, length: lineEnd - lineStart))
            scan = lineEnd
        }
        if lineRanges.isEmpty {
            lineRanges.append(NSRange(location: 0, length: 0))
        }

        func lineIndex(forUTF16 offset: Int) -> Int {
            let o = min(max(offset, 0), len)
            if o == len { return max(0, lineRanges.count - 1) }
            if let idx = lineRanges.firstIndex(where: { o >= $0.location && o < $0.location + $0.length }) {
                return idx
            }
            return max(0, lineRanges.count - 1)
        }

        var loLine = lineIndex(forUTF16: full.lowerBound)
        var hiLine = lineIndex(forUTF16: max(full.lowerBound, full.upperBound - 1))

        while loLine > 0 {
            let prev = ns.substring(with: lineRanges[loLine - 1])
            if isAnchorLine(prev) { break }
            loLine -= 1
        }

        while hiLine + 1 < lineRanges.count {
            let next = ns.substring(with: lineRanges[hiLine + 1])
            if isAnchorLine(next) { break }
            hiLine += 1
        }

        let start = lineRanges[loLine].location
        let end = NSMaxRange(lineRanges[hiLine])
        return start..<end
    }

    private static func isAnchorLine(_ rawLine: String) -> Bool {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        return looksLikeSceneHeading(trimmed)
    }

    private static func looksLikeSceneHeading(_ line: String) -> Bool {
        if line.hasPrefix(".") { return true }
        let u = line.uppercased()
        if u.hasPrefix("INT.") || u.hasPrefix("EXT.") { return true }
        if u.hasPrefix("INT./EXT.") || u.hasPrefix("INT/EXT.") { return true }
        if u.hasPrefix("I/E.") { return true }
        if u.hasPrefix("EST.") { return true }
        return false
    }
}
