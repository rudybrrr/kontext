import Foundation

enum EvalFixtureLoader {
    static func loadDataset(bundle: Bundle) throws -> EvalDataset {
        let url = try resourceURL(named: "captures.json", bundle: bundle)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(EvalDataset.self, from: data)
    }

    static func loadSearchQueries(bundle: Bundle) throws -> EvalSearchQueryFile {
        let url = try resourceURL(named: "search_queries.json", bundle: bundle)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(EvalSearchQueryFile.self, from: data)
    }

    private static func resourceURL(named name: String, bundle: Bundle) throws -> URL {
        if let url = bundle.url(forResource: name, withExtension: nil) {
            return url
        }
        let fallback = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Evals")
            .appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: fallback.path) {
            return fallback
        }
        throw EvalFixtureError.missingResource(name)
    }
}

enum EvalFixtureError: Error {
    case missingResource(String)
}

enum EvalFixtureText {
    static func extractionText(for capture: EvalCaptureFixture) -> String {
        switch capture.kind {
        case "url":
            var parts: [String] = []
            if let sourceURL = capture.sourceURL { parts.append(sourceURL) }
            if !capture.text.isEmpty { parts.append(capture.text) }
            if let mock = capture.mockPageText, !mock.isEmpty { parts.append(mock) }
            return parts.joined(separator: "\n")
        case "screenshot", "text":
            return capture.text
        default:
            return capture.text
        }
    }

    static func searchText(for capture: EvalCaptureFixture) -> String {
        [capture.text, capture.mockPageText, capture.sourceURL]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

enum EvalDateParsing {
    static let singapore = TimeZone(identifier: "Asia/Singapore")!

    static func date(from iso: String?) -> Date? {
        guard let iso, !iso.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = formatter.date(from: iso) { return value }
        formatter.formatOptions = [.withInternetDateTime]
        if let value = formatter.date(from: iso) { return value }
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = singapore
        return formatter.date(from: iso)
    }

    static func referenceDate(for capture: EvalCaptureFixture) -> Date {
        date(from: capture.referenceDateISO) ?? .now
    }
}
