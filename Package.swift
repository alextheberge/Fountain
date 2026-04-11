// swift-tools-version: 5.9
// Fountain Swift Package — core vs HTML split + umbrella `Fountain` (see docs/Fountain-1.1-Implementation-Roadmap.md).
// Syntax target: `FountainSyntaxPin.targetVersionLabel` (currently 1.1).
import PackageDescription

// Package name must differ from the `Fountain` library target to avoid SPM test-runner build cycles.
let package = Package(
    name: "FountainSwiftPM",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
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
    ],
    targets: [
        .target(
            name: "FountainCore",
            path: "Fountain",
            exclude: [
                "Legacy",
                "ScriptCSS.css",
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
            ],
            sources: [
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
            sources: ["Fountain.swift"]
        ),
        .testTarget(
            name: "FountainPackageTests",
            dependencies: ["Fountain"],
            resources: [
                .process("Fixtures"),
            ]
        ),
    ]
)
