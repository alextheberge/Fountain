//
//  FountainStubRenderers.swift
//
//  Reserved error type for optional / future stub renderers (FDX and PDF are implemented in
//  ``FountainFDXWriter`` and ``FountainPDFWriter``).
//

import Foundation

/// Thrown when a renderer path is intentionally unavailable.
public enum FountainStubRendererError: Error, Equatable, Sendable, LocalizedError {
    case notImplemented(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let name):
            return "\(name) is not implemented. Use FountainPlaintextWriter, FountainJSONWriter, FountainHTMLWriter, FountainFDXWriter, or FountainPDFWriter for supported export."
        }
    }
}
