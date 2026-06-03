import UIKit

enum AppColor {
    // MARK: - Primary
    static let primary       = UIColor(hex: "#0058bc")
    static let primaryLight  = UIColor(hex: "#0070eb")
    static let primaryBlue2  = UIColor(hex: "#2563eb")

    // MARK: - Background
    static let background        = UIColor(hex: "#ffffff")
    static let backgroundSecondary = UIColor(hex: "#faf9fe")
    static let backgroundTertiary  = UIColor(hex: "#f4f3f8")

    // MARK: - Text
    static let textPrimary   = UIColor(hex: "#1a1b1f")
    static let textSecondary = UIColor(hex: "#414755")
    static let textTertiary  = UIColor(hex: "#717786")
    static let textDisabled  = UIColor(hex: "#9ca3af")

    // MARK: - Border
    static let border        = UIColor(hex: "#e3e2e7")
    static let borderLight   = UIColor(hex: "#c1c6d7")

    // MARK: - Tag / Chip
    static let tagBackground = UIColor(hex: "#eeedf3")

    // MARK: - D-Day (Urgency)
    static let urgentRed     = UIColor(hex: "#ba1a1a")
    static let urgentOrange  = UIColor(hex: "#ff9500")
    static let urgentOrange2 = UIColor(hex: "#fe9400")
    static let urgentGray    = UIColor(hex: "#e3e2e7")

    // MARK: - AI Summary
    static let aiSectionBG = UIColor(hex: "#0070eb").withAlphaComponent(0.1)
    static let aiSectionBorder = UIColor(hex: "#0070eb").withAlphaComponent(0.2)

    // MARK: - Nav / Separator
    static let separator     = UIColor(hex: "#e5e7eb")
    static let navBarBG      = UIColor(hex: "#ffffff").withAlphaComponent(0.8)
}

extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8)  & 0xFF) / 255
        let b = CGFloat(rgb         & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
