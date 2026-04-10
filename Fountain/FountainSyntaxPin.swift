//
//  FountainSyntaxPin.swift
//
//  Roadmap Phase 0.4 — explicit compliance target for the living spec.
//

import Foundation

/// Canonical Fountain syntax reference and version label this codebase targets.
///
/// When locking a release for 1.1 compliance, record the spec revision (e.g. archive date or
/// changelog URL) in release notes; the live site may drift.
public enum FountainSyntaxPin {
    /// Human-facing syntax documentation (Fountain 1.x).
    public static let specificationURL = URL(string: "https://fountain.io/syntax/")!

    /// Target syntax generation (see roadmap Phase 0–5).
    public static let targetVersionLabel = "1.1"
}
