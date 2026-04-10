import XCTest
import Fountain

final class FNScriptAsyncTests: XCTestCase {
    func testParseStringAsyncMatchesSyncParse() async {
        let source = "\nINT. ASYNC - DAY\n\nHello.\n"
        let asyncScript = await FNScript.parseStringAsync(source)
        let syncScript = FNScript(string: source)
        XCTAssertEqual(asyncScript.elements.count, syncScript.elements.count)
        XCTAssertEqual(asyncScript.elements.map(\.elementType), syncScript.elements.map(\.elementType))
    }
}
