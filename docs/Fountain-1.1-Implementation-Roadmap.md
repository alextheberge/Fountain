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

**Status:** **Complete** for library distribution, CI, module split, documented public API, and **Phase 1.2** — Xcode sample apps and **`FountainTests`** link the **local** Swift package (no duplicate `Fountain/*.swift` compile in those targets). Details: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md).

| Step | Action | Done when |
|------|--------|-----------|
| 1.1 | Create `Package.swift` with **`FountainCore`** + **`FountainHTML`** + umbrella **`Fountain`** — core has **no** UI frameworks; HTML target holds AppKit/UIKit usage. | **Done:** `swift build` + `swift test` at repo root; products `Fountain`, `FountainCore`, `FountainHTML` |
| 1.2 | Move or duplicate **model + parse + write** into the package; keep sample apps consuming the package (or same sources via careful symlink — prefer package as source of truth). | **Done:** Single **`Fountain/`** source tree; **no** second copy of library sources. **SPM** defines the canonical module graph; **Xcode** sample targets and **`FountainTests`** link the **local** package product **Fountain** (see [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)). |
| 1.3 | Define **public API surface** (`FNScript`, element types, errors). Mark experimental APIs `@_spi` or nested `FountainCore.Experimental` if needed. | **Done:** [Public-API-Surface.md](Public-API-Surface.md) — stability tiers + experimental list; **`@_spi`** reserved for when churn drops (not required to close Phase 1) |
| 1.4 | **CI:** `swift build` + `swift test` on macOS (Linux where possible; Wasm later). | **Done:** `.github/workflows/swift.yml` on **macOS**; Linux/Wasm not in matrix because package platforms are **macOS 12+** / **iOS 15+** only (see Phase 10 for Wasm stretch) |

---

## Phase 2 — Data model (replace/align `FNElement`)

**Goal:** **Codable**, **Identifiable**, **stable round-trip** to JSON for tooling.

**Status:** **Complete (initial)** — `FNElement` is a **`struct`** with **`Codable`**, **`Identifiable`**, and stable **`id`** carried into ``ScriptElement``; typed metadata remains on ``ScriptElement.metadata`` / ``FountainMetadataKey``. Legacy **Objective-C** `FNElement` in `Fountain/Legacy/` is unchanged for old targets.

| Step | Action | Done when |
|------|--------|-----------|
| 2.1 | Introduce **`FNElementType`** `String` enum (or similar) covering **all** 1.1 structural kinds you need (including `pageBreak`, `boneyard`, `synopsis`, `section`, `general`, `note`, etc. — align names with spec vocabulary). | **Done:** `FNElementType` + map to `ScriptElementKind` |
| 2.2 | Implement **`FNElement`** struct: `id`, `type`, `content`, **`attributes: [String: String]`** (or typed `Metadata` struct with `Codable`) for scene number, section depth, `dualDialogue`, `centered`, etc. | **Done (Swift):** `FNElement` struct with `id` + legacy field names (`elementType`, `elementText`, …); scene/section/dual/centered via fields + **also** in ``ScriptElement.metadata`` / ``FountainMetadataKey``; golden JSON in `Tests/FountainPackageTests/Fixtures/` |
| 2.3 | Migration shim from **old** `FNElement` class / `elementType: String` if dual-stack period is required. | **Done (Swift):** no dual Swift stack; ``LegacyInteropTests`` cover kind alignment, ``FNElement`` JSON round-trip, and **ID parity** ``FNElement`` ↔ ``ScriptElement`` |
| 2.4 | Define **`FNScript`** (or `FountainDocument`) with `elements` + `titlePage` + version metadata. | **Done:** `FountainDocument(script:)` + ``FNScript.fountainDocument`` / ``fountainDocumentJSONData(prettyPrinted:)`` + ``asFountainDocument()`` + `FountainSyntaxPin` |

---

## Phase 3 — Tokenization (Phase 1 of “Universal Parser”)

**Goal:** **State-aware scanning** — classify **lines** (and line continuations) into **tokens** without building the final tree yet.

**Status:** **Complete (initial)** — shared title-page prescan, structural line matchers, coarse body line tokenizer (aligned with ``FastFountainParser``), and existing forced-prefix + slug helpers. Production parse remains ``FastFountainParser`` by default; **opt-in tokenizer-first load** is ``FNScript(…, parser: .tokenPipeline)`` via ``FountainParsePipeline`` (tests: ``TokenPipelineFNScriptTests``). The tokenizer is for tooling, previews, and the migration path toward a single canonical engine.

| Step | Action | Done when |
|------|--------|-----------|
| 3.1 | Specify **token kinds** (slug, action, character, dialogue, parenthetical, transition, lyrics, section, synopsis, pagebreak, boneyard open/close, title-page directive, blank, unknown…). | **Done:** `FountainTokenKind` + `FountainTokenizedLine` + `LineEndingNormalizationTests` |
| 3.2 | Implement **line splitter** honoring Fountain newline rules; normalize `\r\n` once at input. | **Done:** `FountainLineEndingNormalizer` / `FountainLineSplitter` + `LineSplitterTests` |
| 3.3 | Implement **title page pre-scan** (before body) consistent with 1.1; **do not** mis-classify body lines like `FADE IN:` as title keys (regression from current fast parser fixes). | **Done:** `FountainTitlePagePrescan` (used by ``FastFountainParser``) + `TitlePageRegressionTests` + `Phase3TokenizationTests` |
| 3.4 | Map **forced prefixes** to tokens: `.` scene, `!` action, `@` character, `~` lyrics, `>` transition (non-centered), etc. | **Done:** `FountainForcedPrefixScanner` + `ForcedPrefixScannerTests`; body tokenizer applies full line order including forced lines |
| 3.5 | Replace fragile regex-only checks with **scanner + Regex hybrid**: use `Regex` for **localized** patterns (e.g. scene heading stem), not whole-document substitution. | **Done:** `FountainSceneHeadingMatcher` + `FountainStructuralLineMatchers` + corpus smoke (`BigFishCorpusTests`); **polish:** Swift `Regex` slug stem on **macOS 13+ / iOS 16+**, `NSRegularExpression` fallback for package floors (macOS 12 / iOS 15) |

---

## Phase 4 — Contextual analysis (Phase 2 of “Universal Parser”)

**Goal:** Tokens → **blocks** (dialogue blocks, dual dialogue, continuity).

**Status:** **Complete (initial)** — dialogue line roles align with ``FastFountainParser`` parenthetical detection; dual-`^` columns match the fast parser and ``FountainScriptElementsBuilder``; token→element assembly is parity-tested against ``FNScript`` on package fixtures. Canonical production parse remains ``FNScript`` / ``FastFountainParser``; the builder proves the Phase 3 tokenizer stream can reconstruct element **types** (and merges) for the same inputs.

| Step | Action | Done when |
|------|--------|-----------|
| 4.1 | **Dialogue block** state machine: Character → optional Parenthetical → Dialogue (multi-line rules per 1.1). | **Done:** `FountainDialogueBlockRecognizer` (leading-`(` rule) + `DialogueBlockRecognizerTests` |
| 4.2 | **Dual dialogue** (`^`): pair detection and **column** metadata in `attributes`. | **Done:** Parser + ``FountainScriptElementsBuilder`` + `SpecTraceabilityTests` / `Phase4ParityTests` (`package-dual-dialogue.fountain`) |
| 4.3 | **Action** merging rules (soft line breaks vs hard breaks) — explicitly match 1.1; **remove reliance on trailing spaces** for forcing; prefer **`!`**. | **Done:** `ActionMergingTests`; legacy all-whitespace action lines remain accepted in ``FastFountainParser`` (document-only preference for `!`) |
| 4.4 | **Centered text** `> ... <` vs **forced transition** `>` — disambiguation per spec. | **Done:** `ParseStructureTests` + tokenizer order (`> … TO:` → transition before bare-`>` branch) |
| 4.5 | Emit final **`[FNElement]`** list from token stream. | **Done:** `FountainScriptElementsBuilder` + `Phase4ParityTests` (element-type parity vs ``FNScript`` on fixtures) + existing `Phase45RoundTripTests` / export round-trip |

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

**Status:** **Complete (initial)** — unified ``FountainScriptRendering`` API; plaintext / Markdown / JSON / HTML + **FDX / PDF** exporters with tests. Legacy ``FountainWriter`` remains for Fountain body/title string export; new call sites should prefer protocol conformers.

| Step | Action | Done when |
|------|--------|-----------|
| 8.1 | Define `FountainWriter` (or `ScriptRenderer`) protocol: `func render(_ document: FNScript) throws -> String` (or associated type for binary PDF). | **Done:** ``FountainScriptRendering`` + ``FountainPlaintextWriter``; parity vs ``FountainWriter.documentFromScript`` (``FountainScriptRenderingTests`` / ``testFountainPlaintextWriterMatchesFountainWriterDocument``) |
| 8.2 | **`HTMLWriter`**: migrate from `FNHTMLScript`; modern CSS (grid/flex); keep **CSS as resource** or string template. | **Done:** ``FNHTMLScript`` conforms to ``FountainScriptRendering``; ``FountainHTMLWriter`` (thin adapter in **FountainHTML**); `ScriptCSS.css` resource + dual-dialogue grid tests (`FountainScriptRenderingTests`) |
| 8.3 | **`MarkdownWriter`**: useful for LLM/tooling pipelines. | **Done:** ``FountainMarkdownWriter`` + ``FountainJSONWriter`` + `FountainScriptRenderingTests` (lyrics + bracket notes + JSON shape) |
| 8.4 | **`FDXWriter`** / **`PDFWriter`**: Final Draft XML + PDF export. | **Done:** ``FountainFDXWriter`` emits minimal importable .fdx; ``FountainPDFWriter`` renders US Letter PDF via CoreGraphics/CoreText (``render`` = base64, ``renderPDFData`` = `Data`). Tests: ``FountainScriptRenderingTests`` (`testFDXWriterEmitsFinalDraftXML`, `testPDFWriterProducesValidPDFBytes`). |

---

## Phase 9 — Performance and concurrency

**Goal:** Large scripts don’t freeze UI.

| Step | Action | Done when |
|------|--------|-----------|
| 9.1 | **`parse(_:)` async**: offload full parse to `Task.detached` or custom executor; **synchronous** wrapper documented as “small docs only.” | **Done:** ``FNScript.parseStringAsync`` / ``parseFileAsync`` (``Task.detached``) + class-level doc on sync vs async; `FNScriptAsyncTests` (string parity + **Brick & Steel** file parity vs sync) |
| 9.2 | **Streaming API** (optional): `AsyncSequence` of elements for preview. | **Done:** ``FNScript.scriptElementStream(from:)`` (uses ``parseStringAsync``) / ``scriptElementStream(fromFile:)`` (``parseFileAsync`` + snapshot) → `AsyncStream<ScriptElement>`; `FountainRoadmapExtensionsTests` + `FNScriptAsyncTests` (stream vs async snapshot) |
| 9.3 | **Incremental parse** (advanced): diff by line map; **last** after baseline is solid. | **Done (planning):** [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) — preconditions / risks / **explicit defer**; no incremental merge in tree until spike proves safe |

---

## Phase 10 — Cross-platform packaging

| Step | Action | Done when |
|------|--------|-----------|
| 10.1 | **SPM** is default distribution; tag semver. | **Done:** [SPM-Release-Checklist.md](SPM-Release-Checklist.md) (default distribution, products table, tagging flow); consumers use package URL + **`import Fountain`** / **`FountainCore`** |
| 10.2 | **Conditional compilation:** `#if canImport(UIKit)` only in **render** or **sample** targets, not in parser. | **Done:** `.github/workflows/swift.yml` greps `Fountain/*.swift` (excluding `Platform` / `FNPaginator` / `FNHTMLScript`) for `canImport(UIKit\|AppKit)` **and** stray `import UIKit` / `import AppKit` |
| 10.3 | **SwiftWasm** (stretch): build script + CI matrix entry; document unsupported APIs. | **Done:** `scripts/build-fountaincore-wasm.sh` + [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) + manual workflow [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) (Actions → **Wasm: FountainCore**) |

---

## Spec traceability matrix (seed)

Fill as you implement. Link each row to tests.

| Fountain 1.1 topic | Phase(s) | Test fixture | Status |
|--------------------|----------|--------------|--------|
| Forced scene heading `.` | 3–4 | `SpecTraceabilityTests` | ☑ |
| Forced action `!` | 3–4 | `SpecTraceabilityTests` | ☑ |
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
| Async full parse (string + file) | 9 | `FNScriptAsyncTests` | ☑ |
| `scriptElementStream` preview (full parse, async load) | 9 | `FountainRoadmapExtensionsTests`, `FNScriptAsyncTests` | ☑ |
| Incremental parse | 9 | [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) (deferred) | ☑ |
| SPM distribution + semver tagging | 10 | [SPM-Release-Checklist.md](SPM-Release-Checklist.md) | ☑ |
| Parser free of UIKit/AppKit (core sources) | 10 | `.github/workflows/swift.yml` (Phase 10.2 grep) | ☑ |
| Wasm **FountainCore** (optional CI) | 10 | `scripts/build-fountaincore-wasm.sh`, [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md), `fountaincore-wasm.yml` | ☑ |

---

## Suggested order of execution (summary)

1. **Phase 0** — Gap analysis (days).  
2. **Phase 1** — SPM + boundaries (small slice, high leverage).  
3. **Phase 2** — New model + migration story (blocks everything else).  
4. **Phases 3 → 5** — New parser pipeline (core engineering).  
5. **Phase 7** — Tests tightened **continuously** (don’t defer to end).  
6. **Phase 6** — Rich text when core parse is stable.  
7. **Phase 8** — Writers / ``FountainScriptRendering`` (**initial complete**; FDX/PDF baseline shipped — refine layout vs Final Draft in follow-ups).  
8. **Phase 9** — Async + perf.  
9. **Phase 10** — SPM / Wasm distribution and parser–UI boundary (roadmap complete; optional Wasm CI is manual).

---

## Polish & maintenance (post–Phase 10)

Small, continuous improvements after numbered phases are **initial-complete**:

| Item | Notes |
|------|--------|
| **Phase 3.5** | Prefer Swift ``Regex`` for **localized** slug checks — **started:** ``FountainSceneHeadingMatcher`` uses Swift `Regex` on **macOS 13+ / iOS 16+** and the same rule via `NSRegularExpression` on older OS (package still supports macOS 12 / iOS 15). |
| **Phase 4.3** | **Started:** ``FastFountainParser`` documents legacy whitespace-only action lines vs Fountain 1.1 ``!`` forced action. |
| **Phase 1** | **Polish:** [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) — verification, rollback, and contributor notes (local package wiring **done** in `Fountain.xcodeproj`). |
| **Phase 8** | Deeper HTML/CSS refactor if desired. **Polish:** ``FountainStubRendererError`` retained for future optional stubs; conforms to ``LocalizedError``. |
| **Phase 9.3** | Incremental parse — [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) (deferred until preconditions met). |
| **Gap analysis** | **Closed (matrix):** feature matrix all **Y** with SPM regression pointers — ``GapMatrixClosureTests`` + prior tests; see [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md). |
| **Structural matchers** | **Polish:** ``FountainStructuralLineMatchers`` page break / boneyard / bracket / `TO:` / all-caps cue use **string logic** (no `NSRegularExpression`). |

---

## Related documents

- [Project Specification- Fountain Swift (Next-Gen).md](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) — vision and constraints  
- [README](../README.markdown) — current project state  
- [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) — Xcode sample + test targets on local Swift package (Phase 1.2)  
- [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) — Phase 9.3 incremental parse planning (decision: deferred)  
- [SPM-Release-Checklist.md](SPM-Release-Checklist.md) — Phase 10.1 tagging / semver  
- [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) — Phase 10.3 Wasm notes  
- [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) — manual **Wasm: FountainCore** CI  
- [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) — Phases 0.3 & 1.2  
- [Public-API-Surface.md](Public-API-Surface.md) — Phase 1.3  
- [External-Fountain-Test-References.md](External-Fountain-Test-References.md) — Phase 7.3 external parsers / vendoring notes  

When this roadmap and the gap analysis diverge from reality, **update the tables** in the same PR as the code change.
