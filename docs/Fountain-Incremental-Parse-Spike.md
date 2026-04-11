# Incremental parse spike (Phase 9.3)

**Status:** **Planning complete — chunk merge still deferred.** Phase 9.3 is satisfied by recording preconditions, risks, and an explicit **no chunk-only re-parse** decision until merge safety is proven. **Phase 9.4–9.5 (initial)** add line/UTF-16 indexing, invalidation expansion, and ``FNScript/parseIncremental`` (**full** parse + ID merge); production hot paths remain **full parse** via ``FNScript.parseStringAsync`` / ``parseFileAsync`` and preview via ``FNScript.scriptElementStream(from:)`` unless you adopt ``parseIncremental`` deliberately.

## Goal

Re-parse only changed line ranges during live editing instead of scanning the full script on every keystroke.

## Preconditions (go)

- [x] Phase 4.5 round-trip tests cover the element kinds you care about for editing (`Phase45RoundTripTests`, `GoldenDocumentTests`, corpus JSON checks — baseline stable for **full** parse).
- [x] A **line → element index** map exists (or can be derived) for **body** elements — ``FountainLineToElementIndexMap`` (logical body-line → element index) plus **UTF-16** / ``String/Index`` spans in canonical ``syntheticBodyLineText``. **Still TBD for warm merge proofs:** dialogue ambiguity across edits, boneyard/title scopes in the same line space. **Roadmap:** [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md) **Phase 9.4**.
- [x] Clear definition of **invalidation boundaries**: scene headings, blank lines, boneyard open/close, title page (documented below; title page still implies full pre-scan for edits near the top).

## Roadmap implementation steps (after 9.3 planning)

Tracked in the main roadmap **Phase 9** table:

- [x] **9.4** — **Line → element** index + **UTF-16** spans per logical line (``FountainLineToElementIndexMap``); interval tree / title-page line space still optional.
- [x] **9.5** — **Initial** ``FNScript/parseIncremental(newText:editedUTF16Range:parser:)`` + ``FountainEditRangeExpansion`` — structural expansion + **full** re-parse + prefix/suffix **ID** merge; **chunk-only** re-tokenize + element merge remains future work.

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
| **Defer incremental parse** | 2026-04 | **Update (Phase 9 close):** **9.4** line map + UTF-16 spans and **9.5** ``parseIncremental`` (**full** re-parse + ID merge + expansion API) are merged for tooling and future chunk work; **chunk-only** re-parse + merge is still **not** shipped — UIs should still treat production parse as **full** unless/until stretch goals in § suggested spike are proven. **Original:** no chunk merge prototype. **Follow-up:** chunked tokenizer re-parse + merge + golden proofs. |

Implementation checklist: [Fountain-1.1-Implementation-Roadmap.md](Fountain-1.1-Implementation-Roadmap.md) — **Phase 9** table (**9.4**, **9.5**).
