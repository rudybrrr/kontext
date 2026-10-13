import Foundation

struct EvalDataset: Codable, Sendable {
    let version: Int
    let timezone: String
    let captures: [EvalCaptureFixture]
}

struct EvalCaptureFixture: Codable, Sendable, Identifiable {
    let id: String
    let kind: String
    let referenceDateISO: String
    let text: String
    let negative: Bool
    let expectedActions: [EvalExpectedAction]
    let sourceURL: String?
    let mockPageText: String?
    let imagePath: String?
}

struct EvalExpectedAction: Codable, Sendable {
    let kind: String
    let titleKeywords: [String]
    let startISO: String?
    let endISO: String?
    let dueISO: String?
    let isAllDay: Bool
    let location: String?
}

struct EvalSearchQueryFile: Codable, Sendable {
    let version: Int
    let queries: [EvalSearchQuery]
}

struct EvalSearchQuery: Codable, Sendable, Identifiable {
    let id: String
    let query: String
    let relevantCaptureIds: [String]
}
