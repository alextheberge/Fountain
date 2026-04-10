# Incremental parse spike (Phase 9.3)

**Status:** Planning only — do **not** implement until the fast parser + `FountainDocument` round-trips are stable (see Phase 4.5 tests).

## Goal

Re-parse only changed line ranges during live editing instead of scanning the full script on every keystroke.

## Preconditions (go)

- [ ] Phase 4.5 round-trip tests cover the element kinds you care about for editing.
- [ ] A **line → element index** map exists (or can be derived) without ambiguity for dialogue blocks.
- [ ] Clear definition of **invalidation boundaries**: scene headings, blank lines, boneyard open/close, title page.

## No-go signals

- Dual dialogue, sections, and boneyard frequently cause **non-local** structure changes; a naive diff will mis-parse.
- Title page heuristics already require a full pre-scan; mixing incremental body parse with title edits is high risk.

## Suggested spike (1–2 days)

1. Build a **line index**: `[Range<Int>]` of UTF-16 or character offsets per logical line (after LF normalization).
2. On edit, compute minimal **affected line range** (expand N lines upward until a safe anchor: blank line or scene heading).
3. Re-run `FastFountainParser` on **synthetic document** = prefix (frozen) + affected window + suffix (frozen), then **merge** element arrays — validate with golden tests before shipping.
4. If merge error rate > X% on random edits on Big Fish, stop and document “full parse only.”

## Outcome

Record the decision in this file (go / no-go / defer) and link any prototype branch from the roadmap.
