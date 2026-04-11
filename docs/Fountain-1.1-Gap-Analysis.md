# Fountain 1.1 — Gap analysis (living document)

**Spec pin:** [Fountain syntax](https://fountain.io/syntax/) — target **1.1** (see also `FountainSyntaxPin` in code).

**Purpose:** Track what the **current** Swift stack implements vs full 1.1, to drive [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md).

**Update rule:** Change this file in the same PR as parser or model changes that affect compliance.

---

## Phase 1 — SwiftPM and boundaries complete

**Phase 1** is **complete**: `Package.swift` defines **FountainCore** / **FountainHTML** / umbrella **Fountain**; GitHub Actions runs **`swift build`** / **`swift test`** on macOS; [Public-API-Surface.md](Public-API-Surface.md) documents stability tiers. Xcode sample apps still compile **`Fountain/*.swift` inline** (same tree as SPM, not a forked codebase). Optional follow-up: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md).

---

## Phase 0 — Baseline complete

**Phase 0 (baseline and inventory)** is **complete** for this repository: parsers and regex usage are catalogued below, gaps vs Fountain 1.1 are captured in the feature matrix, **Phase 0.2** (Swift `FountainRegexes.swift`) is classified, **Phase 0.3** deprecation policy is **decided** in [Deprecation-And-Distribution.md](Deprecation-And-Distribution.md) § Phase 0.3, and **Phase 0.4** is implemented as `FountainSyntaxPin` + README link.

This document **remains living**: as Phases 2–7 advance, update the matrix and fixture map so “baseline” does not drift from code.

**Where full 1.1 compliance is tracked:** Roadmap **Phase 7** (tests + traceability), not Phase 0. Phase 0 answers *what we have and where the risks are*. **Phase 7** is **roadmap-complete** (fixtures, structured assertions, external references doc, regression policy); the **feature matrix** below still tracks spec gaps until every **N** / **P** is closed.

---

## Parser inventory (Phase 0.1)

| Component | Entry point | Role | SwiftPM |
|-----------|-------------|------|---------|
| **Fast parser** | `FNScript(string:)` / `init(file:)` (default) | `FastFountainParser` — line-first body, title page heuristics; primary target for 1.1 work | Yes |
| **Regex parser (Swift)** | `FNScript(..., parser: .regex)` | `FountainParser` — legacy `NSRegularExpression` pipeline; parity for older integrations | Yes |
| **Legacy Objective-C** | Not exposed in package API | `Fountain/Legacy/*.m` — RegexKitLite-era implementation | **Excluded** |

**Gaps vs Fountain 1.1** are enumerated in § Feature matrix (Y / P / N). **P** items are not “unknown”; they are tracked risks to close under later roadmap phases (see § Next steps).

---

## Parser implementation

| Path | Role |
|------|------|
| `FastFountainParser.swift` | Default in `FNScript`; line-oriented scanner + `NSRegularExpression` |
| `FountainParser.swift` | Legacy regex pipeline; `FNScript` `parser: .regex` |
| `Fountain/Legacy/*.m` | Obj-C + RegexKitLite (not in SwiftPM target) |

---

## Regex pattern inventory (`Fountain/FountainRegexes.swift`)

Roadmap Phase 0.2 — how patterns are used today. **Spec-critical** patterns participate in structure (sluglines, dialogue, breaks, title page). **Styling** affects inline emphasis for HTML/FDX-style export. **Pipeline** = internal to the legacy regex HTML pipeline (`FountainParser`), not the fast line parser.

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

`FastFountainParser` uses **separate** inline patterns (`FastFountainParser.swift`) for title-page heuristics plus line-first body rules; it does **not** use most of the table above directly.

**Objective-C / `.m` patterns:** Not duplicated in this doc. Anything not in `FountainRegexes.swift` lives under `Fountain/Legacy/` and is out of SwiftPM scope (Phase 0.2 covers the **Swift** inventory).

---

## Feature matrix (Swift `FastFountainParser` + model)

Legend: **Y** = supported in practice, **P** = partial / edge-case risk, **N** = not implemented or wrong, **—** = not reviewed in this pass.

| Fountain 1.1 area | Status | Notes |
|-------------------|--------|--------|
| Title page | Y | Multi-line keys; lone `KEY:` slugline not stripped as title (see parser fix) |
| Scene headings INT/EXT/EST, I/E | Y | Regex compile fix `[.\-\s]` |
| Forced scene heading `.` | Y | |
| Action | Y | |
| Forced action `!` | Y | |
| Character / dialogue | Y | |
| Forced character `@` | P | Verify all spec cases |
| Parenthetical | Y | |
| Dual dialogue `^` | P | Column `0`/`1` in metadata; HTML grid smoke: `FountainScriptRenderingTests.testFNHTMLScriptDualDialogueContainsGridClasses` |
| Lyrics `~` | P | |
| Transition `TO:` | Y | |
| Forced transition `>` | P | vs centered `> ... <` |
| Centered `> ... <` | Y | |
| Page break `===` | Y | |
| Section `#` / `##` | P | Depth |
| Synopsis `=` | P | |
| Boneyard `/* */` | P | Metrics/export semantics |
| Notes `[[ ]]` | P | |
| Scene numbers `#..#` on slug | P | |
| Inline bold/italic/underline | P | `FountainInlineMarkup.htmlFragment` + `attributedFragment` (bold/italic via `InlinePresentationIntent`; underline-only / portable underline on `AttributedString` still limited) |

---

## Distribution

| Item | Status |
|------|--------|
| Xcode project | Y — sample apps + `FountainTests`; compiles `Fountain/` inline until Phase 1.2 package wiring |
| SwiftPM `Package.swift` | Y — **authoritative for CI** (`swift build` / `swift test` on `master`); products `FountainCore` / `FountainHTML` / `Fountain`; Phase **1** closed; [SPM-Release-Checklist.md](SPM-Release-Checklist.md) |
| Contributor workflow | Y — [CONTRIBUTING.md](../CONTRIBUTING.md); [Public-API-Surface.md](Public-API-Surface.md); optional Xcode→SPM: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md) |

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

## Next steps (from roadmap)

1. Keep this table in sync when adding `Fixtures/*.fountain` or corpus tests.
2. Phase 2 (Swift): **`FNElement`** is a **`Codable` `struct`** with stable **`id`** (see roadmap). **Objective-C** `FNElement` under `Fountain/Legacy/` remains a class for unmigrated targets.
3. Phase 3–4: line tokenizer + block builder; retire regex-only body parse incrementally.
