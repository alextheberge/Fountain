import Foundation

/// Fixture URLs for **FountainTests** (SwiftPM `Bundle.module` + **Resources/**).
enum FountainTestResources {
    static func url(forFixture name: String, extension ext: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: ext)
    }

    static func path(forFixture name: String, extension ext: String) -> String? {
        url(forFixture: name, extension: ext)?.path
    }
}
