//
//  FountainParser.swift
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
//  Legacy regex-based parser. Prefer FastFountainParser for new code.
//

import Foundation

public class FountainParser {

    // MARK: - Body parsing

    public static func parseBody(ofString string: String) -> [FNElement] {
        var scriptContent = bodyOfString(string)

        // Three-pass parsing method.
        // 1st: handle block comments (escape newlines inside them)
        // 2nd: regex blast to convert content to intermediate XML-like markup
        // 3rd: walk the markup and build FNElement array

        // 1st pass - Block comments
        let blockCommentMatches = scriptContent.componentsMatchedByRegex(BLOCK_COMMENT_PATTERN, capture: 1)
        for blockComment in blockCommentMatches {
            let modifiedBlock = blockComment.replacingOccurrences(of: "\n", with: NEWLINE_REPLACEMENT)
            scriptContent = scriptContent.replacingOccurrences(of: blockComment, with: modifiedBlock, options: .caseInsensitive)
        }
        let bracketCommentMatches = scriptContent.componentsMatchedByRegex(BRACKET_COMMENT_PATTERN, capture: 1)
        for bracketComment in bracketCommentMatches {
            let modifiedBlock = bracketComment.replacingOccurrences(of: "\n", with: NEWLINE_REPLACEMENT)
            scriptContent = scriptContent.replacingOccurrences(of: bracketComment, with: modifiedBlock, options: .caseInsensitive)
        }

        // Sanitize < and > for the intermediate markup format
        scriptContent = scriptContent.replacingOccurrences(of: "<", with: "&lt;")
        scriptContent = scriptContent.replacingOccurrences(of: ">", with: "&gt;")
        scriptContent = scriptContent.replacingOccurrences(of: "...", with: "::trip::")

        // 2nd pass - Regex blast
        let patterns: [String] = [
            UNIVERSAL_LINE_BREAKS_PATTERN, BLOCK_COMMENT_PATTERN,
            BRACKET_COMMENT_PATTERN, SYNOPSIS_PATTERN, PAGE_BREAK_PATTERN,
            FALSE_TRANSITION_PATTERN, FORCED_TRANSITION_PATTERN,
            SCENE_HEADER_PATTERN, FIRST_LINE_ACTION_PATTERN, TRANSITION_PATTERN,
            CHARACTER_CUE_PATTERN, PARENTHETICAL_PATTERN, DIALOGUE_PATTERN,
            SECTION_HEADER_PATTERN, ACTION_PATTERN, CLEANUP_PATTERN, NEWLINE_REPLACEMENT,
        ]
        let templates: [String] = [
            UNIVERSAL_LINE_BREAKS_TEMPLATE, BLOCK_COMMENT_TEMPLATE,
            BRACKET_COMMENT_TEMPLATE, SYNOPSIS_TEMPLATE, PAGE_BREAK_TEMPLATE,
            FALSE_TRANSITION_TEMPLATE, FORCED_TRANSITION_TEMPLATE,
            SCENE_HEADER_TEMPLATE, FIRST_LINE_ACTION_TEMPLATE, TRANSITION_TEMPLATE,
            CHARACTER_CUE_TEMPLATE, PARENTHETICAL_TEMPLATE, DIALOGUE_TEMPLATE,
            SECTION_HEADER_TEMPLATE, ACTION_TEMPLATE, CLEANUP_TEMPLATE, NEWLINE_RESTORE,
        ]

        guard patterns.count == templates.count else {
            print("The pattern and template arrays don't have the same number of objects!")
            return []
        }

        for (pattern, template) in zip(patterns, templates) {
            scriptContent = scriptContent.replacingOccurrencesOfRegex(pattern, withString: template)
        }

        // 3rd pass - Array construction
        let tagPattern = "<([a-zA-Z\\s]+)>([^<>]*)<\\/[a-zA-Z\\s]+>"
        let elementTexts = scriptContent.componentsMatchedByRegex(tagPattern, capture: 2)
        let elementTypes = scriptContent.componentsMatchedByRegex(tagPattern, capture: 1)

        guard elementTexts.count == elementTypes.count else {
            print("Text and Type counts don't match.")
            return []
        }

        var elementsArray: [FNElement] = []

        for i in 0..<elementTexts.count {
            var element = FNElement()

            var cleanedText = elementTexts[i]
                .replacingOccurrences(of: "&lt;", with: "<", options: .caseInsensitive)
                .replacingOccurrences(of: "&gt;", with: ">", options: .caseInsensitive)
                .replacingOccurrences(of: "::trip::", with: "...", options: .caseInsensitive)

            // Extract scene number from scene headings
            if elementTypes[i] == "Scene Heading" {
                if let sceneNumber = cleanedText.stringByMatching(SCENE_NUMBER_PATTERN, capture: 2, options: .caseInsensitive),
                   let fullSceneText = cleanedText.stringByMatching(SCENE_NUMBER_PATTERN, capture: 1, options: .caseInsensitive) {
                    element.sceneNumber = sceneNumber
                    cleanedText = cleanedText.replacingOccurrences(of: fullSceneText, with: "", options: .caseInsensitive)
                }
            }

            element.elementType = elementTypes[i]
            element.elementText = cleanedText.trimmingCharacters(in: .newlines)

            // Centered text
            if element.elementText.isMatchedByRegex(CENTERED_TEXT_PATTERN) {
                element.isCentered = true
                element.elementText = (element.elementText
                    .stringByMatching("(>?)\\s*([^<>\\n]*)\\s*(<?)", capture: 2) ?? "")
                    .trimmingCharacters(in: .whitespaces)
            }

            // Remove forced scene heading dot
            if element.elementType == "Scene Heading" {
                element.elementText = element.elementText.stringByMatching("^\\.?(.+)", capture: 1) ?? element.elementText
            }

            // Section heading: extract depth from the leading # chars
            if element.elementType == "Section Heading" {
                let depthChars = element.elementText.stringByMatching(SECTION_HEADER_PATTERN, capture: 2) ?? ""
                element.sectionDepth = depthChars.count
                element.elementText = element.elementText.stringByMatching(SECTION_HEADER_PATTERN, capture: 3) ?? element.elementText
            }

            // Dual dialogue: mark this and the previous Character element
            if i > 1 && element.elementType == "Character" && element.elementText.isMatchedByRegex(DUAL_DIALOGUE_PATTERN) {
                element.isDualDialogue = true
                element.dualDialogueColumn = 1
                element.elementText = element.elementText.replacingOccurrencesOfRegex("\\s*\\^$", withString: "")

                let dialogueBlockTypes: Set<String> = ["Dialogue", "Parenthetical"]
                var j = i - 1
                var previousElement: FNElement
                repeat {
                    previousElement = elementsArray[j]
                    if previousElement.elementType == "Character" {
                        previousElement.isDualDialogue = true
                        previousElement.dualDialogueColumn = 0
                        previousElement.elementText = previousElement.elementText.replacingOccurrences(of: "^", with: "")
                        elementsArray[j] = previousElement
                    }
                    j -= 1
                } while j >= 0 && dialogueBlockTypes.contains(previousElement.elementType)
            }

            elementsArray.append(element)
        }

        return elementsArray
    }

    public static func parseBody(ofFile path: String) -> [FNElement] {
        guard let fileContents = try? String(contentsOfFile: path, encoding: .utf8) else { return [] }
        return parseBody(ofString: fileContents)
    }

    // MARK: - Title page parsing

    public static func parseTitlePage(ofString string: String) -> [[String: [String]]] {
        let rawTitlePage = titlePageOfString(string)
        var contents: [[String: [String]]] = []

        let splitTitlePage = rawTitlePage.components(separatedBy: "\n")
        var openDirective: String? = nil
        var directiveData: [String] = []

        for line in splitTitlePage {
            if line.isMatchedByRegex(INLINE_DIRECTIVE_PATTERN) {
                if let open = openDirective, !directiveData.isEmpty {
                    contents.append([open: directiveData])
                    directiveData = []
                }
                openDirective = nil

                var key = (line.stringByMatching(INLINE_DIRECTIVE_PATTERN, capture: 1) ?? "").lowercased()
                let val = line.stringByMatching(INLINE_DIRECTIVE_PATTERN, capture: 2) ?? ""
                if key == "author" || key == "author(s)" { key = "authors" }
                contents.append([key: [val]])
            } else if line.isMatchedByRegex(MULTI_LINE_DIRECTIVE_PATTERN) {
                if let open = openDirective, !directiveData.isEmpty {
                    contents.append([open: directiveData])
                }
                var key = (line.stringByMatching(MULTI_LINE_DIRECTIVE_PATTERN, capture: 1) ?? "").lowercased()
                if key == "author" || key == "author(s)" { key = "authors" }
                openDirective = key
                directiveData = []
            } else {
                if let value = line.stringByMatching(MULTI_LINE_DATA_PATTERN, capture: 2) {
                    directiveData.append(value)
                }
            }
        }

        if let open = openDirective, !directiveData.isEmpty {
            contents.append([open: directiveData])
        }

        return contents
    }

    public static func parseTitlePage(ofFile path: String) -> [[String: [String]]] {
        guard let fileContents = try? String(contentsOfFile: path, encoding: .utf8) else { return [] }
        return parseTitlePage(ofString: fileContents)
    }

    // MARK: - Private helpers

    private static func bodyOfString(_ string: String) -> String {
        var body = string.replacingOccurrencesOfRegex("^\\n+", withString: "")

        let nsBody = body as NSString
        let firstBlankLine = nsBody.range(of: "\n\n")
        if firstBlankLine.length > 0 {
            let beforeBlankRange = NSRange(location: 0, length: firstBlankLine.location + 1)
            let documentTop = nsBody.substring(with: beforeBlankRange) + "\n"
            if documentTop.isMatchedByRegex(TITLE_PAGE_PATTERN) {
                body = (body as NSString).substring(from: beforeBlankRange.location + beforeBlankRange.length - 1)
            }
        }
        return "\n\n\(body)\n\n"
    }

    private static func titlePageOfString(_ string: String) -> String {
        let body = string.replacingOccurrencesOfRegex("^\\n+", withString: "")

        let nsBody = body as NSString
        let firstBlankLine = nsBody.range(of: "\n\n")
        if firstBlankLine.length > 0 {
            let beforeBlankRange = NSRange(location: 0, length: firstBlankLine.location + 1)
            var documentTop = nsBody.substring(with: beforeBlankRange) + "\n"
            if documentTop.isMatchedByRegex(TITLE_PAGE_PATTERN) {
                documentTop = documentTop.replacingOccurrencesOfRegex("^\\n+", withString: "")
                documentTop = documentTop.replacingOccurrencesOfRegex("\\n+$", withString: "")
                return documentTop
            }
        }
        return ""
    }
}
