//
//  FountainScriptElementLineContent.swift
//  FountainUI — Phase 13.3: ``FountainInlineMarkup`` → SwiftUI ``Text`` via ``AttributedString``.
//

import FountainCore
import SwiftUI

/// Chooses plain vs ``FountainInlineMarkup/attributedFragment(from:)`` rows for ``FountainView``.
///
/// **Character** cues use plain ``Text`` + ``textCase(.uppercase)`` so emphasis markers are not reinterpreted as runs.
/// **Scene headings** with scene numbers stay plain (slug + `#…#` suffix). **Underline** uses
/// ``FountainInlineAttributedKeys/Underline`` on the attributed string; SwiftUI maps it where the platform supports
/// custom attribute keys (see Phase 13 roadmap — gaps vs HTML `<u>` are acceptable on older OSes).
public enum FountainUIScriptElementLineContent: Sendable {
    /// Kinds that should use ``FountainInlineMarkup/attributedFragment(from:)`` for body text.
    public static func usesAttributedInline(for kind: ScriptElementKind) -> Bool {
        switch kind {
        case .sceneHeading, .character, .pageBreak:
            return false
        case .action, .dialogue, .parenthetical, .lyrics, .transition, .sectionHeading, .synopsis, .boneyard, .comment, .general, .unknown:
            return true
        }
    }

    /// Primary line ``Text`` for a body ``ScriptElement`` (no scene-number suffix — handled by the row).
    @ViewBuilder
    public static func text(for element: ScriptElement) -> some View {
        if usesAttributedInline(for: element.kind) {
            Text(FountainInlineMarkup.attributedFragment(from: element.text))
        } else {
            Text(element.text)
        }
    }
}
