# Fountain 1.1 — Gap analysis (living document)

**Spec pin:** [Fountain syntax](https://fountain.io/syntax/) — target **1.1** (see also `FountainSyntaxPin` in code).

**Not package SemVer:** **1.1** here is **markup / syntax** coverage. The **Swift package** may ship **2.0.0**, **2.1.0**, etc. independently — see ``FountainPackageVersion`` and [CHANGELOG.md](../CHANGELOG.md) § Version axes.

**Phase 4.6 migration:** If you depended on **whitespace-only** lines becoming standalone **Action** elements, switch to **`!` forced action**; see [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) (Phase **15.2** polish note).

**Purpose:** Track what the **current** Swift stack implements vs full 1.1, to drive [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md).

**Update rule:** Change this file in the same PR as parser or model changes that affect compliance.

---

## Phase 1 — SwiftPM and boundaries complete

**Phase 1** is **complete**: `Package.swift` defines **FountainCore** / **FountainHTML** / umbrella **Fountain**; GitHub Actions runs **`swift build`** / **`swift test`** on macOS; [Public-API-Surface.md](Public-API-Surface.md) documents stability tiers. The Xcode project links the **local** Swift package for sample apps and **`FountainTests`** (Phase **1.2**): [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md).

---

## Phase 0 — Baseline complete

**Phase 0 (baseline and inventory)** is **complete** for this repository: parsers and regex usage are catalogued below, gaps vs Fountain 1.1 are captured in the feature matrix, **Phase 0.2** (Swift `FountainRegexes.swift`) is classified, **Phase 0.3** deprecation policy is **decided** in [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) § Phase 0.3, and **Phase 0.4** is implemented as `FountainSyntaxPin` + README link.

This document **remains living**: when parser, model, or export behavior changes, update the matrix and fixture map in the **same PR** so “baseline” does not drift from code.

**Where full 1.1 compliance is tracked:** Roadmap **Phase 7** (tests + traceability), not Phase 0. Phase 0 answers *what we have and where the risks are*. **Phase 7** is **roadmap-complete** (fixtures, structured assertions, external references doc, regression policy); the **feature matrix** below is **all Y** for the Swift fast parser — keep it accurate when behavior changes.

**Phase 9** is **roadmap-complete** for **async full parse** and **streaming snapshots**; **incremental** re-parse remains out of scope until [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) preconditions are met.

**Phase 10** is **roadmap-complete** for **SPM-first distribution**, **CI enforcement** of the parser vs UIKit/AppKit boundary, and an **optional Wasm** path (`scripts/build-fountaincore-wasm.sh` + manual Actions workflow — see [SwiftWasm-Experimental.md](SwiftWasm-Experimental.md)).

---

## Parser inventory (Phase 0.1)

| Component | Entry point | Role | SwiftPM |
|-----------|-------------|------|---------|
| **Tokenizer pipeline (default)** | `FNScript(string:)` / `init(file:)` (no `parser:`) | `FountainParsePipeline` — state-aware tokenizer + element builder; primary target for 1.1 work | Yes |
| **Fast parser (explicit)** | `FNScript(..., parser: .fast)` | `FastFountainParser` — line-first body, title page heuristics; parity / migration | Yes |

**Gaps vs Fountain 1.1** are enumerated in § Feature matrix (Y / P / N). **P** items are not “unknown”; they are tracked risks to close under later roadmap phases (see § Next steps).

---

## Parser implementation

| Path | Role |
|------|------|
| `FountainParsePipeline.swift` (via `FNParserType.tokenPipeline`) | Default in `FNScript`; tokenizer-first path |
| `FastFountainParser.swift` | Explicit `FNScript(..., parser: .fast)`; line-oriented scanner + `NSRegularExpression` where needed |

---

## Regex pattern inventory (`Fountain/FountainRegexes.swift`)

Roadmap Phase 0.2 — how patterns are used today. **Spec-critical** patterns participate in structure (sluglines, dialogue, breaks, title page). **Styling** affects inline emphasis for HTML/FDX-style export. Some constants still support **HTML** / string styling paths; the tokenizer + **`.fast`** parsers do not use the full legacy regex document pipeline.

| Symbol | Classification | Used for |
|--------|----------------|----------|
| `UNIVERSAL_LINE_BREAKS_*` | Spec-critical (input) | Normalizing newlines before parse |
| `SCENE_HEADER_*` | Spec-critical | Legacy regex pipeline scene detection |
| `ACTION_*`, `MULTI_LINE_ACTION_*`, `FIRST_LINE_ACTION_*` | Spec-critical | Action blocks in regex pipeline |
| `CHARACTER_CUE_*`, `DIALOGUE_*`, `PARENTHETICAL_*` | Spec-critical | Dialogue structure in regex pipeline |
| `TRANSITION_*`, `FORCED_TRANSITION_*`, `FALSE_TRANSITION_*` | Spec-critical | Transitions vs false positives |
| `PAGE_BREAK_*` | Spec-critical | `===` style breaks in regex pipeline |
| `CLEANUP_*` | Pipeline | Empty action tag cleanup |
| `SCENE_NUMBER_*` | Spec-critical | `#..#` on slugs |
| `SECTION_HEADER_*` | Spec-critical | `#` section lines |
| `BLOCK_COMMENT_*`, `BRACKET_COMMENT_*`, `SYNOPSIS_*` | Spec-critical | Boneyard, notes, synopses in regex pipeline |
| `TITLE_PAGE_*`, `INLINE_DIRECTIVE_*`, `MULTI_LINE_DIRECTIVE_*`, `MULTI_LINE_DATA_*` | Spec-critical | Title page in regex pipeline |
| `DUAL_DIALOGUE_*` | Spec-critical | `^` marker |
| `CENTERED_TEXT_*` | Spec-critical | `> ... <` |
| `BOLD_*`, `ITALIC_*`, `UNDERLINE_*` (and combos) | Styling | Inline emphasis → HTML (`FNHTMLScript`) |
| `NEWLINE_REPLACEMENT` / `NEWLINE_RESTORE` | Pipeline | Temp newline encoding inside regex pipeline |

`FastFountainParser` uses **separate** inline patterns (`FastFountainParser.swift`) for title-page heuristics plus line-first body rules; it does **not** use most of the table above directly. **Polish:** ``FountainSceneHeadingMatcher`` uses Swift ``Regex`` on **macOS 13+ / iOS 16+** and `NSRegularExpression` on older deployment targets (Phase 3.5). **Polish:** ``FountainStructuralLineMatchers`` avoids `NSRegularExpression` for page breaks, boneyard shapes, bracket notes, `TO:` transitions, and all-caps cues (string scans).

**Planned migration:** Refactor **`FountainRegexes.swift`** to **Swift 5.7+ `Regex` / `RegexBuilder`** (including **`/…/` literals** where appropriate) and **remove `NSRegularExpression` entirely** from **`String+Regex.swift`** so shared helpers are faster, typed, and free of **`NSString`**/`NSRange` bridging (important for **WebAssembly** and **Linux**). Tracked as **Phase 11** in [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md#phase-11-regex-modernization-swift-native).

**Objective-C / `.m` patterns:** The **`Fountain/Legacy/`** reference tree was **removed** (Phase **14.2**). Historical patterns exist only in **git history** or forks; this doc inventories **Swift** sources only.

---

## Feature matrix (Swift `FastFountainParser` + model)

Legend: **Y** = supported in practice with **SPM regression tests** named below; **N** = not implemented or wrong; **—** = not reviewed in this pass. *(Former **P** rows were closed by ``GapMatrixClosureTests`` + existing corpus tests.)*

| Fountain 1.1 area | Status | Notes |
|-------------------|--------|--------|
| Title page | Y | Multi-line keys; lone `KEY:` slugline not stripped as title (see parser fix) |
| Scene headings INT/EXT/EST, I/E | Y | Regex compile fix `[.\-\s]` |
| Forced scene heading `.` | Y | |
| Action | Y | |
| Forced action `!` | Y | |
| Character / dialogue | Y | |
| Forced character `@` | Y | ``PolishStructuralAndGapTests`` / ``SpecTraceabilityTests`` |
| Parenthetical | Y | |
| Dual dialogue `^` | Y | ``GapMatrixClosureTests`` (columns + metadata + caret whitespace); HTML: ``FountainScriptRenderingTests`` / `package-dual-dialogue.fountain` |
| Lyrics `~` | Y | ``PolishStructuralAndGapTests`` (multi-line `~` + slug); ``SpecTraceabilityTests`` |
| Transition `TO:` | Y | ``FountainStructuralLineMatchers`` / ``PolishStructuralAndGapTests``; ``FountainScriptMetricsTests`` |
| Forced transition `>` | Y | ``GapMatrixClosureTests`` (bare forced line, `> … TO:` vs slug); ``ParseStructureTests`` (centered vs `> CUT TO:`) |
| Centered `> ... <` | Y | ``ParseStructureTests``; ``GapMatrixClosureTests`` |
| Page break `===` | Y | ``Phase5ProductionFeaturesTests``; ``PolishStructuralAndGapTests`` |
| Section `#` / `##` | Y | ``PolishStructuralAndGapTests`` / ``StructuredComplianceTests`` (`###` → depth 3) |
| Synopsis `=` | Y | ``GapMatrixClosureTests`` (after section); ``Phase5ProductionFeaturesTests`` / ``FountainScriptMetricsTests`` |
| Boneyard `/* */` | Y | ``GapMatrixClosureTests`` (multiline + metrics + ``elementsExcludingBoneyard``); ``Phase5ProductionFeaturesTests``; ``FountainScriptMetricsTests`` |
| Notes `[[ ]]` | Y | ``PolishStructuralAndGapTests`` + ``Phase5ProductionFeaturesTests`` |
| Scene numbers `#..#` on slug | Y | ``GapMatrixClosureTests`` + ``Phase5ProductionFeaturesTests`` |
| Inline bold/italic/underline | Y | ``FountainInlineMarkupTests``; ``Phase6InlinePolicyTests``; ``FountainInlineAttributedTests``; ``GapMatrixClosureTests`` (HTML + rich underline/italic) |

---

## Distribution

| Item | Status |
|------|--------|
| Xcode project | Y — sample apps + `FountainTests`; **local** `Package.swift` linked (Phase **1.2**); [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) |
| SwiftPM `Package.swift` | Y — **authoritative for CI** (`swift build` / `swift test` on `master`); products `FountainCore` / `FountainHTML` / `Fountain`; Phase **1** closed; [SPM-Release-Checklist.md](SPM-Release-Checklist.md) |
| Contributor workflow | Y — [CONTRIBUTING.md](../CONTRIBUTING.md); [Public-API-Surface.md](Public-API-Surface.md); Xcode uses same package: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) |

---

## Fixture / test map (SPM)

| Area | Bundled or corpus fixture | Primary tests |
|------|---------------------------|---------------|
| Minimal body + dialogue | `Tests/FountainPackageTests/Fixtures/package-roundtrip-sample.fountain` | `PackageFixtureCorpusTests` |
| Forced block (`.!@>`) | `package-forced-block.fountain` | `PackageFixtureCorpusTests` |
| Dual dialogue `^` | `package-dual-dialogue.fountain` | `PackageFixtureCorpusTests`, `SpecTraceabilityTests` |
| Section, synopsis, lyrics, `[[ note ]]`, action | `package-mixed-production.fountain` | `PackageFixtureCorpusTests` |
| Production features (page break, `#` scene nums, boneyard, notes, sections) | inline strings | `Phase5ProductionFeaturesTests` |
| Boneyard between action lines | `package-boneyard-sandwich.fountain` | `PackageFixtureCorpusTests` |
| Scene numbers + page break | `package-scene-pagebreak.fountain` | `PackageFixtureCorpusTests` |
| Large screenplay | `FountainTests/Big Fish.fountain` | `BigFishCorpusTests` |
| Reference dual + title | `FountainTests/Brick And Steel.txt` | `BrickSteelCorpusTests`, async + stream parity |

## Next steps (prioritized maintenance)

1. **Fixtures and tests** — When adding `Tests/FountainPackageTests/Fixtures/*.fountain` or corpus tests, extend **`Phase7ComplianceTests`** (fixture inventory) where applicable and keep § Fixture / test map above aligned.
2. **Export regressions** — If you change ``FountainFDXWriter`` output shape, update **`export-golden-minimal.fdx`** and run **`ExportGoldenFixtureTests`**. PDF: prefer ``FountainPDFWriter/renderPDFData(_:)`` for files; contract is documented in [Public-API-Surface.md](Public-API-Surface.md) § FDX and PDF export.
3. **Parser architecture** — Production default is **`FountainParsePipeline`** (**`FNScript`**, **`FNParserType.tokenPipeline`**). Use **`FNScript(..., parser: .fast)`** for **`FastFountainParser`**; see **`TokenPipelineFNScriptTests`** and [TokenPipeline-Parity-Coverage.md](TokenPipeline-Parity-Coverage.md). Expand the fast vs token parity matrix for exhaustive Phase 7.3 coverage as risk allows.
4. **Incremental parse** — Still **deferred** until [Fountain-Incremental-Parse-Spike.md](Fountain-Incremental-Parse-Spike.md) preconditions are met.
5. **Spec edge policy** — Fountain 1.1 **`!` forced action** vs legacy whitespace-only “action” lines: **Phase 4.6 partial** — ``FastFountainParser`` / tokenizer no longer emit a **standalone Action** for whitespace-only body lines **outside** dialogue (see ``Phase46WhitespaceActionTests``). **Migration** text: [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) § Parser classification — Phase 4.6. Remaining semver sign-off is tracked in the roadmap Phase 4 table.
