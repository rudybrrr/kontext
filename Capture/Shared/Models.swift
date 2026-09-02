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
