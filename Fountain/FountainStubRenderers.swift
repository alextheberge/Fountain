//
//  FountainStubRenderers.swift
//
//  Phase 8.4 — placeholder renderers so call sites can depend on ``FountainScriptRendering`` before FDX/PDF land.
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
