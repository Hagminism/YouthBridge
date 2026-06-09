import Foundation

final class GeminiRemoteDataSource: GeminiDataSourceProtocol {
    private let apiKey: String
    private static let maxContentLength = 400
    private static let maxRetries = 2

    init() {
        let path = Bundle.main.path(forResource: "Config", ofType: "plist")
        let dict = path.flatMap { NSDictionary(contentsOfFile: $0) }
        self.apiKey = dict?["GEMINI_API_KEY"] as? String ?? ""
    }

    func summarize(content: String) async throws -> String {
        let trimmed = String(content.prefix(Self.maxContentLength))

        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else { throw URLError(.badURL) }

        let prompt = """
        다음 청년 정책 내용을 분석해서 20대 대학생이 이해하기 쉬운 말투로, 반드시 아래 3줄 형식으로만 요약해줘.
        가독성을 위해 각 항목마다 이모지를 섞어줘.

        1. 💰 지원 금액: (구체적인 금액이나 혜택)
        2. 👤 신청 자격: (나이, 조건 등 핵심만)
        3. ⚠️ 주의 사항: (놓치기 쉬운 조건이나 제한)

        정책 내용:
        \(trimmed)
        """

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await sendWithRetry(request: request, retriesLeft: Self.maxRetries)
    }

    private func sendWithRetry(request: URLRequest, retriesLeft: Int) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

        if statusCode == 429, retriesLeft > 0 {
            try await Task.sleep(nanoseconds: 6_000_000_000)
            return try await sendWithRetry(request: request, retriesLeft: retriesLeft - 1)
        }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

        // HTTP 상태 코드가 성공 범위가 아닐 때의 명시적 예외 처리 강화
        guard (200...299).contains(statusCode) else {
            if let errorObj = json?["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                if statusCode == 429 {
                    throw NSError(domain: "GeminiAPI", code: 429,
                                   userInfo: [NSLocalizedDescriptionKey: "요청 한도 초과. 잠시 후 다시 시도해주세요."])
                }
                throw NSError(domain: "GeminiAPI", code: statusCode,
                              userInfo: [NSLocalizedDescriptionKey: message])
            } else {
                throw NSError(domain: "GeminiAPI", code: statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "서버 오류가 발생했습니다. (Status: \(statusCode))"])
            }
        }

        let candidates = json?["candidates"] as? [[String: Any]]
        let responseContent = candidates?.first?["content"] as? [String: Any]
        let parts = responseContent?["parts"] as? [[String: Any]]
        return parts?.first?["text"] as? String ?? "요약을 불러올 수 없습니다."
    }
}
