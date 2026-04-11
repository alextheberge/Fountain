//
//  FountainIncrementalParse.swift
//
//  Phase 9.5 — warm re-parse entry point: full document parse today, stable ID merge, and documented
//  structural range expansion for future chunked tokenizer work.
//

import Foundation

/// How ``FNScript/parseIncremental(newText:editedUTF16Range:parser:)`` performed the parse.
public enum FountainIncrementalReparseStrategy: Sendable {
    /// The entire screenplay string was parsed with the selected ``FNParserType``.
    case fullDocument
}

/// Result of ``FNScript/parseIncremental(newText:editedUTF16Range:parser:)``.
public struct FountainIncrementalParseOutcome {
    public var script: FNScript
    /// UTF-16 half-open range in `newText` after expanding the edit to structural anchors (see ``FountainEditRangeExpansion``).
    public var expandedStructuralUTF16Range: Range<Int>
    public var reparseStrategy: FountainIncrementalReparseStrategy
}

extension FNScript {
    /// Reparses `newText` after an edit, preserving ``FNElement/id`` on a maximal matching **prefix** and
    /// **suffix** of elements where ``FNElement/elementType`` and ``FNElement/elementText`` match the
    /// previous parse snapshot (`self`).
    ///
    /// **Semantics (Phase 9.5 initial):** the implementation **always performs a full document parse** for
    /// correctness. `editedUTF16Range` is used only to compute ``FountainIncrementalParseOutcome/expandedStructuralUTF16Range``
    /// via ``FountainEditRangeExpansion/expandToStructuralAnchorUTF16Range(_:in:)`` — that span is the intended
    /// warm-path invalidation window once chunked merge lands (see ``docs/Fountain-Incremental-Parse-Spike``).
    ///
    /// - Parameters:
    ///   - newText: Full screenplay source after the edit.
    ///   - editedUTF16Range: Half-open UTF-16 offsets in `newText` covering the editor’s changed region.
    ///   - parser: Parser engine (``.tokenPipeline`` is supported for parity experiments).
    @discardableResult
    public func parseIncremental(
        newText: String,
        editedUTF16Range: Range<Int>,
        parser: FNParserType = .fast
    ) -> FountainIncrementalParseOutcome {
        let expanded = FountainEditRangeExpansion.expandToStructuralAnchorUTF16Range(
            editedUTF16Range,
            in: newText
        )
        let next = FNScript()
        next.loadString(newText, parser: parser)
        next.suppressSceneNumbers = suppressSceneNumbers
        Self.mergeStableElementIDs(from: elements, into: &next.elements)
        return FountainIncrementalParseOutcome(
            script: next,
            expandedStructuralUTF16Range: expanded,
            reparseStrategy: .fullDocument
        )
    }

    private static func mergeStableElementIDs(from old: [FNElement], into new: inout [FNElement]) {
        let n = new.count
        let o = old.count
        guard n > 0, o > 0 else { return }

        var prefix = 0
        while prefix < n, prefix < o,
            old[prefix].elementType == new[prefix].elementType,
            old[prefix].elementText == new[prefix].elementText
        {
            new[prefix].id = old[prefix].id
            prefix += 1
        }

        var suffix = 0
        while suffix < n - prefix, suffix < o - prefix,
            old[o - 1 - suffix].elementType == new[n - 1 - suffix].elementType,
            old[o - 1 - suffix].elementText == new[n - 1 - suffix].elementText
        {
            new[n - 1 - suffix].id = old[o - 1 - suffix].id
            suffix += 1
        }
    }
}
