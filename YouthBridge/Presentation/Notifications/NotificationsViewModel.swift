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
    case deleteItem(NotificationItem)
}

@MainActor
final class NotificationsViewModel {
    @Published private(set) var state = NotificationsState()
    
    private let readKeys = "read_notification_identifiers"

    init() {}

    func onAction(_ action: NotificationsAction) {
        switch action {
        case .viewDidLoad:
            refreshNotifications()
        case .markAllRead:
            // 시스템 알림 자체를 지우지 않고, 현재 로드된 모든 알림들의 읽음 상태를 UserDefaults에 반영
            let allIdentifiers = state.items.map { $0.identifier }
            markAllAsRead(identifiers: allIdentifiers)
            refreshNotifications()
        case .tapItem(let item):
            // 카드를 탭했을 때 시스템 알림을 삭제하지 않고, 읽음 상태만 UserDefaults에 저장
            markAsRead(identifier: item.identifier)
            refreshNotifications()
        case .deleteItem(let item):
            // 스와이프 후 삭제 시에만 시스템 알림 및 UserDefaults 읽음 저장소에서 삭제
            let center = UNUserNotificationCenter.current()
            center.removeDeliveredNotifications(withIdentifiers: [item.identifier])
            center.removePendingNotificationRequests(withIdentifiers: [item.identifier])
            removeFromRead(identifier: item.identifier)
            refreshNotifications()
        }
    }

    private func refreshNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { [weak self] pendingRequests in
            center.getDeliveredNotifications { [weak self] deliveredNotifications in
                guard let self = self else { return }
                
                let readSet = self.getReadIdentifiers()
                
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
                        isRead: readSet.contains(request.identifier)
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
                        isRead: readSet.contains(notification.request.identifier)
                    )
                }
                
                Task { @MainActor in
                    // 알림 대기 및 수신 목록 결합 (대기 알림을 상단에 우선 배치)
                    self.state.items = pendingItems + deliveredItems
                }
            }
        }
    }

    // MARK: - UserDefaults 읽음 상태 헬퍼
    private func getReadIdentifiers() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: readKeys) ?? []
        return Set(array)
    }

    private func markAsRead(identifier: String) {
        var set = getReadIdentifiers()
        set.insert(identifier)
        UserDefaults.standard.set(Array(set), forKey: readKeys)
    }

    private func markAllAsRead(identifiers: [String]) {
        var set = getReadIdentifiers()
        for id in identifiers {
            set.insert(id)
        }
        UserDefaults.standard.set(Array(set), forKey: readKeys)
    }

    private func removeFromRead(identifier: String) {
        var set = getReadIdentifiers()
        set.remove(identifier)
        UserDefaults.standard.set(Array(set), forKey: readKeys)
    }
}

