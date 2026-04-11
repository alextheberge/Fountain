//
//  FountainSyntaxPin.swift
//
//  Roadmap Phase 0.4 — explicit compliance target for the living spec.
//

import Foundation

/// Fountain **markup specification** pin: which generation of the [Fountain syntax](https://fountain.io/syntax/)
/// parsers and exporters target.
///
/// ## Not Swift package SemVer
///
/// ``targetVersionLabel`` (e.g. **`"1.1"`**) is **only** the screenplay **syntax / spec** level. It flows into
/// interchange payloads as ``FountainDocument/fountainSyntaxVersion``. It is **independent** of the SwiftPM
/// **library** version — see ``FountainPackageVersion/librarySemanticVersion`` (e.g. **`"2.0.1"`**).
///
/// When locking a release for spec compliance, record the **fountain.io** revision (archive date or
/// changelog URL) in release notes; the live site may drift. Phase 0.4 is satisfied by this URL +
/// ``targetVersionLabel``; add errata links only when you publish a compliance snapshot.
public enum FountainSyntaxPin {
    /// Human-facing syntax documentation (Fountain 1.x).
    public static let specificationURL = URL(string: "https://fountain.io/syntax/")!

    /// Target **Fountain markup** syntax generation (e.g. **1.1**). **Not** the Swift package SemVer.
    public static let targetVersionLabel = "1.1"
}
