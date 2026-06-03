import Foundation

extension Date {
    // "20260301 ~ 20260331" → 마감일 추출
    static func deadline(from applyPeriod: String) -> Date? {
        let parts = applyPeriod.components(separatedBy: "~")
        guard parts.count == 2 else { return nil }
        let raw = parts[1].trimmingCharacters(in: .whitespaces)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: raw)
    }

    var dDayText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadline = calendar.startOfDay(for: self)
        let days = calendar.dateComponents([.day], from: today, to: deadline).day ?? 0
        if days < 0  { return "마감" }
        if days == 0 { return "D-Day" }
        return "D-\(days)"
    }

    var dDaysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadline = calendar.startOfDay(for: self)
        return calendar.dateComponents([.day], from: today, to: deadline).day ?? 0
    }
}
