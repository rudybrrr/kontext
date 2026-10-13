import Foundation

struct DeterministicActionExtractor: ActionExtracting {
    private static let reminderKeywords = ["remind", "reminder", "don't forget", "do not forget"]

    func extractActions(from text: String, referenceDate: Date) async throws -> [ActionCandidate] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var candidates: [ActionCandidate] = []
        let dateMatches = Self.dateMatches(in: trimmed, referenceDate: referenceDate)
        let linkMatches = Self.linkMatches(in: trimmed)
        let addressMatches = Self.addressMatches(in: trimmed)

        for match in dateMatches {
            let span = Self.span(for: match, in: trimmed)
            let title = Self.title(near: match.range, in: trimmed) ?? Self.defaultTitle(for: match, in: trimmed)
            let reminder = Self.looksLikeReminder(near: match.range, in: trimmed)
            let kind: ProposedActionKind = reminder ? .reminder : .event
            let start = match.date
            let end = match.duration.map { start.addingTimeInterval($0) }
            let location = Self.nearestAddress(to: match.range, addresses: addressMatches, in: trimmed)

            if kind == .reminder {
                candidates.append(
                    ActionCandidate(
                        kind: .reminder,
                        title: title,
                        start: nil,
                        end: nil,
                        isAllDay: Self.isAllDay(match),
                        due: start,
                        location: location,
                        people: [],
                        url: nil,
                        sourceSpan: span,
                        confidence: 0.9
                    )
                )
            } else {
                candidates.append(
                    ActionCandidate(
                        kind: .event,
                        title: title,
                        start: start,
                        end: end,
                        isAllDay: Self.isAllDay(match),
                        due: nil,
                        location: location,
                        people: [],
                        url: nil,
                        sourceSpan: span,
                        confidence: 0.9
                    )
                )
            }
        }

        for match in linkMatches {
            guard let url = match.url?.absoluteString else { continue }
            let span = Self.span(for: match, in: trimmed)
            let title = match.url?.host ?? url
            candidates.append(
                ActionCandidate(
                    kind: .followUp,
                    title: "Follow up: \(title)",
                    start: nil,
                    end: nil,
                    isAllDay: false,
                    due: nil,
                    location: nil,
                    people: [],
                    url: url,
                    sourceSpan: span,
                    confidence: 0.85
                )
            )
        }

        return candidates
    }

    private struct DateMatch {
        let date: Date
        let duration: TimeInterval?
        let range: Range<String.Index>
    }

    private static func dateMatches(in text: String, referenceDate: Date) -> [DateMatch] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return [] }
        let nsRange = NSRange(text.startIndex..., in: text)
        let checking = detector.matches(in: text, options: [.referenceDate: referenceDate], range: nsRange)
        return checking.compactMap { result in
            guard let date = result.date, let range = Range(result.range, in: text) else { return nil }
            let duration = result.duration > 0 ? result.duration : nil
            return DateMatch(date: date, duration: duration, range: range)
        }
    }

    private static func linkMatches(in text: String) -> [NSTextCheckingResult] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        return detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
    }

    private static func addressMatches(in text: String) -> [NSTextCheckingResult] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.address.rawValue) else { return [] }
        return detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
    }

    private static func span(for result: NSTextCheckingResult, in text: String) -> String? {
        guard let range = Range(result.range, in: text) else { return nil }
        return String(text[range])
    }

    private static func defaultTitle(for match: DateMatch, in text: String) -> String {
        let lowered = text.lowercased()
        if lowered.contains("meeting") { return "Meeting" }
        if lowered.contains("call") { return "Call" }
        if lowered.contains("lunch") || lowered.contains("dinner") { return "Meal" }
        return "Scheduled item"
    }

    private static func title(near range: Range<String.Index>, in text: String) -> String? {
        let windowStart = text.index(range.lowerBound, offsetBy: -80, limitedBy: text.startIndex) ?? text.startIndex
        let windowEnd = text.index(range.upperBound, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
        let window = String(text[windowStart..<windowEnd])
        let clause = window
            .split(whereSeparator: { ".!?\n".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        guard let clause, !clause.isEmpty else { return nil }
        let words = clause.split(whereSeparator: \.isWhitespace).map(String.init)
        guard words.count >= 2 else { return nil }
        return words.suffix(6).joined(separator: " ")
    }

    private static func looksLikeReminder(near range: Range<String.Index>, in text: String) -> Bool {
        let windowStart = text.index(range.lowerBound, offsetBy: -40, limitedBy: text.startIndex) ?? text.startIndex
        let windowEnd = text.index(range.upperBound, offsetBy: 40, limitedBy: text.endIndex) ?? text.endIndex
        let window = text[windowStart..<windowEnd].lowercased()
        return reminderKeywords.contains { window.contains($0) }
    }

    private static func nearestAddress(to range: Range<String.Index>, addresses: [NSTextCheckingResult], in text: String) -> String? {
        guard let closest = addresses.min(by: { lhs, rhs in
            guard let l = Range(lhs.range, in: text), let r = Range(rhs.range, in: text) else { return false }
            return abs(text.distance(from: range.lowerBound, to: l.lowerBound)) < abs(text.distance(from: range.lowerBound, to: r.lowerBound))
        }) else { return nil }
        return span(for: closest, in: text)
    }

    private static func isAllDay(_ match: DateMatch) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: match.date)
        let minute = calendar.component(.minute, from: match.date)
        return hour == 0 && minute == 0 && match.duration == nil
    }
}
