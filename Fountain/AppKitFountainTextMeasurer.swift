//
//  AppKitFountainTextMeasurer.swift
//
//  Phase 8.5 — AppKit/UIKit text measurement for ``FNPaginator`` (FountainHTML target only).
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit) || canImport(AppKit)

#if SWIFT_PACKAGE
import FountainCore
#endif

/// Uses ``NSLayoutManager`` / ``NSTextStorage`` for line counts (legacy ``FNPaginator`` behavior).
public struct AppKitFountainTextMeasurer: FountainTextMeasuring, @unchecked Sendable {
    private let font: PlatformFont

    public init(font: PlatformFont) {
        self.font = font
    }

    /// Courier 12 (same default as ``FNPaginator``).
    public static func defaultCourier12() -> AppKitFountainTextMeasurer {
        AppKitFountainTextMeasurer(font: PlatformFont(name: "Courier", size: 12)!)
    }

    public var layoutLineHeight: Int { Int(font.pointSize) }

    public func heightForString(_ string: String, maxWidth: Int) -> Int {
        let lineHeight = layoutLineHeight
        let containerWidth = CGFloat(max(1, maxWidth))
        let textStorage = NSTextStorage(string: string, attributes: [.font: font])
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: containerWidth, height: .greatestFiniteMagnitude))

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0

        layoutManager.glyphRange(for: textContainer)

        var numberOfLines = 0
        var index = 0
        let numberOfGlyphs = layoutManager.numberOfGlyphs

        while index < numberOfGlyphs {
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }

        return numberOfLines * lineHeight
    }
}

#endif
