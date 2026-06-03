import UIKit

enum AppFont {
    // MARK: - Public Sans (logo, D-Day badge)
    static func publicSans(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name: String
        switch weight {
        case .bold:       name = "PublicSans-Bold"
        case .semibold:   name = "PublicSans-SemiBold"
        case .medium:     name = "PublicSans-Medium"
        default:          name = "PublicSans-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    // MARK: - System (WenQuanYi Zen Hei 대체 — 한글 시스템폰트)
    static func korean(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        .systemFont(ofSize: size, weight: weight)
    }
}

// MARK: - Figma 스펙 기반 텍스트 스타일
extension AppFont {
    static var logoTitle:       UIFont { publicSans(size: 20, weight: .bold) }
    static var heading1:        UIFont { publicSans(size: 34, weight: .bold) }
    static var heading2:        UIFont { korean(size: 22, weight: .bold) }
    static var sectionTitle:    UIFont { korean(size: 20, weight: .semibold) }
    static var policyTitle:     UIFont { korean(size: 17, weight: .semibold) }
    static var body:            UIFont { korean(size: 17, weight: .regular) }
    static var bodyMedium:      UIFont { korean(size: 15, weight: .regular) }
    static var caption:         UIFont { korean(size: 13, weight: .regular) }
    static var captionSmall:    UIFont { korean(size: 12, weight: .regular) }
    static var tabBarLabel:     UIFont { korean(size: 10, weight: .medium) }
    static var dDayBadge:       UIFont { publicSans(size: 12, weight: .semibold) }
    static var categoryBadge:   UIFont { korean(size: 11, weight: .regular) }
    static var actionButton:    UIFont { korean(size: 17, weight: .semibold) }
}
