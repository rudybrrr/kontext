import Foundation

struct ActionCandidateMerger: Sendable {
    private let minimumModelConfidence = 0.6
    private let dateTolerance: TimeInterval = 15 * 60

    func merge(
        sourceText: String,
        referenceDate: Date,
        deterministic: [ActionCandidate],
        model: [ActionCandidate],
        modelExtractionAvailable: Bool
    ) -> [ActionCandidate] {
        if !modelExtractionAvailable {
            return dedupe(deterministic)
        }

        let detectedDates = Self.detectedDates(in: sourceText, referenceDate: referenceDate)
        let validatedModel = model
            .filter { $0.confidence >= minimumModelConfidence }
            .compactMap { sanitizeModelCandidate($0, detectedDates: detectedDates) }

        return dedupe(deterministic + validatedModel)
    }

    private func sanitizeModelCandidate(_ candidate: ActionCandidate, detectedDates: [Date]) -> ActionCandidate? {
        let start = validatedDate(candidate.start, detectedDates: detectedDates)
        let end = validatedDate(candidate.end, detectedDates: detectedDates)
        let due = validatedDate(candidate.due, detectedDates: detectedDates)

        switch candidate.kind {
        case .event:
            guard start != nil || end != nil else { return nil }
        case .reminder:
            guard due != nil else { return nil }
        case .followUp:
            break
        }

        return ActionCandidate(
            kind: candidate.kind,
            title: candidate.title,
            start: start,
            end: end,
            isAllDay: candidate.isAllDay,
            due: due,
            location: candidate.location,
            people: candidate.people,
            url: candidate.url,
            sourceSpan: candidate.sourceSpan,
            confidence: candidate.confidence
        )
    }

    private func validatedDate(_ date: Date?, detectedDates: [Date]) -> Date? {
        guard let date else { return nil }
        guard detectedDates.contains(where: { Self.datesAlign($0, date, tolerance: dateTolerance) }) else { return nil }
        return date
    }

    private func dedupe(_ candidates: [ActionCandidate]) -> [ActionCandidate] {
        var seen: [String: ActionCandidate] = [:]
        for candidate in candidates.sorted(by: { $0.confidence > $1.confidence }) {
            let key = dedupeKey(for: candidate)
            if let existing = seen[key] {
                if candidate.confidence > existing.confidence {
                    seen[key] = candidate
                }
            } else {
                seen[key] = candidate
            }
        }
        return seen.values.sorted { lhs, rhs in
            if lhs.confidence == rhs.confidence { return lhs.title < rhs.title }
            return lhs.confidence > rhs.confidence
        }
    }

    private func dedupeKey(for candidate: ActionCandidate) -> String {
        let anchor = candidate.start ?? candidate.due ?? candidate.url ?? ""
        return "\(candidate.kind.rawValue)|\(candidate.title.lowercased())|\(anchor.timeIntervalSince1970)"
    }

    private static func detectedDates(in text: String, referenceDate: Date) -> [Date] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return [] }
        return detector
            .matches(in: text, options: [.referenceDate: referenceDate], range: NSRange(text.startIndex..., in: text))
            .compactMap(\.date)
    }

    private static func datesAlign(_ lhs: Date, _ rhs: Date, tolerance: TimeInterval) -> Bool {
        abs(lhs.timeIntervalSince(rhs)) <= tolerance
            || Calendar.current.isDate(lhs, inSameDayAs: rhs)
    }
}
