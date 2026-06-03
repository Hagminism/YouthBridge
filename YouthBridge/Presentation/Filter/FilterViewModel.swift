import Foundation
import Combine

@MainActor
final class FilterViewModel {
    @Published private(set) var state: FilterState
    let effect = PassthroughSubject<FilterEffect, Never>()

    static let regions = ["서울", "부산", "인천", "대구", "대전", "광주", "울산", "경기", "강원", "충북", "충남", "전북", "전남", "경북", "경남", "제주", "세종"]
    // FilterViewController.categoryMeta와 동기화 (이름만 사용)
    static let categoryNames = ["일자리·취업", "주거", "금융", "교육", "건강·복지"]

    init(initialState: FilterState) {
        self.state = initialState
    }

    func onAction(_ action: FilterAction) {
        switch action {
        case .toggleRegion(let region):
            if state.selectedRegions.contains(region) {
                state.selectedRegions.removeAll { $0 == region }
            } else {
                state.selectedRegions.append(region)
            }
        case .toggleCategory(let cat):
            if state.selectedCategories.contains(cat) {
                state.selectedCategories.removeAll { $0 == cat }
            } else {
                state.selectedCategories.append(cat)
            }
        case .selectStatus(let status):
            state.policyStatus = status
        case .reset:
            state = FilterState()
        case .apply:
            effect.send(.dismiss(state))
        }
    }

    var selectionSummary: String {
        var parts: [String] = []
        if !state.selectedRegions.isEmpty { parts.append("\(state.selectedRegions.count)개 지역") }
        if !state.selectedCategories.isEmpty { parts.append("\(state.selectedCategories.count)개 카테고리") }
        return parts.isEmpty ? "" : parts.joined(separator: ", ") + " 선택됨"
    }
}
