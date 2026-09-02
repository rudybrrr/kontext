import XCTest
@testable import Capture

final class ContextAssignmentTests: XCTestCase {
    private let browserID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!

    func testReusesSufficientlySimilarContext() {
        let candidates = [ContextCandidate(id: browserID, name: "mybrowser", description: "Browser UI work", embedding: [0.98, 0.02])]

        let assignment = ContextAssignmentService().assignment(
            itemText: "Arc vertical tabs",
            itemEmbedding: [1, 0],
            candidates: candidates
        )

        XCTAssertEqual(assignment.contextID, browserID)
        XCTAssertGreaterThanOrEqual(assignment.confidence, 0.78)
    }

    func testFallsBackToInboxInsteadOfCreatingWeakContext() {
        let candidates = [ContextCandidate(id: browserID, name: "mybrowser", description: nil, embedding: [0, 1])]

        let assignment = ContextAssignmentService().assignment(
            itemText: "AVL rotations",
            itemEmbedding: [1, 0],
            candidates: candidates
        )

        XCTAssertNil(assignment.contextID)
        XCTAssertEqual(assignment.confidence, 0)
    }

    func testProposedContextReusesSemanticDuplicateAndAllowsDistinctProposal() {
        let candidates = [ContextCandidate(id: browserID, name: "browser UI", description: nil, embedding: [1, 0])]
        let service = ContextAssignmentService()

        XCTAssertEqual(service.existingContext(forProposedName: "sidebar research", embedding: [0.99, 0.01], candidates: candidates), browserID)
        XCTAssertNil(service.existingContext(forProposedName: "DSAA", embedding: [0, 1], candidates: candidates))
    }
}
