# Fountain 1.1 — Implementation Roadmap (Swift Next-Gen)

This document turns [Project Specification- Fountain Swift (Next-Gen).md](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) into **phased, checkable work**. Use it for planning, PR scoping, and regression tracking.

**Naming:** The **“1.1”** in this filename and most section titles means the **Fountain screenplay markup / syntax** generation ([fountain.io/syntax](https://fountain.io/syntax/)), **not** the **Swift package** SemVer. Package releases (e.g. **2.0.0**) are tracked in **[CHANGELOG.md](../CHANGELOG.md)** and ``FountainPackageVersion``; the syntax pin stays on **1.1** until you deliberately retarget the spec.

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
| 0.1 | Inventory current parsers (`FastFountainParser`, `FountainParsePipeline`, historical regex/ObjC paths) and **list gaps vs Fountain 1.1** (forced rules, boneyard, notes, dual dialogue, etc.). | **Done:** [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) § Parser inventory + feature matrix + fixture map |
| 0.2 | Inventory **all regex patterns** (`FountainRegexes.swift` / `.m`) and mark which are **spec-critical** vs **styling-only**. | **Done (Swift):** table in [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) § Regex pattern inventory (`.m` out of package; see gap analysis note) |
| 0.3 | Decide **deprecation policy**: keep legacy targets for one release, feature-flag, or hard cut. | **Done:** [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) § Phase 0.3 — Deprecation policy (decided) |
| 0.4 | Add **pin** to Fountain syntax version you’re targeting (1.1 + any errata). | **Done:** `FountainSyntaxPin` + README link; optional errata URL in release notes when locking compliance |

**Deliverable:** `docs/Fountain-1.1-Gap-Analysis.md` (living document; Phase 0 baseline section marks completion).

---

## Phase 1 — Swift Package and module boundaries

**Goal:** A **SwiftPM library** that can be used by macOS/iOS apps **and** future tooling without Xcode-only coupling.

**Status:** **Complete** for library distribution, CI, module split, documented public API, and **Phase 1.2** — Xcode sample apps and **`FountainTests`** link the **local** Swift package (no duplicate `Fountain/*.swift` compile in those targets). Details: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md). Closing Phase **1** does **not** require linking **FountainUI**; that product is optional and lives in **`FountainUI/`** (see [Phase 13](#phase-13-swiftui-and-fountainui)). **Future:** dropping **`Fountain.xcodeproj`** for **SPM-only** workflows is **[Phase 15.1](#phase-15)** (polish epic).

| Step | Action | Done when |
|------|--------|-----------|
| 1.1 | Create `Package.swift` with **`FountainCore`** + **`FountainHTML`** + umbrella **`Fountain`** — core has **no** UI frameworks; HTML target holds AppKit/UIKit usage. | **Done:** `swift build` + `swift test` at repo root; products `Fountain`, `FountainCore`, `FountainHTML`; optional **`FountainUI`** (Phase **13**, separate product — **not** re-exported by **`Fountain`**) |
| 1.2 | Move or duplicate **model + parse + write** into the package; keep sample apps consuming the package (or same sources via careful symlink — prefer package as source of truth). | **Done:** Single **`Fountain/`** source tree; **no** second copy of library sources. **SPM** defines the canonical module graph; **Xcode** sample targets and **`FountainTests`** link the **local** package product **Fountain** (see [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)). |
| 1.3 | Define **public API surface** (`FNScript`, element types, errors). Mark experimental APIs `@_spi` or nested `FountainCore.Experimental` if needed. | **Done:** [Public-API-Surface.md](Public-API-Surface.md) — stability tiers + experimental list; **`@_spi`** reserved for when churn drops (not required to close Phase 1) |
| 1.4 | **CI:** `swift build` + `swift test` on macOS (Linux where possible; Wasm later). | **Done:** `.github/workflows/swift.yml` on **macOS**; Linux/Wasm not in matrix because package platforms are **macOS 13+** / **iOS 16+** (Phase **11** Swift `Regex` floor; see Phase 10 for Wasm stretch) |

---

## Phase 2 — Data model (replace/align `FNElement`)

**Goal:** **Codable**, **Identifiable**, **stable round-trip** to JSON for tooling.

**Status:** **Complete (initial)** — `FNElement` is a **`struct`** with **`Codable`**, **`Identifiable`**, and stable **`id`** carried into ``ScriptElement``; typed metadata remains on ``ScriptElement.metadata`` / ``FountainMetadataKey``. Legacy **Objective-C** reference sources under **`Fountain/Legacy/`** were **removed** in **Phase 14.2** — [§ Phase 14](#phase-14).

| Step | Action | Done when |
|------|--------|-----------|
| 2.1 | Introduce **`FNElementType`** `String` enum (or similar) covering **all** 1.1 structural kinds you need (including `pageBreak`, `boneyard`, `synopsis`, `section`, `general`, `note`, etc. — align names with spec vocabulary). | **Done:** `FNElementType` + map to `ScriptElementKind` |
| 2.2 | Implement **`FNElement`** struct: `id`, `type`, `content`, **`attributes: [String: String]`** (or typed `Metadata` struct with `Codable`) for scene number, section depth, `dualDialogue`, `centered`, etc. | **Done (Swift):** `FNElement` struct with `id` + legacy field names (`elementType`, `elementText`, …); scene/section/dual/centered via fields + **also** in ``ScriptElement.metadata`` / ``FountainMetadataKey``; golden JSON in `Tests/FountainPackageTests/Fixtures/` |
| 2.3 | Migration shim from **old** `FNElement` class / `elementType: String` if dual-stack period is required. | **Done (Swift):** no dual Swift stack; ``LegacyInteropTests`` cover kind alignment, ``FNElement`` JSON round-trip, and **ID parity** ``FNElement`` ↔ ``ScriptElement`` |
| 2.4 | Define **`FNScript`** (or `FountainDocument`) with `elements` + `titlePage` + version metadata. | **Done:** `FountainDocument(script:)` + ``FNScript.fountainDocument`` / ``fountainDocumentJSONData(prettyPrinted:)`` + ``asFountainDocument()`` + `FountainSyntaxPin` |

---

## Phase 3 — Tokenization (Phase 1 of “Universal Parser”)

**Goal:** **State-aware scanning** — classify **lines** (and line continuations) into **tokens** without building the final tree yet.

**Status:** **Complete (initial)** — shared title-page prescan, structural line matchers, coarse body line tokenizer (aligned with ``FastFountainParser``), and existing forced-prefix + slug helpers. **Phase 12** made **``FountainParsePipeline``** the **default** for ``FNScript`` (``FNParserType/tokenPipeline``); **``.fast``** remains explicit for parity tests and migration. See [Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript) and ``TokenPipelineFNScriptTests``.

| Step | Action | Done when |
|------|--------|-----------|
| 3.1 | Specify **token kinds** (slug, action, character, dialogue, parenthetical, transition, lyrics, section, synopsis, pagebreak, boneyard open/close, title-page directive, blank, unknown…). | **Done:** `FountainTokenKind` + `FountainTokenizedLine` + `LineEndingNormalizationTests` |
| 3.2 | Implement **line splitter** honoring Fountain newline rules; normalize `\r\n` once at input. | **Done:** `FountainLineEndingNormalizer` / `FountainLineSplitter` + `LineSplitterTests` |
| 3.3 | Implement **title page pre-scan** (before body) consistent with 1.1; **do not** mis-classify body lines like `FADE IN:` as title keys (regression from current fast parser fixes). | **Done:** `FountainTitlePagePrescan` (used by ``FastFountainParser``) + `TitlePageRegressionTests` + `Phase3TokenizationTests` |
| 3.4 | Map **forced prefixes** to tokens: `.` scene, `!` action, `@` character, `~` lyrics, `>` transition (non-centered), etc. | **Done:** `FountainForcedPrefixScanner` + `ForcedPrefixScannerTests`; body tokenizer applies full line order including forced lines |
| 3.5 | Replace fragile regex-only checks with **scanner + Regex hybrid**: use `Regex` for **localized** patterns (e.g. scene heading stem), not whole-document substitution. | **Done:** `FountainSceneHeadingMatcher` + `FountainStructuralLineMatchers` + corpus smoke (`BigFishCorpusTests`). **Phase 11** raised the package floor to **macOS 13 / iOS 16** and removed `NSRegularExpression` from **`String+Regex.swift`**; see [Phase 11](#phase-11-regex-modernization-swift-native). |

---

## Phase 4 — Contextual analysis (Phase 2 of “Universal Parser”)

**Goal:** Tokens → **blocks** (dialogue blocks, dual dialogue, continuity).

**Status:** **Complete (initial)** — dialogue line roles align with ``FastFountainParser`` parenthetical detection; dual-`^` columns match the fast parser and ``FountainScriptElementsBuilder``; token→element assembly is parity-tested against ``FNScript`` on package fixtures. **Default** production parse is ``FNScript`` on **``FountainParsePipeline``** (Phase **12**); ``FastFountainParser`` is **``.fast``** only. **Tightening:** **4.6** removes the legacy **whitespace-only** “forced action” path in favor of strict **`!`**.

| Step | Action | Done when |
|------|--------|-----------|
| 4.1 | **Dialogue block** state machine: Character → optional Parenthetical → Dialogue (multi-line rules per 1.1). | **Done:** `FountainDialogueBlockRecognizer` (leading-`(` rule) + `DialogueBlockRecognizerTests` |
| 4.2 | **Dual dialogue** (`^`): pair detection and **column** metadata in `attributes`. | **Done:** Parser + ``FountainScriptElementsBuilder`` + `SpecTraceabilityTests` / `Phase4ParityTests` (`package-dual-dialogue.fountain`) |
| 4.3 | **Action** merging rules (soft line breaks vs hard breaks) — explicitly match 1.1; **remove reliance on trailing spaces** for forcing; prefer **`!`**. | **Done:** `ActionMergingTests`; legacy all-whitespace action lines remain accepted in ``FastFountainParser`` (document-only preference for `!`) |
| 4.4 | **Centered text** `> ... <` vs **forced transition** `>` — disambiguation per spec. | **Done:** `ParseStructureTests` + tokenizer order (`> … TO:` → transition before bare-`>` branch) |
| 4.5 | Emit final **`[FNElement]`** list from token stream. | **Done:** `FountainScriptElementsBuilder` + `Phase4ParityTests` (element-type parity vs ``FNScript`` on fixtures) + existing `Phase45RoundTripTests` / export round-trip |
| 4.6 | **Strict forced action (`!` only):** update the **parser state machine** (``FastFountainParser`` and ``FountainBodyLineTokenizer`` / ``FountainScriptElementsBuilder`` so **`.tokenPipeline`** stays aligned) to **require** the **`!`** prefix for **forced action** per Fountain 1.1; **deprecate** then **remove** the legacy branch that treats **two-or-more whitespace-only lines** (`^\\s{2,}$`) as standalone **Action** elements. Optional one-release **warnings** or migration note before removal. | **Partial:** legacy **standalone Action** for `^\\s+$` **outside** dialogue removed — treated like a **blank** delimiter (tokenizer emits ``.blank``); **inside** dialogue, multi-space / tab-only lines merge as **dialogue** continuation (after the existing **two-space** rule). Tests: ``Phase46WhitespaceActionTests``. **Follow-up:** migration note / semver if any consumer relied on whitespace-only Action rows. |

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

**Status:** **Complete (initial)** — unified ``FountainScriptRendering`` API; plaintext / Markdown / JSON / HTML + **FDX / PDF** exporters with tests. Legacy ``FountainWriter`` remains for Fountain body/title string export; new call sites should prefer protocol conformers. **8.5** — ``FountainTextMeasuring`` + ``FNPaginator`` **closure / generic** injection. **8.6** — ``FountainPDFWriter`` isolated behind **CG+CT** / **Wasm** stub; [ADR-008-PDF-CoreGraphics-availability.md](ADR-008-PDF-CoreGraphics-availability.md). **8.7** — FDX layout metadata (initial). **8.8** — PDF **page numbers** + **draft title** header; **paginated** PDF via umbrella **`Fountain`** (**`renderPDFDataPaginated`**) feeding ``FNPaginator`` slabs into ``renderPDFData(pages:script:)`` so **(MORE)** / **(CONT’D)** elements from pagination appear in export. **Polish (optional later):** HTML/CSS depth; Linux-native PDF backend; Canvas measurer cookbook for Wasm hosts.

| Step | Action | Done when |
|------|--------|-----------|
| 8.1 | Define `FountainWriter` (or `ScriptRenderer`) protocol: `func render(_ document: FNScript) throws -> String` (or associated type for binary PDF). | **Done:** ``FountainScriptRendering`` + ``FountainPlaintextWriter``; parity vs ``FountainWriter.documentFromScript`` (``FountainScriptRenderingTests`` / ``testFountainPlaintextWriterMatchesFountainWriterDocument``) |
| 8.2 | **`HTMLWriter`**: migrate from `FNHTMLScript`; modern CSS (grid/flex); keep **CSS as resource** or string template. | **Done:** ``FNHTMLScript`` conforms to ``FountainScriptRendering``; ``FountainHTMLWriter`` (thin adapter in **FountainHTML**); `ScriptCSS.css` resource + dual-dialogue grid tests (`FountainScriptRenderingTests`) |
| 8.3 | **`MarkdownWriter`**: useful for LLM/tooling pipelines. | **Done:** ``FountainMarkdownWriter`` + ``FountainJSONWriter`` + `FountainScriptRenderingTests` (lyrics + bracket notes + JSON shape) |
| 8.4 | **`FDXWriter`** / **`PDFWriter`**: Final Draft XML + PDF export. | **Done:** ``FountainFDXWriter`` emits minimal importable .fdx; ``FountainPDFWriter`` renders US Letter PDF via CoreGraphics/CoreText (``render`` = base64, ``renderPDFData`` = `Data`). Tests: ``FountainScriptRenderingTests`` (`testFDXWriterEmitsFinalDraftXML`, `testPDFWriterProducesValidPDFBytes`). |
| 8.5 | **Abstract text measurement** out of ``FNPaginator`` behind a protocol (e.g. **`TextMeasurer`**) so **core pagination math** does not hard-code **UIKit/AppKit** font metrics. Ship a **default** implementation in **FountainHTML** (or a thin **`FountainApple`** product) using **`NSAttributedString` / `UIFont` / `NSFont`** (or equivalent) on Apple platforms; **Wasm / Linux** consumers inject their own measurer (e.g. **HTML Canvas**-backed layout in JS, or a stub for tests). | **Done (initial):** ``FountainTextMeasuring`` + ``CourierPitchMonospaceTextMeasurer`` + ``AppKitFountainTextMeasurer``; ``FNPaginator`` uses **closure** + ``layoutLineHeight``; three inits; ``FountainTextMeasuringTests`` + paginator smoke. **Stretch:** Canvas measurer cookbook — [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md). |
| 8.6 | **PDF portability:** if **FountainPDFWriter** stays in-repo, either (a) adopt a **lightweight cross-platform** PDF generator that does not require **CoreGraphics** on every OS, **or** (b) **strictly isolate** ``FountainPDFWriter`` (and any CoreText/CoreGraphics-only code paths) behind **`#if canImport(CoreGraphics)`** (and related guards), matching the existing **wasm32** stub story with a clear **Linux** story. | **Done (initial):** CG+CT / Wasm stub split; [ADR-008-PDF-CoreGraphics-availability.md](ADR-008-PDF-CoreGraphics-availability.md) records Linux / future-backend policy. **Package** remains Apple-only platforms; Wasm script unchanged. |
| 8.7 | **FDX — Final Draft layout metadata:** extend ``FountainFDXWriter`` to emit standard **`<ElementSettings>`** (page size, margins, dialogue / action / character **industry-style** defaults) and **`<MoresAndContinueds>`** (or equivalent Final Draft boilerplate your research confirms) so **Final Draft** opens exports with **correct margins** instead of generic defaults. Prefer **injecting** XML fragments or small templates so values stay maintainable. | **Done (initial):** **`<PageLayout>`** + **`<ElementSettings>`** (General, Scene Heading, Action, Character, Dialogue, Parenthetical, Transition) + **`<MoresAndContinueds>`** (dialogue / scene continued strings) in ``FountainFDXWriter``; golden **`export-golden-minimal.fdx`** + ``ExportGoldenFixtureTests``; ``FountainScriptRenderingTests/testFDXWriterEmitsFinalDraftXML`` asserts key tags; [Public-API-Surface.md](Public-API-Surface.md) *FDX* contract updated. **Manual** Final Draft open still recommended when changing layout numbers. |
| 8.8 | **PDF — screenplay pagination:** implement **(MORE)** and **(CONT’D)** when **dialogue breaks across pages** — coordinate **``FNPaginator``** (page breaks / overflow) with **``FountainPDFWriter``** so split dialogue matches common US screenplay convention (hard requirement for writers). Add a **standard header** with **page numbers top-right** (and document title or revision line if you adopt a standard template). | **Done (initial):** **Top-right** page numbers + **Title**-key **draft title** (top-left) on every PDF page; ``renderPDFData(pages:script:)`` (Core) + ``renderPDFDataPaginated(script:)`` (umbrella **Fountain**, ``Sources/Fountain/FountainPDFPagination.swift``) wiring **FNPaginator** slabs; PDFKit tests (flat multi-page, paginated valid PDF, draft title extraction). **Stretch:** revision / date header line; PDFKit snapshot baselines. |

---

## Phase 9 — Performance and concurrency

**Goal:** Large scripts don’t freeze UI.

**Status:** **Complete (initial)** — async / detached parse (9.1), preview streaming (9.2), incremental **planning** recorded (9.3), **line → element** map with UTF-16 spans (9.4), and **warm re-parse** API with structural range expansion + full parse + stable-ID merge (9.5). **Stretch:** tokenizer-limited chunk re-parse + merge (see [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md)).

| Step | Action | Done when |
|------|--------|-----------|
| 9.1 | **`parse(_:)` async**: offload full parse to `Task.detached` or custom executor; **synchronous** wrapper documented as “small docs only.” | **Done:** ``FNScript.parseStringAsync`` / ``parseFileAsync`` (``Task.detached``) + class-level doc on sync vs async; `FNScriptAsyncTests` (string parity + **Brick & Steel** file parity vs sync) |
| 9.2 | **Streaming API** (optional): `AsyncSequence` of elements for preview. | **Done:** ``FNScript.scriptElementStream(from:)`` (uses ``parseStringAsync``) / ``scriptElementStream(fromFile:)`` (``parseFileAsync`` + snapshot) → `AsyncStream<ScriptElement>`; `FountainRoadmapExtensionsTests` + `FNScriptAsyncTests` (stream vs async snapshot) |
| 9.3 | **Incremental parse** (advanced): diff by line map; **last** after baseline is solid. | **Done (planning):** [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) — preconditions / risks; **chunk** merge still deferred — **9.5** ships **full** re-parse + ID merge + expansion helpers first |
| 9.4 | **Line → element index map** — maintain a queryable mapping from **logical line** (or UTF-16 / **`Character`** offset span per line) to **element indices** in the parsed tree (e.g. **interval tree** on line ranges, or a **flat array** of `(lineRange, elementIDRange)` / character offsets), including ambiguous regions (dialogue blocks) per the spike doc. | **Done (initial):** ``FountainLineToElementIndexMap`` — logical body-line → element index; **UTF-16** half-open spans + ``String/Index`` ranges in canonical ``syntheticBodyLineText`` (element texts joined with `\n`); tests in ``FountainLineToElementIndexMapTests``. **Stretch / later:** interval tree; title-page / boneyard line spaces in the same index as body (today: **body elements only**, matching ``FNScript/elements``). |
| 9.5 | **`parseIncremental(newText: String, range: Range<…>)`** — given a document edit, expand **`range`** to the nearest **safe invalidation boundaries** (e.g. **blank lines**, **scene headings**, and other anchors listed in the spike), **re-tokenize / re-parse only that chunk** (prefer **`FountainParsePipeline`** once it is default — [Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript)), then **merge** the new elements back into the existing **`FountainDocument`** / ``FNScript`` tree with stable IDs where defined. | **Done (initial):** ``FountainEditRangeExpansion`` (full-line + heuristic structural UTF-16 expansion) + ``FNScript/parseIncremental(newText:editedUTF16Range:parser:)`` → ``FountainIncrementalParseOutcome`` — **full document re-parse** for correctness today, **stable ``FNElement/id``** merge on matching prefix/suffix; expanded range exposed for future chunked re-parse; tests: ``FountainEditRangeExpansionTests``, ``FNScriptIncrementalParseTests``; [Public-API-Surface.md](Public-API-Surface.md) updated. **Stretch:** true chunk parse + merge (spike § suggested steps 3–4). |

**Implementation note:** **9.4** is a **prerequisite** for **9.5**. **9.5** defaults **`parseIncremental`** to **``.tokenPipeline``** alongside [Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript); pass **``.fast``** when you need the line-first engine.

---

## Phase 10 — Cross-platform packaging

**Goal:** **SPM-first** distribution, CI guardrails on parser vs UI boundaries, and **Wasm** experiments without blocking **FountainCore** consumers on **Linux** or the browser.

**Status:** **Complete (initial)** — **10.1–10.3** as before; **10.4** closes the **CoreGraphics / CoreText** policy in **FountainCore** (CI grep + `Package.swift` notes + [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) § **10.4**). **Stretch:** optional **`FountainApple`** product; **Linux** / **wasi** in `Package.swift` when CI adopts those hosts.

| Step | Action | Done when |
|------|--------|-----------|
| 10.1 | **SPM** is default distribution; tag semver. | **Done:** [SPM-Release-Checklist.md](SPM-Release-Checklist.md) (default distribution, products table, tagging flow); consumers use package URL + **`import Fountain`** / **`FountainCore`** |
| 10.2 | **Conditional compilation:** `#if canImport(UIKit)` only in **render** or **sample** targets, not in parser. | **Done:** `.github/workflows/swift.yml` greps `Fountain/*.swift` (excluding `Platform` / `FNPaginator` / `FNHTMLScript` / `AppKitFountainTextMeasurer`) for `canImport(UIKit\|AppKit)` **and** stray `import UIKit` / `import AppKit` |
| 10.3 | **SwiftWasm** (stretch): build script + CI matrix entry; document unsupported APIs. | **Done:** `scripts/build-fountaincore-wasm.sh` + [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) + manual workflow [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) (Actions → **Wasm: FountainCore**) |
| 10.4 | **Products vs platform APIs:** when **8.5** / **8.6** land, keep **`FountainCore`** buildable on **Wasm/Linux** without linking **CoreGraphics** / UI font stacks unless explicitly opted in — e.g. optional **`FountainApple`** product, **`#if canImport`**, or **SPM** `exclude` rules updated; extend **CI grep** allowlists if new Apple-only files are introduced. | **Done:** `Package.swift` documents Core vs HTML / CG split; **`.github/workflows/swift.yml`** Phase **10.4** grep (CG/CT imports and `canImport` only in ``FountainPDFWriter.swift``); [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) § **10.4**; **macOS** `swift test` green. **Stretch:** **`FountainApple`**; **Linux** / **wasi** platforms when CI commits. |

---

## Phase 11: Regex modernization (Swift-native)

**Goal:** Express pattern libraries and `String` matching helpers with **Swift 5.7+ `Regex` / `RegexBuilder`** (including **`/…/` literals** where readability wins), and **remove `NSRegularExpression`** from the shared **`String+Regex.swift`** surface so **WebAssembly** and any future **Linux** **`FountainCore`** work avoid **NSString** bridging, gain stricter typing at boundaries, and improve match performance.

**Status:** **Complete (initial)** — **11.2** shipped for **`String+Regex.swift`**: Swift **`Regex`** is the primary path; **`NSRegularExpression`** is used only as a **compile-time fallback** when Swift `Regex` rejects a pattern (e.g. negative lookbehind in **italic**). **`FountainRegexes.swift`** body patterns are Swift **`Regex`–compatible** where possible (leading `\n` made explicit on several patterns). **Package platforms** are **macOS 13** / **iOS 16**. **Stretch:** **`RegexBuilder`** literals, eliminate the NS fallback if patterns can be rewritten without semantic loss; **Wasm:** re-run **`scripts/build-fountaincore-wasm.sh`** when convenient and note in [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md).

| Step | Action | Done when |
|------|--------|-----------|
| 11.1 | Refactor **`Fountain/FountainRegexes.swift`** to use **`RegexBuilder`** and/or **`Regex` literals** (`/…/`) while preserving semantics for **`FNHTMLScript`**, **`String+Regex`**, and other consumers of those constants. | **Partial:** patterns are **Swift `Regex`–compatible** (lookbehind removed; see file comments); still **string constants**, not **`RegexBuilder`**. **Stretch:** typed `Regex` values or literals where it clarifies hot paths. |
| 11.2 | Remove **`NSRegularExpression`** from **`Fountain/String+Regex.swift`** completely: reimplement **`isMatchedByRegex`**, **`replacingOccurrencesOfRegex`**, **`nsRangeOfRegex`**, **`stringByMatching`**, **`componentsMatchedByRegex`** using **native Swift `Regex`** (captures, replacements, range reporting in **`String.Index`** space). Migrate **`FountainCore`** call sites as needed. | **Done (initial):** Swift **`Regex`** is the **default** path; **`NSRegularExpression`** remains only as a **compile-time fallback** when Swift `Regex` rejects a pattern (today: lookbehind in ``ITALIC_PATTERN``). **`FountainSceneHeadingMatcher`** is Swift `Regex` only; **`swift test`** green (core + **FountainUI** test bundles); **`NSRegularExpression.Options`** remains the **options** parameter type. **Stretch:** eliminate the fallback once Swift supports those constructs or patterns are rewritten without semantic loss. |

**Note:** **Phase 3.5** polish text is updated — the old **macOS 12 / iOS 15** `NSRegularExpression` fallback for slug matching is **removed** with the Phase **11** platform bump.

---

## Phase 12: Canonical state-aware parser (default `FNScript`)

**Goal:** Finish **fast vs tokenPipeline** parity coverage, then make **`FountainParsePipeline`** (Phase 3–4 **state-aware** tokenizer + ``FountainScriptElementsBuilder``) the **default** body engine for **`FNScript.init(string:)`** / **`init(file:)`** (and matching **async** defaults). That fulfills the [Project Specification](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) **State-Aware Scanner** direction and retires **`FastFountainParser`** from the hot path.

**Status:** **Complete (12.2 initial)** — **12.2** merged: default **`loadString`** / **`loadFile`**, **`parseStringAsync`** / **`parseFileAsync`**, **`scriptElementStream`** (no-`parser:` overloads), and **`parseIncremental`** default **`parser:`** use **``.tokenPipeline``**. **`FastFountainParser`** remains via **``.fast``**. **12.1** has a living matrix in [TokenPipeline-Parity-Coverage.md](TokenPipeline-Parity-Coverage.md); **exhaustive** Phase 7.3 coverage remains a stretch (see that doc).

| Step | Action | Done when |
|------|--------|-----------|
| 12.1 | **Complete parity tests** — extend **`TokenPipelineFNScriptTests`** (and any sibling suites you split out) so **`.tokenPipeline`** vs **`.fast`** is asserted on **every** agreed corpus: bundled fixtures, **Big Fish**, **Brick & Steel**, minimal spec rows, and any vendored external cases (Phase 7.3) you adopt. | **Initial:** [TokenPipeline-Parity-Coverage.md](TokenPipeline-Parity-Coverage.md) matrix + **`swift test`** green on listed corpora. **Stretch:** maintainer-signed exhaustive matrix vs Phase 7.3 with no open P0/P1 parity deltas. |
| 12.2 | **Deprecate `FastFountainParser`** as the default implementation; make **`FountainParsePipeline`** / **`FNParserType.tokenPipeline`** the default for **`FNScript(string:)`**, **`FNScript(file:)`**, and default **async** parse entry points. | **Done (initial):** Defaults use **`FountainParsePipeline`**; **`FastFountainParser`** only via **`FNParserType.fast`**; [Public-API-Surface.md](Public-API-Surface.md), [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md), README, and this roadmap updated. **`@available` deprecation** on **``.fast``** deferred (would warn in parity tests). |

**Rollout note:** **12.2** shipped without requiring exhaustive **12.1**; expand the parity matrix before treating **12.1** as closed.

---

## Phase 13: SwiftUI and FountainUI

**Goal:** Ship an **optional SwiftPM product** **`FountainUI`** that renders a **`FountainDocument`** with **native SwiftUI** (`Text`, layout primitives) for in-app previews, editors, and tooling — without pulling **SwiftUI** into **`FountainCore`**. **Not** a Wasm target; document platform availability alongside **FountainHTML**.

**Status:** **Complete (initial)** — **`FountainUI`** target + **`FountainUIPackageTests`**; **`FountainView(document:)`** + ``FountainScriptElementTypography`` + ``FountainUIScriptElementLineContent`` (**13.3** — ``Text(FountainInlineMarkup.attributedFragment(from:))`` for body-line kinds); umbrella **`Fountain`** intentionally **does not** depend on **`FountainUI`**. **CI:** **Fountain/*.swift** must not **`import SwiftUI`**. **Stretch:** snapshot tests; richer dual-column layout; DocC; custom underline attribute polish vs HTML `<u>`.

| Step | Action | Done when |
|------|--------|-----------|
| 13.1 | Add **`FountainUI`** SwiftPM **library target** (depends on **`FountainCore`** for ``FountainDocument``, ``ScriptElement``, ``ScriptElementKind``, metadata keys). Wire **macOS / iOS** platforms only (or match existing package floors); keep **SwiftUI** imports **out** of **`FountainCore`**. Optionally add **`FountainUI`** to the umbrella **`Fountain`** product or document **`import FountainUI`** for apps that need it. | **Done (initial):** `Package.swift` product **`FountainUI`** + **`FountainUIPackageTests`**; [Public-API-Surface.md](Public-API-Surface.md) + README + **SPM** checklist; **`.github/workflows/swift.yml`** rejects **`import SwiftUI`** under **`Fountain/`**. **Umbrella:** document **separate** `import FountainUI` (no umbrella merge yet — avoids linking SwiftUI for HTML-only apps). |
| 13.2 | Implement **`FountainView(document: FountainDocument)`** (or equivalent **View** struct) that **iterates** ``ScriptElement`` rows and emits **properly styled** ``Text`` (and containers such as ``VStack`` / spacing) per **element kind** (scene heading, character, dialogue, action, transition, etc.), using **native** typography (system serif / monospaced choices documented). | **Done (initial):** ``FountainView`` + per-kind fonts / alignment; title-page block; dual-dialogue column inset + alignment; **ImageRenderer** smoke tests (minimal + dual fixture). **Stretch:** snapshot tests; **Dynamic Type** doc section; true side-by-side dual columns. |
| 13.3 | **(Bonus)** Map **``FountainInlineMarkup.attributedFragment(from:)``** (or ``renderInline`` → attributed pipeline) **directly** into **SwiftUI**-ready **`AttributedString`** / **`Text`** attributes so **bold / italic / underline** match **Phase 6** semantics without HTML round-trip. | **Done (initial):** ``FountainUIScriptElementLineContent`` + tests in **`FountainUIPackageTests`**; character + scene-heading rows stay plain; **underline** follows ``FountainInlineAttributedKeys`` (platform-dependent vs HTML). **Stretch:** richer inline fixtures; attribute gap doc. |

**Dependency:** Relies on **Phase 2** ``FountainDocument`` / ``ScriptElement`` and **Phase 6** inline markup APIs; coordinate with **Phase 8** so styling choices stay consistent with **HTML** / **PDF** where sensible.

---

<a id="phase-14"></a>

## Phase 14 — Swift package 2.0.0 (SemVer) and legacy removal (**complete**)

**Goal:** Ship the **SwiftPM SemVer `2.0.0`** breaking line: remove **legacy parsers**, the **Objective-C reference tree**, and document **package** version separately from **Fountain syntax 1.1**. **Fountain syntax** remains **1.1** unless a future phase explicitly retargets the spec — **do not** conflate **package 2.x** with **markup 1.1**.

**Status:** **Complete** — **[CHANGELOG.md](../CHANGELOG.md)** **`[2.0.0]`**; **14.2–14.3** removals landed; **14.1** documentation + ``FountainPackageVersion`` + consumer notes are in tree. **Publishing** is **`git tag -a 2.0.0`** when maintainers cut the release. **SPM-only repository** work (**former 14.4**) continues under **[Phase 15](#phase-15)**.

| Step | Action | Done when |
|------|--------|-----------|
| 14.1 | **Swift package SemVer `2.0.0`** (Next-Gen line): changelog, ``FountainPackageVersion``, checklist, README / public-API docs — **without** changing **Fountain syntax** pin **1.1**. | **Done:** [CHANGELOG.md](../CHANGELOG.md) **`[2.0.0]`**; ``FountainPackageVersion.librarySemanticVersion``; docs/tests that assert package version ≠ syntax pin. **Optional:** `git tag -a 2.0.0` when publishing. |
| 14.2 | **Delete `Fountain/Legacy/`** entirely (Objective-C + **RegexKitLite**-era **`.m`** reference tree). Remove any Xcode target references, docs, and scripts that still pointed at those paths. | **Done:** Directory removed; **`Package.swift`** no longer excludes **`Legacy/`**; docs + gap analysis updated; **`swift test`** green. **`FountainTests/Legacy/`** (ObjC **tests**) may remain until **[Phase 15.1](#phase-15)** migrates Xcode-hosted tests. |
| 14.3 | **Delete `FountainParser.swift`** (legacy **regex** pipeline) and remove **`FNParserType.regex`** / **`FNScript(…, parser: .regex)`** / **`loadString(…, parser: .regex)`** and all call sites, tests, and roadmap references that depended on it. **Retain** **`FountainRegexes.swift`** while **FNHTMLScript** / styling still need it (until [Phase 11](#phase-11-regex-modernization-swift-native)). | **Done:** No `FountainParser` Swift symbol; **`Fountain.xcodeproj`** file refs cleaned; **`swift test`** green. |

**Release sequencing:** **14.2** + **14.3** landed before the **`[2.0.0]`** changelog cut. Tagging does **not** change the **Fountain syntax** pin.

---

<a id="phase-15"></a>

## Phase 15 — Polish (post-2.0)

**Goal:** Incremental **quality, ergonomics, and fidelity** after the **2.0.0** line — **without** requiring a new Fountain **syntax** generation unless you explicitly scope one.

**Status:** **Open** for **15.1** only at the repo level — **15.2–15.4** polish shipped in **[CHANGELOG.md](../CHANGELOG.md) `[2.0.1]`** (tests + docs + export/parser fidelity). **15.1** (remove **`Fountain.xcodeproj`**, SPM-native samples/tests) is the remaining structural migration.

| Step | Action | Done when |
|------|--------|-----------|
| 15.1 | **SPM-native repository:** remove **`Fountain.xcodeproj`** (and committed **`.xcworkspace`** if any); migrate **Sample Project Mac/iOS** and **`FountainTests`** to SwiftPM-native app / test targets (or document a split repo). Update **CI** if jobs used **`xcodebuild`** on the removed project; refresh [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md), **README**, and **CONTRIBUTING**. | No `.xcodeproj` in tree (or archived per policy); **`swift build`** / **`swift test`** remain CI truth; contributor docs describe **File → Open** on **`Package.swift`**. |
| 15.2 | **Parser / spec polish:** expand **``.fast``** vs **``.tokenPipeline``** parity toward exhaustive Phase **7.3** coverage; tighten **Phase 4.6** migration notes if any consumer relied on removed edge behavior. | **Shipped in 2.0.1:** shared fixture catalog; **Phase 4** builder parity over all bundled **`.fountain`**; **4.6** migration blurb in deprecation + gap docs. **Stretch:** Big Fish / Brick & Steel exhaustive matrix (traceability row). |
| 15.3 | **Writers & preview polish:** **FDX** / **HTML** fidelity stretches; **`FountainUI`** layout, **Dynamic Type**, snapshot tests ([Phase 13](#phase-13-swiftui-and-fountainui) stretches). | **Shipped in 2.0.1:** **export-golden-minimal** **FDX**/**HTML**/**``FountainDocument``** parity across parsers; narrow **``FountainView``** **ImageRenderer** test; golden minimal corpus kinds. **Stretch:** snapshots / Dynamic Type. |
| 15.4 | **Docs & API hygiene:** DocC or expanded symbol docs where high-traffic types need it; [Public-API-Surface.md](Public-API-Surface.md) stays aligned with semver reality. | **Shipped in 2.0.1:** README SwiftPM–first + integration section; **Public-API-Surface** application checklist + fixture notes; checklist step **8**; project spec §8. **Stretch:** DocC / expanded symbol docs. |

---

## Spec traceability matrix (seed)

Fill as you implement. Link each row to tests.

| Fountain 1.1 topic | Phase(s) | Test fixture | Status |
|--------------------|----------|--------------|--------|
| Forced scene heading `.` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Forced action `!` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Forced action **`!` only** (no whitespace-only action shortcut) | 4.6 | `Phase46WhitespaceActionTests`, `ActionMergingTests`, `TokenPipelineFNScriptTests` | ☐ *(Phase 4.6 **partial** — whitespace-only standalone Action removed; see Phase 4 table.)* |
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
| **`FountainTextMeasuring`** + ``FNPaginator`` injection (non-Apple measurers) | 8.5 / 10 | ``FNPaginator``, ``FountainTextMeasuringTests``; [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) | ☑ |
| **PDF** portable or **CoreGraphics**-isolated (`FountainPDFWriter`) | 8.6 / 10 | ``FountainPDFWriter``, [ADR-008-PDF-CoreGraphics-availability.md](ADR-008-PDF-CoreGraphics-availability.md), [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) | ☑ |
| **FDX** `<PageLayout>` + `<ElementSettings>` + `<MoresAndContinueds>` (Final Draft margins) | 8.7 | ``FountainFDXWriter``, `ExportGoldenFixtureTests` / `.fdx` fixtures, `FountainScriptRenderingTests` | ☑ |
| **PDF** MORE / CONT’D across pages + header page numbers | 8.8 | ``FountainPDFWriter``, ``FountainPDFPagination``, ``FountainScriptRenderingTests`` | ☑ |
| Async full parse (string + file) | 9 | `FNScriptAsyncTests` | ☑ |
| `scriptElementStream` preview (full parse, async load) | 9 | `FountainRoadmapExtensionsTests`, `FNScriptAsyncTests` | ☑ |
| Incremental parse (spike / preconditions) | 9.3 | [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) | ☑ |
| Line → element index map | 9.4 | ``FountainLineToElementIndexMap`` + UTF-16 / ``String/Index`` spans on ``syntheticBodyLineText``; ``FountainLineToElementIndexMapTests``; interval tree / title-page line space stretch | ☑ |
| `parseIncremental` + invalidation expansion (full re-parse + ID merge today) | 9.5 | ``FountainEditRangeExpansion``, ``FNScript/parseIncremental``, ``FountainEditRangeExpansionTests``, ``FNScriptIncrementalParseTests``; **chunk** re-parse + merge stretch | ☑ |
| SPM distribution + semver tagging | 10 | [SPM-Release-Checklist.md](SPM-Release-Checklist.md) | ☑ |
| Parser free of UIKit/AppKit (core sources) | 10 | `.github/workflows/swift.yml` (Phase 10.2 grep) | ☑ |
| Wasm **FountainCore** (optional CI) | 10 | `scripts/build-fountaincore-wasm.sh`, [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md), `fountaincore-wasm.yml` | ☑ |
| **FountainCore** CoreGraphics / CoreText only in PDF writer (CI) | 10.4 | `.github/workflows/swift.yml` (Phase 10.4 grep); ``FountainPDFWriter.swift`` + [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) § **10.4** | ☑ |
| Swift **`Regex`** + no `NSRegularExpression` in **`String+Regex.swift`**; **`FountainRegexes`** Swift-compatible patterns | 11 | [§ Phase 11](#phase-11-regex-modernization-swift-native); `FountainRegexes.swift`, `String+Regex.swift`, `FountainSceneHeadingMatcher.swift`; **stretch:** Wasm script note + **`RegexBuilder`** | ☑ |
| **State-aware default parse** (`FountainParsePipeline`); **`FastFountainParser`** off default (explicit **`.fast`**) | 12 | [§ Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript); `TokenPipelineFNScriptTests`, `FNScript`, [Public-API-Surface.md](Public-API-Surface.md) | ☑ |
| **Fast vs tokenPipeline** parity (exhaustive, pre-default-flip) | 12 / 7 / **15.2** | `TokenPipelineFNScriptTests` (bundled fixtures via ``FountainPackageBundledFountainFixtures`` + Big Fish + **Brick & Steel** file parity), corpus tests, [External-Fountain-Test-References.md](External-Fountain-Test-References.md) | ☐ *(bundled **`.fountain`** set unified — feature-length files + external corpora still the stretch)* |
| **SwiftUI** `FountainView` + **`FountainUI`** SPM target | 13 | [§ Phase 13](#phase-13-swiftui-and-fountainui); `FountainUIPackageTests` | ☑ *(initial — richer layout / snapshot stretch)* |
| **Bonus:** Inline markup → **`AttributedString`** for SwiftUI | 13.3 / 6 | ``FountainInlineMarkup``, ``FountainUIScriptElementLineContent``, `FountainUI` | ☑ *(initial — underline / snapshot stretch)* |
| **`2.0.0`** package release (breaking) | 14.1 | [SPM-Release-Checklist.md](SPM-Release-Checklist.md), [CHANGELOG.md](../CHANGELOG.md) | ☑ *(in tree; tag when publishing)* |
| **`Fountain/Legacy/`** removed | 14.2 | [CHANGELOG.md](../CHANGELOG.md) | ☑ |
| **`FountainParser`** / **`.regex`** removed | 14.3 | `FNScript`, `Fountain.xcodeproj`, [CHANGELOG.md](../CHANGELOG.md) | ☑ |
| **SPM-only** repo (no **`Fountain.xcodeproj`**) | 15.1 | [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md), CI | ☐ |

---

## Suggested order of execution (summary)

1. **Phase 0** — Gap analysis (days).  
2. **Phase 1** — SPM + boundaries (small slice, high leverage).  
3. **Phase 2** — New model + migration story (blocks everything else).  
4. **Phases 3 → 5** — New parser pipeline (core engineering).  
5. **Phase 7** — Tests tightened **continuously** (don’t defer to end).  
6. **Phase 6** — Rich text when core parse is stable.  
7. **Phase 8** — Writers / ``FountainScriptRendering`` (**initial complete** — **8.5–8.8** shipped per Phase 8 table; optional HTML/CSS + Linux PDF backend remain polish).  
8. **Phase 9** — Async + perf.  
9. **Phase 10** — SPM / Wasm distribution, parser–UI boundary (**10.2**), Wasm script + manual CI (**10.3**), and **CoreGraphics/CoreText** containment in **FountainCore** (**10.4**).  
10. **Phase 11** — Regex modernization (**complete (initial):** Swift **`Regex`** in **`String+Regex.swift`**, small NS fallback for unsupported patterns, **`FountainRegexes`** Swift-compatible patterns, **macOS 13 / iOS 16** floor; **stretch:** **`RegexBuilder`**, Wasm script note).  
11. **Phase 12** — **Default `FNScript`** on **`FountainParsePipeline`** (**initial-complete**); expand **fast vs tokenPipeline** matrix for exhaustive Phase 7.3 coverage; **`FastFountainParser`** remains **`.fast`** (Project Specification *State-Aware Scanner*).  
12. **Phase 13** — **`FountainUI`** SwiftUI surface (**initial-complete:** `FountainView`, typography, **13.3** inline **`AttributedString`**) when you want native in-app screenplay preview beyond **HTML** / **WKWebView**.  
13. **Phase 14** — **complete:** **`[2.0.0]`** changelog + legacy removals (**14.1–14.3**); optional **`git tag 2.0.0`** when publishing.  
14. **Phase 15** — **polish:** **15.1** SPM-only repo; **15.2–15.4** parser, writers/UI, and docs hygiene — [§ Phase 15](#phase-15).

---

## Polish & maintenance (post–Phase 10)

**Phase 15** is the **numbered** home for post-2.0 polish (including **SPM-only** migration). The table below remains a **cross-phase** scratchpad for stretches that span older phase numbers.

Small, continuous improvements after numbered phases are **initial-complete**:

| Item | Notes |
|------|--------|
| **Phase 3.5** | Prefer Swift ``Regex`` for **localized** slug checks — **done:** ``FountainSceneHeadingMatcher`` is Swift `Regex` only; package floor is **macOS 13 / iOS 16** (Phase **11**). |
| **Phase 4.3 / 4.6** | **4.3 done:** soft breaks + ``!`` preference. **4.6 started:** whitespace-only lines no longer emit standalone **Action** (see Phase 4 table); full semver/migration polish **open**. |
| **Phase 1** | **Polish:** [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) — verification, rollback, and contributor notes (local package wiring **done** in `Fountain.xcodeproj` **today**). **Superseded by [Phase 15.1](#phase-15)** when the project goes **SPM-only**. |
| **Phase 8** | Deeper HTML/CSS refactor if desired. **Polish:** ``FountainStubRendererError`` retained; conforms to ``LocalizedError``. **8.5–8.8** **initial-complete** per Phase 8 table (PDF pagination + ADR-008); stretch: second PDF backend, richer headers. |
| **Phase 9.3–9.5** | **9.3** planning done — [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md). **Implementation:** **9.4** line→element map; **9.5** `parseIncremental(newText:range:)` (safe boundaries, chunk re-tokenize, merge into ``FountainDocument``) — see Phase 9 table. |
| **Gap analysis** | **Closed (matrix):** feature matrix all **Y** with SPM regression pointers — ``GapMatrixClosureTests`` + prior tests; see [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md). |
| **Structural matchers** | **Polish:** ``FountainStructuralLineMatchers`` page break / boneyard / bracket / `TO:` / all-caps cue use **string logic** (no `NSRegularExpression`). |
| **Phase 11** | **Complete (initial):** Swift **`Regex`** primary path in **`String+Regex.swift`**; small **`NSRegularExpression`** fallback when Swift cannot compile a pattern; **`RegexBuilder`** / Wasm notes stretch — [§ Phase 11](#phase-11-regex-modernization-swift-native). |
| **Phase 12** | **Initial-complete:** **default** **`FNScript`** / async / stream on **`FountainParsePipeline`**; **`.fast`** explicit; expand parity matrix vs Phase 7.3 — [§ Phase 12](#phase-12-canonical-state-aware-parser-default-fnscript). |
| **Phase 13** | **Complete (initial):** **`FountainUI`**, **`FountainView`**, typography, **13.3** inline markup — layout / snapshot polish stretch — [§ Phase 13](#phase-13-swiftui-and-fountainui). |
| **Phase 14** | **Complete:** package **`2.0.0`** line in tree (**14.1–14.3**); Fountain **syntax** pin unchanged — [§ Phase 14](#phase-14). |
| **Phase 15** | **Open:** **15.1** SPM-only migration. **15.2–15.4** closed in **`[2.0.1]`** (tests, export fidelity, README / Public-API / spec §8) — [§ Phase 15](#phase-15). |

---

## Related documents

- [Project Specification- Fountain Swift (Next-Gen).md](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) — vision and constraints  
- [README](../README.markdown) — current project state  
- [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) — Xcode sample + test targets on local Swift package (Phase 1.2)  
- [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) — Phase 9.3 incremental parse planning; **9.4–9.5** implementation steps in Phase 9 table  
- [SPM-Release-Checklist.md](SPM-Release-Checklist.md) — Phase 10.1 tagging / semver  
- [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) — Phase 10.3 Wasm notes  
- [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) — manual **Wasm: FountainCore** CI  
- [CHANGELOG.md](../CHANGELOG.md) — **2.0.0** breaking release (**Phase 14**); **2.0.1** integrator polish; **[Unreleased]** tracks **Phase 15.1** only  
- [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) — Phases 0.3 & 1.2  
- [Public-API-Surface.md](Public-API-Surface.md) — Phase 1.3  
- [External-Fountain-Test-References.md](External-Fountain-Test-References.md) — Phase 7.3 external parsers / vendoring notes  

When this roadmap and the gap analysis diverge from reality, **update the tables** in the same PR as the code change.
