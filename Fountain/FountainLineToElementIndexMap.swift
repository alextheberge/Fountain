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
public struct FountainLineToElementIndexMap: Sendable {
    private let lineToElementIndex: [Int]

    /// Total number of logical lines across all elements (empty elements still count as one row).
    public var totalBodyLines: Int { lineToElementIndex.count }

    public init(elements: [FNElement]) {
        var map: [Int] = []
        for (idx, el) in elements.enumerated() {
            let newlineCount = el.elementText.reduce(0) { $0 + ($1 == "\n" ? 1 : 0) }
            let lines = max(1, newlineCount + 1)
            map.append(contentsOf: repeatElement(idx, count: lines))
        }
        self.lineToElementIndex = map
    }

    /// Owning element index for global body line `lineIndex`, or `nil` if out of range.
    public func elementIndex(forBodyLine lineIndex: Int) -> Int? {
        guard lineIndex >= 0, lineIndex < lineToElementIndex.count else { return nil }
        return lineToElementIndex[lineIndex]
    }
}
