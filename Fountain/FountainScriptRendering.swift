//
//  FountainScriptRendering.swift
//
//  Phase 8.1 — pluggable renderers; Phase 6.1 — inline markup policy (documentation seed).
//

import Foundation

// MARK: - Inline markup policy (Phase 6.1)

/// How inline emphasis markers (`**bold**`, `*italic*`, `_underline_`, etc.) flow through the stack (Phase 6.1).
///
/// | Mode | Meaning |
/// |------|--------|
/// | ``preserveMarkersInPlaintext`` | **Plain** — keep Fountain markers in stored ``FNElement`` / ``ScriptElement`` text; use ``FountainInlineMarkup/htmlFragment(from:)`` only when emitting HTML. |
/// | ``attributedStringFromInlineMarkup`` | **Rich** — parse a fragment to ``AttributedString`` via ``FountainInlineMarkup/attributedFragment(from:)`` (intents + ``FountainInlineAttributedKeys/Underline``). |
///
/// Use ``FountainInlineMarkup/renderInline(_:mode:)`` to branch on this policy without duplicating `switch`es.
public enum FountainInlineRenderingMode: String, Sendable, CaseIterable {
    /// Plain mode: markers remain in content; no automatic `AttributedString` conversion.
    case preserveMarkersInPlaintext
    /// Rich mode: parse markers to ``AttributedString`` (bold/italic intents; underline via ``FountainInlineAttributedKeys/Underline``).
    case attributedStringFromInlineMarkup
}

// MARK: - Script rendering protocol (Phase 8.1)

/// Renders a parsed ``FNScript`` to a textual (or later binary) product.
public protocol FountainScriptRendering {
    /// Produce output from the in-memory model (e.g. Fountain plain text, HTML, Markdown).
    func render(_ script: FNScript) throws -> String
}

/// Round-trip to Fountain plain text using ``FountainWriter``.
public struct FountainPlaintextWriter: FountainScriptRendering, Sendable {
    public init() {}

    public func render(_ script: FNScript) throws -> String {
        FountainWriter.documentFromScript(script)
    }
}

// MARK: - Markdown export (Phase 8.3)

/// Lossy Markdown projection for tooling / LLM pipelines (headings, block quotes, horizontal rules).
public struct FountainMarkdownWriter: FountainScriptRendering, Sendable {
    public init() {}

    public func render(_ script: FNScript) throws -> String {
        var parts: [String] = []

        if !script.titlePage.isEmpty {
            parts.append("---")
            parts.append(FountainWriter.titlePageFromScript(script).trimmingCharacters(in: .newlines))
            parts.append("---")
            parts.append("")
        }

        let body = markdownBody(from: script)
        if !body.isEmpty {
            parts.append(body)
        }

        return parts.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }

    private func markdownBody(from script: FNScript) -> String {
        var lines: [String] = []
        var dualDialogueCount = 0

        for element in script.elements {
            if element.elementText.range(of: #"^\s*$"#, options: .regularExpression) != nil,
               element.elementType != "Page Break" {
                continue
            }

            var block: String?

            switch element.elementType {
            case "Comment":
                block = "\n> [[\(element.elementText)]]\n"
            case "Boneyard":
                block = "\n<!-- boneyard \(element.elementText) -->\n"
            case "Synopsis":
                block = "\n> \(element.elementText)\n"
            case "Scene Heading":
                var t = element.elementText
                if !"\n\(element.elementText)\n".isMatchedByRegex(SCENE_HEADER_PATTERN) {
                    t = ".\(t)"
                }
                if !script.suppressSceneNumbers, let n = element.sceneNumber {
                    t = "\(t) #\(n)#"
                }
                block = "\n## \(t)\n"
            case "Section Heading":
                let hashes = String(repeating: "#", count: max(1, element.sectionDepth))
                block = "\n\(hashes) \(element.elementText.trimmingCharacters(in: .whitespaces))\n"
            case "Page Break":
                block = "\n---\n"
            case "Character":
                var t = element.elementText.replacingOccurrencesOfRegex("^@", withString: "")
                if element.isDualDialogue {
                    t = t.replacingOccurrencesOfRegex("\\s*\\^\\s*$", withString: "")
                }
                var charBlock = "\n**\(t)**"
                if element.isDualDialogue {
                    dualDialogueCount += 1
                    if dualDialogueCount == 2 {
                        charBlock += " ^"
                        dualDialogueCount = 0
                    }
                }
                block = "\(charBlock)\n"
            case "Parenthetical":
                block = "> \(element.elementText)\n"
            case "Dialogue":
                block = "> \(element.elementText)\n"
            case "Transition":
                block = "\n### \(element.elementText)\n"
            case "Lyrics":
                let t = element.elementText.replacingOccurrencesOfRegex("^~", withString: "")
                block = "\n> *\(t)*\n"
            case "Action":
                var t = element.elementText.replacingOccurrencesOfRegex("^\\!", withString: "")
                if element.isCentered {
                    t = "> \(t) "
                }
                block = "\n\(t)\n"
            default:
                block = "\n\(element.elementText)\n"
            }

            if let block {
                lines.append(block)
            }
        }

        return lines.joined()
    }
}

// MARK: - JSON export (tooling / LLM)

/// Encodes ``FountainDocument`` as UTF-8 JSON text (stable for pipelines and fixtures).
public struct FountainJSONWriter: FountainScriptRendering, Sendable {
    public var prettyPrinted: Bool

    public init(prettyPrinted: Bool = false) {
        self.prettyPrinted = prettyPrinted
    }

    public func render(_ script: FNScript) throws -> String {
        let data = try script.fountainDocumentJSONData(prettyPrinted: prettyPrinted)
        return String(decoding: data, as: UTF8.self)
    }
}
