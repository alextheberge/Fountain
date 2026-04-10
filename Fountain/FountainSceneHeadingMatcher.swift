//
//  FountainSceneHeadingMatcher.swift
//
//  Phase 3.5 — localized pattern match for standard slug lines (hybrid path vs whole-document regex).
//

import Foundation

public enum FountainSceneHeadingMatcher {
    /// Same rule as ``FastFountainParser`` for INT/EXT/EST and I/E variants (single-line, trimmed).
    private static let standardSlugRegex: NSRegularExpression = {
        let p = "^(INT|EXT|EST|(I|INT)\\.?\\/(E|EXT)\\.?)[\\.\\-\\s][^\\n]+$"
        return try! NSRegularExpression(pattern: p, options: .caseInsensitive)
    }()

    /// `true` when `line` is a **standard** scene heading (not forced `.` sluglines — use ``FountainForcedPrefixScanner`` for those).
    public static func matchesStandardSlugLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        let range = NSRange(t.startIndex..., in: t)
        return standardSlugRegex.firstMatch(in: t, options: [], range: range) != nil
    }
}
