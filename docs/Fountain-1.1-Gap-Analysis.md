# Fountain 1.1 — Gap analysis (living document)

**Spec pin:** [Fountain syntax](https://fountain.io/syntax/) — target **1.1** (see also `FountainSyntaxPin` in code).

**Purpose:** Track what the **current** Swift stack implements vs full 1.1, to drive [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md).

**Update rule:** Change this file in the same PR as parser or model changes that affect compliance.

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
| Dual dialogue `^` | P | Column `0`/`1` in metadata; verify pairing / HTML |
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
| Inline bold/italic/underline | P | `FountainInlineMarkup.htmlFragment` for HTML (linear scan); still not `AttributedString` |

---

## Distribution

| Item | Status |
|------|--------|
| Xcode project | Y — primary |
| SwiftPM `Package.swift` | **Started** — `swift build` / `swift test`; `FountainCore` / `FountainHTML` / umbrella `Fountain`; CI on `master` via GitHub Actions; release checklist [SPM-Release-Checklist.md](SPM-Release-Checklist.md) |
| Contributor workflow | **Started** — [CONTRIBUTING.md](../CONTRIBUTING.md); `FountainScriptRendering` protocol for pluggable writers (Phase 8.1) |

---

## Next steps (from roadmap)

1. Expand this matrix with **test fixture IDs** per row (`Tests/FountainPackageTests/Fixtures/*.fountain` + `PackageFixtureCorpusTests`, `Phase5ProductionFeaturesTests`, `BigFishCorpusTests`, Xcode `FountainTests` corpora).
2. Phase 2: replace legacy `FNElement` **class** with a `Codable` struct (or dual-stack with explicit migration).
3. Phase 3–4: line tokenizer + block builder; retire regex-only body parse incrementally.
