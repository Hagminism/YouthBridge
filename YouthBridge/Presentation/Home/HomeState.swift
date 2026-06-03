import Foundation

struct HomeState {
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var currentPage: Int = 1
    var hasMore: Bool = true
    var urgentPolicies: [Policy] = []
    var allPolicies: [Policy] = []
    var appliedFilter: FilterState = FilterState()
    var errorMessage: String? = nil

    var displayPolicies: [Policy] {
        switch appliedFilter.policyStatus {
        case .active:  return allPolicies.filter { !$0.isExpired }
        case .expired: return allPolicies.filter { $0.isExpired }
        case .all:     return allPolicies
        }
    }

    static let pageSize = 20
}

struct FilterState {
    var selectedRegions: [String] = []
    var selectedCategories: [String] = []
    var policyStatus: PolicyStatus = .active

    var isDefault: Bool {
        selectedRegions.isEmpty && selectedCategories.isEmpty && policyStatus == .active
    }

    enum PolicyStatus { case active, expired, all }
}
