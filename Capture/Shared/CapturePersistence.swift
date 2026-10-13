import Foundation
import SwiftData

enum CapturePersistence {
    static let appGroupIdentifier = "group.com.rudy.capture"

    @MainActor
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([CaptureItem.self, CaptureContext.self, ProposedAction.self])
        let configuration: ModelConfiguration

        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(
                "Capture",
                schema: schema,
                allowsSave: true,
                groupContainer: .identifier(appGroupIdentifier),
                cloudKitDatabase: .none
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

enum CaptureStoreError: LocalizedError {
    case emptyContent
    case unsupportedURL

    var errorDescription: String? {
        switch self {
        case .emptyContent: "Add text, a link, or an image before saving."
        case .unsupportedURL: "Enter a valid HTTP or HTTPS URL."
        }
    }
}

@MainActor
final class CaptureStore {
    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    @discardableResult
    func captureText(_ text: String) throws -> CaptureItem {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw CaptureStoreError.emptyContent }
        return try insert(CaptureItem(kind: .text, rawText: value))
    }

    @discardableResult
    func captureURL(_ url: URL, remindMeIntent: Bool = false) throws -> CaptureItem {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme), url.host != nil else {
            throw CaptureStoreError.unsupportedURL
        }
        let item = CaptureItem(kind: .url, sourceURL: url.absoluteString)
        item.remindMeIntent = remindMeIntent
        return try insert(item)
    }

    @discardableResult
    func captureImage(assetPath: String, thumbnailPath: String? = nil) throws -> CaptureItem {
        try insert(CaptureItem(kind: .image, localAssetPath: assetPath, thumbnailPath: thumbnailPath))
    }

    @discardableResult
    func createContext(name: String, summary: String? = nil) throws -> CaptureContext {
        let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw CaptureStoreError.emptyContent }
        let captureContext = CaptureContext(name: value, summary: summary)
        context.insert(captureContext)
        try context.save()
        return captureContext
    }

    func inbox() throws -> CaptureContext {
        let name = "Inbox"
        var descriptor = FetchDescriptor<CaptureContext>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first ?? createContext(name: name, summary: "Captures awaiting a confident context.")
    }

    func reassign(_ item: CaptureItem, to captureContext: CaptureContext, confidence: Double = 1) throws {
        item.context = captureContext
        item.contextConfidence = confidence
        item.updatedAt = .now
        try context.save()
    }

    func rename(_ captureContext: CaptureContext, to name: String) throws {
        let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw CaptureStoreError.emptyContent }
        captureContext.name = value
        captureContext.updatedAt = .now
        try context.save()
    }

    private func insert(_ item: CaptureItem) throws -> CaptureItem {
        context.insert(item)
        try context.save()
        return item
    }
}
