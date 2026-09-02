import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    let container: ModelContainer

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaptureItem.createdAt, order: .reverse) private var items: [CaptureItem]
    @Query(sort: \CaptureContext.updatedAt, order: .reverse) private var contexts: [CaptureContext]
    @State private var showingCapture = false
    @State private var coordinator = EnrichmentCoordinator()

    private var pendingIDs: [UUID] {
        items.filter { $0.enrichmentState == .pending }.map(\.id)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Button {
                    showingCapture = true
                } label: {
                    Label("Capture something", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .accessibilityIdentifier("quick-capture")

                List {
                    if !contexts.isEmpty {
                        Section("Contexts") {
                            ForEach(contexts.prefix(4)) { context in
                                NavigationLink {
                                    ContextDetailView(context: context, container: container)
                                } label: {
                                    HStack {
                                        Image(systemName: context.isPinned ? "pin.fill" : "square.stack.3d.up")
                                            .foregroundStyle(.tint)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(context.name)
                                            if let description = context.contextDescription, !description.isEmpty {
                                                Text(description)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        Text(context.items.count, format: .number)
                                            .foregroundStyle(.secondary)
                                            .accessibilityLabel("\(context.items.count) captures")
                                    }
                                }
                            }
                        }
                    }

                    Section("Recent captures") {
                        if items.isEmpty {
                            ContentUnavailableView(
                                "Nothing captured yet",
                                systemImage: "tray",
                                description: Text("Save a thought, link, or screenshot. Capture will organize it after it is safely stored.")
                            )
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
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Capture")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        SearchView(container: container)
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingCapture) {
                CaptureSheet(container: container)
            }
            .task(id: pendingIDs) {
                guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return }
                for item in items where item.enrichmentState == .pending {
                    guard !Task.isCancelled else { return }
                    await coordinator.process(item, contexts: contexts, modelContext: modelContext)
                }
            }
        }
    }
}

struct CaptureRow: View {
    let item: CaptureItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CaptureThumbnail(item: item)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                if let summary = item.summary, summary != item.displayTitle {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 5) {
                    Text(item.context?.name ?? "Unsorted")
                    Text("·")
                    Text(item.createdAt, style: .relative)
                    if item.enrichmentState == .pending || item.enrichmentState == .processing {
                        ProgressView()
                            .controlSize(.mini)
                            .accessibilityLabel("Organizing capture")
                    } else if item.enrichmentState == .failed {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Enrichment failed")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct CaptureThumbnail: View {
    let item: CaptureItem
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: item.kind.symbolName)
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
        }
        .frame(width: 44, height: 44)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .accessibilityHidden(true)
        .task(id: item.thumbnailPath) {
            guard let path = item.thumbnailPath,
                  let data = try? await MediaStore().data(at: path) else { return }
            image = UIImage(data: data)
        }
    }
}

extension CaptureItem {
    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        if let rawText, !rawText.isEmpty { return rawText }
        if let sourceURL, let host = URL(string: sourceURL)?.host() { return host }
        return kind == .image ? "Image capture" : "Untitled capture"
    }
}

private extension CaptureKind {
    var symbolName: String {
        switch self {
        case .text: "text.alignleft"
        case .url: "link"
        case .image: "photo"
        }
    }
}
