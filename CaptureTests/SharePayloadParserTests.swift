import UniformTypeIdentifiers
import XCTest
@testable import Capture

final class SharePayloadParserTests: XCTestCase {
    func testPrefersURLOverCompanionText() {
        let url = URL(string: "https://example.com/article")!

        let payload = SharePayloadParser.preferredPayload(texts: ["Example title"], urls: [url], images: [])

        XCTAssertEqual(payload, .url(url))
    }

    func testNormalizesTextAndRejectsEmptyPayload() {
        XCTAssertEqual(SharePayloadParser.preferredPayload(texts: ["  selected text\n"], urls: [], images: []), .text("selected text"))
        XCTAssertNil(SharePayloadParser.preferredPayload(texts: [" \n"], urls: [], images: []))
    }

    func testAcceptsImageData() {
        let data = Data([1, 2, 3])
        XCTAssertEqual(SharePayloadParser.preferredPayload(texts: [], urls: [], images: [data]), .image(data))
    }

    func testParsesRealTextItemProvider() async {
        let provider = NSItemProvider(object: "Shared selection" as NSString)

        let payload = await SharePayloadParser.parse(providers: [provider])

        XCTAssertEqual(payload, .text("Shared selection"))
    }

    func testParsesRealURLItemProvider() async {
        let url = URL(string: "https://example.com/shared")!
        let provider = NSItemProvider(object: url as NSURL)

        let payload = await SharePayloadParser.parse(providers: [provider])

        XCTAssertEqual(payload, .url(url))
    }
}
