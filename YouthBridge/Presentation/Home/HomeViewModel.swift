import Foundation
import Combine

@MainActor
final class HomeViewModel {
    @Published private(set) var state = HomeState()
    let effect = PassthroughSubject<HomeEffect, Never>()

    private let fetchUseCase: FetchPoliciesUseCase

    init(fetchUseCase: FetchPoliciesUseCase) {
        self.fetchUseCase = fetchUseCase
    }

    func onAction(_ action: HomeAction) {
        switch action {
        case .viewDidLoad, .refresh:
            resetAndLoad()
        case .tapSearchBar:
            effect.send(.navigateToSearch)
        case .tapFilter:
            effect.send(.navigateToFilter(current: state.appliedFilter))
        case .tapPolicy(let policy):
            effect.send(.navigateToDetail(policy))
        case .toggleScrap:
            break
        case .applyFilter(let filter):
            state.appliedFilter = filter
            resetAndLoad()
        case .loadMore:
            guard !state.isLoadingMore, state.hasMore, !state.isLoading else { return }
            loadPage(state.currentPage + 1, append: true)
        }
    }

    private func resetAndLoad() {
        state.allPolicies = []
        state.urgentPolicies = []
        state.currentPage = 1
        state.hasMore = true
        loadPage(1, append: false)
    }

    private func loadPage(_ page: Int, append: Bool) {
        if append {
            state.isLoadingMore = true
        } else {
            state.isLoading = true
            state.errorMessage = nil
        }
        let filter = state.appliedFilter
        Task {
            do {
                let fetched = try await fetchUseCase.execute(
                    region:   filter.selectedRegions.first,
                    category: filter.selectedCategories.first,
                    page:     page
                )
                if append {
                    state.allPolicies.append(contentsOf: fetched)
                } else {
                    state.allPolicies = fetched
                }
                state.urgentPolicies = state.allPolicies.filter { $0.isUrgent }
                state.currentPage = page
                state.hasMore = fetched.count >= HomeState.pageSize
                state.isLoading = false
                state.isLoadingMore = false
            } catch {
                state.isLoading = false
                state.isLoadingMore = false
                state.errorMessage = error.localizedDescription
                effect.send(.showError(error.localizedDescription))
            }
        }
    }
}
