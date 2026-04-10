# SwiftWasm (Phase 10.3 — experimental)

**Goal:** Compile `FountainCore` (parser + model + plain writers) for **WebAssembly** so Fountain tooling can run in the browser without a native binary.

## Current reality

- This repository targets **Apple** platforms in `Package.swift` (`macOS(.v12)`, `iOS(.v15)`).
- **`FountainHTML`** depends on **UIKit/AppKit** (`Platform.swift`, `FNHTMLScript`) and is **not** Wasm-viable as-is.
- **`FountainCore`** uses **Foundation** (`NSString`, `NSRegularExpression`, file I/O in a few paths). SwiftWasm’s Foundation subset may require stubs or conditional compilation.

## Unsupported / risky on Wasm

- `FNScript` initializers that read **files** from disk (`init(file:)`).
- **`Task.detached`** / GCD assumptions — verify against the Wasm concurrency story for your toolchain.
- **`FNHTMLScript`**, **`FNPaginator`**, **`Platform`** — exclude from Wasm products (same split as `FountainHTML` today).

## Suggested approach

1. Add a **documented** Wasm build script (local only) that:
   - Builds **only** `FountainCore` (or a new `FountainWasm` product with a reduced source list).
   - Uses the upstream **SwiftWasm SDK** instructions for your Swift version.
2. Add **CI matrix entry** only after a clean `swift build` on Wasm is reproducible (optional stretch).
3. List **APIs that throw or no-op** on Wasm in this doc as you discover them.

## Status

**Not verified in CI** — this file is a placeholder for the Phase 10.3 roadmap item. Update when a Wasm build has been attempted.
