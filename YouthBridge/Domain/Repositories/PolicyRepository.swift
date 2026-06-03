import Foundation

protocol PolicyRepository {
    func fetchPolicies(region: String?, category: String?, keyword: String?, page: Int) async throws -> [Policy]
}
