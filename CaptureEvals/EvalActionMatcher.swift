import Foundation
@testable import Capture

struct EvalPredictedAction: Sendable {
    let kind: ProposedActionKind
    let title: String
    let start: Date?
    let end: Date?
    let due: Date?
    let isAllDay: Bool
    let location: String?

    init(candidate: ActionCandidate) {
        kind = candidate.kind
        title = candidate.title
        start = candidate.start
        end = candidate.end
        due = candidate.due
        isAllDay = candidate.isAllDay
        location = candidate.location
    }
}

enum EvalActionMatcher {
    static let titleOverlapThreshold = 0.5
    static let dateMatchTolerance: TimeInterval = 15 * 60

    static func matches(expected: EvalExpectedAction, predicted: EvalPredictedAction) -> Bool {
        guard expected.kind == predicted.kind.rawValue else { return false }
        guard titleOverlap(expected.titleKeywords, predicted.title) >= titleOverlapThreshold else { return false }
        return datesAlign(expected: expected, predicted: predicted)
    }

    static func titleOverlap(_ keywords: [String], _ title: String) -> Double {
        let expectedTokens = Set(keywords.flatMap { tokenize($0) })
        let predictedTokens = Set(tokenize(title))
        guard !expectedTokens.isEmpty, !predictedTokens.isEmpty else { return 0 }
        let intersection = expectedTokens.intersection(predictedTokens).count
        return Double(intersection) / Double(min(expectedTokens.count, predictedTokens.count))
    }

    static func tokenize(_ value: String) -> [String] {
        value.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
    }

    static func datesAlign(expected: EvalExpectedAction, predicted: EvalPredictedAction) -> Bool {
        let expectedAnchor = anchorDate(for: expected)
        let predictedAnchor = anchorDate(for: predicted)
        switch (expectedAnchor, predictedAnchor) {
        case (nil, nil):
            return true
        case let (e?, p?):
            if expected.isAllDay || predicted.isAllDay {
                return Calendar.current.isDate(e, inSameDayAs: p)
            }
            return abs(e.timeIntervalSince(p)) <= dateMatchTolerance
        default:
            return false
        }
    }

    static func isExactDateMatch(expected: EvalExpectedAction, predicted: EvalPredictedAction) -> Bool {
        guard let e = anchorDate(for: expected), let p = anchorDate(for: predicted) else { return expectedAnchorMissing(expected) && predictedAnchorMissing(predicted) }
        if expected.isAllDay || predicted.isAllDay {
            return Calendar.current.isDate(e, inSameDayAs: p)
        }
        return e == p
    }

    static func isFifteenMinuteDateMatch(expected: EvalExpectedAction, predicted: EvalPredictedAction) -> Bool {
        datesAlign(expected: expected, predicted: predicted)
    }

    private static func anchorDate(for expected: EvalExpectedAction) -> Date? {
        switch expected.kind {
        case "reminder": return EvalDateParsing.date(from: expected.dueISO)
        case "followUp": return EvalDateParsing.date(from: expected.dueISO) ?? EvalDateParsing.date(from: expected.startISO)
        default: return EvalDateParsing.date(from: expected.startISO)
        }
    }

    private static func anchorDate(for predicted: EvalPredictedAction) -> Date? {
        switch predicted.kind {
        case .reminder: return predicted.due
        case .followUp: return predicted.due ?? predicted.start
        case .event: return predicted.start
        }
    }

    private static func expectedAnchorMissing(_ expected: EvalExpectedAction) -> Bool {
        anchorDate(for: expected) == nil
    }

    private static func predictedAnchorMissing(_ predicted: EvalPredictedAction) -> Bool {
        anchorDate(for: predicted) == nil
    }

    static func greedyMatch(
        expected: [EvalExpectedAction],
        predicted: [EvalPredictedAction]
    ) -> [(EvalExpectedAction, EvalPredictedAction)] {
        var pairs: [(EvalExpectedAction, EvalPredictedAction)] = []
        var usedPredicted = Set<Int>()
        for exp in expected {
            if let index = predicted.indices.first(where: { i in
                !usedPredicted.contains(i) && matches(expected: exp, predicted: predicted[i])
            }) {
                usedPredicted.insert(index)
                pairs.append((exp, predicted[index]))
            }
        }
        return pairs
    }
}
