import Foundation

enum DetailAction {
    case viewDidLoad
    case tapScrap
    case tapAISummary
    case tapExternalLink
    case tapShare
}

enum DetailEffect {
    case openURL(URL)
    case shareText(String)
    case showError(String)
    case scrapToggled(isScrapped: Bool)
}
