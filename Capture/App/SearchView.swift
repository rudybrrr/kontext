import SwiftData
import SwiftUI

struct SearchView: View {
    let container: ModelContainer

    @Query(sort: \CaptureItem.createdAt, order: .reverse) private var items: [CaptureItem]
    @State private var query = ""
    @State private var rankedIDs: [UUID] = []

    private var results: [CaptureItem] {
        let lookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        return rankedIDs.compactMap { lookup[$0] }
    }

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView(
                    "Search your captures",
                    systemImage: "text.magnifyingglass",
                    description: Text("Try a remembered phrase or describe what you are looking for.")
                )
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(results) { item in
                    NavigationLink {
                        ItemDetailView(item: item, container: container)
                    } label: {
                        CaptureRow(item: item)
                    }
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "What do you remember?")
        .task(id: query) { await search() }
    }

    private func search() async {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            rankedIDs = []
            return
        }
        let vector = await NaturalLanguageEmbeddingService().vector(for: value)
        let documents = items.map {
            SearchDocument(id: $0.id, text: $0.canonicalText, createdAt: $0.createdAt, embedding: $0.embeddingData.flatMap(VectorCodec.decode))
        }
        rankedIDs = SearchService.rank(query: value, queryVector: vector, documents: documents).map(\.id)
    }
}
