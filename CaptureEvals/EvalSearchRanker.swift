import Foundation
@testable import Capture

enum EvalSearchMode: String, Sendable {
    case lexical
    case semantic
    case blend
}

enum EvalSearchRanker {
    static func rank(
        query: String,
        queryVector: [Double]?,
        documents: [SearchDocument],
        mode: EvalSearchMode
    ) -> [RankedSearchResult] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }
        let queryTokens = tokens(normalizedQuery)

        return documents.compactMap { document -> (RankedSearchResult, Date)? in
            let normalizedDocument = normalize(document.text)
            let lexical: Double
            if normalizedDocument == normalizedQuery {
                lexical = 1
            } else if normalizedDocument.contains(normalizedQuery) {
                lexical = 0.9
            } else {
                let overlap = queryTokens.intersection(tokens(normalizedDocument)).count
                lexical = queryTokens.isEmpty ? 0 : 0.7 * Double(overlap) / Double(queryTokens.count)
            }

            let semantic = queryVector
                .flatMap { query in document.embedding.flatMap { VectorMath.cosineSimilarity(query, $0) } }
                .map { max(0, $0) } ?? 0

            let score: Double
            switch mode {
            case .lexical:
                score = lexical
            case .semantic:
                score = semantic
            case .blend:
                score = lexical + semantic * 0.45
            }

            return score > 0 ? (RankedSearchResult(id: document.id, score: score), document.createdAt) : nil
        }
        .sorted {
            if abs($0.0.score - $1.0.score) > 0.000_001 { return $0.0.score > $1.0.score }
            if $0.1 != $1.1 { return $0.1 > $1.1 }
            return $0.0.id.uuidString < $1.0.id.uuidString
        }
        .map(\.0)
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokens(_ value: String) -> Set<String> {
        Set(value.components(separatedBy: .alphanumerics.inverted).filter { $0.count > 1 })
    }
}
