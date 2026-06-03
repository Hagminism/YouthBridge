import Foundation

final class ScrapLocalDataSource {
    private let key = "scrapped_policies"

    private struct PolicyRecord: Codable {
        let id, name, category, supportContent, operatingOrg, applyPeriod: String
        let externalUrl, applyUrl: String?
    }

    func getAll() -> [Policy] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([PolicyRecord].self, from: data)
        else { return [] }
        return records.map {
            Policy(id: $0.id, name: $0.name, category: $0.category,
                   supportContent: $0.supportContent, operatingOrg: $0.operatingOrg,
                   applyPeriod: $0.applyPeriod, externalUrl: $0.externalUrl, applyUrl: $0.applyUrl)
        }
    }

    func save(_ policy: Policy) {
        var records = getAllRecords()
        guard !records.contains(where: { $0.id == policy.id }) else { return }
        records.append(PolicyRecord(id: policy.id, name: policy.name, category: policy.category,
                                    supportContent: policy.supportContent, operatingOrg: policy.operatingOrg,
                                    applyPeriod: policy.applyPeriod, externalUrl: policy.externalUrl, applyUrl: policy.applyUrl))
        persist(records)
    }

    func delete(id: String) {
        let records = getAllRecords().filter { $0.id != id }
        persist(records)
    }

    func contains(id: String) -> Bool {
        getAllRecords().contains { $0.id == id }
    }

    private func getAllRecords() -> [PolicyRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([PolicyRecord].self, from: data)
        else { return [] }
        return records
    }

    private func persist(_ records: [PolicyRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
