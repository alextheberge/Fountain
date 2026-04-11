//
//  FountainStructuralLineMatchers.swift
//
//  Roadmap Phase 3.5 — localized line-shape checks (single-line) shared by the coarse tokenizer
//  and tests; they mirror ``FastFountainParser`` rules without whole-document regex passes.
//

import Foundation

public enum FountainStructuralLineMatchers {
    public static func isPageBreakLine(_ line: String) -> Bool {
        line.isMatchedByRegex("^={3,}\\s*$")
    }

    /// `= synopsis text` (not a page-break line of three or more `=` alone).
    public static func isSynopsisLine(trimmedLine: String) -> Bool {
        !trimmedLine.isEmpty && trimmedLine.first == "="
    }

    public static func isSectionHeadingLine(trimmedLine: String) -> Bool {
        !trimmedLine.isEmpty && trimmedLine.first == "#"
    }

    public static func isBracketNoteLine(newlinesBefore: Int, line: String) -> Bool {
        newlinesBefore > 0 && line.isMatchedByRegex("^\\s*\\[{2}\\s*([^\\]\\n])+\\s*\\]{2}\\s*$")
    }

    public static func isBoneyardOpenLine(_ line: String) -> Bool {
        line.isMatchedByRegex("^\\/\\*")
    }

    public static func isSingleLineBoneyard(_ line: String) -> Bool {
        line.isMatchedByRegex("^\\/\\*") && line.isMatchedByRegex("\\*\\/\\s*$")
    }

    public static func isBoneyardCloseLine(_ line: String) -> Bool {
        line.isMatchedByRegex("\\*\\/\\s*$")
    }

    public static func isAllCapsCharacterCue(_ line: String) -> Bool {
        line.isMatchedByRegex("^[^a-z]+(\\(cont'd\\))?$")
    }

    public static func isTransitionEndingInTO(_ line: String) -> Bool {
        line.isMatchedByRegex("[^a-z]*TO:$")
    }

    public static let knownTransitions: Set<String> = ["FADE OUT.", "CUT TO BLACK.", "FADE TO BLACK."]
}
