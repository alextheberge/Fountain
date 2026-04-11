//
//  FountainScriptElementTypography.swift
//  FountainUI — Phase 13: native SwiftUI typography for ``ScriptElementKind``.
//

import FountainCore
import SwiftUI

/// Fonts and alignment for screenplay rows (matches HTML/PDF emphasis hierarchy loosely; see roadmap Phase 13).
public enum FountainScriptElementTypography: Sendable {
    public static func font(for kind: ScriptElementKind) -> Font {
        switch kind {
        case .sceneHeading:
            return .body.weight(.semibold)
        case .character:
            return .body.weight(.medium)
        case .dialogue, .lyrics:
            return .body
        case .parenthetical:
            return .callout
        case .transition:
            return .body.weight(.medium)
        case .action, .sectionHeading, .synopsis, .comment, .boneyard, .pageBreak, .general, .unknown:
            return .body
        }
    }

    public static func multilineAlignment(for element: ScriptElement) -> TextAlignment {
        if element.kind == .transition {
            return .trailing
        }
        if element.kind == .character {
            return .center
        }
        return .leading
    }

    /// Horizontal alignment in parent stack (dual-dialogue right column uses trailing).
    public static func frameAlignment(for element: ScriptElement) -> HorizontalAlignment {
        if element.kind == .transition {
            return .trailing
        }
        if element.kind == .character, dualDialogueColumn(element) == 1 {
            return .trailing
        }
        return .leading
    }

    public static func paddingLeading(for element: ScriptElement) -> CGFloat {
        switch element.kind {
        case .dialogue, .parenthetical, .lyrics:
            return dualDialogueColumn(element) == 1 ? 28 : 14
        case .character:
            return dualDialogueColumn(element) == 1 ? 14 : 0
        default:
            return 0
        }
    }

    public static func paddingTop(for kind: ScriptElementKind) -> CGFloat {
        switch kind {
        case .sceneHeading, .sectionHeading:
            return 10
        case .character:
            return 8
        case .transition:
            return 10
        default:
            return 2
        }
    }

    /// `0` = left column, `1` = right column in a dual block; `nil` if not in dual dialogue.
    public static func dualDialogueColumn(_ element: ScriptElement) -> Int? {
        guard element.metadata[FountainMetadataKey.dualDialogue.rawValue] == "true" else { return nil }
        guard let raw = element.metadata[FountainMetadataKey.dualDialogueColumn.rawValue],
              let v = Int(raw)
        else { return nil }
        return v
    }
}
