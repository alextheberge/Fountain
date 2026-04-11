//
//  FountainInlineMarkup.swift
//
//  Phase 6.2 — linear-scan inline emphasis (bold / italic / underline and Fountain-style combos)
//  without catastrophic-regex backtracking. Matches the delimiter pairs used by legacy HTML export.
//

import Foundation

// MARK: - Phase 6.1 — plain vs rich entry point

/// Result of ``FountainInlineMarkup/renderInline(_:mode:)`` (see ``FountainInlineRenderingMode``).
public enum FountainInlineRenderResult: Sendable, Equatable {
    /// Markers such as `**` remain in the string (no inline transform).
    case plainMarkersPreserved(String)
    /// Parsed emphasis for SwiftUI / Text / AppKit hosts; see ``FountainInlineAttributedKeys/Underline``.
    case richAttributed(AttributedString)
}

/// Converts Fountain inline markers in a single line (or fragment) to HTML or `AttributedString`.
public enum FountainInlineMarkup {
    // MARK: - Public

    /// Phase 6.1 — choose **plain** (identity: keep markers in content) vs **rich** (``attributedFragment(from:)``).
    public static func renderInline(_ source: String, mode: FountainInlineRenderingMode) -> FountainInlineRenderResult {
        switch mode {
        case .preserveMarkersInPlaintext:
            return .plainMarkersPreserved(source)
        case .attributedStringFromInlineMarkup:
            return .richAttributed(attributedFragment(from: source))
        }
    }

    /// HTML equivalent of the legacy ``FNHTMLScript`` emphasis pass: `**bold**`, `*italic*`, `_underline_`, and combined `_***` / `***` forms.
    public static func htmlFragment(from source: String) -> String {
        var out = ""
        out.reserveCapacity(source.utf8.count + 24)
        scan(source) { event in
            switch event {
            case .plain(let ch):
                appendEscapedChar(&out, ch)
            case .styled(let inner, let rule):
                out.append(rule.htmlOpen)
                out.append(escapeHtml(inner))
                out.append(rule.htmlClose)
            case .italicOnly(let inner):
                out.append("<em>")
                out.append(escapeHtml(inner))
                out.append("</em>")
            case .underlineOnly(let inner):
                out.append("<u>")
                out.append(escapeHtml(inner))
                out.append("</u>")
            }
        }
        return out
    }

    /// Rich-text fragment using `InlinePresentationIntent` for bold / italic, and ``FountainInlineAttributedKeys/Underline`` for Fountain `_…_` underline (including underline-only spans). HTML remains the reference for `<u>` tags; UI layers should map ``FountainInlineAttributedKeys/Underline`` to platform underline when needed.
    public static func attributedFragment(from source: String) -> AttributedString {
        var result = AttributedString()
        scan(source) { event in
            switch event {
            case .plain(let ch):
                result.append(AttributedString(String(ch)))
            case .styled(let inner, let rule):
                appendStyled(&result, inner: inner, bold: rule.bold, italic: rule.italic, underline: rule.underline)
            case .italicOnly(let inner):
                appendStyled(&result, inner: inner, bold: false, italic: true, underline: false)
            case .underlineOnly(let inner):
                appendStyled(&result, inner: inner, bold: false, italic: false, underline: true)
            }
        }
        return result
    }

    // MARK: - Scan events (shared HTML + AttributedString)

    private enum ScanEvent {
        case plain(Character)
        case styled(Substring, FountainInlineDelimiterTable.EmphasisPair)
        case italicOnly(Substring)
        case underlineOnly(Substring)
    }

    private static func scan(_ source: String, emit: (ScanEvent) -> Void) {
        var i = source.startIndex
        let end = source.endIndex

        while i < end {
            if source[i] == "\\" {
                let n = source.index(after: i)
                if n < end, source[n] == "*" {
                    emit(.plain("*"))
                    i = source.index(after: n)
                    continue
                }
            }

            if source[i] == "_" {
                if let (j, inner, rule) = matchUnderscoreLed(source: source, i: i, end: end) {
                    emit(.styled(inner, rule))
                    i = j
                    continue
                }
                if let (j, inner) = matchPlainUnderline(source: source, i: i, end: end) {
                    emit(.underlineOnly(inner))
                    i = j
                    continue
                }
            }

            if source[i] == "*" {
                if let (j, inner, rule) = matchStarLed(source: source, i: i, end: end) {
                    emit(.styled(inner, rule))
                    i = j
                    continue
                }
                if source[i...].hasPrefix("**") {
                    emit(.plain("*"))
                    i = source.index(after: i)
                    continue
                }
                if let (j, inner) = matchItalicSingleAsterisk(source: source, i: i, end: end) {
                    emit(.italicOnly(inner))
                    i = j
                    continue
                }
            }

            emit(.plain(source[i]))
            i = source.index(after: i)
        }
    }

    // MARK: - Match helpers (return end index after closing delimiter)

    private static func matchUnderscoreLed(
        source: String,
        i: String.Index,
        end: String.Index
    ) -> (String.Index, Substring, FountainInlineDelimiterTable.EmphasisPair)? {
        for rule in FountainInlineDelimiterTable.underscoreLedEmphasis {
            guard source[i...].hasPrefix(rule.open) else { continue }
            let innerStart = source.index(i, offsetBy: rule.open.count)
            guard let closeStart = findClosingDelimiter(in: source, from: innerStart, end: end, candidates: [rule.close]) else {
                continue
            }
            let inner = source[innerStart..<closeStart]
            guard innerValidForLegacy(inner) else { continue }
            let afterClose = source.index(closeStart, offsetBy: rule.close.count)
            return (afterClose, inner, rule)
        }
        return nil
    }

    private static func matchStarLed(
        source: String,
        i: String.Index,
        end: String.Index
    ) -> (String.Index, Substring, FountainInlineDelimiterTable.EmphasisPair)? {
        for rule in FountainInlineDelimiterTable.starLedEmphasis {
            guard source[i...].hasPrefix(rule.open) else { continue }
            let innerStart = source.index(i, offsetBy: rule.open.count)
            guard let closeStart = findClosingDelimiter(in: source, from: innerStart, end: end, candidates: [rule.close]) else {
                continue
            }
            let inner = source[innerStart..<closeStart]
            guard innerValidForLegacy(inner) else { continue }
            let afterClose = source.index(closeStart, offsetBy: rule.close.count)
            return (afterClose, inner, rule)
        }
        return nil
    }

    private static func matchItalicSingleAsterisk(
        source: String,
        i: String.Index,
        end: String.Index
    ) -> (String.Index, Substring)? {
        guard source[i] == "*" else { return nil }
        let innerStart = source.index(after: i)
        guard innerStart < end else { return nil }
        let close = FountainInlineDelimiterTable.italicSingleAsteriskClose
        guard let closeStart = findClosingDelimiter(in: source, from: innerStart, end: end, candidates: [close]) else {
            return nil
        }
        let inner = source[innerStart..<closeStart]
        guard innerValidForLegacy(inner) else { return nil }
        let afterClose = source.index(after: closeStart)
        return (afterClose, inner)
    }

    private static func matchPlainUnderline(
        source: String,
        i: String.Index,
        end: String.Index
    ) -> (String.Index, Substring)? {
        guard source[i] == "_" else { return nil }
        let innerStart = source.index(after: i)
        guard innerStart < end else { return nil }
        var j = innerStart
        while j < end {
            if source[j] == "<" || source[j] == ">" { return nil }
            if source[j] == "_" {
                let inner = source[innerStart..<j]
                guard !inner.isEmpty, !inner.contains("_") else { return nil }
                return (source.index(after: j), inner)
            }
            j = source.index(after: j)
        }
        return nil
    }

    // MARK: - AttributedString

    private static func appendStyled(
        _ result: inout AttributedString,
        inner: Substring,
        bold: Bool,
        italic: Bool,
        underline: Bool
    ) {
        var piece = AttributedString(String(inner))
        var intent = InlinePresentationIntent()
        if bold { intent.insert(.stronglyEmphasized) }
        if italic { intent.insert(.emphasized) }
        if !intent.isEmpty {
            piece.inlinePresentationIntent = intent
        }
        if underline {
            piece[FountainInlineAttributedKeys.Underline.self] = true
        }
        result += piece
    }

    // MARK: - Scan helpers

    /// Legacy patterns forbid `<` / `>` inside emphasized spans.
    private static func innerValidForLegacy(_ inner: Substring) -> Bool {
        !inner.contains(where: { $0 == "<" || $0 == ">" })
    }

    private static func findClosingDelimiter(
        in source: String,
        from start: String.Index,
        end: String.Index,
        candidates: [String]
    ) -> String.Index? {
        var i = start
        let sorted = candidates.sorted { $0.count > $1.count }
        while i < end {
            if source[i] == "<" || source[i] == ">" { return nil }
            for c in sorted where source[i...].hasPrefix(c) {
                return i
            }
            i = source.index(after: i)
        }
        return nil
    }

    private static func appendEscapedChar(_ out: inout String, _ ch: Character) {
        switch ch {
        case "&": out.append("&amp;")
        case "<": out.append("&lt;")
        case ">": out.append("&gt;")
        default: out.append(ch)
        }
    }

    private static func escapeHtml(_ inner: Substring) -> String {
        var s = ""
        s.reserveCapacity(inner.count)
        for ch in inner {
            appendEscapedChar(&s, ch)
        }
        return s
    }
}
