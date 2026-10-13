import Foundation
import SwiftData

enum CaptureKind: String, Codable, CaseIterable, Sendable {
    case text
    case url
    case image
}

enum EnrichmentState: String, Codable, Sendable {
    case pending
    case processing
    case completed
    case partial
    case failed
}

enum ProposedActionKind: String, Codable, CaseIterable, Sendable {
    case event
    case reminder
    case followUp
}

enum ProposedActionStatus: String, Codable, Sendable {
    case proposed
    case approved
    case dismissed
    case failed
}

@Model
final class CaptureItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var kind: CaptureKind
    var rawText: String?
    var sourceURL: String?
    var localAssetPath: String?
    var thumbnailPath: String?
    var title: String?
    var extractedText: String?
    var summary: String?
    var tags: [String]
    var enrichmentState: EnrichmentState
    var embeddingData: Data?
    var contextConfidence: Double?
    var context: CaptureContext?
    @Relationship(deleteRule: .cascade, inverse: \ProposedAction.captureItem) var proposedActions: [ProposedAction]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: CaptureKind,
        rawText: String? = nil,
        sourceURL: String? = nil,
        localAssetPath: String? = nil,
        thumbnailPath: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        updatedAt = createdAt
        self.kind = kind
        self.rawText = rawText
        self.sourceURL = sourceURL
        self.localAssetPath = localAssetPath
        self.thumbnailPath = thumbnailPath
        tags = []
        enrichmentState = .pending
        proposedActions = []
    }

    var canonicalText: String {
        [title, summary, rawText, extractedText, sourceURL, context?.name, tags.joined(separator: " ")]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

@Model
final class CaptureContext {
    @Attribute(.unique) var id: UUID
    var name: String
    var contextDescription: String?
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    @Relationship(deleteRule: .nullify, inverse: \CaptureItem.context) var items: [CaptureItem]

    init(
        id: UUID = UUID(),
        name: String,
        summary: String? = nil,
        createdAt: Date = .now,
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        contextDescription = summary
        self.createdAt = createdAt
        updatedAt = createdAt
        self.isPinned = isPinned
        items = []
    }
}

@Model
final class ProposedAction {
    @Attribute(.unique) var id: UUID
    var kind: ProposedActionKind
    var title: String
    var start: Date?
    var end: Date?
    var isAllDay: Bool
    var due: Date?
    var location: String?
    var people: [String]
    var url: String?
    var sourceSpan: String?
    var confidence: Double
    var status: ProposedActionStatus
    var ekIdentifier: String?
    var captureItem: CaptureItem?

    init(
        id: UUID = UUID(),
        kind: ProposedActionKind,
        title: String,
        start: Date? = nil,
        end: Date? = nil,
        isAllDay: Bool = false,
        due: Date? = nil,
        location: String? = nil,
        people: [String] = [],
        url: String? = nil,
        sourceSpan: String? = nil,
        confidence: Double,
        status: ProposedActionStatus = .proposed,
        ekIdentifier: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.due = due
        self.location = location
        self.people = people
        self.url = url
        self.sourceSpan = sourceSpan
        self.confidence = confidence
        self.status = status
        self.ekIdentifier = ekIdentifier
    }
}
