//
//  FountainDialogueBlockRecognizer.swift
//
//  Phase 4.1 prototype — line roles inside a dialogue block (character → parenthetical(s) → dialogue).
//  Does not replace ``FastFountainParser``; use for tests and future tokenizer alignment.
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
            let t = line.trimmingCharacters(in: .whitespaces)
            switch phase {
            case .expectCharacter:
                out.append(.characterCue)
                phase = .afterCharacter
            case .afterCharacter:
                if t.hasPrefix("("), t.hasSuffix(")"), t.count >= 2 {
                    out.append(.parenthetical)
                } else {
                    out.append(.dialogue)
                    phase = .inDialogue
                }
            case .inDialogue:
                if t.hasPrefix("("), t.hasSuffix(")"), t.count >= 2 {
                    out.append(.parenthetical)
                } else {
                    out.append(.dialogue)
                }
            }
        }
        return out
    }
}
