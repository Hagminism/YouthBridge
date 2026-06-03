import Foundation
import Combine

@MainActor
final class DetailViewModel {
    @Published private(set) var state: DetailState
    let effect = PassthroughSubject<DetailEffect, Never>()

    private let scrapUseCase: ScrapPolicyUseCase
    private let summarizeUseCase: SummarizePolicyUseCase
    private let notificationUseCase: ScheduleNotificationUseCase

    init(policy: Policy, scrapUseCase: ScrapPolicyUseCase,
         summarizeUseCase: SummarizePolicyUseCase,
         notificationUseCase: ScheduleNotificationUseCase) {
        self.scrapUseCase = scrapUseCase
        self.summarizeUseCase = summarizeUseCase
        self.notificationUseCase = notificationUseCase
        self.state = DetailState(policy: policy, isScrapped: scrapUseCase.isScrapped(policy.id))
    }

    func onAction(_ action: DetailAction) {
        switch action {
        case .viewDidLoad:
            break
        case .tapScrap:
            let isScrapped = scrapUseCase.toggle(state.policy)
            state.isScrapped = isScrapped
            if isScrapped {
                notificationUseCase.execute(for: state.policy)
            } else {
                notificationUseCase.cancel(for: state.policy.id)
            }
            effect.send(.scrapToggled(isScrapped: isScrapped))
        case .tapAISummary:
            fetchAISummary()
        case .tapExternalLink:
            if let url = state.policy.linkUrl {
                effect.send(.openURL(url))
            }
        case .tapShare:
            let text = "\(state.policy.name)\n\n\(state.policy.supportContent)"
            effect.send(.shareText(text))
        }
    }

    private func fetchAISummary() {
        guard !state.isSummarizing else { return }
        state.isSummarizing = true
        let content = state.policy.supportContent
        Task {
            do {
                let summary = try await summarizeUseCase.execute(content: content)
                state.aiSummary = summary
                state.isSummarizing = false
            } catch {
                state.isSummarizing = false
                effect.send(.showError(error.localizedDescription))
            }
        }
    }
}
