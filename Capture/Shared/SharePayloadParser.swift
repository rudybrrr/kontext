@preconcurrency import Foundation
import UniformTypeIdentifiers

enum SharePayload: Equatable, Sendable {
    case text(String)
    case url(URL)
    case image(Data)
}

enum SharePayloadParser {
    static func preferredPayload(texts: [String], urls: [URL], images: [Data]) -> SharePayload? {
        if let url = urls.first { return .url(url) }
        if let image = images.first, !image.isEmpty { return .image(image) }
        if let text = texts.lazy.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }).first(where: { !$0.isEmpty }) {
            return .text(text)
        }
        return nil
    }

    @MainActor
    static func parse(providers: [NSItemProvider]) async -> SharePayload? {
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = await loadURL(provider) { return .url(url) }
            if case let .url(url)? = await loadItem(provider, typeIdentifier: UTType.url.identifier) { return .url(url) }
        }

        for provider in providers {
            guard let type = provider.registeredTypeIdentifiers.first(where: { UTType($0)?.conforms(to: .image) == true }),
                  let data = await loadData(provider, typeIdentifier: type), !data.isEmpty else { continue }
            return .image(data)
        }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            if case let .text(text)? = await loadItem(provider, typeIdentifier: UTType.text.identifier) {
                return preferredPayload(texts: [text], urls: [], images: [])
            }
        }
        return nil
    }

    private enum LoadedItem: Sendable {
        case url(URL)
        case text(String)
    }

    private static func loadItem(_ provider: NSItemProvider, typeIdentifier: String) async -> LoadedItem? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: .url(url))
                } else if let url = item as? NSURL {
                    continuation.resume(returning: .url(url as URL))
                } else if let text = item as? String {
                    continuation.resume(returning: .text(text))
                } else if let text = item as? NSString {
                    continuation.resume(returning: .text(text as String))
                } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                    if typeIdentifier == UTType.url.identifier, let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        continuation.resume(returning: .url(url))
                    } else {
                        continuation.resume(returning: .text(text))
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private static func loadURL(_ provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: NSURL.self) { object, _ in
                continuation.resume(returning: (object as? NSURL).map { $0 as URL })
            }
        }
    }

    private static func loadData(_ provider: NSItemProvider, typeIdentifier: String) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
