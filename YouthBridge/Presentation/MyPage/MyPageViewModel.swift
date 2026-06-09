import Foundation
import Combine
import UserNotifications

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
    case showPermissionAlert
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
            checkNotificationSettings()
        case .toggleNotifications(let enabled):
            if enabled {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if granted {
                            self.state.notificationsEnabled = true
                            UserDefaults.standard.set(true, forKey: self.notifKey)
                            self.scheduleAllNotifications()
                        } else {
                            self.state.notificationsEnabled = false
                            UserDefaults.standard.set(false, forKey: self.notifKey)
                            self.effect.send(.showPermissionAlert)
                        }
                    }
                }
            } else {
                state.notificationsEnabled = false
                UserDefaults.standard.set(false, forKey: notifKey)
                // 모든 로컬 알림 예약 해제
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
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

    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            let isSystemAuthorized = settings.authorizationStatus == .authorized
            let userPref = UserDefaults.standard.bool(forKey: self.notifKey)
            
            Task { @MainActor in
                // 실제 시스템 권한도 켜져 있고 유저가 동의한 플래그도 켜져 있을 때만 true로 설정
                self.state.notificationsEnabled = isSystemAuthorized && userPref
            }
        }
    }

    private func scheduleAllNotifications() {
        let notificationUseCase = DIContainer.shared.scheduleNotificationUseCase
        let scrapped = scrapUseCase.getScrapped()
        for policy in scrapped {
            notificationUseCase.execute(for: policy)
        }
    }
}
