//
//  FountainTokenization.swift
//
//  Phase 3 foundation: line normalization and token-kind vocabulary for the future universal parser.
//

import Foundation

// MARK: - Line endings (Phase 3.2)

/// Normalizes Fountain source text to use `\n` only (Phase 3.2).
public enum FountainLineEndingNormalizer {
    /// Replaces CRLF and CR with LF so downstream line splitting is consistent.
    public static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
}

// MARK: - Token vocabulary (Phase 3.1)

/// Logical line classifications for a state-aware tokenizer (Phase 3 — universal parser).
///
/// This enum is the **vocabulary** only; the current production parser remains ``FastFountainParser``.
/// Expand cases as the tokenizer lands; keep raw values stable for logging and tests.
public enum FountainTokenKind: String, Sendable, CaseIterable {
    case blank
    case titlePageDirective
    case titlePageContinuation
    case sceneHeading
    case forcedSceneHeading
    case action
    case forcedAction
    case characterCue
    case forcedCharacterCue
    case dialogue
    case parenthetical
    case transition
    case forcedTransition
    case lyrics
    case sectionHeading
    case synopsis
    case pageBreak
    case boneyardOpen
    case boneyardClose
    case boneyardText
    case note
    case centeredText
    case dualDialogueSuffix
    case unknown
}
