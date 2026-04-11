//
//  FastFountainParser.swift
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

public class FastFountainParser {
    public var elements: [FNElement] = []
    public var titlePage: [[String: [String]]] = []

    public init(string: String) {
        parseContents(string)
    }

    public init(file filePath: String) {
        guard let contents = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            print("Couldn't read the file \(filePath)")
            return
        }
        parseContents(contents)
    }

    // MARK: - Private

    private func parseContents(_ rawContents: String) {
        let prepared = FountainTitlePagePrescan.normalizeLikeFastParser(rawContents)
        let (parsedTitle, remainder) = FountainTitlePagePrescan.extractTitlePage(fromPreparedContents: prepared)
        titlePage = parsedTitle

        // ----------------------------------------------------------------------
        // BODY
        // ----------------------------------------------------------------------
        let contents = "\n" + remainder
        let lines = contents.components(separatedBy: CharacterSet.newlines)

        var newlinesBefore = 0
        var index = -1
        var isCommentBlock = false
        var isInsideDialogueBlock = false
        var commentText = ""

        for line in lines {
            index += 1

            // Lyrics: lines starting with ~
            if !line.isEmpty && line.first == "~" {
                let lastElement = elements.last
                if lastElement == nil {
                    elements.append(FNElement.element(ofType: "Lyrics", text: line))
                    newlinesBefore = 0
                    continue
                }
                if lastElement?.elementType == "Lyrics" && newlinesBefore > 0 {
                    elements.append(FNElement.element(ofType: "Lyrics", text: " "))
                }
                elements.append(FNElement.element(ofType: "Lyrics", text: line))
                newlinesBefore = 0
                continue
            }

            // Forced action: lines starting with !
            if !line.isEmpty && line.first == "!" {
                elements.append(FNElement.element(ofType: "Action", text: line))
                newlinesBefore = 0
                continue
            }

            // Forced character: lines starting with @
            if !line.isEmpty && line.first == "@" {
                elements.append(FNElement.element(ofType: "Character", text: line))
                newlinesBefore = 0
                isInsideDialogueBlock = true
                continue
            }

            // Empty lines within dialogue -- denoted by two spaces inside a dialogue block
            if line.isMatchedByRegex("^\\s{2}$") && isInsideDialogueBlock {
                newlinesBefore = 0
                let lastIndex = elements.count - 1
                var previousElement = elements[lastIndex]
                if previousElement.elementType == "Dialogue" {
                    previousElement.elementText = "\(previousElement.elementText)\n\(line)"
                    elements[lastIndex] = previousElement
                } else {
                    elements.append(FNElement.element(ofType: "Dialogue", text: line))
                }
                continue
            }

            // Whitespace-only lines are not standalone Action (Fountain 1.1 / roadmap Phase 4.6 — use `!` for forced action).
            if line.isMatchedByRegex("^\\s+$") {
                if isInsideDialogueBlock {
                    newlinesBefore = 0
                    let lastIndex = elements.count - 1
                    var previousElement = elements[lastIndex]
                    if previousElement.elementType == "Dialogue" {
                        previousElement.elementText = "\(previousElement.elementText)\n\(line)"
                        elements[lastIndex] = previousElement
                    } else {
                        elements.append(FNElement.element(ofType: "Dialogue", text: line))
                    }
                    continue
                }
                isInsideDialogueBlock = false
                newlinesBefore += 1
                continue
            }

            // Blank line
            if line.isEmpty && !isCommentBlock {
                isInsideDialogueBlock = false
                newlinesBefore += 1
                continue
            }

            // Open Boneyard /*
            if line.isMatchedByRegex("^\\/\\*") {
                if line.isMatchedByRegex("\\*\\/\\s*$") {
                    // Single-line boneyard
                    let text = line
                        .replacingOccurrences(of: "/*", with: "")
                        .replacingOccurrences(of: "*/", with: "")
                    isCommentBlock = false
                    elements.append(FNElement.element(ofType: "Boneyard", text: text))
                    newlinesBefore = 0
                } else {
                    isCommentBlock = true
                    commentText += "\n"
                }
                continue
            }

            // Close Boneyard */
            if line.isMatchedByRegex("\\*\\/\\s*$") {
                let text = line.replacingOccurrences(of: "*/", with: "")
                if text.isEmpty || text.isMatchedByRegex("^\\s*$") {
                    commentText += text.trimmingCharacters(in: .whitespaces)
                }
                isCommentBlock = false
                elements.append(FNElement.element(ofType: "Boneyard", text: commentText))
                commentText = ""
                newlinesBefore = 0
                continue
            }

            // Inside Boneyard
            if isCommentBlock {
                commentText += line + "\n"
                continue
            }

            // Page Break -- three or more '=' signs
            if line.isMatchedByRegex("^={3,}\\s*$") {
                elements.append(FNElement.element(ofType: "Page Break", text: line))
                newlinesBefore = 0
                continue
            }

            // Synopsis -- a single '=' at the start of the line
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if !trimmedLine.isEmpty && trimmedLine.first == "=" {
                let markupRange = line.nsRangeOfRegex("^\\s*={1}")
                let text: String
                if markupRange.location != NSNotFound {
                    text = (line as NSString).substring(from: markupRange.location + markupRange.length)
                } else {
                    text = line
                }
                elements.append(FNElement.element(ofType: "Synopsis", text: text))
                continue
            }

            // Comment -- double brackets [[Comment]]
            if newlinesBefore > 0 && line.isMatchedByRegex("^\\s*\\[{2}\\s*([^\\]\\n])+\\s*\\]{2}\\s*$") {
                let text = line
                    .replacingOccurrences(of: "[[", with: "")
                    .replacingOccurrences(of: "]]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                elements.append(FNElement.element(ofType: "Comment", text: text))
                continue
            }

            // Section heading -- one or more '#' at the start of the line
            if !trimmedLine.isEmpty && trimmedLine.first == "#" {
                newlinesBefore = 0
                let markupRange = line.nsRangeOfRegex("^\\s*#+")
                if markupRange.location != NSNotFound {
                    let depth = markupRange.length
                    let text = (line as NSString).substring(from: markupRange.location + markupRange.length)
                    if text.isEmpty {
                        print("Error in the Section Heading")
                        continue
                    }
                    var element = FNElement.element(ofType: "Section Heading", text: text)
                    element.sectionDepth = depth
                    elements.append(element)
                }
                continue
            }

            // Forced scene heading -- a single '.' at the start of a line (not '..')
            if line.count > 1 && line.first == "." && line.dropFirst().first != "." {
                newlinesBefore = 0
                var sceneNumber: String? = nil
                var text: String
                if line.isMatchedByRegex("#([^\\n#]*?)#\\s*$") {
                    sceneNumber = line.stringByMatching("#([^\\n#]*?)#\\s*$", capture: 1)
                    text = line.replacingOccurrencesOfRegex("#([^\\n#]*?)#\\s*$", withString: "")
                    text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
                } else {
                    text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                var element = FNElement.element(ofType: "Scene Heading", text: text)
                element.sceneNumber = sceneNumber
                elements.append(element)
                continue
            }

            // Scene Headings -- must be preceded by a blank line
            if newlinesBefore > 0 && line.isMatchedByRegex(
                "^(INT|EXT|EST|(I|INT)\\.?\\/(E|EXT)\\.?)[\\.\\-\\s][^\\n]+$",
                options: .caseInsensitive
            ) {
                newlinesBefore = 0
                var sceneNumber: String? = nil
                var text: String
                if line.isMatchedByRegex("#([^\\n#]*?)#\\s*$") {
                    sceneNumber = line.stringByMatching("#([^\\n#]*?)#\\s*$", capture: 1)
                    text = line.replacingOccurrencesOfRegex("#([^\\n#]*?)#\\s*$", withString: "")
                } else {
                    text = line
                }
                var element = FNElement.element(ofType: "Scene Heading", text: text)
                element.sceneNumber = sceneNumber
                elements.append(element)
                continue
            }

            // Transitions (anything ending in TO:)
            if line.isMatchedByRegex("[^a-z]*TO:$") {
                newlinesBefore = 0
                elements.append(FNElement.element(ofType: "Transition", text: line))
                continue
            }

            // Known hard-coded transitions
            let lineWithTrimmedLeading = line.replacingOccurrencesOfRegex("^\\s*", withString: "")
            let knownTransitions: Set<String> = ["FADE OUT.", "CUT TO BLACK.", "FADE TO BLACK."]
            if knownTransitions.contains(lineWithTrimmedLeading) {
                newlinesBefore = 0
                elements.append(FNElement.element(ofType: "Transition", text: line))
                continue
            }

            // Forced transitions -- lines starting with >
            if !line.isEmpty && line.first == ">" {
                if line.count > 1 && line.last == "<" {
                    // Centered text: > text <
                    var text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                    text = String(text.dropLast()).trimmingCharacters(in: .whitespaces)
                    var element = FNElement.element(ofType: "Action", text: text)
                    element.isCentered = true
                    elements.append(element)
                    newlinesBefore = 0
                    continue
                } else {
                    let text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                    elements.append(FNElement.element(ofType: "Transition", text: text))
                    newlinesBefore = 0
                    continue
                }
            }

            // Character -- all-caps, preceded by a blank line, followed by a non-blank line
            if newlinesBefore > 0 && line.isMatchedByRegex("^[^a-z]+(\\(cont'd\\))?$") {
                let nextIndex = index + 1
                if nextIndex < lines.count {
                    let nextLine = lines[nextIndex]
                    if !nextLine.isEmpty {
                        newlinesBefore = 0
                        var element = FNElement.element(ofType: "Character", text: line)

                        if line.isMatchedByRegex("\\^\\s*$") {
                            element.isDualDialogue = true
                            element.dualDialogueColumn = 1
                            element.elementText = element.elementText
                                .replacingOccurrencesOfRegex("\\s*\\^\\s*$", withString: "")
                            // Walk back to find the previous Character and mark it dual dialogue
                            var foundPreviousCharacter = false
                            var searchIndex = elements.count - 1
                            while searchIndex >= 0 && !foundPreviousCharacter {
                                var previousElement = elements[searchIndex]
                                if previousElement.elementType == "Character" {
                                    previousElement.isDualDialogue = true
                                    previousElement.dualDialogueColumn = 0
                                    elements[searchIndex] = previousElement
                                    foundPreviousCharacter = true
                                }
                                searchIndex -= 1
                            }
                        }

                        elements.append(element)
                        isInsideDialogueBlock = true
                        continue
                    }
                }
            }

            // Dialogue and Parentheticals
            if isInsideDialogueBlock {
                if newlinesBefore == 0 && line.isMatchedByRegex("^\\s*\\(") {
                    elements.append(FNElement.element(ofType: "Parenthetical", text: line))
                    continue
                } else {
                    let lastIndex = elements.count - 1
                    var previousElement = elements[lastIndex]
                    if previousElement.elementType == "Dialogue" {
                        previousElement.elementText = "\(previousElement.elementText)\n\(line)"
                        elements[lastIndex] = previousElement
                    } else {
                        elements.append(FNElement.element(ofType: "Dialogue", text: line))
                    }
                    continue
                }
            }

            // Lines not separated by blank lines are merged with the previous element
            if newlinesBefore == 0 && !elements.isEmpty {
                let lastIndex = elements.count - 1
                var previousElement = elements[lastIndex]
                // Scene Heading must be surrounded by blank lines
                if previousElement.elementType == "Scene Heading" {
                    previousElement.elementType = "Action"
                }
                previousElement.elementText = "\(previousElement.elementText)\n\(line)"
                elements[lastIndex] = previousElement
                newlinesBefore = 0
                continue
            } else {
                elements.append(FNElement.element(ofType: "Action", text: line))
                newlinesBefore = 0
                continue
            }
        }
    }
}
