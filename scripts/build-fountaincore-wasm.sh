#!/usr/bin/env bash
# Phase 10.3 — cross-compile **FountainCore** only (parser + model + plain writers).
# Requires a SwiftWasm (or compatible) Swift SDK installed and `SWIFT_SDK_ID` set to the
# value printed by `swift sdk list` / the `swift-sdk-id` output of `swiftwasm/setup-swiftwasm`.
#
# Example (after installing an SDK, names vary by toolchain):
#   export SWIFT_SDK_ID=wasm32-unknown-wasi
#   ./scripts/build-fountaincore-wasm.sh
#
# **FountainHTML** is intentionally out of scope (UIKit/AppKit + pagination).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -z "${SWIFT_SDK_ID:-}" ]]; then
  echo "error: set SWIFT_SDK_ID to your installed Wasm Swift SDK id (see docs/SwiftWasm-Experimental.md)." >&2
  exit 1
fi

exec swift build --target FountainCore --swift-sdk "$SWIFT_SDK_ID" "$@"
