//
//  FountainLineToElementIndexMap.swift
//
//  Phase 9.4 — lightweight **line → element** lookup for tooling and future incremental parse.
//

import Foundation

/// Maps **0-based body line indices** to the owning element index in ``FNScript/elements``.
///
/// Each element contributes `1 + (count of U+000A in ``FNElement/elementText``)` logical lines, matching
/// how elements appear when stacked as rows separated by newlines (one visual row per line of text).
///
/// UTF-16 spans (``utf16HalfOpenRange(forBodyLine:)``) are measured in ``syntheticBodyLineText``:
/// ``FNElement/elementText`` values joined with a single U+000A between consecutive elements — the same
/// line count as logical body rows (including empty lines inside multiline element text).
public struct FountainLineToElementIndexMap: Sendable {
    private let lineToElementIndex: [Int]
    private let lineUTF16HalfOpenRanges: [(start: Int, end: Int)]
    private let syntheticBodyLineTextStorage: String

    /// Total number of logical lines across all elements (empty elements still count as one row).
    public var totalBodyLines: Int { lineToElementIndex.count }

    /// Canonical body string whose UTF-16 offsets align with ``utf16HalfOpenRange(forBodyLine:)``.
    public var syntheticBodyLineText: String { syntheticBodyLineTextStorage }

    public init(elements: [FNElement]) {
        let synthetic = elements.map(\.elementText).joined(separator: "\n")
        var map: [Int] = []
        var ranges: [(Int, Int)] = []
        var utf16Offset = 0
        let elementCount = elements.count
        for (ei, el) in elements.enumerated() {
            let parts = el.elementText.components(separatedBy: "\n")
            for (li, part) in parts.enumerated() {
                map.append(ei)
                let start = utf16Offset
                let end = utf16Offset + part.utf16.count
                ranges.append((start, end))
                utf16Offset = end
                let isLastLineOfElement = (li == parts.count - 1)
                let isLastElement = (ei == elementCount - 1)
                if !(isLastLineOfElement && isLastElement) {
                    utf16Offset += 1
                }
            }
        }
        self.lineToElementIndex = map
        self.lineUTF16HalfOpenRanges = ranges
        self.syntheticBodyLineTextStorage = synthetic
        assert(map.count == ranges.count)
        assert(utf16Offset == synthetic.utf16.count)
    }

    /// Owning element index for global body line `lineIndex`, or `nil` if out of range.
    public func elementIndex(forBodyLine lineIndex: Int) -> Int? {
        guard lineIndex >= 0, lineIndex < lineToElementIndex.count else { return nil }
        return lineToElementIndex[lineIndex]
    }

    /// UTF-16 half-open span `[lower, upper)` of logical body line `lineIndex` in ``syntheticBodyLineText``.
    public func utf16HalfOpenRange(forBodyLine lineIndex: Int) -> Range<Int>? {
        guard lineIndex >= 0, lineIndex < lineUTF16HalfOpenRanges.count else { return nil }
        let r = lineUTF16HalfOpenRanges[lineIndex]
        return r.start..<r.end
    }

    /// Same span as ``utf16HalfOpenRange(forBodyLine:)``, expressed in ``String/Index`` space of ``syntheticBodyLineText``.
    public func stringIndexRange(forBodyLine lineIndex: Int) -> Range<String.Index>? {
        guard let utf16 = utf16HalfOpenRange(forBodyLine: lineIndex) else { return nil }
        let s = syntheticBodyLineTextStorage
        guard utf16.lowerBound >= 0, utf16.upperBound <= s.utf16.count else { return nil }
        let start = String.Index(utf16Offset: utf16.lowerBound, in: s)
        let end = String.Index(utf16Offset: utf16.upperBound, in: s)
        return start..<end
    }
}
