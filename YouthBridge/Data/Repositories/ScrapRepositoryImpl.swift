import Foundation

final class ScrapRepositoryImpl: ScrapRepository {
    private let local: ScrapLocalDataSource

    init(local: ScrapLocalDataSource) {
        self.local = local
    }

    func getScrapped() -> [Policy]  { local.getAll() }
    func scrap(_ policy: Policy)    { local.save(policy) }
    func unscrap(_ id: String)      { local.delete(id: id) }
    func isScrapped(_ id: String) -> Bool { local.contains(id: id) }
}
