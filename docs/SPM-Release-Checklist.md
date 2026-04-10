# Swift Package release checklist (Phase 10.1)

The **source of truth** for library code is SwiftPM (`Package.swift`). Xcode sample targets may still compile `Fountain/` inline; consumers should depend on tagged SPM versions.

## Before tagging

1. Run **`swift build`** and **`swift test`** on the oldest supported Xcode / Swift toolchain you claim.
2. Confirm **`FountainSyntaxPin.targetVersionLabel`** matches the Fountain spec level documented in the README.
3. Review **SemVer** impact:
   - **Major:** breaking public API or behavior changes to parse output.
   - **Minor:** additive API, new element metadata keys, new optional writers.
   - **Patch:** bug fixes, docs, tests only.
4. Update **README** “Work in progress” / version note if present.
5. Ensure **CI** (`.github/workflows/swift.yml`) is green on `master`.

## Tagging

```bash
git tag -a X.Y.Z -m "FountainSwiftPM X.Y.Z"
git push origin X.Y.Z
```

## After tagging

- Optional: attach **GitHub Release** notes (highlights + migration tips).
- If breaking: document in release notes and bump **major**.

## Distribution note

Products: `Fountain` (umbrella), `FountainCore`, `FountainHTML`. Apps that only need parse + plain export can depend on `FountainCore`; HTML export requires `FountainHTML` (and thus UI frameworks at link time on Apple platforms).
