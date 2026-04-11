//
//  FountainInlineDelimiterTable.swift
//
//  Phase 6.3 — single source of truth for inline emphasis delimiter strings (Fountain / legacy HTML).
//  Keep styling literals here (not scattered across regex templates) so Wasm and other targets can share one module.
//

import Foundation

/// Ordered delimiter pairs for ``FountainInlineMarkup`` (open → close → HTML wrapper + rich-text flags).
public enum FountainInlineDelimiterTable: Sendable {
    public struct EmphasisPair: Sendable {
        public let open: String
        public let close: String
        public let htmlOpen: String
        public let htmlClose: String
        /// Maps to ``InlinePresentationIntent`` / underline when building `AttributedString`.
        public let bold: Bool
        public let italic: Bool
        public let underline: Bool

        public init(
            open: String,
            close: String,
            htmlOpen: String,
            htmlClose: String,
            bold: Bool,
            italic: Bool,
            underline: Bool
        ) {
            self.open = open
            self.close = close
            self.htmlOpen = htmlOpen
            self.htmlClose = htmlClose
            self.bold = bold
            self.italic = italic
            self.underline = underline
        }
    }

    /// Star-led forms: try in this order in the scanner (longest open first).
    public static let starLedEmphasis: [EmphasisPair] = [
        EmphasisPair(open: "***_", close: "_***", htmlOpen: "<strong><em><u>", htmlClose: "</u></em></strong>", bold: true, italic: true, underline: true),
        EmphasisPair(open: "***", close: "***", htmlOpen: "<strong><em>", htmlClose: "</em></strong>", bold: true, italic: true, underline: false),
        EmphasisPair(open: "**_", close: "_**", htmlOpen: "<strong><u>", htmlClose: "</u></strong>", bold: true, italic: false, underline: true),
        EmphasisPair(open: "**", close: "**", htmlOpen: "<strong>", htmlClose: "</strong>", bold: true, italic: false, underline: false),
    ]

    /// Underscore-led forms (BIU / BU / IU).
    public static let underscoreLedEmphasis: [EmphasisPair] = [
        EmphasisPair(open: "_***", close: "***_", htmlOpen: "<strong><em><u>", htmlClose: "</u></em></strong>", bold: true, italic: true, underline: true),
        EmphasisPair(open: "_**", close: "**_", htmlOpen: "<strong><u>", htmlClose: "</u></strong>", bold: true, italic: false, underline: true),
        EmphasisPair(open: "_*", close: "*_", htmlOpen: "<em><u>", htmlClose: "</u></em>", bold: false, italic: true, underline: true),
    ]

    /// Closing marker for single-asterisk italic (handled after multi-star rules fail).
    public static let italicSingleAsteriskClose: String = "*"
}
