import Foundation

enum HTMLTextExtractor {
    static let maxCharacterCount = 50_000

    static func extractBodyText(from html: String) -> String {
        let withoutScripts = html.replacingOccurrences(
            of: "(?is)<script[^>]*>.*?</script>",
            with: " ",
            options: .regularExpression
        )
        let withoutStyles = withoutScripts.replacingOccurrences(
            of: "(?is)<style[^>]*>.*?</style>",
            with: " ",
            options: .regularExpression
        )
        let body = extractBody(from: withoutStyles) ?? withoutStyles
        let withoutTags = body.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        let decoded = decodeBasicEntities(withoutTags)
        let collapsed = decoded
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if collapsed.count <= maxCharacterCount { return collapsed }
        return String(collapsed.prefix(maxCharacterCount))
    }

    private static func extractBody(from html: String) -> String? {
        guard let range = html.range(of: "(?is)<body[^>]*>(.*?)</body>", options: .regularExpression) else { return nil }
        let match = String(html[range])
        return match.replacingOccurrences(
            of: "(?is)^<body[^>]*>|</body>$",
            with: "",
            options: .regularExpression
        )
    }

    private static func decodeBasicEntities(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}
