import Foundation

final class RecentPoliciesManager {
    static let shared = RecentPoliciesManager()
    private let key = "recently_viewed_policies"
    
    private init() {}

    func add(policy: Policy) {
        var list = getAll()
        // 중복 제거
        list.removeAll { $0.id == policy.id }
        // 맨 앞에 삽입
        list.insert(policy, at: 0)
        // 최대 10개만 유지
        if list.count > 10 {
            list = Array(list.prefix(10))
        }
        // 저장
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func getAll() -> [Policy] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Policy].self, from: data) else {
            return []
        }
        return list
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
