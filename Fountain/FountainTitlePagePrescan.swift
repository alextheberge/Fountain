//
//  FountainTitlePagePrescan.swift
//
//  Roadmap Phase 3.3 — title-page region detection and parsing **before** body tokenization,
//  shared with ``FastFountainParser`` so tooling and tests use one implementation.
//

import Foundation

public enum FountainTitlePagePrescan {
    fileprivate static let kInlinePattern = "^([^\\t\\s][^:]+):\\s*([^\\t\\s].*$)"
    fileprivate static let kDirectivePattern = "^([^\\t\\s][^:]+):([\\t\\s]*$)"

    /// Trims leading whitespace, normalizes line endings to `\n`, appends `\n\n` — same preparation as ``FastFountainParser``.
    public static func normalizeLikeFastParser(_ rawContents: String) -> String {
        var contents = rawContents.replacingOccurrencesOfRegex("^\\s*", withString: "")
        contents = contents.replacingOccurrencesOfRegex("\\r\\n|\\r|\\n", withString: "\n")
        contents += "\n\n"
        return contents
    }

    /// Text before the first `\n\n` in **prepared** content (see ``normalizeLikeFastParser(_:)``).
    public static func topSegmentBeforeFirstBlankLine(preparedContents: String) -> String {
        let ns = preparedContents as NSString
        let r = ns.range(of: "\n\n")
        if r.location != NSNotFound {
            return ns.substring(to: r.location)
        }
        return preparedContents
    }

    /// `false` when the only non-empty line before the first blank line is a lone `Key:` directive (e.g. `FADE IN:`) with no inline value — that must stay in the body.
    public static func shouldParseStructuredTitlePage(topOfDocument: String) -> Bool {
        let nonEmptyTopLines = topOfDocument.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        if nonEmptyTopLines.count == 1,
           let only = nonEmptyTopLines.first,
           only.isMatchedByRegex(kDirectivePattern),
           !only.isMatchedByRegex(kInlinePattern) {
            return false
        }
        return true
    }

    /// Parses an initial title page when present; returns the same `[[String: [String]]]` shape as ``FNScript/titlePage`` and the remainder string (post-strip) that the fast parser feeds into the body loop **before** it prepends `\n`.
    public static func extractTitlePage(fromPreparedContents preparedContents: String) -> (titlePage: [[String: [String]]], bodyRemainder: String) {
        let topOfDocument = topSegmentBeforeFirstBlankLine(preparedContents: preparedContents)

        guard shouldParseStructuredTitlePage(topOfDocument: topOfDocument) else {
            return ([], preparedContents)
        }

        var titlePage: [[String: [String]]] = []
        var foundTitlePage = false
        var openKey = ""
        var openValues: [String] = []
        let topLines = topOfDocument.components(separatedBy: "\n")

        for line in topLines {
            if line.isEmpty || line.isMatchedByRegex(kDirectivePattern) {
                foundTitlePage = true
                if !openKey.isEmpty {
                    titlePage.append([openKey: openValues])
                }
                openKey = line.stringByMatching(kDirectivePattern, capture: 1)?.lowercased() ?? ""
                if openKey == "author" { openKey = "authors" }
                openValues = []
            } else if line.isMatchedByRegex(kInlinePattern) {
                foundTitlePage = true
                if !openKey.isEmpty {
                    titlePage.append([openKey: openValues])
                    openKey = ""
                    openValues = []
                }
                var key = line.stringByMatching(kInlinePattern, capture: 1)?.lowercased() ?? ""
                let value = line.stringByMatching(kInlinePattern, capture: 2) ?? ""
                if key == "author" { key = "authors" }
                titlePage.append([key: [value]])
                openKey = ""
                openValues = []
            } else if foundTitlePage {
                openValues.append(line.trimmingCharacters(in: .whitespaces))
            }
        }

        guard foundTitlePage else {
            return ([], preparedContents)
        }

        if openKey.isEmpty && openValues.isEmpty && titlePage.isEmpty {
            return ([], preparedContents)
        }

        if !openKey.isEmpty {
            titlePage.append([openKey: openValues])
        }

        let remainder = preparedContents.replacingOccurrences(of: topOfDocument, with: "")
        return (titlePage, remainder)
    }
}
