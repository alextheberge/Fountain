//
//  FountainScriptElementsBuilder.swift
//
//  Roadmap Phase 4.5 — assemble ``[FNElement]`` from ``FountainTokenizedLine`` output (same ordering as
//  ``FastFountainParser`` / ``FNScript``). Used for parity checks and future tokenizer-first pipelines.
//

import Foundation

public enum FountainScriptElementsBuilder {
    /// Body tokens only (after title-page prescan + leading `\n`); use ``buildElements(fromRawDocument:)`` for full documents.
    public static func buildElements(fromBodyTokens tokens: [FountainTokenizedLine]) -> [FNElement] {
        var elements: [FNElement] = []
        var isCommentBlock = false
        var commentText = ""

        /// Matches ``FastFountainParser`` continuation merge: any non-blank line after a line with no intervening blank is appended to the previous element; a trailing ``Scene Heading`` becomes ``Action``.
        func mergeContinuationLikeFast(text: String) {
            guard var previous = elements.last else {
                elements.append(FNElement.element(ofType: "Action", text: text))
                return
            }
            if previous.elementType == "Scene Heading" {
                previous.elementType = "Action"
            }
            previous.elementText = "\(previous.elementText)\n\(text)"
            elements[elements.count - 1] = previous
        }

        func mergeOrAppendDialogue(text: String) {
            if let last = elements.last, last.elementType == "Dialogue" {
                var m = last
                m.elementText = "\(m.elementText)\n\(text)"
                elements[elements.count - 1] = m
            } else {
                elements.append(FNElement.element(ofType: "Dialogue", text: text))
            }
        }

        func appendCharacterCue(rawLine: String) {
            var el = FNElement.element(ofType: "Character", text: rawLine)
            if rawLine.isMatchedByRegex("\\^\\s*$") {
                el.isDualDialogue = true
                el.dualDialogueColumn = 1
                el.elementText = rawLine.replacingOccurrencesOfRegex("\\s*\\^\\s*$", withString: "")
                for idx in stride(from: elements.count - 1, through: 0, by: -1) {
                    if elements[idx].elementType == "Character" {
                        var prev = elements[idx]
                        prev.isDualDialogue = true
                        prev.dualDialogueColumn = 0
                        elements[idx] = prev
                        break
                    }
                }
            }
            elements.append(el)
        }

        for t in tokens {
            switch t.kind {
            case .blank:
                break

            case .boneyardOpen:
                isCommentBlock = true
                commentText += "\n"

            case .boneyardClose:
                let line = t.text
                let stripped = line.replacingOccurrences(of: "*/", with: "")
                if stripped.isEmpty || stripped.isMatchedByRegex("^\\s*$") {
                    commentText += stripped.trimmingCharacters(in: .whitespaces)
                }
                isCommentBlock = false
                elements.append(FNElement.element(ofType: "Boneyard", text: commentText))
                commentText = ""

            case .boneyardText:
                let line = t.text
                if FountainStructuralLineMatchers.isSingleLineBoneyard(line) {
                    let inner = line
                        .replacingOccurrences(of: "/*", with: "")
                        .replacingOccurrences(of: "*/", with: "")
                    elements.append(FNElement.element(ofType: "Boneyard", text: inner))
                    isCommentBlock = false
                } else if isCommentBlock {
                    commentText += line + "\n"
                }

            case .pageBreak:
                elements.append(FNElement.element(ofType: "Page Break", text: t.text))

            case .synopsis:
                let line = t.text
                let markupRange = line.nsRangeOfRegex("^\\s*={1}")
                let synopsisBody: String
                if markupRange.location != NSNotFound {
                    synopsisBody = (line as NSString).substring(from: markupRange.location + markupRange.length)
                } else {
                    synopsisBody = line
                }
                elements.append(FNElement.element(ofType: "Synopsis", text: synopsisBody))

            case .note:
                let inner = t.text
                    .replacingOccurrences(of: "[[", with: "")
                    .replacingOccurrences(of: "]]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                elements.append(FNElement.element(ofType: "Comment", text: inner))

            case .sectionHeading:
                let line = t.text
                let markupRange = line.nsRangeOfRegex("^\\s*#+")
                guard markupRange.location != NSNotFound else { continue }
                let depth = markupRange.length
                let body = (line as NSString).substring(from: markupRange.location + markupRange.length)
                guard !body.isEmpty else { continue }
                var el = FNElement.element(ofType: "Section Heading", text: body)
                el.sectionDepth = depth
                elements.append(el)

            case .forcedSceneHeading:
                let line = t.text
                var sceneNumber: String?
                var text: String
                if line.isMatchedByRegex("#([^\\n#]*?)#\\s*$") {
                    sceneNumber = line.stringByMatching("#([^\\n#]*?)#\\s*$", capture: 1)
                    text = line.replacingOccurrencesOfRegex("#([^\\n#]*?)#\\s*$", withString: "")
                    text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
                } else {
                    text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                var el = FNElement.element(ofType: "Scene Heading", text: text)
                el.sceneNumber = sceneNumber
                elements.append(el)

            case .sceneHeading:
                let line = t.text
                var sceneNumber: String?
                var text = line
                if line.isMatchedByRegex("#([^\\n#]*?)#\\s*$") {
                    sceneNumber = line.stringByMatching("#([^\\n#]*?)#\\s*$", capture: 1)
                    text = line.replacingOccurrencesOfRegex("#([^\\n#]*?)#\\s*$", withString: "")
                }
                var el = FNElement.element(ofType: "Scene Heading", text: text)
                el.sceneNumber = sceneNumber
                elements.append(el)

            case .transition:
                elements.append(FNElement.element(ofType: "Transition", text: t.text))

            case .forcedTransition:
                let stripped = String(t.text.dropFirst()).trimmingCharacters(in: .whitespaces)
                elements.append(FNElement.element(ofType: "Transition", text: stripped))

            case .centeredText:
                var inner = String(t.text.dropFirst()).trimmingCharacters(in: .whitespaces)
                if inner.last == "<" { inner = String(inner.dropLast()).trimmingCharacters(in: .whitespaces) }
                var el = FNElement.element(ofType: "Action", text: inner)
                el.isCentered = true
                elements.append(el)

            case .lyrics:
                elements.append(FNElement.element(ofType: "Lyrics", text: t.text))

            case .forcedAction:
                elements.append(FNElement.element(ofType: "Action", text: t.text))

            case .action:
                if t.isMergeContinuation {
                    mergeContinuationLikeFast(text: t.text)
                } else {
                    elements.append(FNElement.element(ofType: "Action", text: t.text))
                }

            case .forcedCharacterCue, .characterCue:
                appendCharacterCue(rawLine: t.text)

            case .parenthetical:
                elements.append(FNElement.element(ofType: "Parenthetical", text: t.text))

            case .dialogue:
                mergeOrAppendDialogue(text: t.text)

            case .titlePageDirective, .titlePageContinuation, .dualDialogueSuffix:
                break

            case .unknown:
                if t.isMergeContinuation {
                    mergeContinuationLikeFast(text: t.text)
                } else {
                    elements.append(FNElement.element(ofType: "Action", text: t.text))
                }
            }
        }

        return elements
    }

    /// Prescans title page like ``FastFountainParser``, tokenizes the body, then assembles elements.
    public static func buildElements(fromRawDocument raw: String) -> [FNElement] {
        FountainParsePipeline.parseDocument(string: raw).elements
    }
}
