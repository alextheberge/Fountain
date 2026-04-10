# Fountain 1.1 — Gap analysis (living document)

**Spec pin:** [Fountain syntax](https://fountain.io/syntax/) — target **1.1** (verify section anchors when locking compliance).

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
| Dual dialogue `^` | P | Verify pairing / HTML |
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
| Inline bold/italic/underline | P | Passed through; not `AttributedString` |

---

## Distribution

| Item | Status |
|------|--------|
| Xcode project | Y — primary |
| SwiftPM `Package.swift` | **Started** — `swift build` from repo root; `Legacy/` excluded; `ScriptCSS.css` bundled |

---

## Next steps (from roadmap)

1. Expand this matrix with **test fixture IDs** per row.
2. Add SPM **test target** (or keep Xcode-only tests until core is split).
3. Phase 2+: new `Codable` model and tokenizer pipeline per roadmap.
