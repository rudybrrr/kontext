import XCTest
@testable import Capture

final class SearchTests: XCTestCase {
    func testVectorRoundTripAndMalformedData() throws {
        let values = [1.25, -2.5, 0]
        let decoded = try XCTUnwrap(VectorCodec.decode(VectorCodec.encode(values)))

        XCTAssertEqual(decoded.count, 3)
        XCTAssertEqual(decoded[0], 1.25, accuracy: 0.0001)
        XCTAssertEqual(decoded[1], -2.5, accuracy: 0.0001)
        XCTAssertNil(VectorCodec.decode(Data([0x01])))
    }

    func testCosineSimilarityHandlesValidMissingAndZeroVectors() throws {
        XCTAssertEqual(try XCTUnwrap(VectorMath.cosineSimilarity([1, 0], [1, 0])), 1, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(VectorMath.cosineSimilarity([1, 0], [0, 1])), 0, accuracy: 0.0001)
        XCTAssertNil(VectorMath.cosineSimilarity([1], [1, 0]))
        XCTAssertNil(VectorMath.cosineSimilarity([0, 0], [1, 0]))
    }

    func testExactLexicalMatchOutranksSemanticOnlyMatch() {
        let lexicalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let semanticID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let documents = [
            SearchDocument(id: semanticID, text: "balanced binary data structure", createdAt: .distantPast, embedding: [1, 0]),
            SearchDocument(id: lexicalID, text: "AVL trees", createdAt: .distantFuture, embedding: [0, 1])
        ]

        let results = SearchService.rank(query: "AVL trees", queryVector: [1, 0], documents: documents)

        XCTAssertEqual(results.map(\.id), [lexicalID, semanticID])
    }

    func testSemanticRankingAndMissingEmbeddingFallback() {
        let closeID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let farID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let lexicalID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let documents = [
            SearchDocument(id: farID, text: "gardening", createdAt: .now, embedding: [0, 1]),
            SearchDocument(id: lexicalID, text: "browser UI inspiration", createdAt: .now, embedding: nil),
            SearchDocument(id: closeID, text: "sidebar references", createdAt: .now, embedding: [0.9, 0.1])
        ]

        XCTAssertEqual(SearchService.rank(query: "dark sidebar", queryVector: [1, 0], documents: documents).first?.id, closeID)
        XCTAssertEqual(SearchService.rank(query: "browser", queryVector: nil, documents: documents).map(\.id), [lexicalID])
    }

    func testEmptyQueryAndDeterministicTies() {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let date = Date(timeIntervalSince1970: 100)
        let documents = [
            SearchDocument(id: secondID, text: "same", createdAt: date, embedding: nil),
            SearchDocument(id: firstID, text: "same", createdAt: date, embedding: nil)
        ]

        XCTAssertTrue(SearchService.rank(query: "  ", queryVector: nil, documents: documents).isEmpty)
        XCTAssertEqual(SearchService.rank(query: "same", queryVector: nil, documents: documents).map(\.id), [firstID, secondID])
    }
}
