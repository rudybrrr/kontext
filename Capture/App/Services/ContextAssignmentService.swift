import Foundation

struct ContextCandidate: Sendable {
    let id: UUID
    let name: String
    let description: String?
    let embedding: [Double]?
}

struct ContextAssignment: Equatable, Sendable {
    let contextID: UUID?
    let confidence: Double
}

struct ContextAssignmentService: Sendable {
    let reuseThreshold: Double

    init(reuseThreshold: Double = 0.78) {
        self.reuseThreshold = reuseThreshold
    }

    func assignment(itemText: String, itemEmbedding: [Double]?, candidates: [ContextCandidate]) -> ContextAssignment {
        let normalizedText = Self.normalize(itemText)
        if let lexical = candidates.first(where: { normalizedText.contains(Self.normalize($0.name)) }) {
            return ContextAssignment(contextID: lexical.id, confidence: 1)
        }

        guard let itemEmbedding,
              let best = bestSemanticMatch(embedding: itemEmbedding, candidates: candidates),
              best.similarity >= reuseThreshold else {
            return ContextAssignment(contextID: nil, confidence: 0)
        }
        return ContextAssignment(contextID: best.candidate.id, confidence: best.similarity)
    }

    func existingContext(forProposedName name: String, embedding: [Double]?, candidates: [ContextCandidate]) -> UUID? {
        let normalizedName = Self.normalize(name)
        if let lexical = candidates.first(where: { Self.normalize($0.name) == normalizedName }) {
            return lexical.id
        }
        guard let embedding,
              let best = bestSemanticMatch(embedding: embedding, candidates: candidates),
              best.similarity >= reuseThreshold else { return nil }
        return best.candidate.id
    }

    private func bestSemanticMatch(embedding: [Double], candidates: [ContextCandidate]) -> (candidate: ContextCandidate, similarity: Double)? {
        candidates.compactMap { candidate in
            candidate.embedding
                .flatMap { VectorMath.cosineSimilarity(embedding, $0) }
                .map { (candidate, $0) }
        }.max {
            if abs($0.1 - $1.1) > 0.000_001 { return $0.1 < $1.1 }
            return $0.0.id.uuidString > $1.0.id.uuidString
        }
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
