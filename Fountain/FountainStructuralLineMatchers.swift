//
//  FountainStructuralLineMatchers.swift
//
//  Roadmap Phase 3.5 — localized line-shape checks (single-line) shared by the coarse tokenizer
//  and tests; they mirror ``FastFountainParser`` rules without whole-document regex passes.
//  **Polish:** page break, boneyard, bracket notes, transition `TO:`, and all-caps cues use string logic (no `NSRegularExpression`).
//

import Foundation

public enum FountainStructuralLineMatchers {
    public static func isPageBreakLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 3 else { return false }
        return t.allSatisfy { $0 == "=" }
    }

    /// `= synopsis text` (not a page-break line of three or more `=` alone).
    public static func isSynopsisLine(trimmedLine: String) -> Bool {
        !trimmedLine.isEmpty && trimmedLine.first == "="
    }

    public static func isSectionHeadingLine(trimmedLine: String) -> Bool {
        !trimmedLine.isEmpty && trimmedLine.first == "#"
    }

    public static func isBracketNoteLine(newlinesBefore: Int, line: String) -> Bool {
        guard newlinesBefore > 0 else { return false }
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("[[") else { return false }
        let searchFrom = t.index(t.startIndex, offsetBy: 2)
        guard searchFrom < t.endIndex,
              let closeRange = t.range(of: "]]", range: searchFrom ..< t.endIndex)
        else { return false }
        guard closeRange.upperBound == t.endIndex else { return false }

        let inner = t[searchFrom ..< closeRange.lowerBound]
        guard !inner.isEmpty else { return false }
        return !inner.contains("]") && !inner.contains("\n")
    }

    public static func isBoneyardOpenLine(_ line: String) -> Bool {
        line.hasPrefix("/*")
    }

    public static func isSingleLineBoneyard(_ line: String) -> Bool {
        isBoneyardOpenLine(line) && line.trimmingCharacters(in: .whitespaces).hasSuffix("*/")
    }

    public static func isBoneyardCloseLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasSuffix("*/")
    }

    /// Uppercase-style character cue: no lowercase letters, optional trailing ``(cont'd)`` / ``(CONT'D)`` (case-insensitive).
    public static func isAllCapsCharacterCue(_ line: String) -> Bool {
        var t = line.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        let suffix = "(cont'd)"
        if t.lowercased().hasSuffix(suffix) {
            t = String(t.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
        }
        guard !t.isEmpty else { return false }
        return !t.contains(where: { $0.isLetter && $0.isLowercase })
    }

    /// Line ends with ``TO:`` and has no lowercase letters (matches legacy ``[^a-z]*TO:$`` intent).
    public static func isTransitionEndingInTO(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.hasSuffix("TO:") else { return false }
        let before = t.dropLast("TO:".count)
        return !before.contains(where: { $0.isLetter && $0.isLowercase })
    }

    public static let knownTransitions: Set<String> = ["FADE OUT.", "CUT TO BLACK.", "FADE TO BLACK."]
}
