# Public API surface (Phase 1.3)

This is a **map** of supported entry points, not a substitute for Xcode DocC. Prefer **`import Fountain`** in apps (umbrella); use **`import FountainCore`** or **`import FountainHTML`** only when you want a slimmer dependency graph.

## Modules

| Module | Contents |
|--------|----------|
| **FountainCore** | Parse (`FNScript`, `FastFountainParser`, `FountainParser`), model (`FNElement`, `FNElementType`), Codable export (`FountainDocument`, `ScriptElement`, `FountainMetadataKey`), write (`FountainWriter`), metrics (`FountainScriptMetrics` / `FNScript.metrics`: word counts, element counts, **scene-heading count**, **transition count**), inline markup (`FountainInlineMarkup`, `FountainInlineDelimiterTable`), rendering protocol (`FountainScriptRendering`, plaintext/Markdown/JSON/stub writers), tokens/scanners, async helpers (`parseStringAsync`, `parseFileAsync`, `scriptElementStream(from:)`, `scriptElementStream(fromFile:)`). **No** UIKit/AppKit. |
| **FountainHTML** | `FNHTMLScript`, `FNPaginator`, `Platform` (font typealias), `ScriptCSS.css` resource. |
| **Fountain** | Re-exports Core + HTML for one import. |

## Stability expectations

- **`fountainDocument`** / **`asFountainDocument()`** build a **new** snapshot each time (new ``ScriptElement`` UUIDs). For stable JSON, call ``fountainDocumentJSONData(prettyPrinted:)`` once, or hold a single ``FountainDocument`` value if you need to compare exports.
- **`FNScript`** / **`FNElement`** / **`FountainWriter`** string labels (`elementType`) are **legacy-stable** for existing documents.
- **`FountainDocument`** / **`ScriptElement`** / **`ScriptElementKind`** are the **preferred** interchange shape for JSON and tooling; additive metadata keys may appear in minor releases.
- **`FountainScriptRendering`** conformers may grow; throwing stubs (**`FountainFDXWriter`**, **`FountainPDFWriter`**) are explicitly incomplete.

## Experimental / evolving

- **`FNScript.scriptElementStream(from:)`** / **`scriptElementStream(fromFile:)`** — full parse then stream; not incremental (see [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md)).
- **`FountainMarkdownWriter`** — lossy projection for tools, not a Fountain spec inverse.

For semantic versioning guidance when you change any of the above, see [SPM-Release-Checklist.md](SPM-Release-Checklist.md).
