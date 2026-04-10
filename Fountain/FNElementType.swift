//
//  FNElementType.swift
//
//  Canonical `elementType` strings emitted by `FastFountainParser` today, as a typed enum (Phase 2.1).
//  New parsers should prefer this over free-form strings at boundaries.
//

import Foundation

/// Structural element labels matching the legacy `FNElement.elementType` property.
///
/// Naming follows the parser’s English display strings for stable round-trip with existing documents.
/// For JSON and tooling, map through ``scriptElementKind`` to ``ScriptElementKind``.
public enum FNElementType: String, CaseIterable, Sendable {
    case sceneHeading = "Scene Heading"
    case action = "Action"
    case character = "Character"
    case dialogue = "Dialogue"
    case parenthetical = "Parenthetical"
    case transition = "Transition"
    case lyrics = "Lyrics"
    case sectionHeading = "Section Heading"
    case synopsis = "Synopsis"
    case pageBreak = "Page Break"
    case boneyard = "Boneyard"
    /// Inline `[[ note ]]` content from the fast parser (Fountain 1.1 notes).
    case comment = "Comment"
    case general = "General"
}

extension FNElementType {
    /// Interchange / Codable kind used in ``FountainDocument`` and JSON export.
    public var scriptElementKind: ScriptElementKind {
        switch self {
        case .sceneHeading: return .sceneHeading
        case .action: return .action
        case .character: return .character
        case .dialogue: return .dialogue
        case .parenthetical: return .parenthetical
        case .transition: return .transition
        case .lyrics: return .lyrics
        case .sectionHeading: return .sectionHeading
        case .synopsis: return .synopsis
        case .pageBreak: return .pageBreak
        case .boneyard: return .boneyard
        case .comment: return .comment
        case .general: return .general
        }
    }
}

extension ScriptElementKind {
    /// Best-effort reverse map for writers that emit legacy type strings.
    public var legacyElementTypeString: String? {
        switch self {
        case .sceneHeading: return FNElementType.sceneHeading.rawValue
        case .action: return FNElementType.action.rawValue
        case .character: return FNElementType.character.rawValue
        case .dialogue: return FNElementType.dialogue.rawValue
        case .parenthetical: return FNElementType.parenthetical.rawValue
        case .transition: return FNElementType.transition.rawValue
        case .lyrics: return FNElementType.lyrics.rawValue
        case .sectionHeading: return FNElementType.sectionHeading.rawValue
        case .synopsis: return FNElementType.synopsis.rawValue
        case .pageBreak: return FNElementType.pageBreak.rawValue
        case .boneyard: return FNElementType.boneyard.rawValue
        case .comment: return FNElementType.comment.rawValue
        case .general: return FNElementType.general.rawValue
        case .unknown: return nil
        }
    }
}
