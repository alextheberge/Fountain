import Foundation

/// Single list of every **`.fountain`** resource under ``Tests/FountainPackageTests/Fixtures`` (Phase **15.2** polish).
///
/// When you add a new bundled screenplay fixture, append its basename here and keep the list **sorted** so
/// ``Phase7ComplianceTests`` and ``TokenPipelineFNScriptTests`` stay aligned.
enum FountainPackageBundledFountainFixtures {
    static let basenames: [String] = [
        "export-golden-minimal",
        "package-boneyard-sandwich",
        "package-dual-dialogue",
        "package-forced-block",
        "package-mixed-production",
        "package-roundtrip-sample",
        "package-scene-pagebreak",
    ]
}
