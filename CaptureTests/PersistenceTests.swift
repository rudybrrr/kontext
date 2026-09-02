import SwiftData
import UIKit
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

    func testStoresImageAndThumbnailAsFiles() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let data = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).pngData { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }

        let media = try await MediaStore(rootURL: root).saveImageData(data)

        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appending(path: media.assetPath).path()))
        XCTAssertNotNil(media.thumbnailPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appending(path: media.thumbnailPath!).path()))
    }
}
