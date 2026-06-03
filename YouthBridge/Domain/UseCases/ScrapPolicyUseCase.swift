import Foundation

final class ScrapPolicyUseCase {
    private let repository: ScrapRepository
    init(repository: ScrapRepository) { self.repository = repository }

    @discardableResult
    func toggle(_ policy: Policy) -> Bool {
        if repository.isScrapped(policy.id) {
            repository.unscrap(policy.id)
            return false
        } else {
            repository.scrap(policy)
            return true
        }
    }

    func isScrapped(_ policyId: String) -> Bool {
        repository.isScrapped(policyId)
    }

    func getScrapped() -> [Policy] {
        repository.getScrapped()
    }
}
