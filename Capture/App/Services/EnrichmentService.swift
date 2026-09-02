import Foundation

struct EnrichmentContext: Sendable {
    let id: UUID
    let name: String
    let summary: String?
}

struct EnrichmentResult: Sendable {
    let title: String
    let summary: String
    let tags: [String]
    let suggestedContextName: String?
    let suggestedContextSummary: String?
    let contextConfidence: Double
}

protocol EnrichmentProviding: Sendable {
    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult
}

struct FallbackEnrichmentService: EnrichmentProviding {
    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult {
        let compact = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let firstSentence = compact.split(whereSeparator: { ".!?\n".contains($0) }).first.map(String.init) ?? compact
        let title = firstSentence.split(separator: " ").prefix(10).joined(separator: " ")
        let summary = String(compact.prefix(220))
        let tags = Self.tags(from: compact)
        return EnrichmentResult(
            title: title.isEmpty ? "Untitled capture" : title,
            summary: summary,
            tags: tags,
            suggestedContextName: nil,
            suggestedContextSummary: nil,
            contextConfidence: 0
        )
    }

    private static func tags(from text: String) -> [String] {
        let stopWords: Set<String> = ["about", "after", "again", "also", "from", "have", "into", "that", "the", "their", "this", "with"]
        let words = text.lowercased().components(separatedBy: .alphanumerics.inverted).filter { $0.count > 3 && !stopWords.contains($0) }
        let counts = Dictionary(words.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.prefix(5).map(\.key)
    }
}

struct ResilientEnrichmentService: EnrichmentProviding {
    let primary: any EnrichmentProviding
    let fallback: any EnrichmentProviding

    init(
        primary: any EnrichmentProviding = FoundationModelEnrichmentService(),
        fallback: any EnrichmentProviding = FallbackEnrichmentService()
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    func enrich(text: String, contexts: [EnrichmentContext]) async throws -> EnrichmentResult {
        do {
            return try await primary.enrich(text: text, contexts: contexts)
        } catch {
            return try await fallback.enrich(text: text, contexts: contexts)
        }
    }
}
