import Foundation

struct DetailState {
    var policy: Policy
    var isScrapped: Bool = false
    var isSummarizing: Bool = false
    var aiSummary: String? = nil
    var errorMessage: String? = nil
}
