import NaturalLanguage

protocol EmbeddingProviding: Sendable {
    func vector(for text: String) async -> [Double]?
}

actor NaturalLanguageEmbeddingService: EmbeddingProviding {
    func vector(for text: String) -> [Double]? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        let language = NLLanguageRecognizer.dominantLanguage(for: value) ?? .english
        let embedding = NLEmbedding.sentenceEmbedding(for: language) ?? NLEmbedding.sentenceEmbedding(for: .english)
        return embedding?.vector(for: value)
    }

    var isAvailable: Bool {
        NLEmbedding.sentenceEmbedding(for: .english) != nil
    }
}
