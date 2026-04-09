//
//  FountainWriter.swift
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

public class FountainWriter {

    public static func documentFromScript(_ script: FNScript) -> String {
        let bodyContent      = bodyFromScript(script)
        let titlePageContent = titlePageFromScript(script)

        var document = ""
        if !titlePageContent.isEmpty {
            document += "\(titlePageContent)\n"
        }
        if !bodyContent.isEmpty {
            document += bodyContent
        }
        return document.trimmingCharacters(in: .newlines)
    }

    public static func bodyFromScript(_ script: FNScript) -> String {
        var content = ""
        var dualDialogueCount = 0
        let dialogueTypes: Set<String> = ["Dialogue", "Parenthetical", "Comment"]

        for element in script.elements {
            // Skip empty non-page-break elements
            if element.elementText.isMatchedByRegex("^[\\s\\n\\t]*$") && element.elementType != "Page Break" {
                continue
            }

            var textToWrite: String? = nil

            switch element.elementType {
            case "Comment":
                textToWrite = "\n[[\(element.elementText)]]"

            case "Boneyard":
                textToWrite = "/*\(element.elementText)*/"

            case "Synopsis":
                textToWrite = "=\(element.elementText)"

            case "Scene Heading":
                var text = element.elementText
                // If the element text doesn't match the natural scene heading pattern,
                // it was a forced scene heading and needs the leading '.' restored.
                if !"\n\(element.elementText)\n".isMatchedByRegex(SCENE_HEADER_PATTERN) {
                    text = ".\(text)"
                }
                if !script.suppressSceneNumbers, let sceneNumber = element.sceneNumber {
                    text = "\(text) #\(sceneNumber)#"
                }
                textToWrite = text

            case "Page Break":
                textToWrite = "===="

            case "Section Heading":
                let hashes = String(repeating: "#", count: element.sectionDepth)
                textToWrite = hashes + element.elementText

            case "Transition":
                if !element.elementText.isMatchedByRegex(TRANSITION_PATTERN) {
                    textToWrite = "> \(element.elementText)"
                }

            default:
                textToWrite = element.elementText
            }

            // Centered text
            if element.isCentered, var text = textToWrite {
                if text.isMatchedByRegex("[ ]$") {
                    text = "> \(text)<"
                } else {
                    text = "> \(text) <"
                }
                textToWrite = text
            }

            // Dual dialogue marker
            if element.elementType == "Character" && element.isDualDialogue {
                dualDialogueCount += 1
                if dualDialogueCount == 2 {
                    textToWrite = "\(textToWrite ?? "") ^"
                    dualDialogueCount = 0
                }
            }

            guard let text = textToWrite else { continue }

            if dialogueTypes.contains(element.elementType) {
                content += "\(text)\n"
            } else {
                content += "\n\(text)\n"
            }
        }

        return content
    }

    public static func titlePageFromScript(_ script: FNScript) -> String {
        var content = ""

        for dict in script.titlePage {
            for (key, obj) in dict {
                // Capitalize the first character of the key
                let keyString = key.prefix(1).uppercased() + key.dropFirst()
                if obj.count == 1 {
                    // Use "Author" (singular) when there is only one author
                    let displayKey = key == "authors" ? "Author" : keyString
                    content += "\(displayKey): \(obj[0])\n"
                } else {
                    content += "\(keyString):\n"
                    for value in obj {
                        content += "\t\(value)\n"
                    }
                }
            }
        }

        return content
    }
}
