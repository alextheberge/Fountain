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
| 0.1 | Inventory current parsers (`FastFountainParser`, `FountainParser`, legacy ObjC) and **list gaps vs Fountain 1.1** (forced rules, boneyard, notes, dual dialogue, etc.). | Written matrix: *feature → file → supported?* |
| 0.2 | Inventory **all regex patterns** (`FountainRegexes.swift` / `.m`) and mark which are **spec-critical** vs **styling-only**. | Table + link to spec sections |
| 0.3 | Decide **deprecation policy**: keep legacy targets for one release, feature-flag, or hard cut. | ADR or README section |
| 0.4 | Add **pin** to Fountain syntax version you’re targeting (1.1 + any errata). | Comment in repo + link in README |

**Deliverable:** `docs/Fountain-1.1-Gap-Analysis.md` (short, living document).

---

## Phase 1 — Swift Package and module boundaries

**Goal:** A **SwiftPM library** that can be used by macOS/iOS apps **and** future tooling without Xcode-only coupling.

| Step | Action | Done when |
|------|--------|-----------|
| 1.1 | Create `Package.swift` with a **`FountainCore`** (or `Fountain`) **library product** — pure Swift, **no** UI frameworks. | `swift build` succeeds on macOS |
| 1.2 | Move or duplicate **model + parse + write** into the package; keep sample apps consuming the package (or same sources via careful symlink — prefer package as source of truth). | Apps build against package |
| 1.3 | Define **public API surface** (`FNScript`, element types, errors). Mark experimental APIs `@_spi` or nested `FountainCore.Experimental` if needed. | Doc comments on public types |
| 1.4 | **CI:** `swift build` + `swift test` on macOS (Linux where possible; Wasm later). | Workflow green |

---

## Phase 2 — Data model (replace/align `FNElement`)

**Goal:** **Codable**, **Identifiable**, **stable round-trip** to JSON for tooling.

| Step | Action | Done when |
|------|--------|-----------|
| 2.1 | Introduce **`FNElementType`** `String` enum (or similar) covering **all** 1.1 structural kinds you need (including `pageBreak`, `boneyard`, `synopsis`, `section`, `general`, `note`, etc. — align names with spec vocabulary). | Enum documented + frozen naming policy |
| 2.2 | Implement **`FNElement`** struct: `id`, `type`, `content`, **`attributes: [String: String]`** (or typed `Metadata` struct with `Codable`) for scene number, section depth, `dualDialogue`, `centered`, etc. | Golden JSON fixtures encode/decode |
| 2.3 | Migration shim from **old** `FNElement` class / `elementType: String` if dual-stack period is required. | Tests prove equivalent documents for a corpus subset |
| 2.4 | Define **`FNScript`** (or `FountainDocument`) with `elements` + `titlePage` + version metadata. | Single type is “source of truth” for writers |

---

## Phase 3 — Tokenization (Phase 1 of “Universal Parser”)

**Goal:** **State-aware scanning** — classify **lines** (and line continuations) into **tokens** without building the final tree yet.

| Step | Action | Done when |
|------|--------|-----------|
| 3.1 | Specify **token kinds** (slug, action, character, dialogue, parenthetical, transition, lyrics, section, synopsis, pagebreak, boneyard open/close, title-page directive, blank, unknown…). | `TokenKind` enum + doc |
| 3.2 | Implement **line splitter** honoring Fountain newline rules; normalize `\r\n` once at input. | Tests with mixed newlines |
| 3.3 | Implement **title page pre-scan** (before body) consistent with 1.1; **do not** mis-classify body lines like `FADE IN:` as title keys (regression from current fast parser fixes). | Targeted tests |
| 3.4 | Map **forced prefixes** to tokens: `.` scene, `!` action, `@` character, `~` lyrics, `>` transition (non-centered), etc. | Spec table ↔ tests |
| 3.5 | Replace fragile regex-only checks with **scanner + Regex hybrid**: use `Regex` for **localized** patterns (e.g. scene heading stem), not whole-document substitution. | Performance snapshot on Big Fish |

---

## Phase 4 — Contextual analysis (Phase 2 of “Universal Parser”)

**Goal:** Tokens → **blocks** (dialogue blocks, dual dialogue, continuity).

| Step | Action | Done when |
|------|--------|-----------|
| 4.1 | **Dialogue block** state machine: Character → optional Parenthetical → Dialogue (multi-line rules per 1.1). | Unit tests from small fixtures |
| 4.2 | **Dual dialogue** (`^`): pair detection and **column** metadata in `attributes`. | Dual-dialogue fixture passes |
| 4.3 | **Action** merging rules (soft line breaks vs hard breaks) — explicitly match 1.1; **remove reliance on trailing spaces** for forcing; prefer **`!`**. | Tests + doc note |
| 4.4 | **Centered text** `> ... <` vs **forced transition** `>` — disambiguation per spec. | Regression tests |
| 4.5 | Emit final **`[FNElement]`** list from token stream. | Round-trip: parse → canonical structure matches golden |

---

## Phase 5 — Production features (Phase 3 of “Universal Parser”)

**Goal:** Page breaks, scene numbers, omissions/notes, boneyard semantics for **metrics** and **export**.

| Step | Action | Done when |
|------|--------|-----------|
| 5.1 | **Page breaks** (`===`…): distinct elements; interaction with pagination if you keep `FNPaginator`. | Tests |
| 5.2 | **Scene numbers** (`#...#` on slugs): capture in attributes; optional `suppressSceneNumbers` flag. | Tests |
| 5.3 | **Boneyard** `/* ... */`: strip or isolate for **word-count / timing** estimators; verify **not** counted as dialogue. | Tests |
| 5.4 | **Notes** `[[ ... ]]` per 1.1: element type or annotation model; clarify vs boneyard for exporters. | Tests |
| 5.5 | **Sections / synopses** (`#`, `##`, `=`): hierarchical depth in attributes. | Tests |

---

## Phase 6 — Inline markup and `AttributedString` (optional but spec-aligned)

**Goal:** Fix “markup leakage” — **optional** rich-text pipeline.

| Step | Action | Done when |
|------|--------|-----------|
| 6.1 | Document **two modes**: `plain` (preserve markers in `content`) vs `rich` (parse to `AttributedString` segments). | Public API documented |
| 6.2 | Implement **bold / italic / underline** (and `_` where spec applies) with **Fuzzili-safe** parsing (no catastrophic backtracking). | Golden strings |
| 6.3 | Keep **regex/constants** in one module for **Wasm** reuse. | Same tests run on native target |

---

## Phase 7 — Test suite & Fountain 1.1 compliance

**Goal:** **Repeatable** compliance, not “looks right in the app.”

| Step | Action | Done when |
|------|--------|-----------|
| 7.1 | Curate **official-style fixture set**: minimal one-liners per rule + **Big Fish** + **Brick & Steel** + edge cases (forced lines, boneyard, dual). | `Tests/Fixtures/` |
| 7.2 | Add **structured assertions**: expected `FNElementType` sequences + key attributes (not only string snapshots). | CI stable |
| 7.3 | Track **external suite** if one exists (community “standardized Fountain test suite” — integrate or vendor with license check). | Linked in README |
| 7.4 | **Regression policy:** any parser bugfix adds a **minimal** new fixture. | Team agreement |

---

## Phase 8 — `FountainWriter` protocol and renderers

**Goal:** **Eliminate monolithic HTML** in core; multiple backends.

| Step | Action | Done when |
|------|--------|-----------|
| 8.1 | Define `FountainWriter` (or `ScriptRenderer`) protocol: `func render(_ document: FNScript) throws -> String` (or associated type for binary PDF). | Protocol in core |
| 8.2 | **`HTMLWriter`**: migrate from `FNHTMLScript`; modern CSS (grid/flex); keep **CSS as resource** or string template. | Visual/regression optional |
| 8.3 | **`MarkdownWriter`**: useful for LLM/tooling pipelines. | Tests |
| 8.4 | **`FDXWriter`** / **`PDFWriter`**: stub behind feature flags or separate products to avoid bloating core. | Roadmap issues filed |

---

## Phase 9 — Performance and concurrency

**Goal:** Large scripts don’t freeze UI.

| Step | Action | Done when |
|------|--------|-----------|
| 9.1 | **`parse(_:)` async**: offload full parse to `Task.detached` or custom executor; **synchronous** wrapper documented as “small docs only.” | UI test / benchmark on Big Fish |
| 9.2 | **Streaming API** (optional): `AsyncSequence` of elements for preview. | Prototype behind SPI |
| 9.3 | **Incremental parse** (advanced): diff by line map; **last** after baseline is solid. | Spike doc + go/no-go |

---

## Phase 10 — Cross-platform packaging

| Step | Action | Done when |
|------|--------|-----------|
| 10.1 | **SPM** is default distribution; tag semver. | Release doc |
| 10.2 | **Conditional compilation:** `#if canImport(UIKit)` only in **render** or **sample** targets, not in parser. | Grep guard in CI |
| 10.3 | **SwiftWasm** (stretch): build script + CI matrix entry; document unsupported APIs. | Issue or doc “experimental” |

---

## Spec traceability matrix (seed)

Fill as you implement. Link each row to tests.

| Fountain 1.1 topic | Phase(s) | Test fixture | Status |
|--------------------|----------|--------------|--------|
| Forced scene heading `.` | 3–4 | (add) | ☐ |
| Forced action `!` | 3–4 | (add) | ☐ |
| Forced character `@` | 3–4 | (add) | ☐ |
| Forced transition `>` | 3–4 | (add) | ☐ |
| Lyrics `~` | 3–4 | (add) | ☐ |
| Centered `> <` | 4 | (add) | ☐ |
| Dual dialogue `^` | 4 | `DualDialogue.fountain` | ☐ |
| Title page | 3 | `Simple.fountain` | ☐ |
| Page breaks | 5 | `PageBreaks.fountain` | ☐ |
| Boneyard | 5 | `Boneyard.fountain` | ☐ |
| Notes `[[ ]]` | 5 | (add) | ☐ |
| Sections / synopses | 5 | `SectionHeaders.fountain` | ☐ |

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

When this roadmap and the gap analysis diverge from reality, **update the tables** in the same PR as the code change.
