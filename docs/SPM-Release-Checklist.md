# Swift Package release checklist (Phase 10.1)

**Phase 10.1 (distribution):** SwiftPM is the **default** distribution surface for the next-gen stack. The **`Fountain.xcodeproj`** sample apps and **`FountainTests`** link the **local** package for demos and Xcode-hosted tests — **library consumers should still depend on this package by URL** (or a fork) and prefer **semver tags** (`X.Y.Z`) for reproducible builds.

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
3. Confirm **`FountainSyntaxPin.targetVersionLabel`** matches the Fountain spec level documented in the README.
4. Review **SemVer** impact:
   - **Major:** breaking public API or behavior changes to parse output.
   - **Minor:** additive API, new element metadata keys, new optional writers.
   - **Patch:** bug fixes, docs, tests only.
5. Update **README** “Fountain 1.1 (Swift next-gen)” / version note if present.
6. Ensure **CI** (`.github/workflows/swift.yml`) is green on `master`.

## Tagging

```bash
git tag -a X.Y.Z -m "FountainSwiftPM X.Y.Z"
git push origin X.Y.Z
```

## After tagging

- Optional: attach **GitHub Release** notes (highlights + migration tips).
- If breaking: document in release notes and bump **major**.

Stability expectations for these products: [Public-API-Surface.md](Public-API-Surface.md).
