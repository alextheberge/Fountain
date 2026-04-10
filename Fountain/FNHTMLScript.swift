//
//  FNHTMLScript.swift
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

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if SWIFT_PACKAGE
import FountainCore
#endif

public class FNHTMLScript {
    public var font: PlatformFont
    public let script: FNScript

    private var _bodyText: String?

    public init(script aScript: FNScript) {
        script = aScript
        font = PlatformFont(name: "Courier", size: 13)!
    }

    public func html() -> String {
        if _bodyText == nil {
            _bodyText = bodyForScript()
        }
        let body = _bodyText ?? ""

        var html = ""
        html += "<!DOCTYPE html>\n"
        html += "<html>\n"
        html += "<head>\n"
        html += "<style type='text/css'>\n"
        html += cssText
        html += "</style>\n"
        html += "</head>\n"
        html += "<body>\n<article>\n<section>\n"
        html += body
        html += "</section>\n</article>\n</body>\n"
        html += "</html>"
        return html
    }

    public func htmlClassForType(_ elementType: String) -> String {
        return elementType.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    // MARK: - Private

    private static var resourcesBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }

    private var cssText: String {
        guard let path = Self.resourcesBundle.path(forResource: "ScriptCSS", ofType: "css"),
              let css = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Couldn't load CSS")
            return ""
        }
        return css
    }

    private func bodyForScript() -> String {
        var body = ""

        // Title page
        var titlePageDict: [String: [String]] = [:]
        for dict in script.titlePage {
            for (key, value) in dict {
                titlePageDict[key] = value
            }
        }

        if !titlePageDict.isEmpty {
            body += "<div id='script-title'>"

            // Title
            if let obj = titlePageDict["title"] {
                let values = obj.map { "\($0)<br>" }.joined()
                body += "<p class='title'>\(values)</p>"
            } else {
                body += "<p class='title'>Untitled</p>"
            }

            // Credit and authors
            if titlePageDict["credit"] != nil || titlePageDict["authors"] != nil {
                if let obj = titlePageDict["credit"] {
                    let values = obj.map { "\($0)<br>" }.joined()
                    body += "<p class='credit'>\(values)</p>"
                } else {
                    body += "<p class='credit'>written by</p>"
                }

                if let obj = titlePageDict["authors"] {
                    let values = obj.map { "\($0)<br>" }.joined()
                    body += "<p class='authors'>\(values)</p>"
                } else {
                    body += "<p class='authors'>Anonymous</p>"
                }
            }

            // Source
            if let obj = titlePageDict["source"] {
                let values = obj.map { "\($0)<br>" }.joined()
                body += "<p class='source'>\(values)</p>"
            }

            // Draft date
            if let obj = titlePageDict["draft date"] {
                let values = obj.map { "\($0)<br>" }.joined()
                body += "<p class='draft date'>\(values)</p>"
            }

            // Contact
            if let obj = titlePageDict["contact"] {
                let values = obj.map { "\($0)<br>" }.joined()
                body += "<p class='contact'>\(values)</p>"
            }

            body += "</div>"
        }

        let dialogueTypes: Set<String> = ["Character", "Dialogue", "Parenthetical"]
        let ignoringTypes: Set<String>  = ["Boneyard", "Comment", "Synopsis", "Section Heading"]

        let paginator = FNPaginator(script: script)
        let maxPages  = paginator.numberOfPages
        var dualDialogueCharacterCount = 0

        for pageIndex in 0..<maxPages {
            let elementsOnPage = paginator.pageAtIndex(pageIndex)

            body += "<p class='page-break'>\(pageIndex + 1).</p>\n"

            for element in elementsOnPage {
                if ignoringTypes.contains(element.elementType) { continue }

                if element.elementType == "Page Break" {
                    body += "</section>\n<section>\n"
                    continue
                }

                if element.elementType == "Character" && element.isDualDialogue {
                    dualDialogueCharacterCount += 1
                    if dualDialogueCharacterCount == 1 {
                        body += "<div class='dual-dialogue'>\n"
                        body += "<div class='dual-dialogue-left'>\n"
                    } else if dualDialogueCharacterCount == 2 {
                        body += "</div>\n<div class='dual-dialogue-right'>\n"
                    }
                }

                if dualDialogueCharacterCount >= 2 && !dialogueTypes.contains(element.elementType) {
                    dualDialogueCharacterCount = 0
                    body += "</div>\n</div>\n"
                }

                var text = ""

                if element.elementType == "Scene Heading", let sceneNumber = element.sceneNumber {
                    text += "<span class='scene-number-left'>\(sceneNumber)</span>"
                    text += element.elementText
                    text += "<span class='scene-number-right'>\(sceneNumber)</span>"
                } else {
                    text += element.elementText
                }

                // Clean up forced-element markers
                if element.elementType == "Character" && element.isDualDialogue {
                    text = text.replacingOccurrences(of: "^", with: "", options: .caseInsensitive)
                }
                if element.elementType == "Character" {
                    text = text.replacingOccurrencesOfRegex("^@", withString: "")
                }
                if element.elementType == "Scene Heading" {
                    text = text.replacingOccurrencesOfRegex("^\\.", withString: "")
                }
                if element.elementType == "Lyrics" {
                    text = text.replacingOccurrencesOfRegex("^~", withString: "")
                }
                if element.elementType == "Action" {
                    text = text.replacingOccurrencesOfRegex("^\\!", withString: "")
                }

                // Apply inline styling (Phase 6.2 — linear scan shared with tests)
                text = FountainInlineMarkup.htmlFragment(from: text)

                // Strip inline comments
                text = text.replacingOccurrencesOfRegex("\\[{2}(.*?)\\]{2}", withString: "")

                if !text.isEmpty {
                    var additionalClasses = ""
                    if element.isCentered { additionalClasses += " center" }
                    body += "<p class='\(htmlClassForType(element.elementType))\(additionalClasses)'>\(text)</p>\n"
                }
            }
        }

        return body
    }
}

// MARK: - Phase 8.2 (FountainScriptRendering)

extension FNHTMLScript: FountainScriptRendering {
    /// Renders full HTML. When `script` matches this instance’s script, cached body text is reused; otherwise a sibling renderer is built with the same font.
    public func render(_ script: FNScript) throws -> String {
        let doc: FNHTMLScript
        if script === self.script {
            doc = self
        } else {
            doc = FNHTMLScript(script: script)
            doc.font = font
        }
        return doc.html()
    }
}
