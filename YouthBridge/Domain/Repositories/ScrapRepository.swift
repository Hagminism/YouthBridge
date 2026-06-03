import Foundation

protocol ScrapRepository {
    func getScrapped() -> [Policy]
    func scrap(_ policy: Policy)
    func unscrap(_ policyId: String)
    func isScrapped(_ policyId: String) -> Bool
}
