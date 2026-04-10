//
//  FountainInlineMarkup.swift
//
//  Phase 6.2 — linear-scan inline emphasis (bold / italic / underline and Fountain-style combos)
//  without catastrophic-regex backtracking. Matches the delimiter pairs used by legacy HTML export.
//

import Foundation

/// Converts Fountain inline markers in a single line (or fragment) to a safe HTML string.
public enum FountainInlineMarkup {
    // MARK: - Public

    /// HTML equivalent of the legacy ``FNHTMLScript`` emphasis pass: `**bold**`, `*italic*`, `_underline_`, and combined `_***` / `***` forms.
    public static func htmlFragment(from source: String) -> String {
        var out = ""
        out.reserveCapacity(source.utf8.count + 24)
        var i = source.startIndex
        let end = source.endIndex

        while i < end {
            if source[i] == "\\" {
                let n = source.index(after: i)
                if n < end, source[n] == "*" {
                    out.append("*")
                    i = source.index(after: n)
                    continue
                }
            }

            if source[i] == "_" {
                if let j = consumeUnderscoreLedOpen(&out, source: source, i: i, end: end) {
                    i = j
                    continue
                }
                if let j = consumePlainUnderline(&out, source: source, i: i, end: end) {
                    i = j
                    continue
                }
            }

            if source[i] == "*" {
                if let j = consumeStarLedOpen(&out, source: source, i: i, end: end) {
                    i = j
                    continue
                }
                // Do not fall through to single-`*` italic while still sitting on the first `*` of `**` that failed validation.
                if source[i...].hasPrefix("**") {
                    appendEscapedChar(&out, "*")
                    i = source.index(after: i)
                    continue
                }
                if let j = consumeItalicSingleAsterisk(&out, source: source, i: i, end: end) {
                    i = j
                    continue
                }
            }

            appendEscapedChar(&out, source[i])
            i = source.index(after: i)
        }

        return out
    }

    // MARK: - Underscore-led (BIU, BU, IU)

    private static func consumeUnderscoreLedOpen(
        _ out: inout String,
        source: String,
        i: String.Index,
        end: String.Index
    ) -> String.Index? {
        for rule in FountainInlineDelimiterTable.underscoreLedEmphasis {
            guard source[i...].hasPrefix(rule.open) else { continue }
            let innerStart = source.index(i, offsetBy: rule.open.count)
            guard let closeStart = findClosingDelimiter(in: source, from: innerStart, end: end, candidates: [rule.close]) else {
                continue
            }
            let inner = source[innerStart..<closeStart]
            guard innerValidForLegacy(inner) else { continue }
            out.append(rule.htmlOpen)
            out.append(escapeHtml(inner))
            out.append(rule.htmlClose)
            return source.index(closeStart, offsetBy: rule.close.count)
        }
        return nil
    }

    // MARK: - Star-led (BIU mirror, BI, BU, B, I)

    private static func consumeStarLedOpen(
        _ out: inout String,
        source: String,
        i: String.Index,
        end: String.Index
    ) -> String.Index? {
        for rule in FountainInlineDelimiterTable.starLedEmphasis {
            guard source[i...].hasPrefix(rule.open) else { continue }
            let innerStart = source.index(i, offsetBy: rule.open.count)
            guard let closeStart = findClosingDelimiter(in: source, from: innerStart, end: end, candidates: [rule.close]) else {
                continue
            }
            let inner = source[innerStart..<closeStart]
            guard innerValidForLegacy(inner) else { continue }
            out.append(rule.htmlOpen)
            out.append(escapeHtml(inner))
            out.append(rule.htmlClose)
            return source.index(closeStart, offsetBy: rule.close.count)
        }
        return nil
    }

    private static func consumeItalicSingleAsterisk(
        _ out: inout String,
        source: String,
        i: String.Index,
        end: String.Index
    ) -> String.Index? {
        guard source[i] == "*" else { return nil }
        let innerStart = source.index(after: i)
        guard innerStart < end else { return nil }
        let close = FountainInlineDelimiterTable.italicSingleAsteriskClose
        guard let closeStart = findClosingDelimiter(in: source, from: innerStart, end: end, candidates: [close]) else {
            return nil
        }
        let inner = source[innerStart..<closeStart]
        guard innerValidForLegacy(inner) else { return nil }
        out.append("<em>")
        out.append(escapeHtml(inner))
        out.append("</em>")
        return source.index(after: closeStart)
    }

    // MARK: - Plain underline _word_

    private static func consumePlainUnderline(
        _ out: inout String,
        source: String,
        i: String.Index,
        end: String.Index
    ) -> String.Index? {
        guard source[i] == "_" else { return nil }
        let innerStart = source.index(after: i)
        guard innerStart < end else { return nil }
        var j = innerStart
        while j < end {
            if source[j] == "<" || source[j] == ">" { return nil }
            if source[j] == "_" {
                let inner = source[innerStart..<j]
                guard !inner.isEmpty, !inner.contains("_") else { return nil }
                out.append("<u>")
                out.append(escapeHtml(inner))
                out.append("</u>")
                return source.index(after: j)
            }
            j = source.index(after: j)
        }
        return nil
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
