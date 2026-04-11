# Fast vs tokenPipeline — parity coverage (Phase 12.1)

Living checklist of corpora and suites where **`.fast`** and **`.tokenPipeline`** are asserted equivalent (or intentionally exempt). Expand this file as you add rows to the roadmap matrix.

| Corpus / fixture | Suite | Notes |
|------------------|-------|--------|
| Bundled `Tests/FountainPackageTests/Fixtures/*.fountain` | `TokenPipelineFNScriptTests.testTokenPipelineParityAllBundledFountainFixtures` | Package fixtures |
| **Big Fish** | `testTokenPipelineBigFishFileMatchesFast` | Requires `FountainTests/Big Fish.fountain` |
| **Brick & Steel** | `testTokenPipelineBrickAndSteelFileMatchesFast` | Requires `FountainTests/Brick And Steel.txt` |
| Minimal slug / dialogue / title-page rows | `Phase3TokenizationTests`, `Phase4ParityTests`, `Phase45RoundTripTests` | Structural + round-trip |
| Boneyard sandwich, dual dialogue | `Phase4ParityTests`, `TokenPipelineFNScriptTests` | Dedicated fixtures |
| **Whitespace-only body line (Phase 4.6)** | `Phase46WhitespaceActionTests` | No standalone `Action` for `^\\s+$` outside dialogue |
| **``FNPaginator`` + ``CourierPitchMonospaceTextMeasurer``** | `FountainTextMeasuringTests.testPaginatorUsesCourierPitchMeasurerWithoutCrash` | Phase 8.5 closure injection smoke |

**Not yet exhaustive:** maintainer-signed matrix vs Phase 7.3 external cases remains open on the roadmap until every adopted external file is listed here.
