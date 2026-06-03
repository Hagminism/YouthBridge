import Foundation

struct Policy: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let supportContent: String
    let operatingOrg: String
    let applyPeriod: String
    let externalUrl: String?
    let applyUrl: String?

    var deadline: Date? { Date.deadline(from: applyPeriod) }

    var dDayText: String { deadline?.dDayText ?? "" }

    var dDaysRemaining: Int { deadline?.dDaysRemaining ?? Int.max }

    var isUrgent: Bool { dDaysRemaining >= 0 && dDaysRemaining <= 7 }

    var isExpired: Bool { dDaysRemaining < 0 }

    var linkUrl: URL? {
        if let raw = externalUrl ?? applyUrl, !raw.isEmpty {
            return URL(string: raw)
        }
        return nil
    }

    var displayApplyPeriod: String {
        let trimmed = applyPeriod.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "기간이 정해져있지 않습니다" }

        let parts = trimmed.components(separatedBy: "~")
        guard parts.count == 2 else { return trimmed }

        let input = DateFormatter()
        input.dateFormat = "yyyyMMdd"
        let output = DateFormatter()
        output.dateFormat = "yyyy.MM.dd"

        func fmt(_ s: String) -> String {
            let raw = s.trimmingCharacters(in: .whitespaces)
            return input.date(from: raw).map { output.string(from: $0) } ?? raw
        }
        return "\(fmt(parts[0])) ~ \(fmt(parts[1]))"
    }
}
