# Fountain

Fountain is a simple markup syntax that allows screenplays to be written, edited, and shared in plain, human-readable text. Fountain allows you to work on your screenplay anywhere, on any computer, using any software that edits text files.

Like John Gruber’s Markdown, a priority of Fountain is that the raw file itself is eminently readable. Every effort has been made to impose a minimum of syntax requirements. When syntax is required, it should be intuitive. Even when viewed in plain text, your screenplay should feel like a screenplay.

Fountain supports everything that a writer is likely to need in the early, creative phases of writing. Not included are production features such as MOREs, CONTINUEDs, revision marks, locked pages, or colored pages.

Fountain is also a good format for archiving screenplays without worry of file-format obsolescence or incompatibility. For this reason, Fountain does support scene numbers.

For more details on Fountain see [fountain.io](https://fountain.io).

## Fountain Swift package (next-gen)

The **default development path** is **`Package.swift`**: **`swift build`** / **`swift test`** on macOS define CI truth. The library ships a **Swift-native** tokenizer-first parser (**``FountainParsePipeline``**; **no RegexKitLite** in SwiftPM), optional **line-first** **`FastFountainParser`** via **`parser: .fast`**, a **`Codable`** model (`FNElement`, `FountainDocument` / `ScriptElement`), **async** parse helpers, **protocol-based** writers (HTML, Markdown, JSON, plaintext, **minimal FDX**, **PDF**), and an umbrella **`Fountain`** product. **Xcode** (`Fountain.xcodeproj`) links the **same local package** for sample apps and **`FountainTests`** — see [docs/Phase-1-Xcode-SPM-Integration.md](docs/Phase-1-Xcode-SPM-Integration.md). Ongoing work is **polish and depth** (export fidelity vs Final Draft, optional incremental parse, stricter spec edges), not “waiting for a first SwiftPM drop.”

**Two independent version numbers:**

- **Fountain syntax (markup spec):** **`1.1`** today — ``FountainSyntaxPin`` in `FountainSyntaxPin.swift`, [fountain.io/syntax](https://fountain.io/syntax/), and ``FountainDocument.fountainSyntaxVersion`` in JSON. This tracks the **screenplay format** generation, **not** SwiftPM releases.
- **Swift package (SemVer):** **`2.0.0`** today — ``FountainPackageVersion`` in `FountainPackageVersion.swift`, **[CHANGELOG.md](CHANGELOG.md)**, and **git tags**. Library **2.0.0** can ship while the syntax target stays **1.1** (and vice versa in principle).

- **Phased implementation plan:** [docs/Fountain-1.1-Implementation-Roadmap.md](docs/Fountain-1.1-Implementation-Roadmap.md) — **spec / syntax** work is organized there (filename **1.1** = markup roadmap, not package SemVer). **Phase 14** (Swift package **2.0.0** breaking line) is **complete**; **Phase 15** ([polish](docs/Fountain-1.1-Implementation-Roadmap.md#phase-15), including SPM-only **15.1**) is **active**.
- **Changelog / package releases:** [CHANGELOG.md](CHANGELOG.md) — **Swift package** SemVer and breaking API notes.
- **Syntax pin:** ``FountainSyntaxPin`` points at [fountain.io/syntax](https://fountain.io/syntax/) with ``targetVersionLabel`` **`"1.1"`**; lock a spec revision in release notes when you publish a compliance snapshot.
- **Design goals:** [Project Specification: Fountain Swift (Next-Gen)](Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md).
- **Gap analysis:** [docs/Fountain-1.1-Gap-Analysis.md](docs/Fountain-1.1-Gap-Analysis.md) — living inventory and feature matrix; update in the same PR as parser or export changes.
- **SwiftPM:** `Package.swift` at the repo root defines **`FountainCore`** (parse/model/write, no UI), **`FountainHTML`** (`FNHTMLScript`, `FNPaginator`, `Platform`, CSS resource), optional **`FountainUI`** (**SwiftUI** `FountainView` — import **`FountainUI`** in addition to Core when needed), and an umbrella **`Fountain`** product that re-exports Core + HTML only (import **`Fountain`** in apps). The manifest package name is **`FountainSwiftPM`** so it does not collide with the `Fountain` library target under `swift test`. From the repository root run **`swift build`** and **`swift test`** (macOS 13+ / iOS 16+ / Swift 5.9+; Phase **11** Swift `Regex` floor). `FNHTMLScript` loads `ScriptCSS.css` via `Bundle.module` when built as a package. **CI:** pushes and PRs to **`master`** run **`swift build`** and **`swift test`** (`.github/workflows/swift.yml`). Tests include **`Phase5ProductionFeaturesTests`**, **`BrickSteelCorpusTests`**, **`ExportGoldenFixtureTests`** (FDX/PDF golden minimal fixture), and corpus smoke tests. **Tooling:** **`FountainJSONWriter`** / **`FNScript.fountainDocumentJSONData`** emit `FountainDocument` JSON; **`FNScript.metrics`** gives word/element counts (plus scene, transition, character-cue, and dialogue-element counts) with boneyard excluded from body-wide totals; **`FountainInlineMarkup.attributedFragment`** builds `AttributedString` for inline bold/italic (see API doc for underline limits).
- **Cross-platform packaging (Phase 10):** SwiftPM + semver tagging are the default consumer path — [docs/SPM-Release-Checklist.md](docs/SPM-Release-Checklist.md). CI enforces **no UIKit/AppKit** in core `Fountain/*.swift` (see `.github/workflows/swift.yml`). Optional **WebAssembly** compile for **`FountainCore`** only: [docs/SwiftWasm-Experimental.md](docs/SwiftWasm-Experimental.md), `scripts/build-fountaincore-wasm.sh`, and the manual GitHub Actions workflow **Wasm: FountainCore** (`.github/workflows/fountaincore-wasm.yml`).
- **Deprecation stance:** **`Fountain.xcodeproj`** links the **local** Swift package for sample apps and **`FountainTests`** (no duplicate compile of `Fountain/*.swift` in those targets). **`Fountain/Legacy/`** and the Swift **`FountainParser`** / **`FNParserType.regex`** path were **removed** on the road to **2.0.0** — see **[CHANGELOG.md](CHANGELOG.md)** and [docs/Deprecation-And-Distribution.md](docs/Deprecation-And-Distribution.md).
- **Phase 1 (SwiftPM + boundaries):** **Complete** — `Package.swift` defines **FountainCore** / **FountainHTML** / **Fountain**; CI uses **`swift build`** / **`swift test`**. **Phase 1.2:** Xcode samples and **`FountainTests`** use the same package — [docs/Phase-1-Xcode-SPM-Integration.md](docs/Phase-1-Xcode-SPM-Integration.md). **Distribution:** [docs/Deprecation-And-Distribution.md](docs/Deprecation-And-Distribution.md).
- **Public API map (Phase 1.3):** [docs/Public-API-Surface.md](docs/Public-API-Surface.md) — modules, stability notes, experimental areas. **FDX / PDF:** same doc, section *FDX and PDF export (consumer contract)* — minimal `.fdx` XML, PDF file bytes via **`FountainPDFWriter.renderPDFData`**, base64 on **`FountainScriptRendering.render`**, PDF stub on **WebAssembly**.
- **Other implementations & fixtures (Phase 7.3):** there is no single blessed cross-language test corpus; **`swift test`** plus bundled fixtures are the source of truth. For external parsers, links, and a **vendoring/license checklist**, see [docs/External-Fountain-Test-References.md](docs/External-Fountain-Test-References.md).

Contributors: see **[CONTRIBUTING.md](CONTRIBUTING.md)** (regression tests + `swift test`). Use the roadmap to scope issues and PRs; update the roadmap and gap analysis when phases complete or the spec pin changes.

## Overview

To encourage and ease integration of Fountain into your own apps we're making our own Fountain code available to you under a permissive MIT license. The code was designed for our own use, so your mileage may vary, but we're hoping this will at least help you get going with Fountain.

The Xcode project **Fountain** targets **macOS 13+** and **iOS 16+** (match **`Package.swift`**); sample apps and **`FountainTests`** link the **Fountain** Swift package product (core + HTML). The repo-root **`Fountain/Legacy/`** Objective-C tree was **removed** in package **2.0.0**; old **`FountainTests/Legacy/`** `.m` files are not part of SwiftPM CI. The library reads and writes Fountain files and stores the script in a generic data model. If this model is insufficient for your needs, or you have your own model you'd like to use, we recommend using a converter to bridge the two models.

One important note: we do not deal with text styling (bold, italic, underline, etc) in the parser or data model. We retain the styling and pass it along for downstream use. That is, whatever is supposed to display or print the Fountain file should handle text styling and clean up of the styling markup. We think that's just easier on everyone. We've included regular expressions for text styling, in case you need them.

### Sample apps and tests

- **Sample Project Mac** loads `Big Fish.fountain`, builds HTML with `FNHTMLScript`, and displays it in a **`WKWebView`** (see `Application.xib` and `AppDelegate.swift`). The app delegate is exposed to the nib as **`@objc(AppDelegate)`** so the class resolves correctly at load time.
- **Sample Project iOS** does the same in code with `WKWebView` (`ViewController.swift`).
- **FountainTests** is a macOS unit-test bundle; the scheme runs tests hosted in the Mac sample app. Set **`PRODUCT_BUNDLE_IDENTIFIER`** in the target that owns each `Info.plist` so it matches **`$(PRODUCT_BUNDLE_IDENTIFIER)`** in the plist (avoids Xcode warnings and signing issues).

### Parser notes (default vs line-first)

**Default:** **`FNScript(string:)`** / **`init(file:)`** and async/stream overloads without **`parser:`** use **`FountainParsePipeline`** (**`.tokenPipeline`** — Phases **3–4** on the roadmap). **`parser: .fast`** selects **FastFountainParser** (line-first) for parity or migration.

Recent maintenance aligned **FastFountainParser** and the shared tokenizer stack with practical Fountain documents:

- **Scene headings**: slug detection uses patterns and scans that behave correctly across engines (see **`FountainSceneHeadingMatcher`** and roadmap Phase **3.5**).
- **Title page**: a lone directive-only line before the first blank line (for example **`FADE IN:`** with nothing after the colon) is **not** treated as a title-page field, so sluglines are not stripped from the body.
- **Regex modernization:** [docs/Fountain-1.1-Implementation-Roadmap.md](docs/Fountain-1.1-Implementation-Roadmap.md#phase-11-regex-modernization-swift-native) **Phase 11** — Swift **`Regex`** in **`String+Regex.swift`** with a small **`NSRegularExpression`** fallback only when Swift cannot compile a pattern; **`FountainRegexes`** tuned for Swift **`Regex`** where possible.

**SwiftUI preview:** optional **`FountainUI`** (**`FountainView`**) maps inline emphasis via **`FountainInlineMarkup`** (Phase **13.3**).

## Components

### FNScript

FNScript is intended to make it easy to drop Fountain support into new apps. FNScript handles reading and writing of Fountain files, and holds the script content. In Swift, script elements are **`[FNElement]`** and the title page is an array of dictionaries **`[[String: [String]]]`** (legacy Objective-C uses `NSArray` / `NSDictionary`).

### FNElement

This is the data model for the script elements (Objective-C **`FNElement`**, Swift **`FNElement`**).

### FastFountainParser

FastFountainParser is a redesigned line-by-line parser with less reliance on whole-document regular expressions than the pre–SwiftPM regex pipeline. **Swift** `FNScript` defaults to the **tokenizer pipeline** (**`.tokenPipeline`**); pass **`parser: .fast`** for this engine.

### FountainWriter

FountainWriter converts an `FNScript` back into Fountain markup (**`String`** / **`NSString`** APIs depending on language).

### FNHTMLScript

FNHTMLScript renders an `FNScript` as HTML for preview or export. The sample apps bundle **`ScriptCSS.css`** and load it from **`Bundle.main`** when building the page.

### FountainRegexes

Shared regular-expression constants for **HTML** export, slug/title helpers, and legacy string utilities. Matching helpers in **`String+Regex.swift`** prefer Swift **`Regex`**. Day-to-day parsing uses **`FountainParsePipeline`** (**`.tokenPipeline`**, default) or **`FastFountainParser`** (**`.fast`**).

## Installation

**Using this Xcode project**

1. Open **`Fountain.xcodeproj`** in Xcode (recommended **Xcode 15+**).
2. Build the **Fountain** Swift sources into your own target, or copy the **`Fountain/`** Swift files into your app and add them to a target that also imports **Foundation** (and **AppKit** / **UIKit** where platform types are used).
3. For **HTML output**, include **`ScriptCSS.css`** in your app target’s **Copy Bundle Resources** if you use **`FNHTMLScript`** the same way as the samples.

## Usage

See **Sample Project Mac** and **Sample Project iOS**: load a `.fountain` file into **`FNScript`**, wrap it in **`FNHTMLScript`**, and load the resulting HTML in a **`WKWebView`**. The Mac sample uses **`Application.nib`** for the window and web view; the iOS sample builds the web view in code.

## Testing

The **FountainTests** scheme runs a **macOS** XCTest bundle against the **Sample Project Mac** host app. Tests cover parsing, writer round-trips, and sample screenplays (including **Big Fish**). Run **Product → Test** or `xcodebuild -scheme FountainTests test`.

## License

All code is copyright Nima Yousefi &amp; John August. Released under an MIT license. Do whatever you want with this code, but it would be super cool if you shared your improvements with the world.

See the included LICENSE file for legal jargon.

## Contact

If you have any questions, or just want to say 'hi', you can catch me on Twitter [@nyousefi](http://twitter.com/nyousefi).

Follow Qapps on Twitter [@qapps](http://twitter.com/qapps).


## Credits

### Fountain Format

Fountain comes from several sources. John August and Nima Yousefi developed Scrippets, which used simple markup to embed screenplay-formatted material in websites. Stu Maschwitz drafted a more extensive spec known as Screenplay Markdown or SPMD, designed for full-length screenplays.

Stu and John discovered that they were simultaneously working on similar text-based screenplay formats, and merged them into what you see here. Other contributors to the spec include Martin Vilcans, Brett Terpstra, Jonathan Poritsky, and Clinton Torres.

### Fountain Code

The code included here was developed by Nima Yousefi and John August, with copious emotional and spiritual support by Ryan Nelson and Stuart Friedel. However, all invectives should be directly solely at Nima Yousefi (don't worry, he has it coming).