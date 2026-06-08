import Foundation
import UIKit

final class DIContainer {
    static let shared = DIContainer()
    private init() {}

    // MARK: - Data Sources
    lazy var policyRemote = PolicyRemoteDataSource()
    lazy var scrapLocal   = ScrapLocalDataSource()
    lazy var geminiRemote = GeminiRemoteDataSource()

    // MARK: - Repositories
    lazy var policyRepository: PolicyRepository = PolicyRepositoryImpl(remote: policyRemote)
    lazy var scrapRepository: ScrapRepository   = ScrapRepositoryImpl(local: scrapLocal)

    // MARK: - Use Cases
    lazy var fetchPoliciesUseCase    = FetchPoliciesUseCase(repository: policyRepository)
    lazy var scrapPolicyUseCase      = ScrapPolicyUseCase(repository: scrapRepository)
    lazy var summarizePolicyUseCase  = SummarizePolicyUseCase(dataSource: geminiRemote)
    lazy var scheduleNotificationUseCase = ScheduleNotificationUseCase()

    // MARK: - ViewModels
    func makeHomeViewModel()        -> HomeViewModel        { HomeViewModel(fetchUseCase: fetchPoliciesUseCase) }
    func makeSearchViewModel()      -> SearchViewModel      { SearchViewModel(fetchUseCase: fetchPoliciesUseCase) }
    func makeFilterViewModel(current: FilterState) -> FilterViewModel { FilterViewModel(initialState: current) }
    func makeDetailViewModel(policy: Policy) -> DetailViewModel {
        DetailViewModel(policy: policy, scrapUseCase: scrapPolicyUseCase,
                        summarizeUseCase: summarizePolicyUseCase, notificationUseCase: scheduleNotificationUseCase)
    }
    func makeMyPageViewModel()      -> MyPageViewModel      { MyPageViewModel(scrapUseCase: scrapPolicyUseCase) }
    func makeNotificationsViewModel() -> NotificationsViewModel { NotificationsViewModel() }

    // MARK: - View Controllers
    func makeDetailViewController(policy: Policy) -> DetailViewController {
        DetailViewController(policy: policy)
    }

    func makeFilterViewController(current: FilterState) -> FilterViewController {
        FilterViewController(currentFilter: current)
    }

    func makeHomeViewController() -> HomeViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
    }

    func makeSearchViewController() -> SearchViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
    }

    func makeNotificationsViewController() -> NotificationsViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
    }

    func makeMyPageViewController() -> MyPageViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "MyPageViewController") as! MyPageViewController
    }
}
