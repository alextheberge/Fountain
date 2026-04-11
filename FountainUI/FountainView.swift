//
//  FountainView.swift
//  FountainUI — Phase 13.2: SwiftUI preview of a ``FountainDocument``.
//

import FountainCore
import SwiftUI

/// Renders a ``FountainDocument`` as a vertically scrolling screenplay-style column.
///
/// Uses system typography (serif body for readability). **Dual dialogue:** rows with
/// ``FountainMetadataKey/dualDialogueColumn`` `1` are inset toward the trailing edge; pair with
/// Dynamic Type in previews. **Inline emphasis** (``FountainInlineMarkup`` → ``AttributedString`` → ``Text``) is applied
/// per ``FountainUIScriptElementLineContent/usesAttributedInline(for:)`` (Phase **13.3**).
public struct FountainView: View {
    private let document: FountainDocument

    public init(document: FountainDocument) {
        self.document = document
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !document.titlePage.isEmpty {
                    FountainTitlePageBlock(entries: document.titlePage)
                        .padding(.bottom, 12)
                }
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(document.elements) { element in
                        FountainScriptElementRow(element: element)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .fontDesign(.serif)
        .accessibilityIdentifier("fountain-document-root")
    }
}

// MARK: - Title page

struct FountainTitlePageBlock: View {
    let entries: [[String: [String]]]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(entries.enumerated()), id: \.offset) { _, dict in
                ForEach(Array(dict.keys.sorted().enumerated()), id: \.offset) { _, key in
                    if let values = dict[key], !values.isEmpty {
                        Text(titlePageLine(key: key, values: values))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func titlePageLine(key: String, values: [String]) -> String {
        let joined = values.joined(separator: "\n")
        return joined.isEmpty ? key : "\(key): \(joined)"
    }
}

// MARK: - Body rows

struct FountainScriptElementRow: View {
    let element: ScriptElement

    var body: some View {
        rowText
            .modifier(FountainScriptElementRowChrome(element: element))
    }

    @ViewBuilder
    private var rowText: some View {
        if element.kind == .sceneHeading, let sn = element.metadata[FountainMetadataKey.sceneNumber.rawValue], !sn.isEmpty {
            Text("\(element.text)  #\(sn)#")
        } else {
            FountainUIScriptElementLineContent.text(for: element)
        }
    }
}

private struct FountainScriptElementRowChrome: ViewModifier {
    let element: ScriptElement

    @ViewBuilder
    func body(content: Content) -> some View {
        let laidOut = content
            .font(FountainScriptElementTypography.font(for: element.kind))
            .multilineTextAlignment(FountainScriptElementTypography.multilineAlignment(for: element))
            .frame(
                maxWidth: .infinity,
                alignment: Alignment(horizontal: FountainScriptElementTypography.frameAlignment(for: element), vertical: .center)
            )
            .padding(.leading, FountainScriptElementTypography.paddingLeading(for: element))
            .padding(.top, FountainScriptElementTypography.paddingTop(for: element.kind))
            .accessibilityIdentifier("fountain-element-\(element.kind.rawValue)")
        if element.kind == .character {
            laidOut.textCase(.uppercase)
        } else {
            laidOut
        }
    }
}
