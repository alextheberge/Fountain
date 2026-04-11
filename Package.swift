// swift-tools-version: 5.9
// Fountain Swift Package — core vs HTML split + umbrella `Fountain` (see docs/Fountain-1.1-Implementation-Roadmap.md, Phase 10 distribution).
// Syntax target: `FountainSyntaxPin.targetVersionLabel` (currently 1.1).
//
// Phase 10.4: **FountainCore** excludes UI pagination/HTML sources; CoreGraphics/CoreText appear only in
// `FountainPDFWriter.swift` behind `#if canImport` + wasm32 stub (see ADR-008). **FountainHTML** holds
// AppKit/UIKit. **FountainUI** (Phase 13) holds SwiftUI — keep `import SwiftUI` out of `Fountain/*.swift`.
// CI in `.github/workflows/swift.yml` greps these boundaries.
import PackageDescription

// Package name must differ from the `Fountain` library target to avoid SPM test-runner build cycles.
let package = Package(
    name: "FountainSwiftPM",
    platforms: [
        // Phase 11 — Swift `Regex` / `String` matching APIs require macOS 13 / iOS 16+ (see roadmap §11).
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "Fountain",
            targets: ["Fountain"]
        ),
        .library(
            name: "FountainCore",
            targets: ["FountainCore"]
        ),
        .library(
            name: "FountainHTML",
            targets: ["FountainHTML"]
        ),
        .library(
            name: "FountainUI",
            targets: ["FountainUI"]
        ),
    ],
    targets: [
        .target(
            name: "FountainCore",
            path: "Fountain",
            exclude: [
                "Legacy",
                "ScriptCSS.css",
                "AppKitFountainTextMeasurer.swift",
                "FNHTMLScript.swift",
                "FNPaginator.swift",
                "Platform.swift",
            ]
        ),
        .target(
            name: "FountainHTML",
            dependencies: ["FountainCore"],
            path: "Fountain",
            exclude: [
                "Legacy",
                "String+Regex.swift",
                "FountainRegexes.swift",
                "FNElement.swift",
                "FastFountainParser.swift",
                "FountainParser.swift",
                "FountainWriter.swift",
                "FNScript.swift",
                "FountainCodable.swift",
                "FNElementType.swift",
                "FountainTokenization.swift",
                "FountainSyntaxPin.swift",
                "FountainForcedPrefix.swift",
                "FountainSceneHeadingMatcher.swift",
                "FountainTitlePagePrescan.swift",
                "FountainStructuralLineMatchers.swift",
                "FountainBodyLineTokenizer.swift",
                "FountainScriptElementsBuilder.swift",
                "FountainDialogueBlockRecognizer.swift",
                "FountainScriptRendering.swift",
                "FountainInlineMarkup.swift",
                "FountainInlineAttributedKeys.swift",
                "FountainInlineDelimiterTable.swift",
                "FountainStubRenderers.swift",
                "FountainScriptMetrics.swift",
                "FountainFDXWriter.swift",
                "FountainPDFWriter.swift",
                "FountainParsePipeline.swift",
                "FountainLineToElementIndexMap.swift",
                "FountainEditRangeExpansion.swift",
                "FountainIncrementalParse.swift",
                "FountainTextMeasuring.swift",
            ],
            sources: [
                "AppKitFountainTextMeasurer.swift",
                "FNHTMLScript.swift",
                "FNPaginator.swift",
                "Platform.swift",
            ],
            resources: [
                .process("ScriptCSS.css"),
            ]
        ),
        .target(
            name: "Fountain",
            dependencies: ["FountainCore", "FountainHTML"],
            path: "Sources/Fountain",
            sources: [
                "Fountain.swift",
                "FountainPDFPagination.swift",
            ]
        ),
        .target(
            name: "FountainUI",
            dependencies: ["FountainCore"],
            path: "FountainUI"
        ),
        .testTarget(
            name: "FountainPackageTests",
            dependencies: ["Fountain"],
            resources: [
                .process("Fixtures"),
            ]
        ),
        .testTarget(
            name: "FountainUIPackageTests",
            dependencies: ["FountainUI", "FountainCore"],
            path: "Tests/FountainUIPackageTests"
        ),
    ]
)
