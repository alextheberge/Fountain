# External Fountain test references (Phase 7.3)

There is **no single official cross-language Fountain conformance suite**. Phase 7.3 is satisfied by **tracking** useful third-party parsers and corpora here, with a clear **license** reminder before copying tests into this repo.

## In-repo compliance (primary)

- **SwiftPM:** `swift test` — structured helpers in `Tests/FountainPackageTests/ParseAssertions.swift`, corpus tests (`BigFishCorpusTests`, `BrickSteelCorpusTests`), bundled fixtures under `Tests/FountainPackageTests/Fixtures/`, and `Phase7ComplianceTests` (fixture inventory + minimal one-liners).
- **Xcode:** `FountainTests` (same shared `Fountain/` sources); keep behavior aligned when changing the parser.

## External implementations (examples)

| Project | Notes |
|--------|--------|
| [fountain.io/syntax](https://fountain.io/syntax/) | Normative syntax reference (not executable tests). |
| [nyousefi/Fountain](https://github.com/nyousefi/Fountain) | Original Objective-C implementation; includes tests — check license before vendoring. |
| [Fountain.js](https://github.com/mattdaly/Fountain.js) | JavaScript parser; Brick & Steel–style coverage in ecosystem. |
| [fountain-js](https://github.com/jonnygreenwald/fountain-js) | Alternative JS parser; verify license and API shape before porting cases. |

## Vendoring checklist

1. Confirm **license** allows redistribution or adaptation.
2. Prefer **minimal** `.fountain` snippets (Phase 7.4) plus a focused assertion in `Tests/FountainPackageTests/`.
3. Credit the source in the test file or fixture comment when required by the license.
