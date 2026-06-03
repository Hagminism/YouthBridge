import Foundation
import Combine

struct MyPageState {
    var scrappedPolicies: [Policy] = []
    var notificationsEnabled: Bool = false
    var scrappedCount: Int { scrappedPolicies.count }
}

enum MyPageAction {
    case viewDidLoad
    case toggleNotifications(Bool)
    case tapPolicy(Policy)
    case tapRemoveScrap(Policy)
}

enum MyPageEffect {
    case navigateToDetail(Policy)
}

@MainActor
final class MyPageViewModel {
    @Published private(set) var state = MyPageState()
    let effect = PassthroughSubject<MyPageEffect, Never>()

    private let scrapUseCase: ScrapPolicyUseCase
    private let notifKey = "notifications_enabled"

    init(scrapUseCase: ScrapPolicyUseCase) {
        self.scrapUseCase = scrapUseCase
    }

    func onAction(_ action: MyPageAction) {
        switch action {
        case .viewDidLoad:
            loadScrapped()
            state.notificationsEnabled = UserDefaults.standard.bool(forKey: notifKey)
        case .toggleNotifications(let enabled):
            state.notificationsEnabled = enabled
            UserDefaults.standard.set(enabled, forKey: notifKey)
        case .tapPolicy(let policy):
            effect.send(.navigateToDetail(policy))
        case .tapRemoveScrap(let policy):
            scrapUseCase.toggle(policy)
            loadScrapped()
        }
    }

    private func loadScrapped() {
        state.scrappedPolicies = scrapUseCase.getScrapped()
    }
}
