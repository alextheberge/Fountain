# Public API surface (Phase 1.3)

This is a **map** of supported entry points, not a substitute for Xcode DocC. Prefer **`import Fountain`** in apps (umbrella); use **`import FountainCore`** or **`import FountainHTML`** only when you want a slimmer dependency graph.

**Phase 1.3 status:** **Complete** for documentation and stability expectations below. **Phase 7** (SwiftPM test matrix and external-suite tracking) is documented in [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md) and [External-Fountain-Test-References.md](External-Fountain-Test-References.md). **Phase 8** (``FountainScriptRendering`` + plaintext / Markdown / JSON / HTML + **FDX / PDF** exporters) is **initial-complete** per the roadmap. **Phase 9** (async full parse + element streaming; incremental parse explicitly deferred) is summarized in the roadmap and [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md). **Phase 10** (SPM default distribution, CI parser/UI boundary, optional Wasm **FountainCore** build) is covered in [SPM-Release-Checklist.md](SPM-Release-Checklist.md) and [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md). **`@_spi(…)`** is not applied in source yet; when a subsystem stabilizes, you may narrow visibility without changing runtime behavior.

## API tiers (semver guidance)

| Tier | Treat as | Examples |
|------|-----------|----------|
| **Stable intent** | Avoid breaking changes in patch releases; deprecate before removal. | `FNScript` default initializers, `FNElement` (value type: `id` + `elementType` / `elementText` fields), `FountainWriter`, `FastFountainParser` as used by `FNScript` |
| **Preferred interchange** | Additive fields/keys OK in minor releases. | `FountainDocument`, `ScriptElement`, `ScriptElementKind`, `FountainMetadataKey` |
| **Evolving** | May change more freely; document in release notes. | `FountainScriptMetrics` fields, new `FountainScriptRendering` conformers, coarse tokenizer output (`FountainBodyLineTokenizer` / `FountainTokenizedLine` kinds), `FountainScriptElementsBuilder`, **`FNParserType/tokenPipeline`** on ``FNScript`` (tokenizer-first path; parity-tested vs ``fast`` — API and default may change before it becomes the sole engine) |
| **Experimental** | Not semver-stable; may change or be removed. | Streaming APIs, `FountainMarkdownWriter`, `FountainFDXWriter` / `FountainPDFWriter` export layouts (minimal .fdx structure; PDF base64 via ``FountainScriptRendering`` — treat output format as evolving) |

## Modules

| Module | Contents |
|--------|----------|
| **FountainCore** | Parse (`FNScript`, `FastFountainParser`, `FountainParser`), model (`FNElement`: `Codable`, `Identifiable`, UUID `id`; `FNElementType`), Codable export (`FountainDocument`, `ScriptElement`, `FountainMetadataKey`), write (`FountainWriter`), metrics (`FountainScriptMetrics` / `FNScript.metrics`: word counts, scene/transition/cue/dialogue counts, **page-break / boneyard / section / synopsis / bracket-note counts**), inline markup (**Phase 6:** `FountainInlineMarkup`, `FountainInlineDelimiterTable`, `FountainInlineRenderingMode`, `FountainInlineRenderResult`, `FountainInlineMarkup.renderInline`, `FountainInlineAttributedKeys` for underline on `AttributedString`), rendering protocol (`FountainScriptRendering`, plaintext/Markdown/JSON/FDX/PDF writers), **Phase 3–4 pipeline** (`FountainTokenKind`, `FountainTokenizedLine`, `FountainLineSplitter`, `FountainTitlePagePrescan`, `FountainStructuralLineMatchers`, `FountainBodyLineTokenizer`, `FountainForcedPrefixScanner`, `FountainSceneHeadingMatcher`, `FountainDialogueBlockRecognizer`, `FountainScriptElementsBuilder`), async helpers (`parseStringAsync`, `parseFileAsync`, `scriptElementStream(from:)`, `scriptElementStream(fromFile:)`). **No** UIKit/AppKit. |
| **FountainHTML** | `FNHTMLScript`, `FountainHTMLWriter` (``FountainScriptRendering`` adapter), `FNPaginator`, `Platform` (font typealias), `ScriptCSS.css` resource. |
| **Fountain** | Re-exports Core + HTML for one import. |

## FDX and PDF export (consumer contract)

Use this section as the **single** contract for Final Draft and PDF output (see also [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) for Wasm).

| Writer | Output | How to consume |
|--------|--------|----------------|
| **`FountainFDXWriter`** | **Minimal Final Draft `.fdx` XML** (`String`): `FinalDraft` + `Content` + `Paragraph`/`Text` only — enough for typical import into Final Draft; **not** a full native FD document (no `ElementSettings` / watermark boilerplate). | Save UTF-8 bytes to a `.fdx` file. **Regression:** `Tests/FountainPackageTests/Fixtures/export-golden-minimal.{fountain,fdx}` + ``ExportGoldenFixtureTests/testFDXWriterMatchesGoldenMinimalFixture`` — update the `.fdx` fixture only when intentionally changing export shape. |
| **`FountainPDFWriter`** | **US Letter**, Courier, CoreGraphics + CoreText (`Data` via ``renderPDFData(_:)``). | **Always** use ``renderPDFData(_:)`` to write a `.pdf` file. ``FountainScriptRendering/render(_:)`` returns **base64-encoded** `Data` because the protocol returns `String` — decode with `Data(base64Encoded:)`. **Regression:** ``ExportGoldenFixtureTests`` checks PDFKit-extracted text for the same minimal fixture. |
| **Wasm (`arch(wasm32)`)** | **`FountainPDFWriter`** is a **stub** (throws ``FountainStubRendererError``); **FDX** still works (Foundation-only). | Use FDX / plaintext / JSON on WebAssembly builds of **FountainCore**. |

## Stability expectations

- **`fountainDocument`** / **`asFountainDocument()`** build a **new** snapshot each time; each ``ScriptElement`` reuses the corresponding parsed ``FNElement/id`` so IDs stay aligned across repeated snapshots of the same ``FNScript``. For stable JSON bytes, call ``fountainDocumentJSONData(prettyPrinted:)`` once, or hold a single ``FountainDocument`` value while comparing exports.
- **`FNScript`** / **`FNElement`** / **`FountainWriter`** string labels (`elementType`) are **legacy-stable** for existing documents.
- **`FountainDocument`** / **`ScriptElement`** / **`ScriptElementKind`** are the **preferred** interchange shape for JSON and tooling; additive metadata keys may appear in minor releases.
- **`FountainScriptRendering`** conformers may grow; **FDX/PDF** output details (layout, full Final Draft metadata) may evolve in minor releases — decode PDF via ``FountainPDFWriter/renderPDFData(_:)`` when you need `Data`.

## Experimental / evolving

- **`FNScript.scriptElementStream(from:)`** / **`scriptElementStream(fromFile:)`** — full parse then stream (``scriptElementStream(from:)`` uses ``parseStringAsync``); **not** line-incremental (see [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md)).
- **`FountainMarkdownWriter`** — lossy projection for tools, not a Fountain spec inverse.

For semantic versioning guidance when you change any of the above, see [SPM-Release-Checklist.md](SPM-Release-Checklist.md).
