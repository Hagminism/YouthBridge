import Foundation
import Combine

enum SearchAction {
    case updateKeyword(String)
    case search(String)
    case selectTrending(String)
    case clearHistory
    case deleteHistoryItem(String)
    case tapResult(Policy)
    case applyFilter(FilterState)
}

enum SearchEffect {
    case navigateToDetail(Policy)
}

struct SearchState {
    var keyword: String = ""
    var recentKeywords: [String] = []
    var trendingKeywords: [String] = ["#청년수당", "#월세지원", "#취업성공패키지", "#창업교육", "#전세자금대출"]
    var results: [Policy] = []
    var isSearching: Bool = false
    var showResults: Bool = false
    var appliedFilter: FilterState = FilterState()

    var isFilterActive: Bool { !appliedFilter.isDefault }
}

@MainActor
final class SearchViewModel {
    @Published private(set) var state = SearchState()
    let effect = PassthroughSubject<SearchEffect, Never>()

    private let fetchUseCase: FetchPoliciesUseCase
    private let historyKey = "search_history"

    init(fetchUseCase: FetchPoliciesUseCase) {
        self.fetchUseCase = fetchUseCase
        loadHistory()
    }

    func onAction(_ action: SearchAction) {
        switch action {
        case .updateKeyword(let kw):
            state.keyword = kw
            if kw.isEmpty {
                if state.appliedFilter.isDefault {
                    state.showResults = false
                    state.results = []
                } else {
                    performSearch("")
                }
            }
        case .search(let kw):
            guard !kw.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            addToHistory(kw)
            performSearch(kw)
        case .selectTrending(let kw):
            let clean = kw.replacingOccurrences(of: "#", with: "")
            state.keyword = clean
            addToHistory(clean)
            performSearch(clean)
        case .clearHistory:
            state.recentKeywords = []
            UserDefaults.standard.removeObject(forKey: historyKey)
        case .deleteHistoryItem(let kw):
            state.recentKeywords.removeAll { $0 == kw }
            saveHistory()
        case .tapResult(let policy):
            effect.send(.navigateToDetail(policy))
        case .applyFilter(let filter):
            state.appliedFilter = filter
            if state.keyword.isEmpty && filter.isDefault {
                state.showResults = false
                state.results = []
            } else {
                performSearch(state.keyword)
            }
        }
    }

    private func performSearch(_ kw: String) {
        state.isSearching = true
        state.showResults = true
        let filter = state.appliedFilter
        Task {
            do {
                let raw = try await fetchUseCase.execute(
                    region:   filter.selectedRegions.first,
                    category: filter.selectedCategories.first,
                    keyword:  kw,
                    page:     1
                )
                state.results = raw.filter { policy in
                    switch filter.policyStatus {
                    case .active:  return !policy.isExpired
                    case .expired: return policy.isExpired
                    case .all:     return true
                    }
                }
                state.isSearching = false
            } catch {
                state.isSearching = false
            }
        }
    }

    private func addToHistory(_ kw: String) {
        state.recentKeywords.removeAll { $0 == kw }
        state.recentKeywords.insert(kw, at: 0)
        if state.recentKeywords.count > 10 { state.recentKeywords = Array(state.recentKeywords.prefix(10)) }
        saveHistory()
    }

    private func loadHistory() {
        state.recentKeywords = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    }

    private func saveHistory() {
        UserDefaults.standard.set(state.recentKeywords, forKey: historyKey)
    }
}
