//
//  FountainPDFPagination.swift
//
//  Phase 8.8 — lives in the umbrella **Fountain** product so ``import Fountain`` exposes
//  ``FountainPDFWriter/renderPDFDataPaginated(script:)`` (needs both **FountainCore** and **FountainHTML**).
//

import Foundation
import FountainCore
import FountainHTML

#if !arch(wasm32) && canImport(CoreGraphics) && canImport(CoreText)

extension FountainPDFWriter {
    /// Runs ``FNPaginator`` (default AppKit measurement) then renders **one PDF page per paginator page**.
    ///
    /// Use this when you need **(MORE)** / **(CONT’D)** and other screenplay pagination rules from ``FNPaginator``.
    /// For a simple mono wrap without paginator, use ``renderPDFData(_:)`` instead.
    public func renderPDFDataPaginated(script: FNScript) throws -> Data {
        let paginator = FNPaginator(script: script)
        var slabs: [[FNElement]] = []
        slabs.reserveCapacity(paginator.numberOfPages)
        for i in 0 ..< paginator.numberOfPages {
            slabs.append(paginator.pageAtIndex(i))
        }
        return try renderPDFData(pages: slabs, script: script)
    }
}

#endif
