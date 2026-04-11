//
//  FountainPackageVersion.swift
//
//  Phase 14.1 — SwiftPM **library** semantic version, distinct from Fountain **markup** syntax level
//  (see ``FountainSyntaxPin``).
//

import Foundation

/// Semantic version of this **Swift package** (**FountainSwiftPM** / `Package.swift` products).
///
/// This value tracks **API and distribution** releases (SemVer). It is **not** the same as
/// ``FountainSyntaxPin/targetVersionLabel``, which names the **Fountain screenplay markup**
/// generation targeted by parsers and ``FountainDocument/fountainSyntaxVersion`` (today **"1.1"**).
///
/// When you cut a release, bump ``librarySemanticVersion`` in lockstep with **[CHANGELOG.md](../CHANGELOG.md)**
/// and git tags — see [SPM-Release-Checklist.md](../docs/SPM-Release-Checklist.md).
public enum FountainPackageVersion: Sendable {
    /// Current **package** SemVer string (e.g. **`"2.0.1"`**).
    public static let librarySemanticVersion = "2.0.1"
}
