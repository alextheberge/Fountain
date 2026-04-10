//
//  FountainForcedPrefix.swift
//
//  Roadmap Phase 3.4 — map Fountain 1.1 forced line prefixes to coarse ``FountainTokenKind`` values.
//  This mirrors the intent of `FastFountainParser` body rules without replacing that parser.
//

import Foundation

public enum FountainForcedPrefixScanner {
    /// If the line begins with a forced marker (after leading ASCII whitespace), returns the token kind
    /// the universal tokenizer should use before contextual rules run.
    ///
    /// - Note: `>` … `<` is classified as ``FountainTokenKind/centeredText`` to match the parser’s
    ///   centered-action path; a lone `>` line is ``FountainTokenKind/forcedTransition``.
    public static func forcedTokenKind(forLine line: String) -> FountainTokenKind? {
        let trimmed = String(line.drop(while: \.isWhitespace))
        guard let first = trimmed.first else { return nil }

        switch first {
        case "!":
            return .forcedAction
        case "@":
            return .forcedCharacterCue
        case "~":
            return .lyrics
        case ".":
            if trimmed.count > 1, trimmed.dropFirst().first != "." {
                return .forcedSceneHeading
            }
            return nil
        case ">":
            if trimmed.count > 1, trimmed.last == "<" {
                return .centeredText
            }
            return .forcedTransition
        default:
            return nil
        }
    }
}
