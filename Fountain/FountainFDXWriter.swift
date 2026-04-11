//
//  FountainFDXWriter.swift
//
//  Final Draft .fdx (XML) export — minimal structure Final Draft can import (Phase 8 / Next-Gen spec §4).
//

import Foundation

/// Writes ``FNScript`` as Final Draft **.fdx** XML (UTF-8 string).
///
/// Paragraph ``Type`` values follow Final Draft’s script element names. Unsupported or unknown
/// Fountain element types are emitted as **General** so content is preserved.
public struct FountainFDXWriter: FountainScriptRendering, Sendable {
    public init() {}

    public func render(_ script: FNScript) throws -> String {
        var paragraphs: [String] = []

        for block in script.titlePage {
            for (key, values) in block {
                for line in values where !line.isEmpty {
                    let label = key.trimmingCharacters(in: .whitespacesAndNewlines)
                    let combined = label.isEmpty ? line : "\(label.uppercased()): \(line)"
                    paragraphs.append(fdxParagraph(type: "General", text: combined))
                }
            }
        }

        for element in script.elements {
            if element.elementText.range(of: #"^\s*$"#, options: .regularExpression) != nil,
               element.elementType != "Page Break" {
                continue
            }
            let type = fdxParagraphType(for: element.elementType)
            let text = displayText(for: element, script: script)
            paragraphs.append(fdxParagraph(type: type, text: text))
        }

        let body = paragraphs.joined(separator: "\n")
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="no" ?>
        <FinalDraft DocumentType="Script" Template="No" Version="1">
          <Content>
        \(body)
          </Content>
        \(Self.fdxLayoutBoilerplate)
        </FinalDraft>
        """
    }

    /// Final Draft **PageLayout**, **ElementSettings** (per common element types), and **MoresAndContinueds**
    /// so imports pick up US-style margins and (MORE)/(cont'd) defaults (roadmap Phase 8.7).
    private static let fdxLayoutBoilerplate = #"""
          <PageLayout BackgroundColor="#FFFFFFFFFFFF" BottomMargin="72" BreakDialogueAndActionAtSentences="Yes" DocumentLeading="Normal" FooterMargin="72" ForegroundColor="#000000000000" HeaderMargin="72" InvisiblesColor="#808080808080" TopMargin="72" UsesSmartQuotes="Yes"/>
          <ElementSettings Type="General">
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style=""/>
            <ParagraphSpec Alignment="Left" FirstIndent="0.00" Leading="Regular" LeftIndent="1.50" RightIndent="7.50" SpaceBefore="0" Spacing="1" StartsNewPage="No"/>
          </ElementSettings>
          <ElementSettings Type="Scene Heading">
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style="AllCaps"/>
            <ParagraphSpec Alignment="Left" FirstIndent="0.00" Leading="Regular" LeftIndent="1.50" RightIndent="7.50" SpaceBefore="12" Spacing="1" StartsNewPage="No"/>
          </ElementSettings>
          <ElementSettings Type="Action">
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style=""/>
            <ParagraphSpec Alignment="Left" FirstIndent="0.00" Leading="Regular" LeftIndent="1.50" RightIndent="7.50" SpaceBefore="0" Spacing="1" StartsNewPage="No"/>
          </ElementSettings>
          <ElementSettings Type="Character">
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style="AllCaps"/>
            <ParagraphSpec Alignment="Left" FirstIndent="0.00" Leading="Regular" LeftIndent="3.50" RightIndent="7.25" SpaceBefore="12" Spacing="1" StartsNewPage="No"/>
          </ElementSettings>
          <ElementSettings Type="Dialogue">
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style=""/>
            <ParagraphSpec Alignment="Left" FirstIndent="0.00" Leading="Regular" LeftIndent="2.50" RightIndent="6.50" SpaceBefore="0" Spacing="1" StartsNewPage="No"/>
          </ElementSettings>
          <ElementSettings Type="Parenthetical">
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style=""/>
            <ParagraphSpec Alignment="Left" FirstIndent="-0.10" Leading="Regular" LeftIndent="3.00" RightIndent="6.50" SpaceBefore="0" Spacing="1" StartsNewPage="No"/>
          </ElementSettings>
          <ElementSettings Type="Transition">
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style="AllCaps"/>
            <ParagraphSpec Alignment="Right" FirstIndent="0.00" Leading="Regular" LeftIndent="5.50" RightIndent="1.00" SpaceBefore="12" Spacing="1" StartsNewPage="No"/>
          </ElementSettings>
          <MoresAndContinueds>
            <FontSpec AdornmentStyle="0" Background="#FFFFFFFFFFFF" Color="#000000000000" Font="Courier Final Draft" RevisionID="0" Size="12" Style=""/>
            <DialogueBreaks AutomaticCharacterContinueds="Yes" BottomOfPage="Yes" DialogueBottom="(MORE)" DialogueTop="(cont'd)" TopOfNext="Yes"/>
            <SceneBreaks ContinuedNumber="No" SceneBottom="(CONTINUED)" SceneBottomOfPage="No" SceneTop="CONTINUED:" SceneTopOfNext="No"/>
          </MoresAndContinueds>
        """#

    private func fdxParagraphType(for fountainType: String) -> String {
        switch fountainType {
        case "Scene Heading": return "Scene Heading"
        case "Action": return "Action"
        case "Character": return "Character"
        case "Dialogue": return "Dialogue"
        case "Parenthetical": return "Parenthetical"
        case "Transition": return "Transition"
        case "Shot": return "Shot"
        case "Cast List": return "Cast List"
        case "General": return "General"
        case "Lyrics": return "Lyrics"
        case "Section Heading": return "Section"
        case "Synopsis": return "Synopsis"
        case "Page Break": return "General"
        case "Comment", "Boneyard": return "General"
        default: return "General"
        }
    }

    private func displayText(for element: FNElement, script: FNScript) -> String {
        var text = element.elementText
        switch element.elementType {
        case "Scene Heading":
            if !script.suppressSceneNumbers, let n = element.sceneNumber, !n.isEmpty {
                if !text.contains("#\(n)#") {
                    text = "\(text) #\(n)#"
                }
            }
        case "Character":
            text = text.replacingOccurrences(of: #"^\s*@\s*"#, with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: #"\s*\^\s*$"#, with: "", options: .regularExpression)
        case "Lyrics":
            text = text.replacingOccurrences(of: #"^\s*~\s*"#, with: "", options: .regularExpression)
        case "Action":
            text = text.replacingOccurrences(of: #"^\s*!\s*"#, with: "", options: .regularExpression)
        default:
            break
        }
        return text
    }

    private func fdxParagraph(type: String, text: String) -> String {
        let escaped = Self.xmlEscape(text)
        return "    <Paragraph Type=\"\(Self.xmlEscapeAttribute(type))\">\n      <Text>\(escaped)</Text>\n    </Paragraph>"
    }

    private static func xmlEscape(_ s: String) -> String {
        var out = String()
        out.reserveCapacity(s.utf16.count)
        for ch in s {
            switch ch {
            case "&": out.append("&amp;")
            case "<": out.append("&lt;")
            case ">": out.append("&gt;")
            case "\"": out.append("&quot;")
            case "'": out.append("&apos;")
            default:
                if ch.unicodeScalars.allSatisfy({ $0.value < 0x20 && $0.value != 0x09 && $0.value != 0x0A && $0.value != 0x0D }) {
                    out.append(" ")
                } else {
                    out.append(ch)
                }
            }
        }
        return out
    }

    private static func xmlEscapeAttribute(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
    }
}
