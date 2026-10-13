import Foundation
import SwiftData

@MainActor
struct RemindMeIntentService {
    func applyPendingIntents(modelContext: ModelContext) throws {
        var descriptor = FetchDescriptor<CaptureItem>()
        let items = try modelContext.fetch(descriptor).filter(\.remindMeIntent)
        guard !items.isEmpty else { return }

        for item in items {
            defer { item.remindMeIntent = false }
            guard let candidate = URLFollowUpProposalService.readFollowUpCandidate(for: item),
                  let url = candidate.url else { continue }
            guard !URLFollowUpProposalService.alreadyProposedReadFollowUp(for: item, matching: url) else { continue }
            let action = candidate.asProposedAction()
            action.captureItem = item
            modelContext.insert(action)
        }
        try modelContext.save()
    }
}
