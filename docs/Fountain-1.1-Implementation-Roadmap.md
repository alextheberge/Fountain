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

| Step | Action | Done when |
|------|--------|-----------|
| 0.1 | Inventory current parsers (`FastFountainParser`, `FountainParser`, legacy ObjC) and **list gaps vs Fountain 1.1** (forced rules, boneyard, notes, dual dialogue, etc.). | **Started:** [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) |
| 0.2 | Inventory **all regex patterns** (`FountainRegexes.swift` / `.m`) and mark which are **spec-critical** vs **styling-only**. | **Done (Swift):** table in [Fountain-1.1-Gap-Analysis.md](Fountain-1.1-Gap-Analysis.md) § Regex pattern inventory |
| 0.3 | Decide **deprecation policy**: keep legacy targets for one release, feature-flag, or hard cut. | **Started:** README + [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) |
| 0.4 | Add **pin** to Fountain syntax version you’re targeting (1.1 + any errata). | **Done:** `FountainSyntaxPin` + README link |

**Deliverable:** `docs/Fountain-1.1-Gap-Analysis.md` (short, living document).

---

## Phase 1 — Swift Package and module boundaries

**Goal:** A **SwiftPM library** that can be used by macOS/iOS apps **and** future tooling without Xcode-only coupling.

| Step | Action | Done when |
|------|--------|-----------|
| 1.1 | Create `Package.swift` with **`FountainCore`** + **`FountainHTML`** + umbrella **`Fountain`** — core has **no** UI frameworks; HTML target holds AppKit/UIKit usage. | **Done (initial):** `swift build` + `swift test` at repo root; products `Fountain`, `FountainCore`, `FountainHTML` |
| 1.2 | Move or duplicate **model + parse + write** into the package; keep sample apps consuming the package (or same sources via careful symlink — prefer package as source of truth). | **Started:** README + [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) (SPM vs Xcode table) |
| 1.3 | Define **public API surface** (`FNScript`, element types, errors). Mark experimental APIs `@_spi` or nested `FountainCore.Experimental` if needed. | **Started:** [Public-API-Surface.md](Public-API-Surface.md) + doc comments on core types |
| 1.4 | **CI:** `swift build` + `swift test` on macOS (Linux where possible; Wasm later). | **Done:** `.github/workflows/swift.yml` |

---

## Phase 2 — Data model (replace/align `FNElement`)

**Goal:** **Codable**, **Identifiable**, **stable round-trip** to JSON for tooling.

| Step | Action | Done when |
|------|--------|-----------|
| 2.1 | Introduce **`FNElementType`** `String` enum (or similar) covering **all** 1.1 structural kinds you need (including `pageBreak`, `boneyard`, `synopsis`, `section`, `general`, `note`, etc. — align names with spec vocabulary). | **Started:** `FNElementType` + map to `ScriptElementKind` |
| 2.2 | Implement **`FNElement`** struct: `id`, `type`, `content`, **`attributes: [String: String]`** (or typed `Metadata` struct with `Codable`) for scene number, section depth, `dualDialogue`, `centered`, etc. | **Started:** `FountainMetadataKey` + `ScriptElement.metadata` + golden JSON (`Tests/FountainPackageTests/Fixtures/`) |
| 2.3 | Migration shim from **old** `FNElement` class / `elementType: String` if dual-stack period is required. | **Started:** `LegacyInteropTests` (SPM) prove `asFountainDocument()` matches `FNElementType` for a slice |
| 2.4 | Define **`FNScript`** (or `FountainDocument`) with `elements` + `titlePage` + version metadata. | **Started:** `FountainDocument(script:)` + ``FNScript.fountainDocument`` / ``fountainDocumentJSONData(prettyPrinted:)`` (single ``asFountainDocument()`` snapshot per encode) + `FountainSyntaxPin` |

---

## Phase 3 — Tokenization (Phase 1 of “Universal Parser”)

**Goal:** **State-aware scanning** — classify **lines** (and line continuations) into **tokens** without building the final tree yet.

| Step | Action | Done when |
|------|--------|-----------|
| 3.1 | Specify **token kinds** (slug, action, character, dialogue, parenthetical, transition, lyrics, section, synopsis, pagebreak, boneyard open/close, title-page directive, blank, unknown…). | **Started:** `FountainTokenKind` + tests |
| 3.2 | Implement **line splitter** honoring Fountain newline rules; normalize `\r\n` once at input. | **Done (initial):** `FountainLineSplitter.lines` + `LineSplitterTests` |
| 3.3 | Implement **title page pre-scan** (before body) consistent with 1.1; **do not** mis-classify body lines like `FADE IN:` as title keys (regression from current fast parser fixes). | **Started:** `TitlePageRegressionTests` |
| 3.4 | Map **forced prefixes** to tokens: `.` scene, `!` action, `@` character, `~` lyrics, `>` transition (non-centered), etc. | **Started:** `FountainForcedPrefixScanner` + `ForcedPrefixScannerTests` |
| 3.5 | Replace fragile regex-only checks with **scanner + Regex hybrid**: use `Regex` for **localized** patterns (e.g. scene heading stem), not whole-document substitution. | **Started:** `FountainSceneHeadingMatcher` + `BigFishCorpusTests` element-count smoke |

---

## Phase 4 — Contextual analysis (Phase 2 of “Universal Parser”)

**Goal:** Tokens → **blocks** (dialogue blocks, dual dialogue, continuity).

| Step | Action | Done when |
|------|--------|-----------|
| 4.1 | **Dialogue block** state machine: Character → optional Parenthetical → Dialogue (multi-line rules per 1.1). | **Started:** `FountainDialogueBlockRecognizer` + `DialogueBlockRecognizerTests` |
| 4.2 | **Dual dialogue** (`^`): pair detection and **column** metadata in `attributes`. | **Started:** `SpecTraceabilityTests` (`dualDialogue` + `dualDialogueColumn` `0`/`1` on ``FNElement`` / ``FountainMetadataKey``) |
| 4.3 | **Action** merging rules (soft line breaks vs hard breaks) — explicitly match 1.1; **remove reliance on trailing spaces** for forcing; prefer **`!`**. | **Started:** `ActionMergingTests` (soft merge + `!` continuation); prefer `!` over whitespace-only “forced” lines (parser still accepts legacy `^\\s{2,}$` action lines — document only) |
| 4.4 | **Centered text** `> ... <` vs **forced transition** `>` — disambiguation per spec. | **Started:** `ParseStructureTests` |
| 4.5 | Emit final **`[FNElement]`** list from token stream. | **Started:** `Phase45RoundTripTests` (JSON `FountainDocument` round-trip + `FountainWriter` re-parse kind sequence) |

---

## Phase 5 — Production features (Phase 3 of “Universal Parser”)

**Goal:** Page breaks, scene numbers, omissions/notes, boneyard semantics for **metrics** and **export**.

| Step | Action | Done when |
|------|--------|-----------|
| 5.1 | **Page breaks** (`===`…): distinct elements; interaction with pagination if you keep `FNPaginator`. | **Started:** `Phase5ProductionFeaturesTests.testPageBreakIsDistinctElement` |
| 5.2 | **Scene numbers** (`#...#` on slugs): capture in attributes; optional `suppressSceneNumbers` flag. | **Started:** `Phase5ProductionFeaturesTests` (slug capture + `suppressSceneNumbers` export) |
| 5.3 | **Boneyard** `/* ... */`: strip or isolate for **word-count / timing** estimators; verify **not** counted as dialogue. | **Started:** `FNScript.elementsExcludingBoneyard` + ``FNScript.metrics`` (`FountainScriptMetrics`: words, dialogue words, element counts, scene / transition counts, **character cue / dialogue element counts**) + `FountainScriptMetricsTests` + `package-boneyard-sandwich.fountain` |
| 5.4 | **Notes** `[[ ... ]]` per 1.1: element type or annotation model; clarify vs boneyard for exporters. | **Started:** `Phase5ProductionFeaturesTests.testBracketNoteAfterBlankLine` (`Comment` element) |
| 5.5 | **Sections / synopses** (`#`, `##`, `=`): hierarchical depth in attributes. | **Started:** `Phase5ProductionFeaturesTests` (depth + synopsis + Codable metadata) |

---

## Phase 6 — Inline markup and `AttributedString` (optional but spec-aligned)

**Goal:** Fix “markup leakage” — **optional** rich-text pipeline.

| Step | Action | Done when |
|------|--------|-----------|
| 6.1 | Document **two modes**: `plain` (preserve markers in `content`) vs `rich` (parse to `AttributedString` segments). | **Started:** `FountainInlineRenderingMode` (incl. ``attributedStringFromInlineMarkup``) + ``FountainInlineMarkup.attributedFragment(from:)`` + `FountainInlineAttributedTests` |
| 6.2 | Implement **bold / italic / underline** (and `_` where spec applies) with **Fuzzili-safe** parsing (no catastrophic backtracking). | **Started:** shared scanner → ``htmlFragment`` / ``attributedFragment``; underline in `AttributedString` is partial (see ``attributedFragment`` doc); HTML full fidelity |
| 6.3 | Keep **regex/constants** in one module for **Wasm** reuse. | **Started:** `FountainInlineDelimiterTable` (incl. bold/italic/underline flags per rule) + `FountainRoadmapExtensionsTests` |

---

## Phase 7 — Test suite & Fountain 1.1 compliance

**Goal:** **Repeatable** compliance, not “looks right in the app.”

| Step | Action | Done when |
|------|--------|-----------|
| 7.1 | Curate **official-style fixture set**: minimal one-liners per rule + **Big Fish** + **Brick & Steel** + edge cases (forced lines, boneyard, dual). | **Started:** `BigFishCorpusTests` + `BrickSteelCorpusTests` + `PackageFixtureCorpusTests` (incl. `package-mixed-production.fountain`, `package-scene-pagebreak.fountain` for `#…#` + `===`) |
| 7.2 | Add **structured assertions**: expected `FNElementType` sequences + key attributes (not only string snapshots). | **Started:** `ParseAssertions` + `ParseStructureTests` + `StructuredComplianceTests` + `assertFountainDocumentsStructurallyEqual` (JSON decode vs re-parse); **Big Fish** / **Brick & Steel** corpus JSON + metrics checks |
| 7.3 | Track **external suite** if one exists (community “standardized Fountain test suite” — integrate or vendor with license check). | **Started:** README § other implementations & fixtures |
| 7.4 | **Regression policy:** any parser bugfix adds a **minimal** new fixture. | **Started:** [CONTRIBUTING.md](../CONTRIBUTING.md) |

---

## Phase 8 — `FountainWriter` protocol and renderers

**Goal:** **Eliminate monolithic HTML** in core; multiple backends.

| Step | Action | Done when |
|------|--------|-----------|
| 8.1 | Define `FountainWriter` (or `ScriptRenderer`) protocol: `func render(_ document: FNScript) throws -> String` (or associated type for binary PDF). | **Started:** `FountainScriptRendering` + `FountainPlaintextWriter` (`FountainScriptRendering.swift`); parity test vs ``FountainWriter.documentFromScript`` (`FountainScriptRenderingTests`) |
| 8.2 | **`HTMLWriter`**: migrate from `FNHTMLScript`; modern CSS (grid/flex); keep **CSS as resource** or string template. | **Started:** ``FNHTMLScript`` + ``FountainScriptRendering``; `ScriptCSS.css` dual-dialogue **grid** + title `.notes` typo fix; `FountainScriptRenderingTests.testFNHTMLScriptDualDialogueContainsGridClasses` (`package-dual-dialogue.fountain`) |
| 8.3 | **`MarkdownWriter`**: useful for LLM/tooling pipelines. | **Started:** `FountainMarkdownWriter` + **`FountainJSONWriter`** (`FountainScriptRendering`) + `FountainScriptRenderingTests` (lyrics + bracket notes) |
| 8.4 | **`FDXWriter`** / **`PDFWriter`**: stub behind feature flags or separate products to avoid bloating core. | **Started:** `FountainFDXWriter` / `FountainPDFWriter` + `FountainStubRendererError` |

---

## Phase 9 — Performance and concurrency

**Goal:** Large scripts don’t freeze UI.

| Step | Action | Done when |
|------|--------|-----------|
| 9.1 | **`parse(_:)` async**: offload full parse to `Task.detached` or custom executor; **synchronous** wrapper documented as “small docs only.” | **Started:** ``FNScript.parseStringAsync`` / ``parseFileAsync`` + `FNScriptAsyncTests` (incl. **Brick & Steel** file parity vs sync) |
| 9.2 | **Streaming API** (optional): `AsyncSequence` of elements for preview. | **Started:** ``FNScript.scriptElementStream(from:)`` / ``scriptElementStream(fromFile:)`` → `AsyncStream<ScriptElement>` (full parse, then yield); `FountainRoadmapExtensionsTests` field parity vs parallel ``FountainDocument`` (string + **Brick & Steel** file) |
| 9.3 | **Incremental parse** (advanced): diff by line map; **last** after baseline is solid. | **Started:** [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) (go/no-go checklist) |

---

## Phase 10 — Cross-platform packaging

| Step | Action | Done when |
|------|--------|-----------|
| 10.1 | **SPM** is default distribution; tag semver. | **Started:** [SPM-Release-Checklist.md](SPM-Release-Checklist.md) |
| 10.2 | **Conditional compilation:** `#if canImport(UIKit)` only in **render** or **sample** targets, not in parser. | **Started:** `.github/workflows/swift.yml` greps `Fountain/*.swift` excluding `Platform` / `FNPaginator` / `FNHTMLScript` |
| 10.3 | **SwiftWasm** (stretch): build script + CI matrix entry; document unsupported APIs. | **Started:** [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) (CI Wasm not enabled yet) |

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
| Boneyard between body lines | 5 | `package-boneyard-sandwich.fountain`, `PackageFixtureCorpusTests` | ☑ |
| Script metrics (scenes / transitions) | 5 | `FountainScriptMetricsTests` | ☑ |
| Scene numbers + page break | 5 | `package-scene-pagebreak.fountain`, `PackageFixtureCorpusTests` | ☑ |
| Dual dialogue HTML (grid CSS) | 8 | `package-dual-dialogue.fountain`, `FountainScriptRenderingTests` | ☑ |

---

## Suggested order of execution (summary)

1. **Phase 0** — Gap analysis (days).  
2. **Phase 1** — SPM + boundaries (small slice, high leverage).  
3. **Phase 2** — New model + migration story (blocks everything else).  
4. **Phases 3 → 5** — New parser pipeline (core engineering).  
5. **Phase 7** — Tests tightened **continuously** (don’t defer to end).  
6. **Phase 6** — Rich text when core parse is stable.  
7. **Phase 8** — Writers refactor.  
8. **Phase 9** — Async + perf.  
9. **Phase 10** — Wasm / distribution hardening.

---

## Related documents

- [Project Specification- Fountain Swift (Next-Gen).md](../Project%20Specification-%20Fountain%20Swift%20(Next-Gen).md) — vision and constraints  
- [README](../README.markdown) — current project state  
- [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) — Phase 9.3 incremental parse planning  
- [SPM-Release-Checklist.md](SPM-Release-Checklist.md) — Phase 10.1 tagging / semver  
- [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md) — Phase 10.3 Wasm notes  
- [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) — Phases 0.3 & 1.2  
- [Public-API-Surface.md](Public-API-Surface.md) — Phase 1.3  

When this roadmap and the gap analysis diverge from reality, **update the tables** in the same PR as the code change.
