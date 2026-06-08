import UIKit

final class PolicyCardCell: UITableViewCell {
    static let reuseID = "PolicyCardCell"

    // Shadow lives here (masksToBounds = false to show shadow)
    @IBOutlet private weak var shadowContainer: UIView!
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var urgentBar: UIView!
    @IBOutlet private weak var dDayBadge: PaddedLabel!
    @IBOutlet private weak var categoryBadge: PaddedLabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var actionLabel: UILabel!

    private let rippleView = UIView()

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadowPath after layout so the shadow follows the rounded card exactly
        shadowContainer.layer.shadowPath = UIBezierPath(
            roundedRect: shadowContainer.bounds, cornerRadius: 14
        ).cgPath
    }

    func configure(with policy: Policy) {
        titleLabel.text    = policy.name
        descLabel.text     = policy.supportContent
        categoryBadge.text = policy.category
        actionLabel.text   = "상세 보기 ›"

        let hasDeadline = !policy.applyPeriod.trimmingCharacters(in: .whitespaces).isEmpty
        let dDay = policy.dDaysRemaining

        if !hasDeadline {
            dDayBadge.text             = "상시"
            dDayBadge.textColor        = AppColor.textTertiary
            dDayBadge.backgroundColor  = AppColor.tagBackground
            urgentBar.isHidden         = true
            cardView.layer.borderColor = AppColor.border.cgColor
        } else if policy.isExpired {
            dDayBadge.text             = policy.dDayText
            dDayBadge.textColor        = AppColor.urgentRed
            dDayBadge.backgroundColor  = AppColor.urgentRed.withAlphaComponent(0.1)
            urgentBar.backgroundColor  = AppColor.urgentRed
            urgentBar.isHidden         = false
            cardView.layer.borderColor = AppColor.urgentRed.withAlphaComponent(0.4).cgColor
        } else if dDay <= 7 {
            dDayBadge.text             = policy.dDayText
            dDayBadge.textColor        = AppColor.urgentOrange
            dDayBadge.backgroundColor  = AppColor.urgentOrange.withAlphaComponent(0.12)
            urgentBar.backgroundColor  = AppColor.urgentOrange
            urgentBar.isHidden         = false
            cardView.layer.borderColor = AppColor.urgentOrange.withAlphaComponent(0.4).cgColor
        } else {
            dDayBadge.text             = policy.dDayText
            dDayBadge.textColor        = AppColor.textTertiary
            dDayBadge.backgroundColor  = AppColor.tagBackground
            urgentBar.isHidden         = true
            cardView.layer.borderColor = AppColor.border.cgColor
        }
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        guard shadowContainer != nil else { return }

        // Shadow container — no background, shadow only
        shadowContainer.backgroundColor = .clear
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.06
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowContainer.layer.shadowRadius = 8
        shadowContainer.layer.masksToBounds = false

        // Card — clips all children (urgentBar, ripple, etc.)
        cardView.backgroundColor = AppColor.background
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColor.border.cgColor
        cardView.layer.masksToBounds = true

        // Ripple overlay — on top of everything, clipped by cardView
        rippleView.backgroundColor = .clear
        rippleView.isUserInteractionEnabled = false
        rippleView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rippleView)

        NSLayoutConstraint.activate([
            rippleView.topAnchor.constraint(equalTo: cardView.topAnchor),
            rippleView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            rippleView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            rippleView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])
    }

    // MARK: - Ripple
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        addRipple(at: touch.location(in: cardView))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        fadeRipple()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        fadeRipple()
    }

    private func addRipple(at point: CGPoint) {
        rippleView.subviews.forEach { $0.removeFromSuperview() }
        let size = max(cardView.bounds.width, cardView.bounds.height) * 2.5
        let circle = UIView()
        circle.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        circle.layer.cornerRadius = size / 2
        circle.frame = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        circle.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        rippleView.addSubview(circle)
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            circle.transform = .identity
        }
    }

    private func fadeRipple() {
        UIView.animate(withDuration: 0.25, delay: 0.05, options: [.allowUserInteraction]) {
            self.rippleView.subviews.forEach { $0.alpha = 0 }
        } completion: { _ in
            self.rippleView.subviews.forEach { $0.removeFromSuperview() }
        }
    }
}

// MARK: - PaddedLabel
final class PaddedLabel: UILabel {
    var insets: UIEdgeInsets

    init(insets: UIEdgeInsets = .zero) {
        self.insets = insets
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) {
        self.insets = .zero
        super.init(coder: coder)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}
