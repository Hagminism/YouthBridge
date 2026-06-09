import UserNotifications
import Foundation

final class ScheduleNotificationUseCase {
    func execute(for policy: Policy) {
        guard let deadline = policy.deadline else { return }
        let now = Date()
        
        let notifyDate7DaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: deadline)
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        if let triggerDate = notifyDate7DaysBefore, triggerDate > now {
            // 1. 마감 7일 전 날짜가 미래인 경우 -> 7일 전에 알림 스케줄링
            content.title = "마감 7일 전 알림"
            content.body = "[\(policy.name)] 신청 마감이 7일 남았습니다."
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "policy-7days-\(policy.id)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else if deadline > now {
            // 2. 이미 7일 전은 지났으나, 마감일이 아직 지나지 않은 경우 (마감 D-1 ~ D-7 이내)
            // 사용자가 즉각 테스트해 볼 수 있도록 저장 후 5초 뒤 즉시 알림 발송
            let daysLeft = Calendar.current.dateComponents([.day], from: now, to: deadline).day ?? 0
            let daysText = daysLeft == 0 ? "오늘" : "\(daysLeft)일"
            
            content.title = "마감 임박 알림"
            content.body = "[\(policy.name)] 신청 마감이 \(daysText) 남았습니다. 서둘러 신청하세요!"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "policy-urgent-\(policy.id)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancel(for policyId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "policy-7days-\(policyId)",
            "policy-urgent-\(policyId)"
        ])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [
            "policy-7days-\(policyId)",
            "policy-urgent-\(policyId)"
        ])
    }
}
