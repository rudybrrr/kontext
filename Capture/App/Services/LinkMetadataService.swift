import Foundation
import LinkPresentation

struct LinkMetadata: Sendable {
    let title: String?
}

actor LinkMetadataService {
    func metadata(for url: URL) async -> LinkMetadata? {
        do {
            let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
            return LinkMetadata(title: metadata.title)
        } catch {
            return nil
        }
    }
}
