import SwiftData
import XCTest
@testable import Capture

@MainActor
final class PersistenceTests: XCTestCase {
    func testCreatesAndRetrievesTextCapture() throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let store = CaptureStore(container: container)

        let saved = try store.captureText("Look into Swift actors")
        let fetched = try container.mainContext.fetch(FetchDescriptor<CaptureItem>())

        XCTAssertEqual(saved.kind, .text)
        XCTAssertEqual(fetched.map(\.rawText), ["Look into Swift actors"])
        XCTAssertEqual(saved.enrichmentState, .pending)
    }

    func testCreatesURLAndImageMetadataCaptures() throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let store = CaptureStore(container: container)

        let url = try store.captureURL(URL(string: "https://example.com/article")!)
        let image = try store.captureImage(assetPath: "Media/image.jpg", thumbnailPath: "Media/thumb.jpg")

        XCTAssertEqual(url.sourceURL, "https://example.com/article")
        XCTAssertEqual(image.kind, .image)
        XCTAssertEqual(image.localAssetPath, "Media/image.jpg")
        XCTAssertEqual(image.thumbnailPath, "Media/thumb.jpg")
    }

    func testPersistsContextRelationshipAndManualCorrection() throws {
        let container = try CapturePersistence.makeContainer(inMemory: true)
        let store = CaptureStore(container: container)
        let item = try store.captureText("AVL tree rotations")
        let context = try store.createContext(name: "DSAA", summary: "Data structures")

        try store.reassign(item, to: context)

        XCTAssertEqual(item.context?.name, "DSAA")
        XCTAssertEqual(context.items.map(\.id), [item.id])
        XCTAssertEqual(item.contextConfidence, 1)
    }
}
