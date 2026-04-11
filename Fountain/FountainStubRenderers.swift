//
//  FountainStubRenderers.swift
//
//  Phase 8.4 — stub renderers (roadmap-complete): throw ``FountainStubRendererError`` until real FDX/PDF exporters are implemented as separate milestones.
//

import Foundation

/// Thrown by stub exporters until real writers ship.
public enum FountainStubRendererError: Error, Equatable, Sendable, LocalizedError {
    case notImplemented(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let name):
            return "\(name) is not implemented. Use FountainPlaintextWriter, FountainJSONWriter, or FountainHTMLWriter for supported export."
        }
    }
}

/// Final Draft XML export (not implemented).
public struct FountainFDXWriter: FountainScriptRendering, Sendable {
    public init() {}

    public func render(_ script: FNScript) throws -> String {
        throw FountainStubRendererError.notImplemented("FountainFDXWriter")
    }
}

/// PDF screenplay export (not implemented).
public struct FountainPDFWriter: FountainScriptRendering, Sendable {
    public init() {}

    public func render(_ script: FNScript) throws -> String {
        throw FountainStubRendererError.notImplemented("FountainPDFWriter")
    }
}
