//
//  FountainInlineAttributedKeys.swift
//
//  Phase 6.2 — machine-readable underline on ``AttributedString`` without UIKit/AppKit in FountainCore.
//  SwiftUI / AppKit hosts can map this key to platform underline when building views from ``FountainInlineMarkup``.
//

import Foundation

/// Custom ``AttributedString`` attributes emitted by ``FountainInlineMarkup/attributedFragment(from:)``.
public enum FountainInlineAttributedKeys {
    /// `true` when the span used Fountain `_…_` underline (alone or combined with `*` emphasis).
    public struct Underline: CodableAttributedStringKey {
        public static let name = "fountain.inline.underline"
        public typealias Value = Bool
    }
}
