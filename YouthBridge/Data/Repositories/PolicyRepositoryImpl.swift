import Foundation

final class PolicyRepositoryImpl: PolicyRepository {
    private let remote: PolicyRemoteDataSource

    // 시도명 → 행정구역코드 앞 2자리 매핑
    private static let regionPrefixes: [String: String] = [
        "서울": "11", "부산": "26", "대구": "27", "인천": "28",
        "광주": "29", "대전": "30", "울산": "31", "세종": "36",
        "경기": "41", "강원": "51", "충북": "43", "충남": "44",
        "전북": "52", "전남": "46", "경북": "47", "경남": "48", "제주": "50",
    ]

    // 필터 카테고리명 → API lclsfNm 부분 매칭 키워드
    private static let categoryKeywords: [String: [String]] = [
        "일자리·취업": ["일자리", "취업"],
        "주거":        ["주거"],
        "금융":        ["금융"],
        "교육":        ["교육"],
        "건강·복지":   ["건강", "복지", "문화"],
    ]

    init(remote: PolicyRemoteDataSource) {
        self.remote = remote
    }

    func fetchPolicies(region: String?, category: String?, keyword: String?, page: Int) async throws -> [Policy] {
        let dtos = try await remote.fetchPolicies(region: nil, category: nil, keyword: keyword, page: page)
        let filtered = filter(dtos: dtos, region: region, category: category)
        return PolicyMapper.toDomainList(filtered)
    }

    private func filter(dtos: [PolicyDTO], region: String?, category: String?) -> [PolicyDTO] {
        dtos.filter { dto in
            if let region, !region.isEmpty, region != "전체" {
                guard let prefix = Self.regionPrefixes[region],
                      let zipCd = dto.zipCd, !zipCd.isEmpty else { return false }
                let codes = zipCd.components(separatedBy: ",")
                let match = codes.contains { $0.hasPrefix(prefix) }
                if !match { return false }
            }
            if let category, !category.isEmpty {
                let keywords = Self.categoryKeywords[category] ?? [category]
                let lclsf = dto.lclsfNm ?? ""
                let mclsf = dto.mclsfNm ?? ""
                let combined = lclsf + mclsf
                if !keywords.contains(where: { combined.contains($0) }) { return false }
            }
            return true
        }
    }
}
