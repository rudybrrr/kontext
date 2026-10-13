import Foundation

enum WebpageTextFetchError: Error {
    case invalidResponse
    case emptyContent
}

struct WebpageTextFetcher: Sendable {
    static let maxBytes = 512_000
    static let timeout: TimeInterval = 12

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchText(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.timeoutInterval = Self.timeout
        request.setValue("text/html,application/xhtml+xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw WebpageTextFetchError.invalidResponse
        }
        let limited = Data(data.prefix(Self.maxBytes))
        guard let html = String(data: limited, encoding: .utf8)
            ?? String(data: limited, encoding: .isoLatin1) else {
            throw WebpageTextFetchError.invalidResponse
        }
        let text = HTMLTextExtractor.extractBodyText(from: html)
        guard !text.isEmpty else { throw WebpageTextFetchError.emptyContent }
        return text
    }
}
