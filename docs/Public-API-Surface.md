# Public API surface (Phase 1.3)

This is a **map** of supported entry points, not a substitute for Xcode DocC. Prefer **`import Fountain`** in apps (umbrella); use **`import FountainCore`** or **`import FountainHTML`** only when you want a slimmer dependency graph.

**Phase 1.3 status:** **Complete** for documentation and stability expectations below. **`@_spi(…)`** is not applied in source yet; when a subsystem stabilizes, you may narrow visibility without changing runtime behavior.

## API tiers (semver guidance)

| Tier | Treat as | Examples |
|------|-----------|----------|
| **Stable intent** | Avoid breaking changes in patch releases; deprecate before removal. | `FNScript` default initializers, `FNElement` (value type: `id` + `elementType` / `elementText` fields), `FountainWriter`, `FastFountainParser` as used by `FNScript` |
| **Preferred interchange** | Additive fields/keys OK in minor releases. | `FountainDocument`, `ScriptElement`, `ScriptElementKind`, `FountainMetadataKey` |
| **Evolving** | May change more freely; document in release notes. | `FountainScriptMetrics` fields, new `FountainScriptRendering` conformers, coarse tokenizer output (`FountainBodyLineTokenizer` / `FountainTokenizedLine` kinds) as the universal parser evolves |
| **Experimental** | Not semver-stable; may change or be removed. | Streaming APIs, `FountainMarkdownWriter`, stub `FountainFDXWriter` / `FountainPDFWriter` |

## Modules

| Module | Contents |
|--------|----------|
| **FountainCore** | Parse (`FNScript`, `FastFountainParser`, `FountainParser`), model (`FNElement`: `Codable`, `Identifiable`, UUID `id`; `FNElementType`), Codable export (`FountainDocument`, `ScriptElement`, `FountainMetadataKey`), write (`FountainWriter`), metrics (`FountainScriptMetrics` / `FNScript.metrics`: word counts, element counts, scene/transition counts, **character-cue count**, **dialogue-element count**), inline markup (`FountainInlineMarkup`, `FountainInlineDelimiterTable`), rendering protocol (`FountainScriptRendering`, plaintext/Markdown/JSON/stub writers), **Phase 3 tokenization** (`FountainTokenKind`, `FountainTokenizedLine`, `FountainLineSplitter`, `FountainTitlePagePrescan`, `FountainStructuralLineMatchers`, `FountainBodyLineTokenizer`, `FountainForcedPrefixScanner`, `FountainSceneHeadingMatcher`), async helpers (`parseStringAsync`, `parseFileAsync`, `scriptElementStream(from:)`, `scriptElementStream(fromFile:)`). **No** UIKit/AppKit. |
| **FountainHTML** | `FNHTMLScript`, `FNPaginator`, `Platform` (font typealias), `ScriptCSS.css` resource. |
| **Fountain** | Re-exports Core + HTML for one import. |

## Stability expectations

- **`fountainDocument`** / **`asFountainDocument()`** build a **new** snapshot each time; each ``ScriptElement`` reuses the corresponding parsed ``FNElement/id`` so IDs stay aligned across repeated snapshots of the same ``FNScript``. For stable JSON bytes, call ``fountainDocumentJSONData(prettyPrinted:)`` once, or hold a single ``FountainDocument`` value while comparing exports.
- **`FNScript`** / **`FNElement`** / **`FountainWriter`** string labels (`elementType`) are **legacy-stable** for existing documents.
- **`FountainDocument`** / **`ScriptElement`** / **`ScriptElementKind`** are the **preferred** interchange shape for JSON and tooling; additive metadata keys may appear in minor releases.
- **`FountainScriptRendering`** conformers may grow; throwing stubs (**`FountainFDXWriter`**, **`FountainPDFWriter`**) are explicitly incomplete.

## Experimental / evolving

- **`FNScript.scriptElementStream(from:)`** / **`scriptElementStream(fromFile:)`** — full parse then stream; not incremental (see [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md)).
- **`FountainMarkdownWriter`** — lossy projection for tools, not a Fountain spec inverse.

For semantic versioning guidance when you change any of the above, see [SPM-Release-Checklist.md](SPM-Release-Checklist.md).
