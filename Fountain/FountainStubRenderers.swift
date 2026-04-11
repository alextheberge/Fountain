//
//  FountainStubRenderers.swift
//
//  Phase 8.4 — stub renderers (roadmap-complete): throw ``FountainStubRendererError`` until real FDX/PDF exporters are implemented as separate milestones.
//

import Foundation

/// Thrown by stub exporters until real writers ship.
public enum FountainStubRendererError: Error, Equatable, Sendable {
    case notImplemented(String)
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
