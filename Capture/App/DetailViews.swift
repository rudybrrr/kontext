import SwiftData
import SwiftUI
import UIKit

struct ContextDetailView: View {
    @Bindable var context: CaptureContext
    let container: ModelContainer

    @State private var showingRename = false
    @State private var proposedName = ""
    @State private var errorMessage: String?

    private var items: [CaptureItem] {
        context.items.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            if let description = context.contextDescription, !description.isEmpty {
                Section {
                    Text(description)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Captures") {
                if items.isEmpty {
                    ContentUnavailableView("No captures", systemImage: "tray")
                } else {
                    ForEach(items) { item in
                        NavigationLink {
                            ItemDetailView(item: item, container: container)
                        } label: {
                            CaptureRow(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle(context.name)
        .toolbar {
            Button("Rename") {
                proposedName = context.name
                showingRename = true
            }
        }
        .alert("Rename Context", isPresented: $showingRename) {
            TextField("Context name", text: $proposedName)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                do {
                    try CaptureStore(container: container).rename(context, to: proposedName)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("Could Not Rename", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}

struct ItemDetailView: View {
    @Bindable var item: CaptureItem
    let container: ModelContainer

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaptureContext.name) private var contexts: [CaptureContext]
    @State private var newContextName = ""
    @State private var showingNewContext = false
    @State private var errorMessage: String?
    @State private var image: UIImage?
    @State private var coordinator = EnrichmentCoordinator()

    var body: some View {
        Form {
            originalContent

            Section("Understanding") {
                LabeledContent("Title", value: item.displayTitle)
                if let summary = item.summary, !summary.isEmpty {
                    Text(summary)
                        .textSelection(.enabled)
                }
                if item.enrichmentState == .pending || item.enrichmentState == .processing {
                    Label("Organizing on device", systemImage: "sparkles")
                        .foregroundStyle(.secondary)
                }
                if item.enrichmentState == .failed || item.enrichmentState == .partial {
                    Button("Retry enrichment", systemImage: "arrow.clockwise") { retry() }
                }
            }

            Section("Context") {
                Picker("Context", selection: contextSelection) {
                    Text("Unsorted").tag(UUID?.none)
                    ForEach(contexts) { context in
                        Text(context.name).tag(Optional(context.id))
                    }
                }
                Button("New Context", systemImage: "plus") {
                    showingNewContext = true
                }
            }

            SuggestedActionsSection(item: item)

            if !item.tags.isEmpty {
                Section("Topics") {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.quaternary, in: Capsule())
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }

            Section("Saved") {
                LabeledContent("Created") {
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("Privacy", value: "On this device")
            }
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: item.localAssetPath) { await loadImage() }
        .alert("New Context", isPresented: $showingNewContext) {
            TextField("Context name", text: $newContextName)
            Button("Cancel", role: .cancel) {}
            Button("Create") { createContext() }
        }
        .alert("Could Not Update Capture", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    @ViewBuilder
    private var originalContent: some View {
        Section("Original") {
            switch item.kind {
            case .text:
                Text(item.rawText ?? "")
                    .textSelection(.enabled)
            case .url:
                if let source = item.sourceURL, let url = URL(string: source) {
                    Link(destination: url) {
                        Label(source, systemImage: "safari")
                    }
                }
            case .image:
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Captured image")
                } else {
                    ProgressView("Loading image")
                }
                if let extractedText = item.extractedText, !extractedText.isEmpty {
                    Text(extractedText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var contextSelection: Binding<UUID?> {
        Binding(
            get: { item.context?.id },
            set: { id in
                item.context = id.flatMap { selected in contexts.first { $0.id == selected } }
                item.contextConfidence = id == nil ? nil : 1
                item.updatedAt = .now
                do { try modelContext.save() } catch { errorMessage = error.localizedDescription }
            }
        )
    }

    private func createContext() {
        do {
            let context = try CaptureStore(container: container).createContext(name: newContextName)
            try CaptureStore(container: container).reassign(item, to: context)
            newContextName = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func retry() {
        item.enrichmentState = .pending
        try? modelContext.save()
        Task { await coordinator.process(item, contexts: contexts, modelContext: modelContext) }
    }

    private func loadImage() async {
        guard let path = item.localAssetPath,
              let data = try? await MediaStore().data(at: path) else { return }
        image = UIImage(data: data)
    }
}
