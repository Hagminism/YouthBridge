import UserNotifications

final class ScheduleNotificationUseCase {
    func execute(for policy: Policy) {
        guard let deadline = policy.deadline else { return }
        let notifyDate = Calendar.current.date(byAdding: .day, value: -7, to: deadline)
        guard let triggerDate = notifyDate, triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "마감 7일 전 알림"
        content.body = "\(policy.name) 신청 마감이 7일 남았습니다."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "policy-\(policy.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancel(for policyId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["policy-\(policyId)"])
    }
}
