# Swift Package release checklist (Phase 10.1)

**Phase 10.1 (distribution):** SwiftPM is the **only** supported surface (**Phase 15.1** removed **`Fountain.xcodeproj`**). **Library consumers** should depend on this package by **URL** (or a fork) and prefer **semver tags** (`X.Y.Z`) for reproducible builds.

The manifest **package name** is **`FountainSwiftPM`** so the umbrella **library** product can be named `Fountain` without SPM resolver cycles. Apps still **`import Fountain`** when using the umbrella product.

## Products (consumer choice)

| Product | Use when |
|---------|----------|
| **`Fountain`** | One import: parse + HTML + JSON/plain writers. |
| **`FountainCore`** | Parse, `FountainDocument`, metrics, plaintext/JSON writers — **no** UIKit/AppKit at link time from HTML stack. |
| **`FountainHTML`** | `FNHTMLScript`, pagination, CSS resource — Apple platforms. |
| **`FountainUI`** | Native **SwiftUI** preview of **`FountainDocument`** (`FountainView`) — optional; depends on **`FountainCore`** only (not bundled in **`Fountain`** umbrella). |

## Before tagging

1. Run **`swift build`** and **`swift test`** on the oldest supported Xcode / Swift toolchain you claim.
2. Update **[CHANGELOG.md](../CHANGELOG.md)** (move **Unreleased** into a versioned section for **major** bumps).
3. If the **Swift package** SemVer changes, bump **`FountainPackageVersion.librarySemanticVersion`** in `Fountain/FountainPackageVersion.swift` to match the tag — **independently** of **`FountainSyntaxPin.targetVersionLabel`** (Fountain **markup** generation, e.g. **1.1**).
4. Confirm **`FountainSyntaxPin.targetVersionLabel`** matches the **Fountain syntax** level documented in the README (do **not** bump this when only the **package** SemVer advances, e.g. **2.0.0** → **2.0.2**).
5. Review **SemVer** impact:
   - **Major:** breaking public API or behavior changes to parse output.
   - **Minor:** additive API, new element metadata keys, new optional writers.
   - **Patch:** bug fixes, docs, tests only.
6. Update **README** “Fountain Swift package” / version notes if present (keep **syntax 1.1** vs **package 2.x** wording distinct).
7. Ensure **CI** (`.github/workflows/swift.yml`) is green on `master`.
8. If you add **`.fountain`** files under **`Tests/FountainPackageTests/Fixtures/`**, append the basename (sorted) to **`FountainPackageBundledFountainFixtures.basenames`** so inventory, **fast**/**tokenPipeline** parity, and **Phase 4** builder parity stay in sync ([CONTRIBUTING.md](../CONTRIBUTING.md)).

## Tagging

```bash
git tag -a X.Y.Z -m "FountainSwiftPM X.Y.Z"
git push origin X.Y.Z
```

## After tagging

- Optional: attach **GitHub Release** notes (highlights + migration tips).
- If breaking: document in release notes and bump **major**.

Stability expectations for these products: [Public-API-Surface.md](Public-API-Surface.md).
