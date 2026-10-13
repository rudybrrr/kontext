import Foundation
import SwiftData

@MainActor
final class EnrichmentCoordinator {
    private let enricher: any EnrichmentProviding
    private let embedder: any EmbeddingProviding
    private let mediaStore: MediaStore
    private let ocr: OCRService
    private let linkMetadata: LinkMetadataService
    private let webpageTextFetcher: WebpageTextFetcher
    private let assignment = ContextAssignmentService()
    private let actionExtractor: any ActionExtracting

    init(
        enricher: any EnrichmentProviding = ResilientEnrichmentService(),
        embedder: any EmbeddingProviding = NaturalLanguageEmbeddingService(),
        mediaStore: MediaStore = MediaStore(),
        ocr: OCRService = OCRService(),
        linkMetadata: LinkMetadataService = LinkMetadataService(),
        webpageTextFetcher: WebpageTextFetcher = WebpageTextFetcher(),
        actionExtractor: any ActionExtracting = ResilientActionExtractionService()
    ) {
        self.enricher = enricher
        self.embedder = embedder
        self.mediaStore = mediaStore
        self.ocr = ocr
        self.linkMetadata = linkMetadata
        self.webpageTextFetcher = webpageTextFetcher
        self.actionExtractor = actionExtractor
    }

    func process(_ item: CaptureItem, contexts _: [CaptureContext], modelContext: ModelContext) async {
        guard item.enrichmentState == .pending || item.enrichmentState == .failed else { return }
        item.enrichmentState = .processing
        try? modelContext.save()

        do {
            var extractionWasPartial = false
            var text: String
            switch item.kind {
            case .text:
                text = item.rawText ?? ""
            case .url:
                text = item.sourceURL ?? ""
                if let source = item.sourceURL, let url = URL(string: source) {
                    if let metadata = await linkMetadata.metadata(for: url) {
                        if item.title == nil { item.title = metadata.title }
                        text += metadata.title.map { "\n\($0)" } ?? ""
                    }
                    do {
                        let pageText = try await webpageTextFetcher.fetchText(from: url)
                        item.extractedText = pageText
                        text += "\n\(pageText)"
                    } catch {
                        extractionWasPartial = true
                    }
                }
            case .image:
                text = "Image capture"
                if let path = item.localAssetPath {
                    do {
                        let data = try await mediaStore.data(at: path)
                        let extracted = try await ocr.text(in: data)
                        if !extracted.isEmpty {
                            item.extractedText = extracted
                            text = extracted
                        } else {
                            extractionWasPartial = true
                        }
                    } catch {
                        extractionWasPartial = true
                    }
                }
            }

            let contexts = try modelContext.fetch(FetchDescriptor<CaptureContext>())
            let contextValues = contexts.map { EnrichmentContext(id: $0.id, name: $0.name, summary: $0.contextDescription) }
            let result = try await enricher.enrich(text: text, contexts: contextValues)
            item.title = result.title
            item.summary = result.summary
            item.tags = result.tags

            let vector = await embedder.vector(for: [result.title, result.summary, text, result.tags.joined(separator: " ")].joined(separator: "\n"))
            item.embeddingData = vector.map(VectorCodec.encode)
            if await extractActions(for: item, text: text, modelContext: modelContext) {
                extractionWasPartial = true
            }
            try await assign(item, result: result, vector: vector, contexts: contexts, modelContext: modelContext)
            item.enrichmentState = extractionWasPartial ? .partial : .completed
            item.updatedAt = .now
            try modelContext.save()
        } catch {
            item.enrichmentState = .failed
            item.updatedAt = .now
            try? modelContext.save()
        }
    }

    private func extractActions(for item: CaptureItem, text: String, modelContext: ModelContext) async -> Bool {
        do {
            var candidates = try await actionExtractor.extractActions(from: text, referenceDate: item.createdAt)
            URLFollowUpProposalService.appendReadFollowUpIfNeeded(to: &candidates, item: item)
            for existing in item.proposedActions {
                modelContext.delete(existing)
            }
            item.proposedActions.removeAll()
            for candidate in candidates {
                let action = candidate.asProposedAction()
                action.captureItem = item
                modelContext.insert(action)
            }
            return false
        } catch {
            return true
        }
    }

    private func assign(
        _ item: CaptureItem,
        result: EnrichmentResult,
        vector: [Double]?,
        contexts: [CaptureContext],
        modelContext: ModelContext
    ) async throws {
        if let name = result.suggestedContextName,
           let exact = contexts.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            item.context = exact
            item.contextConfidence = result.contextConfidence
            return
        }

        var candidates: [ContextCandidate] = []
        for context in contexts where context.name != "Inbox" {
            let contextVector = await embedder.vector(for: [context.name, context.contextDescription].compactMap { $0 }.joined(separator: "\n"))
            candidates.append(ContextCandidate(id: context.id, name: context.name, description: context.contextDescription, embedding: contextVector))
        }

        if let name = result.suggestedContextName, result.contextConfidence >= 0.85 {
            let proposedVector = await embedder.vector(for: [name, result.suggestedContextSummary].compactMap { $0 }.joined(separator: "\n"))
            if let existingID = assignment.existingContext(forProposedName: name, embedding: proposedVector, candidates: candidates),
               let existing = contexts.first(where: { $0.id == existingID }) {
                item.context = existing
            } else {
                let created = CaptureContext(name: name, summary: result.suggestedContextSummary)
                modelContext.insert(created)
                item.context = created
            }
            item.contextConfidence = result.contextConfidence
            return
        }

        let fallback = assignment.assignment(itemText: item.canonicalText, itemEmbedding: vector, candidates: candidates)
        if let id = fallback.contextID, let context = contexts.first(where: { $0.id == id }) {
            item.context = context
            item.contextConfidence = fallback.confidence
        } else {
            item.context = try inbox(in: contexts, modelContext: modelContext)
            item.contextConfidence = 0
        }
    }

    private func inbox(in contexts: [CaptureContext], modelContext: ModelContext) throws -> CaptureContext {
        if let existing = contexts.first(where: { $0.name == "Inbox" }) { return existing }
        let created = CaptureContext(name: "Inbox", summary: "Captures awaiting a confident context.")
        modelContext.insert(created)
        return created
    }
}
