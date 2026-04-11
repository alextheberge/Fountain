//
//  FountainSceneHeadingMatcher.swift
//
//  Phase 3.5 — localized pattern match for standard slug lines (Swift `Regex` on newer OS; `NSRegularExpression` fallback for package deployment targets).
//

import Foundation

public enum FountainSceneHeadingMatcher {
    /// Legacy path: same pattern as ``FastFountainParser`` (INT/EXT/EST and I/E variants), case-insensitive.
    private static let legacyStandardSlugRegex: NSRegularExpression = {
        let p = "^(INT|EXT|EST|(I|INT)\\.?\\/?(E|EXT)\\.?)[\\.\\-\\s][^\\n]+$"
        return try! NSRegularExpression(pattern: p, options: .caseInsensitive)
    }()

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    private enum ModernSlugRegex {
        /// Non-capturing groups so the type is a plain whole-line `Regex<Substring>` (capturing groups would change `Match` output).
        static let value: Regex<Substring> = {
            let p = "(?i)^(?:INT|EXT|EST|(?:I|INT)\\.?\\/?(?:E|EXT)\\.?)[\\.\\-\\s][^\\n]+$"
            do {
                return try Regex(p)
            } catch {
                preconditionFailure("Invalid scene heading regex: \(error)")
            }
        }()
    }

    /// `true` when `line` is a **standard** scene heading (not forced `.` sluglines — use ``FountainForcedPrefixScanner`` for those).
    public static func matchesStandardSlugLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            return (try? ModernSlugRegex.value.wholeMatch(in: t)) != nil
        }
        let range = NSRange(t.startIndex..., in: t)
        return legacyStandardSlugRegex.firstMatch(in: t, options: [], range: range) != nil
    }
}
