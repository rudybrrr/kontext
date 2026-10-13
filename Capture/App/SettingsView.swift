import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var embeddingsAvailable: Bool?

    var body: some View {
        Form {
            Section("On-device intelligence") {
                LabeledContent("Apple Intelligence", value: modelStatus)
                LabeledContent("Action extraction", value: actionExtractionStatus)
                LabeledContent("Semantic search", value: embeddingStatus)
            }

            Section("Privacy") {
                Text("Your captures, images, organization, and search index stay on this device. Capture has no account, analytics, backend, or external AI calls.")
            }

            Section("About") {
                LabeledContent("Version", value: version)
            }
        }
        .navigationTitle("Settings")
        .task {
            embeddingsAvailable = await NaturalLanguageEmbeddingService().isAvailable
        }
    }

    private var modelStatus: String {
        switch FoundationModelEnrichmentService.status {
        case .available: "Available"
        case .unavailable(let reason): reason
        }
    }

    private var actionExtractionStatus: String {
        switch FoundationModelActionExtractor.status {
        case .available: "Foundation Models available"
        case .unavailable(let reason): "Deterministic only (\(reason))"
        }
    }

    private var embeddingStatus: String {
        switch embeddingsAvailable {
        case true: "Available"
        case false: "Lexical fallback"
        case nil: "Checking…"
        }
    }

    private var version: String {
        let dictionary = Bundle.main.infoDictionary
        return dictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }
}
