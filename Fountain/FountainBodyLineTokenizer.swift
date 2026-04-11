//
//  FountainBodyLineTokenizer.swift
//
//  Roadmap Phase 3 — coarse **per-line** token stream for the body (after title-page strip),
//  mirroring ``FastFountainParser`` classification order without building ``FNElement`` values.
//

import Foundation

public enum FountainBodyLineTokenizer {
    /// Classifies each line of a body array (typically ``FountainLineSplitter/lines(from:)`` on the string returned by ``FountainTitlePagePrescan`` + leading `\n` from ``FastFountainParser``).
    public static func tokenize(lines: [String]) -> [FountainTokenizedLine] {
        var out: [FountainTokenizedLine] = []
        out.reserveCapacity(lines.count)

        var newlinesBefore = 0
        var index = -1
        var isCommentBlock = false
        var isInsideDialogueBlock = false
        var commentText = ""
        var lastNonBlankKind: FountainTokenKind?

        func append(_ lineIndex: Int, kind: FountainTokenKind, text: String) {
            out.append(FountainTokenizedLine(lineIndex: lineIndex, kind: kind, text: text))
            if kind != .blank {
                lastNonBlankKind = kind
            }
        }

        for line in lines {
            index += 1

            if !line.isEmpty, line.first == "~" {
                append(index, kind: .lyrics, text: line)
                newlinesBefore = 0
                continue
            }

            if !line.isEmpty, line.first == "!" {
                append(index, kind: .forcedAction, text: line)
                newlinesBefore = 0
                continue
            }

            if !line.isEmpty, line.first == "@" {
                append(index, kind: .forcedCharacterCue, text: line)
                newlinesBefore = 0
                isInsideDialogueBlock = true
                continue
            }

            if line.isMatchedByRegex("^\\s{2}$"), isInsideDialogueBlock {
                newlinesBefore = 0
                append(index, kind: .dialogue, text: line)
                continue
            }

            if line.isMatchedByRegex("^\\s{2,}$") {
                append(index, kind: .action, text: line)
                newlinesBefore = 0
                continue
            }

            if line.isEmpty, !isCommentBlock {
                isInsideDialogueBlock = false
                newlinesBefore += 1
                append(index, kind: .blank, text: "")
                continue
            }

            if FountainStructuralLineMatchers.isBoneyardOpenLine(line) {
                if FountainStructuralLineMatchers.isSingleLineBoneyard(line) {
                    isCommentBlock = false
                    append(index, kind: .boneyardText, text: line)
                    newlinesBefore = 0
                } else {
                    isCommentBlock = true
                    commentText += "\n"
                    append(index, kind: .boneyardOpen, text: line)
                }
                continue
            }

            if FountainStructuralLineMatchers.isBoneyardCloseLine(line) {
                let text = line.replacingOccurrences(of: "*/", with: "")
                if text.isEmpty || text.isMatchedByRegex("^\\s*$") {
                    commentText += text.trimmingCharacters(in: .whitespaces)
                }
                isCommentBlock = false
                append(index, kind: .boneyardClose, text: line)
                commentText = ""
                newlinesBefore = 0
                continue
            }

            if isCommentBlock {
                commentText += line + "\n"
                append(index, kind: .boneyardText, text: line)
                continue
            }

            if FountainStructuralLineMatchers.isPageBreakLine(line) {
                append(index, kind: .pageBreak, text: line)
                newlinesBefore = 0
                continue
            }

            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if FountainStructuralLineMatchers.isSynopsisLine(trimmedLine: trimmedLine) {
                append(index, kind: .synopsis, text: line)
                continue
            }

            if FountainStructuralLineMatchers.isBracketNoteLine(newlinesBefore: newlinesBefore, line: line) {
                append(index, kind: .note, text: line)
                continue
            }

            if FountainStructuralLineMatchers.isSectionHeadingLine(trimmedLine: trimmedLine) {
                newlinesBefore = 0
                let markupRange = line.nsRangeOfRegex("^\\s*#+")
                if markupRange.location != NSNotFound {
                    let text = (line as NSString).substring(from: markupRange.location + markupRange.length)
                    if text.isEmpty {
                        append(index, kind: .unknown, text: line)
                    } else {
                        append(index, kind: .sectionHeading, text: line)
                    }
                } else {
                    append(index, kind: .unknown, text: line)
                }
                continue
            }

            if line.count > 1, line.first == ".", line.dropFirst().first != "." {
                newlinesBefore = 0
                append(index, kind: .forcedSceneHeading, text: line)
                continue
            }

            if newlinesBefore > 0, FountainSceneHeadingMatcher.matchesStandardSlugLine(line) {
                newlinesBefore = 0
                append(index, kind: .sceneHeading, text: line)
                continue
            }

            if FountainStructuralLineMatchers.isTransitionEndingInTO(line) {
                newlinesBefore = 0
                append(index, kind: .transition, text: line)
                continue
            }

            let lineWithTrimmedLeading = line.replacingOccurrencesOfRegex("^\\s*", withString: "")
            if FountainStructuralLineMatchers.knownTransitions.contains(lineWithTrimmedLeading) {
                newlinesBefore = 0
                append(index, kind: .transition, text: line)
                continue
            }

            if !line.isEmpty, line.first == ">" {
                if line.count > 1, line.last == "<" {
                    append(index, kind: .centeredText, text: line)
                } else {
                    append(index, kind: .forcedTransition, text: line)
                }
                newlinesBefore = 0
                continue
            }

            if newlinesBefore > 0, FountainStructuralLineMatchers.isAllCapsCharacterCue(line) {
                let nextIndex = index + 1
                if nextIndex < lines.count {
                    let nextLine = lines[nextIndex]
                    if !nextLine.isEmpty {
                        newlinesBefore = 0
                        append(index, kind: .characterCue, text: line)
                        isInsideDialogueBlock = true
                        continue
                    }
                }
            }

            if isInsideDialogueBlock {
                if newlinesBefore == 0, line.isMatchedByRegex("^\\s*\\(") {
                    append(index, kind: .parenthetical, text: line)
                } else {
                    append(index, kind: .dialogue, text: line)
                }
                continue
            }

            if newlinesBefore == 0, lastNonBlankKind != nil {
                append(index, kind: .action, text: line)
                newlinesBefore = 0
                continue
            }

            append(index, kind: .action, text: line)
            newlinesBefore = 0
        }

        return out
    }

    /// Convenience: normalize, extract title page, prepend `\n` to the body remainder, split lines, then ``tokenize(lines:)``.
    public static func tokenizeBodyAfterTitlePrescan(rawDocument: String) -> (titlePage: [[String: [String]]], tokens: [FountainTokenizedLine]) {
        let prepared = FountainTitlePagePrescan.normalizeLikeFastParser(rawDocument)
        let (titlePage, remainder) = FountainTitlePagePrescan.extractTitlePage(fromPreparedContents: prepared)
        let body = "\n" + remainder
        let lines = FountainLineSplitter.lines(from: body, normalizeLineEndings: false)
        return (titlePage, tokenize(lines: lines))
    }
}
