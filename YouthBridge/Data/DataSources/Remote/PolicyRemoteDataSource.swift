import Foundation

final class PolicyRemoteDataSource {
    private let apiKey: String
    private static let baseURL = "https://www.youthcenter.go.kr/go/ythip/getPlcy"

    init() {
        let path = Bundle.main.path(forResource: "Config", ofType: "plist")
        let dict = path.flatMap { NSDictionary(contentsOfFile: $0) }
        self.apiKey = dict?["YOUTH_POLICY_API_KEY"] as? String ?? ""
    }

    func fetchPolicies(region: String?, category: String?, keyword: String?, page: Int = 1) async throws -> [PolicyDTO] {
        var components = URLComponents(string: Self.baseURL)!
        // 클라이언트 필터링을 위해 더 많이 가져옴
        let pageSize = (region != nil || category != nil) ? 50 : 20
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKeyNm",  value: apiKey),
            URLQueryItem(name: "pageNum",   value: "\(page)"),
            URLQueryItem(name: "pageSize",  value: "\(pageSize)"),
            URLQueryItem(name: "rtnType",   value: "json"),
        ]
        if let keyword, !keyword.isEmpty {
            queryItems.append(URLQueryItem(name: "srchKrdFld", value: keyword))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(PolicyListResponseDTO.self, from: data)
        return decoded.result?.youthPolicyList ?? []
    }
}
