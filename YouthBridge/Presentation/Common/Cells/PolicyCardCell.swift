import UIKit

final class PolicyCardCell: UITableViewCell {
    static let reuseID = "PolicyCardCell"

    // Shadow lives here (masksToBounds = false to show shadow)
    private let shadowContainer = UIView()
    // Content lives here (masksToBounds = true to clip urgentBar + ripple)
    private let cardView        = UIView()
    private let urgentBar       = UIView()
    private let rippleView      = UIView()
    private let dDayBadge       = PaddedLabel(insets: UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
    private let categoryBadge   = PaddedLabel(insets: UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
    private let titleLabel      = UILabel()
    private let descLabel       = UILabel()
    private let actionLabel     = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
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

        // Shadow container — no background, shadow only
        shadowContainer.backgroundColor = .clear
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.06
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowContainer.layer.shadowRadius = 8
        shadowContainer.layer.masksToBounds = false
        contentView.addSubview(shadowContainer)
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false

        // Card — clips all children (urgentBar, ripple, etc.)
        cardView.backgroundColor = AppColor.background
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColor.border.cgColor
        cardView.layer.masksToBounds = true
        shadowContainer.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Urgent bar — straight edges will be clipped by cardView's corner radius
        urgentBar.isHidden = true
        cardView.addSubview(urgentBar)
        urgentBar.translatesAutoresizingMaskIntoConstraints = false

        // D-Day badge
        dDayBadge.font = AppFont.dDayBadge
        dDayBadge.layer.cornerRadius = 6
        dDayBadge.clipsToBounds = true
        dDayBadge.textAlignment = .center
        dDayBadge.setContentHuggingPriority(.required, for: .horizontal)
        dDayBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Category badge
        categoryBadge.font = AppFont.categoryBadge
        categoryBadge.textColor = AppColor.textTertiary
        categoryBadge.backgroundColor = AppColor.tagBackground
        categoryBadge.layer.cornerRadius = 5
        categoryBadge.clipsToBounds = true
        categoryBadge.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // Title
        titleLabel.font = AppFont.policyTitle
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 2

        // Desc
        descLabel.font = AppFont.caption
        descLabel.textColor = AppColor.textSecondary
        descLabel.numberOfLines = 2

        // Action
        actionLabel.font = AppFont.bodyMedium
        actionLabel.textColor = AppColor.primary

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let badgeRow = UIStackView(arrangedSubviews: [dDayBadge, spacer, categoryBadge])
        badgeRow.axis = .horizontal
        badgeRow.spacing = 6
        badgeRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [badgeRow, titleLabel, descLabel, actionLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stack)

        // Ripple overlay — on top of everything, clipped by cardView
        rippleView.backgroundColor = .clear
        rippleView.isUserInteractionEnabled = false
        rippleView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rippleView)

        NSLayoutConstraint.activate([
            shadowContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            shadowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shadowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            shadowContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            cardView.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor),

            urgentBar.topAnchor.constraint(equalTo: cardView.topAnchor),
            urgentBar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            urgentBar.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            urgentBar.heightAnchor.constraint(equalToConstant: 3),

            stack.topAnchor.constraint(equalTo: urgentBar.bottomAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

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
