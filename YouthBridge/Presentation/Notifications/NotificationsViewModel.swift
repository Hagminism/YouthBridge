import Foundation
import Combine

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let time: String
    let isUrgent: Bool
    var isRead: Bool
}

struct NotificationsState {
    var items: [NotificationItem] = []
    var hasUnread: Bool { items.contains { !$0.isRead } }
}

enum NotificationsAction {
    case viewDidLoad
    case markAllRead
    case tapItem(NotificationItem)
}

@MainActor
final class NotificationsViewModel {
    @Published private(set) var state = NotificationsState()

    init() {}

    func onAction(_ action: NotificationsAction) {
        switch action {
        case .viewDidLoad:
            loadDemoNotifications()
        case .markAllRead:
            for i in state.items.indices { state.items[i].isRead = true }
        case .tapItem(let item):
            if let idx = state.items.firstIndex(where: { $0.id == item.id }) {
                state.items[idx].isRead = true
            }
        }
    }

    private func loadDemoNotifications() {
        state.items = [
            NotificationItem(title: "청년일자리 성공패키지 신청 마감이 내일입니다!", body: "오늘 밤 11:59까지 서류 제출을 완료하여 혜택을 놓치지 마세요.", time: "2시간 전", isUrgent: true, isRead: false),
            NotificationItem(title: "서울시 거주 청년을 위한 새로운 주거 지원 정책이 게시되었습니다", body: "독립 청년을 위한 새로운 월세 지원 프로그램 신청이 시작되었습니다.", time: "5시간 전", isUrgent: false, isRead: false),
            NotificationItem(title: "프로필 인증 완료", body: "본인 확인이 완료되었습니다. 이제 모든 맞춤형 정책에 지원하실 수 있습니다.", time: "어제", isUrgent: false, isRead: true),
        ]
    }
}
