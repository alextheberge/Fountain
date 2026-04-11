//
//  FountainSceneHeadingMatcher.swift
//
//  Phase 3.5 / 11 — localized pattern match for standard slug lines (Swift `Regex` only).
//

import Foundation

public enum FountainSceneHeadingMatcher {
    /// Same rule as legacy ``FastFountainParser`` slug detection: INT/EXT/EST and I/E variants, case-insensitive.
    private static let standardSlugRegex: Regex<Substring> = {
        let p = "(?i)^(?:INT|EXT|EST|(?:I|INT)\\.?\\/?(?:E|EXT)\\.?)[\\.\\-\\s][^\\n]+$"
        do {
            return try Regex(p)
        } catch {
            preconditionFailure("Invalid scene heading regex: \(error)")
        }
    }()

    /// `true` when `line` is a **standard** scene heading (not forced `.` sluglines — use ``FountainForcedPrefixScanner`` for those).
    public static func matchesStandardSlugLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        return (try? standardSlugRegex.wholeMatch(in: t)) != nil
    }
}
