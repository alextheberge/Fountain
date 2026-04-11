# Fountain 1.1 — Implementation Roadmap (Swift Next-Gen)

This document turns [Project Specification- Fountain Swift (Next-Gen).md](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) into **phased, checkable work**. Use it for planning, PR scoping, and regression tracking.

**Canonical spec:** [Fountain 1.1](https://fountain.io/syntax/) (keep a pinned revision or changelog URL in this repo when you start compliance work).

---

## How to maintain this roadmap

| Practice | Why |
|--------|-----|
| **One phase per epic / major PR series** | Keeps reviews bounded and bisect-friendly. |
| **Check boxes in Git** | Use `- [ ]` / `- [x]` in PR descriptions or a living issue; sync major milestones here quarterly. |
| **Spec diff workflow** | When Fountain spec updates, add a row to § [Spec traceability](#spec-traceability-matrix) and open a focused “spec delta” task. |
| **Tests before “done”** | No phase closes without automated tests listed under that phase (see § [Test suite](#7-test-suite--fountain-11-compliance)). |

---

## Guiding outcomes (from the Next-Gen spec)

1. **No RegexKitLite / `-licucore`** — Swift `Regex` (5.7+) or hand-rolled scanning where clearer.
2. **Parser core is platform-agnostic** — No UIKit/AppKit in parse/model packages; platform hooks only behind `#if` at render or app boundaries.
3. **Fountain 1.1 coverage** — Forced elements, sections/synopses, lyrics, dual dialogue, boneyard, page breaks, scene numbers, transitions, etc., per spec.
4. **Structured, tool-friendly model** — `Codable`, stable IDs, explicit types; suitable for AI-assisted editing and round-trips.
5. **Pluggable output** — Not only HTML; protocol-based writers.
6. **Large-document UX** — Async parsing path; optional incremental parse later.

---

## Phase 0 — Baseline and inventory

**Goal:** Know what you have and what “1.1 done” means in this codebase.

**Status:** **Complete.** Baseline inventory and policy are documented; the gap analysis file stays **living** as implementation progresses (see § Phase 0 in [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md)).

| Step | Action | Done when |
|------|--------|-----------|
| 0.1 | Inventory current parsers (`FastFountainParser`, `FountainParser`, legacy ObjC) and **list gaps vs Fountain 1.1** (forced rules, boneyard, notes, dual dialogue, etc.). | **Done:** [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) § Parser inventory + feature matrix + fixture map |
| 0.2 | Inventory **all regex patterns** (`FountainRegexes.swift` / `.m`) and mark which are **spec-critical** vs **styling-only**. | **Done (Swift):** table in [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) § Regex pattern inventory (`.m` out of package; see gap analysis note) |
| 0.3 | Decide **deprecation policy**: keep legacy targets for one release, feature-flag, or hard cut. | **Done:** [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) § Phase 0.3 — Deprecation policy (decided) |
| 0.4 | Add **pin** to Fountain syntax version you’re targeting (1.1 + any errata). | **Done:** `FountainSyntaxPin` + README link; optional errata URL in release notes when locking compliance |

**Deliverable:** `docs/Fountain-1.1-Gap-Analysis.md` (living document; Phase 0 baseline section marks completion).

---

## Phase 1 — Swift Package and module boundaries

**Goal:** A **SwiftPM library** that can be used by macOS/iOS apps **and** future tooling without Xcode-only coupling.

**Status:** **Complete** for library distribution, CI, module split, documented public API, and **Phase 1.2** — Xcode sample apps and **`FountainTests`** link the **local** Swift package (no duplicate `Fountain/*.swift` compile in those targets). Details: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md). An optional **SwiftUI** **`FountainUI`** library is **not** required to close Phase 1 — see [Phase 13](#phase-13-swiftui-and-fountainui). **Future:** dropping **`Fountain.xcodeproj`** for **SPM-only** workflows is **[Phase 14](#phase-14-version-20-and-spm-only-repository)**.

| Step | Action | Done when |
|------|--------|-----------|
| 1.1 | Create `Package.swift` with **`FountainCore`** + **`FountainHTML`** + umbrella **`Fountain`** — core has **no** UI frameworks; HTML target holds AppKit/UIKit usage. | **Done:** `swift build` + `swift test` at repo root; products `Fountain`, `FountainCore`, `FountainHTML` |
| 1.2 | Move or duplicate **model + parse + write** into the package; keep sample apps consuming the package (or same sources via careful symlink — prefer package as source of truth). | **Done:** Single **`Fountain/`** source tree; **no** second copy of library sources. **SPM** defines the canonical module graph; **Xcode** sample targets and **`FountainTests`** link the **local** package product **Fountain** (see [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)). |
| 1.3 | Define **public API surface** (`FNScript`, element types, errors). Mark experimental APIs `@_spi` or nested `FountainCore.Experimental` if needed. | **Done:** [Public-API-Surface.md](Public-API-Surface.md) — stability tiers + experimental list; **`@_spi`** reserved for when churn drops (not required to close Phase 1) |
| 1.4 | **CI:** `swift build` + `swift test` on macOS (Linux where possible; Wasm later). | **Done:** `.github/workflows/swift.yml` on **macOS**; Linux/Wasm not in matrix because package platforms are **macOS 12+** / **iOS 15+** only (see Phase 10 for Wasm stretch) |

---

## Phase 2 — Data model (replace/align `FNElement`)

**Goal:** **Codable**, **Identifiable**, **stable round-trip** to JSON for tooling.

**Status:** **Complete (initial)** — `FNElement` is a **`struct`** with **`Codable`**, **`Identifiable`**, and stable **`id`** carried into ``ScriptElement``; typed metadata remains on ``ScriptElement.metadata`` / ``FountainMetadataKey``. Legacy **Objective-C** reference sources under **`Fountain/Legacy/`** remain **out of SwiftPM** until removed in **[Phase 14](#phase-14-version-20-and-spm-only-repository)**.

| Step | Action | Done when |
|------|--------|-----------|
| 2.1 | Introduce **`FNElementType`** `String` enum (or similar) covering **all** 1.1 structural kinds you need (including `pageBreak`, `boneyard`, `synopsis`, `section`, `general`, `note`, etc. — align names with spec vocabulary). | **Done:** `FNElementType` + map to `ScriptElementKind` |
| 2.2 | Implement **`FNElement`** struct: `id`, `type`, `content`, **`attributes: [String: String]`** (or typed `Metadata` struct with `Codable`) for scene number, section depth, `dualDialogue`, `centered`, etc. | **Done (Swift):** `FNElement` struct with `id` + legacy field names (`elementType`, `elementText`, …); scene/section/dual/centered via fields + **also** in ``ScriptElement.metadata`` / ``FountainMetadataKey``; golden JSON in `Tests/FountainPackageTests/Fixtures/` |
| 2.3 | Migration shim from **old** `FNElement` class / `elementType: String` if dual-stack period is required. | **Done (Swift):** no dual Swift stack; ``LegacyInteropTests`` cover kind alignment, ``FNElement`` JSON round-trip, and **ID parity** ``FNElement`` ↔ ``ScriptElement`` |
| 2.4 | Define **`FNScript`** (or `FountainDocument`) with `elements` + `titlePage` + version metadata. | **Done:** `FountainDocument(script:)` + ``FNScript.fountainDocument`` / ``fountainDocumentJSONData(prettyPrinted:)`` + ``asFountainDocument()`` + `FountainSyntaxPin` |

---

## Phase 3 — Tokenization (Phase 1 of “Universal Parser”)

**Goal:** **State-aware scanning** — classify **lines** (and line continuations) into **tokens** without building the final tree yet.

**Status:** **Complete (initial)** — shared title-page prescan, structural line matchers, coarse body line tokenizer (aligned with ``FastFountainParser``), and existing forced-prefix + slug helpers. Production parse remains ``FastFountainParser`` by default; **opt-in tokenizer-first load** is ``FNScript(…, parser: .tokenPipeline)`` via ``FountainParsePipeline`` (tests: ``TokenPipelineFNScriptTests``). The tokenizer is for tooling, previews, and the migration path toward a single canonical engine. **Next:** [Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript) flips the default to the state-aware pipeline and deprecates the line-first engine once parity work is complete.

| Step | Action | Done when |
|------|--------|-----------|
| 3.1 | Specify **token kinds** (slug, action, character, dialogue, parenthetical, transition, lyrics, section, synopsis, pagebreak, boneyard open/close, title-page directive, blank, unknown…). | **Done:** `FountainTokenKind` + `FountainTokenizedLine` + `LineEndingNormalizationTests` |
| 3.2 | Implement **line splitter** honoring Fountain newline rules; normalize `\r\n` once at input. | **Done:** `FountainLineEndingNormalizer` / `FountainLineSplitter` + `LineSplitterTests` |
| 3.3 | Implement **title page pre-scan** (before body) consistent with 1.1; **do not** mis-classify body lines like `FADE IN:` as title keys (regression from current fast parser fixes). | **Done:** `FountainTitlePagePrescan` (used by ``FastFountainParser``) + `TitlePageRegressionTests` + `Phase3TokenizationTests` |
| 3.4 | Map **forced prefixes** to tokens: `.` scene, `!` action, `@` character, `~` lyrics, `>` transition (non-centered), etc. | **Done:** `FountainForcedPrefixScanner` + `ForcedPrefixScannerTests`; body tokenizer applies full line order including forced lines |
| 3.5 | Replace fragile regex-only checks with **scanner + Regex hybrid**: use `Regex` for **localized** patterns (e.g. scene heading stem), not whole-document substitution. | **Done:** `FountainSceneHeadingMatcher` + `FountainStructuralLineMatchers` + corpus smoke (`BigFishCorpusTests`); **polish:** Swift `Regex` slug stem on **macOS 13+ / iOS 16+**, `NSRegularExpression` fallback for package floors (macOS 12 / iOS 15). **Follow-up:** [Phase 11](#phase-11-regex-modernization-swift-native) removes `NSRegularExpression` from **`String+Regex.swift`** and modernizes **`FountainRegexes.swift`**. |

---

## Phase 4 — Contextual analysis (Phase 2 of “Universal Parser”)

**Goal:** Tokens → **blocks** (dialogue blocks, dual dialogue, continuity).

**Status:** **Complete (initial)** — dialogue line roles align with ``FastFountainParser`` parenthetical detection; dual-`^` columns match the fast parser and ``FountainScriptElementsBuilder``; token→element assembly is parity-tested against ``FNScript`` on package fixtures. Canonical production parse remains ``FNScript`` / ``FastFountainParser``; the builder proves the Phase 3 tokenizer stream can reconstruct element **types** (and merges) for the same inputs. **Next:** [Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript) makes that stream the **default** parse path (Project Specification *State-Aware Scanner*). **Tightening:** **4.6** removes the legacy **whitespace-only** “forced action” path in favor of strict **`!`**.

| Step | Action | Done when |
|------|--------|-----------|
| 4.1 | **Dialogue block** state machine: Character → optional Parenthetical → Dialogue (multi-line rules per 1.1). | **Done:** `FountainDialogueBlockRecognizer` (leading-`(` rule) + `DialogueBlockRecognizerTests` |
| 4.2 | **Dual dialogue** (`^`): pair detection and **column** metadata in `attributes`. | **Done:** Parser + ``FountainScriptElementsBuilder`` + `SpecTraceabilityTests` / `Phase4ParityTests` (`package-dual-dialogue.fountain`) |
| 4.3 | **Action** merging rules (soft line breaks vs hard breaks) — explicitly match 1.1; **remove reliance on trailing spaces** for forcing; prefer **`!`**. | **Done:** `ActionMergingTests`; legacy all-whitespace action lines remain accepted in ``FastFountainParser`` (document-only preference for `!`) |
| 4.4 | **Centered text** `> ... <` vs **forced transition** `>` — disambiguation per spec. | **Done:** `ParseStructureTests` + tokenizer order (`> … TO:` → transition before bare-`>` branch) |
| 4.5 | Emit final **`[FNElement]`** list from token stream. | **Done:** `FountainScriptElementsBuilder` + `Phase4ParityTests` (element-type parity vs ``FNScript`` on fixtures) + existing `Phase45RoundTripTests` / export round-trip |
| 4.6 | **Strict forced action (`!` only):** update the **parser state machine** (``FastFountainParser`` and ``FountainBodyLineTokenizer`` / ``FountainScriptElementsBuilder`` so **`.tokenPipeline`** stays aligned) to **require** the **`!`** prefix for **forced action** per Fountain 1.1; **deprecate** then **remove** the legacy branch that treats **two-or-more whitespace-only lines** (`^\\s{2,}$`) as standalone **Action** elements. Optional one-release **warnings** or migration note before removal. | `- [ ]` Legacy whitespace path **gone** or removed per semver plan; **`ActionMergingTests`**, **`SpecTraceabilityTests`**, **`TokenPipelineFNScriptTests`** updated; [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) / README document any **breaking** classification change. |

---

## Phase 5 — Production features (Phase 3 of “Universal Parser”)

**Goal:** Page breaks, scene numbers, omissions/notes, boneyard semantics for **metrics** and **export**.

**Status:** **Complete (initial)** — production parse + export paths covered; ``FountainScriptMetrics`` extended for page breaks, boneyard, sections, synopses, and bracket notes; ``FNPaginator`` interaction with explicit page breaks tested; ``ScriptElementKind`` documents note vs boneyard for exporters.

| Step | Action | Done when |
|------|--------|-----------|
| 5.1 | **Page breaks** (`===`…): distinct elements; interaction with pagination if you keep `FNPaginator`. | **Done:** `Phase5ProductionFeaturesTests` (distinct element + ``FNPaginator`` flush) |
| 5.2 | **Scene numbers** (`#...#` on slugs): capture in attributes; optional `suppressSceneNumbers` flag. | **Done:** `Phase5ProductionFeaturesTests` (slug capture + `suppressSceneNumbers` export) |
| 5.3 | **Boneyard** `/* ... */`: strip or isolate for **word-count / timing** estimators; verify **not** counted as dialogue. | **Done:** `FNScript.elementsExcludingBoneyard` + ``FNScript.metrics`` (body slice for words / dialogue / scenes / cues; **`boneyardElementCount`**) + `FountainScriptMetricsTests` + `package-boneyard-sandwich.fountain` |
| 5.4 | **Notes** `[[ ... ]]` per 1.1: element type or annotation model; clarify vs boneyard for exporters. | **Done:** `Phase5ProductionFeaturesTests` + ``ScriptElementKind`` doc on ``comment`` vs ``boneyard`` + ``FountainScriptRendering`` behavior |
| 5.5 | **Sections / synopses** (`#`, `##`, `=`): hierarchical depth in attributes. | **Done:** `Phase5ProductionFeaturesTests` + metrics **`sectionHeadingCount`** / **`synopsisCount`** |

---

## Phase 6 — Inline markup and `AttributedString` (optional but spec-aligned)

**Goal:** Fix “markup leakage” — **optional** rich-text pipeline.

| Step | Action | Done when |
|------|--------|-----------|
| 6.1 | Document **two modes**: `plain` (preserve markers in `content`) vs `rich` (parse to `AttributedString` segments). | **Done:** ``FountainInlineRenderingMode`` + ``FountainInlineRenderResult`` + ``FountainInlineMarkup.renderInline(_:mode:)`` + ``attributedStringFromInlineMarkup`` + ``FountainInlineMarkup.attributedFragment(from:)`` + `FountainInlineAttributedTests` + `Phase6InlinePolicyTests` |
| 6.2 | Implement **bold / italic / underline** (and `_` where spec applies) with **Fuzzili-safe** parsing (no catastrophic backtracking). | **Done:** shared scanner → ``htmlFragment`` / ``attributedFragment``; underline on `AttributedString` via ``FountainInlineAttributedKeys.Underline`` (core-only, no UIKit/AppKit); HTML full fidelity + `FountainInlineMarkupTests` / `Phase6InlinePolicyTests` |
| 6.3 | Keep **regex/constants** in one module for **Wasm** reuse. | **Done:** `FountainInlineDelimiterTable` (bold/italic/underline flags per rule) + `FountainRoadmapExtensionsTests` |

---

## Phase 7 — Test suite & Fountain 1.1 compliance

**Goal:** **Repeatable** compliance, not “looks right in the app.”

| Step | Action | Done when |
|------|--------|-----------|
| 7.1 | Curate **official-style fixture set**: minimal one-liners per rule + **Big Fish** + **Brick & Steel** + edge cases (forced lines, boneyard, dual). | **Done:** `BigFishCorpusTests` + `BrickSteelCorpusTests` + `PackageFixtureCorpusTests` + bundled `Tests/FountainPackageTests/Fixtures/*.fountain` + `SpecTraceabilityTests` + `Phase7ComplianceTests` (fixture inventory + minimal slug / parenthetical / bracket note / page break / `CUT TO:` rows) |
| 7.2 | Add **structured assertions**: expected `FNElementType` sequences + key attributes (not only string snapshots). | **Done:** `ParseAssertions` + `ParseStructureTests` + `StructuredComplianceTests` + `GoldenDocumentTests` + `Phase45RoundTripTests` / `Phase7ComplianceTests` (`assertFountainDocumentsStructurallyEqual` on JSON); **Big Fish** / **Brick & Steel** corpus JSON + metrics |
| 7.3 | Track **external suite** if one exists (community “standardized Fountain test suite” — integrate or vendor with license check). | **Done:** [README](../README.markdown) (summary) + [External-Fountain-Test-References.md](External-Fountain-Test-References.md) (table + vendoring checklist) |
| 7.4 | **Regression policy:** any parser bugfix adds a **minimal** new fixture. | **Done:** [CONTRIBUTING.md](../CONTRIBUTING.md) (parser / format regression section) |

---

## Phase 8 — `FountainWriter` protocol and renderers

**Goal:** **Eliminate monolithic HTML** in core; multiple backends.

**Status:** **Complete (initial)** — unified ``FountainScriptRendering`` API; plaintext / Markdown / JSON / HTML + **FDX / PDF** exporters with tests. Legacy ``FountainWriter`` remains for Fountain body/title string export; new call sites should prefer protocol conformers. **Follow-up:** **8.5** / **8.6** improve **cross-platform** pagination measurement and **PDF** portability (Wasm / Linux). **8.7** / **8.8** deepen **FDX** / **PDF** fidelity for **Final Draft** layout and **screenplay pagination** (MORE / CONT’D, headers).

| Step | Action | Done when |
|------|--------|-----------|
| 8.1 | Define `FountainWriter` (or `ScriptRenderer`) protocol: `func render(_ document: FNScript) throws -> String` (or associated type for binary PDF). | **Done:** ``FountainScriptRendering`` + ``FountainPlaintextWriter``; parity vs ``FountainWriter.documentFromScript`` (``FountainScriptRenderingTests`` / ``testFountainPlaintextWriterMatchesFountainWriterDocument``) |
| 8.2 | **`HTMLWriter`**: migrate from `FNHTMLScript`; modern CSS (grid/flex); keep **CSS as resource** or string template. | **Done:** ``FNHTMLScript`` conforms to ``FountainScriptRendering``; ``FountainHTMLWriter`` (thin adapter in **FountainHTML**); `ScriptCSS.css` resource + dual-dialogue grid tests (`FountainScriptRenderingTests`) |
| 8.3 | **`MarkdownWriter`**: useful for LLM/tooling pipelines. | **Done:** ``FountainMarkdownWriter`` + ``FountainJSONWriter`` + `FountainScriptRenderingTests` (lyrics + bracket notes + JSON shape) |
| 8.4 | **`FDXWriter`** / **`PDFWriter`**: Final Draft XML + PDF export. | **Done:** ``FountainFDXWriter`` emits minimal importable .fdx; ``FountainPDFWriter`` renders US Letter PDF via CoreGraphics/CoreText (``render`` = base64, ``renderPDFData`` = `Data`). Tests: ``FountainScriptRenderingTests`` (`testFDXWriterEmitsFinalDraftXML`, `testPDFWriterProducesValidPDFBytes`). |
| 8.5 | **Abstract text measurement** out of ``FNPaginator`` behind a protocol (e.g. **`TextMeasurer`**) so **core pagination math** does not hard-code **UIKit/AppKit** font metrics. Ship a **default** implementation in **FountainHTML** (or a thin **`FountainApple`** product) using **`NSAttributedString` / `UIFont` / `NSFont`** (or equivalent) on Apple platforms; **Wasm / Linux** consumers inject their own measurer (e.g. **HTML Canvas**-backed layout in JS, or a stub for tests). | `- [ ]` Protocol + injection API documented in [Public-API-Surface.md](Public-API-Surface.md); **FountainHTML** (or new target) builds on **macOS/iOS**; **FountainCore** stays free of UIKit/AppKit except allowed files per Phase 10.2; regression tests for paginator output with a **fake** `TextMeasurer`; [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) notes how hosts supply measurement. |
| 8.6 | **PDF portability:** if **FountainPDFWriter** stays in-repo, either (a) adopt a **lightweight cross-platform** PDF generator that does not require **CoreGraphics** on every OS, **or** (b) **strictly isolate** ``FountainPDFWriter`` (and any CoreText/CoreGraphics-only code paths) behind **`#if canImport(CoreGraphics)`** (and related guards), matching the existing **wasm32** stub story with a clear **Linux** story. | `- [ ]` Decision recorded in this doc or **ADR**; **Package.swift** / conditional stubs aligned; **`swift test`** on **macOS** unchanged or updated per choice; **Wasm** script outcome recorded; consumers without CoreGraphics get a **compile-time** or **runtime** stub with documented behavior. |
| 8.7 | **FDX — Final Draft layout metadata:** extend ``FountainFDXWriter`` to emit standard **`<ElementSettings>`** (page size, margins, dialogue / action / character **industry-style** defaults) and **`<MoresAndContinueds>`** (or equivalent Final Draft boilerplate your research confirms) so **Final Draft** opens exports with **correct margins** instead of generic defaults. Prefer **injecting** XML fragments or small templates so values stay maintainable. | `- [ ]` Golden **`.fdx`** fixture updated or new fixture added; **manual** open in Final Draft (document version in PR); [Public-API-Surface.md](Public-API-Surface.md) *FDX consumer contract* updated if output shape changes. |
| 8.8 | **PDF — screenplay pagination:** implement **(MORE)** and **(CONT’D)** when **dialogue breaks across pages** — coordinate **``FNPaginator``** (page breaks / overflow) with **``FountainPDFWriter``** so split dialogue matches common US screenplay convention (hard requirement for writers). Add a **standard header** with **page numbers top-right** (and document title or revision line if you adopt a standard template). | `- [ ]` Unit tests on a **short fixture** forcing page overflow + snapshot / PDFKit text extraction; paginator + writer contract documented; [Public-API-Surface.md](Public-API-Surface.md) PDF section updated. |

---

## Phase 9 — Performance and concurrency

**Goal:** Large scripts don’t freeze UI.

| Step | Action | Done when |
|------|--------|-----------|
| 9.1 | **`parse(_:)` async**: offload full parse to `Task.detached` or custom executor; **synchronous** wrapper documented as “small docs only.” | **Done:** ``FNScript.parseStringAsync`` / ``parseFileAsync`` (``Task.detached``) + class-level doc on sync vs async; `FNScriptAsyncTests` (string parity + **Brick & Steel** file parity vs sync) |
| 9.2 | **Streaming API** (optional): `AsyncSequence` of elements for preview. | **Done:** ``FNScript.scriptElementStream(from:)`` (uses ``parseStringAsync``) / ``scriptElementStream(fromFile:)`` (``parseFileAsync`` + snapshot) → `AsyncStream<ScriptElement>`; `FountainRoadmapExtensionsTests` + `FNScriptAsyncTests` (stream vs async snapshot) |
| 9.3 | **Incremental parse** (advanced): diff by line map; **last** after baseline is solid. | **Done (planning):** [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) — preconditions / risks / **explicit defer**; no incremental merge in tree until spike proves safe |
| 9.4 | **Line → element index map** — maintain a queryable mapping from **logical line** (or UTF-16 / **`Character`** offset span per line) to **element indices** in the parsed tree (e.g. **interval tree** on line ranges, or a **flat array** of `(lineRange, elementIDRange)` / character offsets), including ambiguous regions (dialogue blocks) per the spike doc. | `- [ ]` Data structure documented in API or design note; **O(log n)** or documented linear tradeoff; unit tests on fixtures proving correct lookup for slug / dialogue / boneyard windows; [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) preconditions updated when satisfied. |
| 9.5 | **`parseIncremental(newText: String, range: Range<…>)`** — given a document edit, expand **`range`** to the nearest **safe invalidation boundaries** (e.g. **blank lines**, **scene headings**, and other anchors listed in the spike), **re-tokenize / re-parse only that chunk** (prefer **`FountainParsePipeline`** once it is default — [Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript)), then **merge** the new elements back into the existing **`FountainDocument`** / ``FNScript`` tree with stable IDs where defined. | `- [ ]` Public or `@_spi` API with documented boundary rules; property tests or golden tests showing full-parse == incremental on scripted edits; failure / fallback path to **full parse** documented; [Public-API-Surface.md](Public-API-Surface.md) updated if shipped. |

**Implementation note:** **9.4** is a **prerequisite** for **9.5**. Ship **9.5** only after [Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript) if you require a single canonical tokenizer for both cold and warm paths; otherwise prototype **9.5** may still target **`FountainParsePipeline`** behind **`parser: .tokenPipeline`** while **`.fast`** remains default.

---

## Phase 10 — Cross-platform packaging

**Goal:** **SPM-first** distribution, CI guardrails on parser vs UI boundaries, and **Wasm** experiments without blocking **FountainCore** consumers on **Linux** or the browser.

| Step | Action | Done when |
|------|--------|-----------|
| 10.1 | **SPM** is default distribution; tag semver. | **Done:** [SPM-Release-Checklist.md](SPM-Release-Checklist.md) (default distribution, products table, tagging flow); consumers use package URL + **`import Fountain`** / **`FountainCore`** |
| 10.2 | **Conditional compilation:** `#if canImport(UIKit)` only in **render** or **sample** targets, not in parser. | **Done:** `.github/workflows/swift.yml` greps `Fountain/*.swift` (excluding `Platform` / `FNPaginator` / `FNHTMLScript`) for `canImport(UIKit\|AppKit)` **and** stray `import UIKit` / `import AppKit` |
| 10.3 | **SwiftWasm** (stretch): build script + CI matrix entry; document unsupported APIs. | **Done:** `scripts/build-fountaincore-wasm.sh` + [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) + manual workflow [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) (Actions → **Wasm: FountainCore**) |
| 10.4 | **Products vs platform APIs:** when **8.5** / **8.6** land, keep **`FountainCore`** buildable on **Wasm/Linux** without linking **CoreGraphics** / UI font stacks unless explicitly opted in — e.g. optional **`FountainApple`** product, **`#if canImport`**, or **SPM** `exclude` rules updated; extend **CI grep** allowlists if new Apple-only files are introduced. | `- [ ]` `Package.swift` + workflow allowlists + [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) updated in the same PR as **8.5** / **8.6**; no regression on **macOS** `swift test`. |

---

## Phase 11: Regex modernization (Swift-native)

**Goal:** Express pattern libraries and `String` matching helpers with **Swift 5.7+ `Regex` / `RegexBuilder`** (including **`/…/` literals** where readability wins), and **remove `NSRegularExpression`** from the shared **`String+Regex.swift`** surface so **WebAssembly** and any future **Linux** **`FountainCore`** work avoid **NSString** bridging, gain stricter typing at boundaries, and improve match performance.

**Status:** **Not started** — checklist below.

| Step | Action | Done when |
|------|--------|-----------|
| 11.1 | Refactor **`Fountain/FountainRegexes.swift`** to use **`RegexBuilder`** and/or **`Regex` literals** (`/…/`) while preserving semantics for **`FountainParser`**, **`FNHTMLScript`**, and other consumers of those constants. | `- [ ]` All patterns used in-package compile as Swift `Regex` (or thin wrappers); **`swift test`** green; no intentional behavior change on legacy regex pipeline + HTML styling paths (existing tests + spot-check **`FountainInlineMarkup`** / export tests). |
| 11.2 | Remove **`NSRegularExpression`** from **`Fountain/String+Regex.swift`** completely: reimplement **`isMatchedByRegex`**, **`replacingOccurrencesOfRegex`**, **`nsRangeOfRegex`**, **`stringByMatching`**, **`componentsMatchedByRegex`** using **native Swift `Regex`** (captures, replacements, range reporting in **`String.Index`** space). Migrate **`FountainCore`** call sites as needed. | `- [ ]` File contains **no** `NSRegularExpression` (and no regex-only **`NSRange`**/`NSString` bridging left solely for those helpers); **`swift test`** green on **macOS**; **`FountainSceneHeadingMatcher`** and other dual-path code either use one Swift `Regex` implementation across supported OS versions **or** document a temporary `#available` shim with a dated removal issue; **Wasm:** run **`scripts/build-fountaincore-wasm.sh`** and record outcome in [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md). |

**Note:** Completing **11.2** may allow removing the **`NSRegularExpression`** fallback called out in **Phase 3.5** / **Polish § Phase 3.5** once deployment targets and CI agree on a single Swift `Regex` floor.

---

## Phase 12: Canonical state-aware parser (default `FNScript`)

**Goal:** Finish **fast vs tokenPipeline** parity coverage, then make **`FountainParsePipeline`** (Phase 3–4 **state-aware** tokenizer + ``FountainScriptElementsBuilder``) the **default** body engine for **`FNScript.init(string:)`** / **`init(file:)`** (and matching **async** defaults). That fulfills the [Project Specification](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) **State-Aware Scanner** direction and retires **`FastFountainParser`** from the hot path.

**Status:** **Not started** — parity tests today are **green** in **`TokenPipelineFNScriptTests`**; expand coverage and ship the switch when the checklist below is satisfied.

| Step | Action | Done when |
|------|--------|-----------|
| 12.1 | **Complete parity tests** — extend **`TokenPipelineFNScriptTests`** (and any sibling suites you split out) so **`.tokenPipeline`** vs **`.fast`** is asserted on **every** agreed corpus: bundled fixtures, **Big Fish**, **Brick & Steel**, minimal spec rows, and any vendored external cases (Phase 7.3) you adopt. | `- [ ]` Maintainer-signed **coverage matrix** checked in or linked from this doc; **`swift test`** green; no open P0/P1 parity deltas. *(Today: **`TokenPipelineFNScriptTests`** already passing on the tracked set.)* |
| 12.2 | **Deprecate `FastFountainParser`** as the default implementation; make **`FountainParsePipeline`** / **`FNParserType.tokenPipeline`** the default for **`FNScript(string:)`**, **`FNScript(file:)`**, and default **async** parse entry points. | `- [ ]` Default **`loadString`** / **`loadFile`** (and **`parseStringAsync`** / **`parseFileAsync`** / **`scriptElementStream`** defaults) use **`FountainParsePipeline`**; **`FastFountainParser`** reachable only via explicit **`FNParserType.fast`** (or equivalent) for a **semver-documented** transition; **`@available` deprecation** on legacy entry points if applicable; [Public-API-Surface.md](Public-API-Surface.md) + [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) updated; README “default parser” wording updated. |

**Prerequisite:** Treat **12.1** as a hard gate before merging **12.2** (or ship **12.2** only behind a feature flag if you need staged rollout).

---

## Phase 13: SwiftUI and FountainUI

**Goal:** Ship an **optional SwiftPM product** **`FountainUI`** that renders a **`FountainDocument`** with **native SwiftUI** (`Text`, layout primitives) for in-app previews, editors, and tooling — without pulling **SwiftUI** into **`FountainCore`**. **Not** a Wasm target; document platform availability alongside **FountainHTML**.

**Status:** **Not started**.

| Step | Action | Done when |
|------|--------|-----------|
| 13.1 | Add **`FountainUI`** SwiftPM **library target** (depends on **`FountainCore`** for ``FountainDocument``, ``ScriptElement``, ``ScriptElementKind``, metadata keys). Wire **macOS / iOS** platforms only (or match existing package floors); keep **SwiftUI** imports **out** of **`FountainCore`**. Optionally add **`FountainUI`** to the umbrella **`Fountain`** product or document **`import FountainUI`** for apps that need it. | `- [ ]` `Package.swift` + `swift test` (add **`FountainUIPackageTests`** or host tests in existing bundle); [Public-API-Surface.md](Public-API-Surface.md) + README note; **CI** allowlists updated if **Phase 10.2** grep must permit new SwiftUI-only paths under **`FountainUI/`**. |
| 13.2 | Implement **`FountainView(document: FountainDocument)`** (or equivalent **View** struct) that **iterates** ``ScriptElement`` rows and emits **properly styled** ``Text`` (and containers such as ``VStack`` / spacing) per **element kind** (scene heading, character, dialogue, action, transition, etc.), using **native** typography (system serif / monospaced choices documented). | `- [ ]` Snapshot or unit tests on **minimal** + **dual-dialogue** fixtures; accessibility **Dynamic Type** behavior documented; dual-column layout respects ``ScriptElement`` dual-dialogue metadata where applicable. |
| 13.3 | **(Bonus)** Map **``FountainInlineMarkup.attributedFragment(from:)``** (or ``renderInline`` → attributed pipeline) **directly** into **SwiftUI**-ready **`AttributedString`** / **`Text`** attributes so **bold / italic / underline** match **Phase 6** semantics without HTML round-trip. | `- [ ]` Focused tests on inline-heavy snippets; document any **SwiftUI** / **Foundation** attribute gaps vs HTML export. |

**Dependency:** Relies on **Phase 2** ``FountainDocument`` / ``ScriptElement`` and **Phase 6** inline markup APIs; coordinate with **Phase 8** so styling choices stay consistent with **HTML** / **PDF** where sensible.

---

## Phase 14: Version 2.0 and SPM-only repository

**Goal:** Signal **next-gen maturity** with **`2.0.0`**, remove **legacy parsers and Objective-C reference trees**, and make **`Package.swift`** the **sole** canonical project entry (no **`Fountain.xcodeproj`** / workspace merge churn). This is **intentionally breaking** — schedule after consumers can drop **`FNParserType.regex`**, **RegexKitLite-era** sources, and **Xcode-only** workflows.

**Status:** **Not started**.

| Step | Action | Done when |
|------|--------|-----------|
| 14.1 | **Bump semantic version to `2.0.0`** for the Swift package (Next-Gen line). Update **`Package.swift`** default / marketing version if used, **[SPM-Release-Checklist.md](SPM-Release-Checklist.md)**, **CHANGELOG** / release notes listing **every** breaking removal from **14.2–14.4**, and consumer migration notes ([Public-API-Surface.md](Public-API-Surface.md), README). | `- [ ]` Git tag **`2.0.0`** (or monorepo equivalent) cut **after** breaking commits land; pre-1.0 consumers warned in release notes. |
| 14.2 | **Delete `Fountain/Legacy/`** entirely (Objective-C + **RegexKitLite**-era **`.m`** reference tree). Remove any Xcode target references, docs, and scripts that still pointed at those paths. | `- [ ]` Directory absent from repo; **`swift test`** green; [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) + [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) updated to state **removed in 2.0**. |
| 14.3 | **Delete `FountainParser.swift`** (legacy **regex** pipeline) and remove **`FNParserType.regex`** / **`FNScript(…, parser: .regex)`** / **`loadString(…, parser: .regex)`** and all call sites, tests, and roadmap references that depended on it. **Retain** **`FountainRegexes.swift`** while **FNHTMLScript** / styling still need it (until [Phase 11](#phase-11-regex-modernization-swift-native)). | `- [ ]` No `FountainParser` symbol in package; **`swift test`** green; gap analysis parser inventory row updated. |
| 14.4 | **Remove `Fountain.xcodeproj`** (and any committed **`.xcworkspace`**) from the repo; rely on **opening `Package.swift`** in modern Xcode for samples and tests. Migrate **Sample Project Mac/iOS** and **`FountainTests`** to **SPM-native** app / test targets (or document moving them to a separate repo). Update **CI** if jobs used **`xcodebuild`** on the removed project; refresh [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md), **README**, and **CONTRIBUTING** for the new workflow. | `- [ ]` No `.xcodeproj` in tree (or archived per policy); **`swift build`** / **`swift test`** remain CI truth; contributor docs describe **File → Open** on **`Package.swift`**. |

**Release sequencing:** Typically land **14.2**, **14.3**, and **14.4** on **`main`**, verify CI, **then** tag **14.1** **`2.0.0`**. **Phase 12** (default token pipeline) is a **logical prerequisite** before deleting **`FountainParser`** if you still need a single supported parser story.

---

## Spec traceability matrix (seed)

Fill as you implement. Link each row to tests.

| Fountain 1.1 topic | Phase(s) | Test fixture | Status |
|--------------------|----------|--------------|--------|
| Forced scene heading `.` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Forced action `!` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Forced action **`!` only** (no whitespace-only action shortcut) | 4.6 | `ActionMergingTests`, `SpecTraceabilityTests`, `TokenPipelineFNScriptTests` | ☐ |
| Forced character `@` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Forced transition `>` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Lyrics `~` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Centered `> <` | 4 | `SpecTraceabilityTests`, `ParseStructureTests` | ☑ |
| Dual dialogue `^` + column metadata | 4 | `DualDialogue.fountain`, `SpecTraceabilityTests` | ☑ |
| Title page | 3 | `Simple.fountain`, `SpecTraceabilityTests`, `TitlePageRegressionTests` | ☑ |
| Scene numbers `#…#` (slug end) | 5 | `SceneNumbers.fountain`, `Phase5ProductionFeaturesTests` | ☑ |
| Page breaks | 5 | `PageBreaks.fountain`, `Phase5ProductionFeaturesTests` | ☑ |
| Boneyard | 5 | `Boneyard.fountain`, `Phase5ProductionFeaturesTests` | ☑ |
| Notes `[[ ]]` | 5 | `Phase5ProductionFeaturesTests` | ☑ |
| Sections / synopses | 5 | `SectionHeaders.fountain`, `Phase5ProductionFeaturesTests` | ☑ |
| Brick & Steel sample | 7 | `Brick And Steel.txt`, `BrickSteelCorpusTests` | ☑ |
| Phase 7 matrix (fixtures + minimal one-liners + JSON structural parity) | 7 | `Phase7ComplianceTests`, `PackageFixtureCorpusTests` | ☑ |
| External parsers / vendoring policy | 7 | [External-Fountain-Test-References.md](External-Fountain-Test-References.md) | ☑ |
| Boneyard between body lines | 5 | `package-boneyard-sandwich.fountain`, `PackageFixtureCorpusTests` | ☑ |
| Script metrics (scenes / transitions / page breaks / boneyard / sections / synopses / notes) | 5 | `FountainScriptMetricsTests` | ☑ |
| Scene numbers + page break | 5 | `package-scene-pagebreak.fountain`, `PackageFixtureCorpusTests` | ☑ |
| Dual dialogue HTML (grid CSS) | 8 | `package-dual-dialogue.fountain`, `FountainScriptRenderingTests` | ☑ |
| Writer protocol + adapters (plain / MD / JSON / HTML / FDX / PDF) | 8 | ``FountainScriptRendering``, ``FountainHTMLWriter``, ``FountainFDXWriter``, ``FountainPDFWriter``, `FountainScriptRenderingTests` | ☑ |
| **`TextMeasurer`** + ``FNPaginator`` injection (non-Apple measurers) | 8.5 / 10 | ``FNPaginator``, [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) | ☐ |
| **PDF** portable or **CoreGraphics**-isolated (`FountainPDFWriter`) | 8.6 / 10 | ``FountainPDFWriter``, Wasm / Linux build notes | ☐ |
| **FDX** `<ElementSettings>` + `<MoresAndContinueds>` (Final Draft margins) | 8.7 | ``FountainFDXWriter``, `ExportGoldenFixtureTests` / `.fdx` fixtures | ☐ |
| **PDF** MORE / CONT’D across pages + header page numbers | 8.8 | ``FNPaginator``, ``FountainPDFWriter``, `FountainScriptRenderingTests` | ☐ |
| Async full parse (string + file) | 9 | `FNScriptAsyncTests` | ☑ |
| `scriptElementStream` preview (full parse, async load) | 9 | `FountainRoadmapExtensionsTests`, `FNScriptAsyncTests` | ☑ |
| Incremental parse (spike / preconditions) | 9.3 | [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) | ☑ |
| Line → element index map | 9.4 | Phase 9 incremental track (tests TBD) | ☐ |
| `parseIncremental(newText:range:)` bounded re-parse + merge | 9.5 | Phase 9 incremental track (tests TBD) | ☐ |
| SPM distribution + semver tagging | 10 | [SPM-Release-Checklist.md](SPM-Release-Checklist.md) | ☑ |
| Parser free of UIKit/AppKit (core sources) | 10 | `.github/workflows/swift.yml` (Phase 10.2 grep) | ☑ |
| Wasm **FountainCore** (optional CI) | 10 | `scripts/build-fountaincore-wasm.sh`, [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md), `fountaincore-wasm.yml` | ☑ |
| Swift **`Regex` / `RegexBuilder`** + no `NSRegularExpression` in **`String+Regex.swift`** | 11 | [§ Phase 11](#phase-11-regex-modernization-swift-native); `FountainRegexes.swift`, `String+Regex.swift`, Wasm script + [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) | ☐ |
| **State-aware default parse** (`FountainParsePipeline`); **`FastFountainParser`** deprecated off default | 12 | [§ Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript); `TokenPipelineFNScriptTests`, `FNScript`, [Public-API-Surface.md](Public-API-Surface.md) | ☐ |
| **Fast vs tokenPipeline** parity (exhaustive, pre-default-flip) | 12 / 7 | `TokenPipelineFNScriptTests`, corpus tests, [External-Fountain-Test-References.md](External-Fountain-Test-References.md) | ☐ |
| **SwiftUI** `FountainView` + **`FountainUI`** SPM target | 13 | [§ Phase 13](#phase-13-swiftui-and-fountainui); `FountainUI` tests | ☐ |
| **Bonus:** Inline markup → **`AttributedString`** for SwiftUI | 13.3 / 6 | ``FountainInlineMarkup``, `FountainUI` | ☐ |
| **`2.0.0`** package release (breaking) | 14.1 | [SPM-Release-Checklist.md](SPM-Release-Checklist.md), CHANGELOG | ☐ |
| **`Fountain/Legacy/`** removed | 14.2 | — | ☐ |
| **`FountainParser`** / **`.regex`** removed | 14.3 | `FNScript`, tests | ☐ |
| **SPM-only** repo (no **`Fountain.xcodeproj`**) | 14.4 | [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md), CI | ☐ |

---

## Suggested order of execution (summary)

1. **Phase 0** — Gap analysis (days).  
2. **Phase 1** — SPM + boundaries (small slice, high leverage).  
3. **Phase 2** — New model + migration story (blocks everything else).  
4. **Phases 3 → 5** — New parser pipeline (core engineering).  
5. **Phase 7** — Tests tightened **continuously** (don’t defer to end).  
6. **Phase 6** — Rich text when core parse is stable.  
7. **Phase 8** — Writers / ``FountainScriptRendering`` (**initial complete**; FDX/PDF baseline shipped — refine layout vs Final Draft in follow-ups; **8.5**/**8.6** cross-platform + PDF portability; **8.7**/**8.8** Final Draft margins + screenplay PDF pagination).  
8. **Phase 9** — Async + perf.  
9. **Phase 10** — SPM / Wasm distribution and parser–UI boundary (roadmap complete; optional Wasm CI is manual); **10.4** when landing **8.5** / **8.6**.  
10. **Phase 11** — Regex modernization (**`FountainRegexes.swift`**, **`String+Regex.swift`**) when raising the Swift/os floor or doing a focused perf/Wasm pass.  
11. **Phase 12** — **Parity-complete** token pipeline, then **default `FNScript`** on **`FountainParsePipeline`** and **deprecate `FastFountainParser`** from the default path (aligns with the Project Specification *State-Aware Scanner*).  
12. **Phase 13** — **`FountainUI`** SwiftUI surface (`FountainView`, optional **AttributedString** inline path) when you want native in-app screenplay preview beyond **HTML** / **WKWebView**.  
13. **Phase 14** — **`2.0.0`**, delete **`Fountain/Legacy/`** + **`FountainParser`**, **SPM-only** repo (drop **`Fountain.xcodeproj`**) when breaking changes are acceptable.

---

## Polish & maintenance (post–Phase 10)

Small, continuous improvements after numbered phases are **initial-complete**:

| Item | Notes |
|------|--------|
| **Phase 3.5** | Prefer Swift ``Regex`` for **localized** slug checks — **started:** ``FountainSceneHeadingMatcher`` uses Swift `Regex` on **macOS 13+ / iOS 16+** and the same rule via `NSRegularExpression` on older OS (package still supports macOS 12 / iOS 15). |
| **Phase 4.3 / 4.6** | **4.3 done:** soft breaks + ``!`` preference. **4.6 planned:** strict **`!`** only — remove legacy whitespace-only action branch — see Phase 4 table. |
| **Phase 1** | **Polish:** [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) — verification, rollback, and contributor notes (local package wiring **done** in `Fountain.xcodeproj` **today**). **Superseded by [Phase 14](#phase-14-version-20-and-spm-only-repository)** when the project goes **SPM-only**. |
| **Phase 8** | Deeper HTML/CSS refactor if desired. **Polish:** ``FountainStubRendererError`` retained for future optional stubs; conforms to ``LocalizedError``. **Planned:** **8.5** ``TextMeasurer`` + ``FNPaginator``; **8.6** PDF portability / **CoreGraphics** isolation; **8.7** FDX **ElementSettings** / **MoresAndContinueds**; **8.8** PDF **(MORE)**/**(CONT’D)** + page-number header — see Phase 8 table. |
| **Phase 9.3–9.5** | **9.3** planning done — [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md). **Implementation:** **9.4** line→element map; **9.5** `parseIncremental(newText:range:)` (safe boundaries, chunk re-tokenize, merge into ``FountainDocument``) — see Phase 9 table. |
| **Gap analysis** | **Closed (matrix):** feature matrix all **Y** with SPM regression pointers — ``GapMatrixClosureTests`` + prior tests; see [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md). |
| **Structural matchers** | **Polish:** ``FountainStructuralLineMatchers`` page break / boneyard / bracket / `TO:` / all-caps cue use **string logic** (no `NSRegularExpression`). |
| **Phase 11** | **Planned:** Swift **`Regex` / `RegexBuilder`** for **`FountainRegexes.swift`**; remove **`NSRegularExpression`** from **`String+Regex.swift`** — see [§ Phase 11](#phase-11-regex-modernization-swift-native) (Wasm + Linux performance). |
| **Phase 12** | **Planned:** Full **`.fast`** / **`.tokenPipeline`** parity suite, then **default** **`FNScript`** on **`FountainParsePipeline`**; deprecate **`FastFountainParser`** as default — [§ Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript). |
| **Phase 13** | **Planned:** **`FountainUI`** SPM target, **`FountainView(document:)`**, optional inline → **`AttributedString`** — [§ Phase 13](#phase-13-swiftui-and-fountainui). |
| **Phase 14** | **Planned:** **`2.0.0`**, remove **`Fountain/Legacy/`** + **`FountainParser`**, delete **`Fountain.xcodeproj`** — [§ Phase 14](#phase-14-version-20-and-spm-only-repository). |

---

## Related documents

- [Project Specification- Fountain Swift (Next-Gen).md](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) — vision and constraints  
- [README](../README.markdown) — current project state  
- [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) — Xcode sample + test targets on local Swift package (Phase 1.2)  
- [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) — Phase 9.3 incremental parse planning; **9.4–9.5** implementation steps in Phase 9 table  
- [SPM-Release-Checklist.md](SPM-Release-Checklist.md) — Phase 10.1 tagging / semver  
- [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) — Phase 10.3 Wasm notes  
- [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) — manual **Wasm: FountainCore** CI  
- [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) — Phases 0.3 & 1.2  
- [Public-API-Surface.md](Public-API-Surface.md) — Phase 1.3  
- [External-Fountain-Test-References.md](External-Fountain-Test-References.md) — Phase 7.3 external parsers / vendoring notes  

When this roadmap and the gap analysis diverge from reality, **update the tables** in the same PR as the code change.
