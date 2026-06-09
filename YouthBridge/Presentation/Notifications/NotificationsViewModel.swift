import Foundation
import Combine
import UserNotifications

struct NotificationItem: Identifiable {
    let id = UUID()
    let identifier: String
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
            refreshNotifications()
        case .markAllRead:
            // 시스템 알림 센터에서 모든 발송된(Delivered) 알림들을 일괄 삭제하여 '모두 읽음' 처리
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications()
            
            for i in state.items.indices {
                state.items[i].isRead = true
            }
            refreshNotifications()
        case .tapItem(let item):
            // 탭한 알림은 시스템 알림 목록에서 제거 (읽음 처리)
            let center = UNUserNotificationCenter.current()
            center.removeDeliveredNotifications(withIdentifiers: [item.identifier])
            center.removePendingNotificationRequests(withIdentifiers: [item.identifier])
            
            if let idx = state.items.firstIndex(where: { $0.id == item.id }) {
                state.items[idx].isRead = true
            }
            refreshNotifications()
        }
    }

    private func refreshNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { [weak self] pendingRequests in
            center.getDeliveredNotifications { [weak self] deliveredNotifications in
                guard let self = self else { return }
                
                // 1. Pending (예약 대기 중인) 알림들 변환
                let pendingItems = pendingRequests.compactMap { request -> NotificationItem? in
                    let content = request.content
                    var timeText = "알림 예정"
                    
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let date = trigger.nextTriggerDate() {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM/dd HH:mm"
                        timeText = "\(formatter.string(from: date)) 예정"
                    } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger,
                              let date = trigger.nextTriggerDate() {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm:ss"
                        timeText = "\(formatter.string(from: date)) 예정"
                    }
                    
                    return NotificationItem(
                        identifier: request.identifier,
                        title: content.title,
                        body: content.body,
                        time: timeText,
                        isUrgent: request.identifier.contains("urgent"),
                        isRead: false
                    )
                }
                
                // 2. Delivered (이미 수신된) 알림들 변환
                let deliveredItems = deliveredNotifications.map { notification -> NotificationItem in
                    let content = notification.request.content
                    let date = notification.date
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/dd HH:mm"
                    
                    return NotificationItem(
                        identifier: notification.request.identifier,
                        title: content.title,
                        body: content.body,
                        time: formatter.string(from: date),
                        isUrgent: notification.request.identifier.contains("urgent"),
                        isRead: true
                    )
                }
                
                Task { @MainActor in
                    // 알림 대기 및 수신 목록 결합 (대기 알림을 상단에 우선 배치)
                    self.state.items = pendingItems + deliveredItems
                }
            }
        }
    }
}
