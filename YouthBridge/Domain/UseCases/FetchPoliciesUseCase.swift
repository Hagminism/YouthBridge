import Foundation

final class FetchPoliciesUseCase {
    private let repository: PolicyRepository
    init(repository: PolicyRepository) { self.repository = repository }

    func execute(region: String? = nil, category: String? = nil, keyword: String? = nil, page: Int = 1) async throws -> [Policy] {
        let policies = try await repository.fetchPolicies(region: region, category: category, keyword: keyword, page: page)
        return policies.sorted { $0.dDaysRemaining < $1.dDaysRemaining }
    }
}
