import Foundation
import ImageIO
import UniformTypeIdentifiers

struct StoredMedia: Sendable {
    let assetPath: String
    let thumbnailPath: String?
}

enum MediaStoreError: Error {
    case appGroupUnavailable
    case invalidImage
    case thumbnailWriteFailed
}

actor MediaStore {
    nonisolated let explicitRootURL: URL?

    init(rootURL: URL? = nil) {
        explicitRootURL = rootURL
    }

    func saveImageData(_ data: Data) throws -> StoredMedia {
        guard let rootURL = resolvedRootURL else { throw MediaStoreError.appGroupUnavailable }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { throw MediaStoreError.invalidImage }
        let directory = rootURL.appending(path: "Media", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let id = UUID().uuidString.lowercased()
        let type = CGImageSourceGetType(source).flatMap { UTType($0 as String) }
        let extensionName = type?.preferredFilenameExtension ?? "img"
        let assetName = "\(id).\(extensionName)"
        try data.write(to: directory.appending(path: assetName), options: .atomic)

        let thumbnailName = "\(id)-thumb.jpg"
        let thumbnailURL = directory.appending(path: thumbnailName)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 480
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let destination = CGImageDestinationCreateWithURL(thumbnailURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            return StoredMedia(assetPath: "Media/\(assetName)", thumbnailPath: nil)
        }
        CGImageDestinationAddImage(destination, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.78] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw MediaStoreError.thumbnailWriteFailed }
        return StoredMedia(assetPath: "Media/\(assetName)", thumbnailPath: "Media/\(thumbnailName)")
    }

    func data(at relativePath: String) throws -> Data {
        guard let rootURL = resolvedRootURL else { throw MediaStoreError.appGroupUnavailable }
        return try Data(contentsOf: rootURL.appending(path: relativePath))
    }

    nonisolated func fileURL(for relativePath: String?) -> URL? {
        let rootURL = explicitRootURL ?? FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CapturePersistence.appGroupIdentifier)
        guard let rootURL, let relativePath else { return nil }
        return rootURL.appending(path: relativePath)
    }

    private var resolvedRootURL: URL? {
        explicitRootURL ?? FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CapturePersistence.appGroupIdentifier)
    }
}
