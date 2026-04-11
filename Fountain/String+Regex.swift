//
//  String+Regex.swift
//
//  Copyright (c) 2012-2013 Nima Yousefi & John August
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

// Phase 11 — Prefer Swift `Regex`. When a pattern uses constructs Swift does not compile yet (e.g. negative
// lookbehind in ``ITALIC_PATTERN``), fall back to `NSRegularExpression` for that pattern only.

extension String {

    func isMatchedByRegex(_ pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let compiled = Self.compile(pattern: pattern, options: options) else { return false }
        switch compiled {
        case .swift(let regex):
            return firstMatch(of: regex) != nil
        case .foundation(let nsRegex, _):
            let range = NSRange(startIndex..., in: self)
            return nsRegex.firstMatch(in: self, options: [], range: range) != nil
        }
    }

    public func replacingOccurrencesOfRegex(
        _ pattern: String,
        withString template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let compiled = Self.compile(pattern: pattern, options: options) else { return self }
        switch compiled {
        case .swift(let regex):
            return replacing(regex) { m in
                Self.expandSwiftTemplate(template, match: m, in: self)
            }
        case .foundation(let nsRegex, _):
            let range = NSRange(startIndex..., in: self)
            return nsRegex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
        }
    }

    /// Returns an `NSRange` (UTF-16) for the first match of the pattern, or `NSNotFound` / zero length.
    func nsRangeOfRegex(_ pattern: String) -> NSRange {
        guard let compiled = Self.compile(pattern: pattern, options: []) else {
            return NSRange(location: NSNotFound, length: 0)
        }
        switch compiled {
        case .swift(let regex):
            guard let m = firstMatch(of: regex) else {
                return NSRange(location: NSNotFound, length: 0)
            }
            return NSRange(m.range, in: self)
        case .foundation(let nsRegex, _):
            let range = NSRange(startIndex..., in: self)
            return nsRegex.rangeOfFirstMatch(in: self, options: [], range: range)
        }
    }

    /// Returns the text of the specified capture group for the first match (same indexing as `NSRegularExpression`).
    func stringByMatching(_ pattern: String, capture: Int, options: NSRegularExpression.Options = []) -> String? {
        guard let compiled = Self.compile(pattern: pattern, options: options) else { return nil }
        switch compiled {
        case .swift(let regex):
            guard let m = firstMatch(of: regex) else { return nil }
            let caps = Self.captureStrings(from: m, in: self)
            guard capture >= 0, capture < caps.count else { return nil }
            return caps[capture]
        case .foundation(let nsRegex, _):
            let nsRange = NSRange(startIndex..., in: self)
            guard let match = nsRegex.firstMatch(in: self, options: [], range: nsRange) else { return nil }
            let capR = match.range(at: capture)
            guard capR.location != NSNotFound, let swiftR = Range(capR, in: self) else { return nil }
            return String(self[swiftR])
        }
    }

    /// Returns the text of the specified capture group for every match.
    public func componentsMatchedByRegex(_ pattern: String, capture: Int) -> [String] {
        guard let compiled = Self.compile(pattern: pattern, options: []) else { return [] }
        switch compiled {
        case .swift(let regex):
            return matches(of: regex).compactMap { m in
                let caps = Self.captureStrings(from: m, in: self)
                guard capture >= 0, capture < caps.count else { return nil }
                return caps[capture]
            }
        case .foundation(let nsRegex, _):
            let nsRange = NSRange(startIndex..., in: self)
            let matches = nsRegex.matches(in: self, options: [], range: nsRange)
            return matches.compactMap { match -> String? in
                let capR = match.range(at: capture)
                guard capR.location != NSNotFound, let swiftR = Range(capR, in: self) else { return nil }
                return String(self[swiftR])
            }
        }
    }

    // MARK: - Phase 11

    private enum CompiledRegex {
        case swift(Regex<AnyRegexOutput>)
        case foundation(NSRegularExpression, NSRegularExpression.Options)
    }

    /// Tries Swift `Regex` first (with inline `(?ims)` flags); if compilation fails, uses `NSRegularExpression`.
    private static func compile(pattern: String, options: NSRegularExpression.Options) -> CompiledRegex? {
        var flagLetters = ""
        if options.contains(.caseInsensitive) { flagLetters.append("i") }
        if options.contains(.anchorsMatchLines) { flagLetters.append("m") }
        if options.contains(.dotMatchesLineSeparators) { flagLetters.append("s") }
        let combined: String =
            if flagLetters.isEmpty {
                pattern
            } else {
                "(?\(flagLetters))\(pattern)"
            }
        if let r = try? Regex<AnyRegexOutput>(combined) {
            return .swift(r)
        }
        if let ns = try? NSRegularExpression(pattern: pattern, options: options) {
            return .foundation(ns, options)
        }
        return nil
    }

    private static func captureStrings(from match: Regex<AnyRegexOutput>.Match, in string: String) -> [String] {
        var out: [String] = []
        for cap in match.output {
            if let r = cap.range {
                out.append(String(string[r]))
            } else {
                out.append("")
            }
        }
        return out
    }

    private static func expandSwiftTemplate(_ template: String, match: Regex<AnyRegexOutput>.Match, in string: String) -> String {
        let caps = captureStrings(from: match, in: string)
        let sentinel = "\u{FFFC}\u{FFFD}\u{FFFC}"
        var t = template.replacingOccurrences(of: "$$", with: sentinel)
        if caps.isEmpty { return t.replacingOccurrences(of: sentinel, with: "$") }
        for i in stride(from: 9, through: 0, by: -1) where i < caps.count {
            t = t.replacingOccurrences(of: "$\(i)", with: caps[i])
        }
        return t.replacingOccurrences(of: sentinel, with: "$")
    }
}
