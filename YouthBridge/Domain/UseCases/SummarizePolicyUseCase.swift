import Foundation

final class SummarizePolicyUseCase {
    private let dataSource: GeminiDataSourceProtocol
    init(dataSource: GeminiDataSourceProtocol) { self.dataSource = dataSource }

    func execute(content: String) async throws -> String {
        try await dataSource.summarize(content: content)
    }
}

protocol GeminiDataSourceProtocol {
    func summarize(content: String) async throws -> String
}
