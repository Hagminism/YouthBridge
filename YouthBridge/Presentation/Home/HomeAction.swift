import Foundation

enum HomeAction {
    case viewDidLoad
    case tapSearchBar
    case tapFilter
    case tapPolicy(Policy)
    case toggleScrap(Policy)
    case applyFilter(FilterState)
    case refresh
    case loadMore
}

enum HomeEffect {
    case navigateToSearch
    case navigateToFilter(current: FilterState)
    case navigateToDetail(Policy)
    case showError(String)
}
