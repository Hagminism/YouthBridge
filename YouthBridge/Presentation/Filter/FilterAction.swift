import Foundation

enum FilterAction {
    case toggleRegion(String)
    case toggleCategory(String)
    case selectStatus(FilterState.PolicyStatus)
    case reset
    case apply
}

enum FilterEffect {
    case dismiss(FilterState)
}
