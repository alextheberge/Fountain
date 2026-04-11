# SwiftWasm (Phase 10.3 — experimental)

**Goal:** Cross-compile **`FountainCore`** (parser + model + plain writers) for **WebAssembly** so Fountain tooling can run in the browser without a native binary.

## Current reality

- `Package.swift` declares **Apple** platforms (`macOS(.v12)`, `iOS(.v15)`). Cross-compiling with a **Swift SDK for Wasm** is still the supported experiment path; there is no `SupportedPlatform.wasi` entry in this manifest yet.
- **`FountainHTML`** depends on **UIKit/AppKit** (`Platform.swift`, `FNHTMLScript`, `FNPaginator`) and is **not** Wasm-viable as-is — exclude from Wasm builds (same split as today’s `FountainCore` / `FountainHTML` targets).
- **`FountainCore`** uses **Foundation** (`NSString`, `NSRegularExpression`, file paths in `FNScript.init(file:)`). A Wasm deployment should treat **file URL** entry points as unsupported or bridge from JS (see below).

## Build script (local or CI)

- **`scripts/build-fountaincore-wasm.sh`** — runs `swift build --target FountainCore --swift-sdk "$SWIFT_SDK_ID"`.
- Set **`SWIFT_SDK_ID`** to the SDK id from `swift sdk list` or from the **`swift-sdk-id`** output of [`swiftwasm/setup-swiftwasm`](https://github.com/swiftwasm/setup-swiftwasm) (used in CI).

## CI (manual)

Wasm is **not** run on every push (toolchain + SDK size); it is available as a **manual** workflow:

- [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) — **Actions → “Wasm: FountainCore” → Run workflow** on `master` / your branch.

Uses **`swift:6.0.3-noble`** + **`swiftwasm/setup-swiftwasm@v2`** + the script above. If the job fails after a Swift or SDK upgrade, update this doc and the workflow container/SDK pin.

## Unsupported / risky on Wasm

| API / pattern | Notes |
|---------------|--------|
| **`FNScript(file:)`** / **`parseFileAsync(_:)`** reading host paths | No traditional POSIX filesystem in the browser; pass **`String`** / async string from JS host. |
| **`FountainHTML`** (`FNHTMLScript`, `FNPaginator`, `Platform`) | UIKit/AppKit — **omit** from Wasm products. |
| **`Task.detached`** (Phase 9.1 async parse) | Verify against your SwiftWasm concurrency/runtime version; prefer cooperative tasks if issues appear. |
| **Full `swift test` on Wasm** | Not in CI yet; tests assume Apple test bundles and fixtures. |

## Parser / UI boundary (Phase 10.2)

Core sources under `Fountain/*.swift` **must not** use `canImport(UIKit|AppKit)` or `import UIKit` / `import AppKit` except in **`Platform.swift`**, **`FNPaginator.swift`**, and **`FNHTMLScript.swift`**. This is enforced in **`.github/workflows/swift.yml`** on every push/PR.

## Status

**Manual CI + script in tree** — run the **Wasm: FountainCore** workflow after substantive parser changes. Update this file when a Wasm SDK pin or Foundation limitation changes.
