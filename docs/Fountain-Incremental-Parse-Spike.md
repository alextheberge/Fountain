# Incremental parse spike (Phase 9.3)

**Status:** **Planning complete — implementation deferred.** Phase 9.3 is satisfied by recording preconditions, risks, and an explicit **no-ship** decision until a dedicated spike proves merge safety. Production path remains **full parse** via ``FNScript.parseStringAsync`` / ``parseFileAsync`` and preview via ``FNScript.scriptElementStream(from:)``.

## Goal

Re-parse only changed line ranges during live editing instead of scanning the full script on every keystroke.

## Preconditions (go)

- [x] Phase 4.5 round-trip tests cover the element kinds you care about for editing (`Phase45RoundTripTests`, `GoldenDocumentTests`, corpus JSON checks — baseline stable for **full** parse).
- [ ] A **line → element index** map exists (or can be derived) without ambiguity for dialogue blocks — **partial:** ``FountainLineToElementIndexMap`` (logical body-line → element index) is implemented; **UTF-16 / character spans**, dialogue ambiguity, and boneyard/title scopes remain **TBD**. **Roadmap:** [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md) **Phase 9.4**.
- [x] Clear definition of **invalidation boundaries**: scene headings, blank lines, boneyard open/close, title page (documented below; title page still implies full pre-scan for edits near the top).

## Roadmap implementation steps (after 9.3 planning)

Tracked in the main roadmap **Phase 9** table:

- [ ] **9.4** — **Line → element** index (interval tree or array of character / line offsets per logical line).
- [ ] **9.5** — **`parseIncremental(newText: String, range: …)`** — expand to nearest safe boundaries, re-tokenize the chunk only, merge into **`FountainDocument`** / ``FNScript``.

## No-go signals

- Dual dialogue, sections, and boneyard frequently cause **non-local** structure changes; a naive diff will mis-parse.
- Title page heuristics already require a full pre-scan; mixing incremental body parse with title edits is high risk.

## Suggested spike (1–2 days)

1. Build a **line index**: `[Range<Int>]` of UTF-16 or character offsets per logical line (after LF normalization).
2. On edit, compute minimal **affected line range** (expand N lines upward until a safe anchor: blank line or scene heading).
3. Re-run `FastFountainParser` on **synthetic document** = prefix (frozen) + affected window + suffix (frozen), then **merge** element arrays — validate with golden tests before shipping.
4. If merge error rate > X% on random edits on Big Fish, stop and document “full parse only.”

## Outcome (recorded)

| Decision | Date | Notes |
|----------|------|--------|
| **Defer incremental parse** | 2026-04 | No prototype merged. **Phase 9** ships **async full parse** + **streaming snapshot** only. Revisit when a line→element map and invalidation proofs exist; until then, UIs should use ``parseFileAsync`` / ``parseStringAsync`` and optionally ``scriptElementStream`` for progressive display after one full parse. **Follow-up:** implementation broken out as roadmap **9.4** (index map) and **9.5** (`parseIncremental`). |

Implementation checklist: [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md) — **Phase 9** table (**9.4**, **9.5**).
