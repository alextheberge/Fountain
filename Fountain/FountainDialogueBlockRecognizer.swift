//
//  FountainDialogueBlockRecognizer.swift
//
//  Phase 4.1 — line roles inside a dialogue block (character → parenthetical(s) → dialogue).
//  Parenthetical detection uses the same leading-`(` rule as ``FastFountainParser``. Does not replace the fast parser.
//

import Foundation

public enum FountainDialogueBlockRecognizer {
    public enum LineRole: String, Sendable, Equatable {
        case characterCue
        case parenthetical
        case dialogue
        case blank
    }

    /// Classifies lines in a dialogue block. Blank lines reset to expecting a character cue.
    public static func lineRoles(forNormalizedLines lines: [String]) -> [LineRole] {
        enum Phase {
            case expectCharacter
            case afterCharacter
            case inDialogue
        }
        var phase = Phase.expectCharacter
        var out: [LineRole] = []
        for line in lines {
            if line.isEmpty {
                out.append(.blank)
                phase = .expectCharacter
                continue
            }
            switch phase {
            case .expectCharacter:
                out.append(.characterCue)
                phase = .afterCharacter
            case .afterCharacter:
                if line.isMatchedByRegex("^\\s*\\(") {
                    out.append(.parenthetical)
                } else {
                    out.append(.dialogue)
                    phase = .inDialogue
                }
            case .inDialogue:
                if line.isMatchedByRegex("^\\s*\\(") {
                    out.append(.parenthetical)
                } else {
                    out.append(.dialogue)
                }
            }
        }
        return out
    }
}
