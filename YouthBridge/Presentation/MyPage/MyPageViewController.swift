import UIKit
import Combine

final class MyPageViewController: UIViewController {

    private var viewModel: MyPageViewModel!
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Identity section
    private let logoImageView = UIImageView()
    private let appNameLabel = UILabel()
    private let appTaglineLabel = UILabel()

    // Stats section
    private let statsCard = UIView()
    private let scrappedCountLabel = UILabel()

    // Notification toggle
    private let notifCard = UIView()
    private let notifToggle = UISwitch()

    // Saved policies
    private let savedSectionLabel = UILabel()
    private let savedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 200, height: 120)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = DIContainer.shared.makeMyPageViewModel()
        setupNavBar()
        setupUI()
        bindState()
        bindEffect()
        viewModel.onAction(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.onAction(.viewDidLoad)
    }

    private func setupNavBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = AppColor.backgroundSecondary
    }

    private func bindState() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    private func bindEffect() {
        viewModel.effect
            .receive(on: DispatchQueue.main)
            .sink { [weak self] effect in
                switch effect {
                case .navigateToDetail(let policy):
                    let vc = DetailViewController(policy: policy)
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            .store(in: &cancellables)
    }

    private func render(_ state: MyPageState) {
        scrappedCountLabel.text = "저장한 정책 \(state.scrappedCount)개"
        notifToggle.isOn = state.notificationsEnabled
        savedCollectionView.reloadData()
        emptyLabel.isHidden = !state.scrappedPolicies.isEmpty
        savedCollectionView.isHidden = state.scrappedPolicies.isEmpty
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        buildIdentitySection()
        buildStatsSection()
        buildNotifSection()
        buildSavedSection()
    }

    private func buildIdentitySection() {
        let container = UIView()
        container.backgroundColor = AppColor.background
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = AppColor.border.cgColor

        let iconBg = UIView()
        iconBg.backgroundColor = AppColor.primary.withAlphaComponent(0.1)
        iconBg.layer.cornerRadius = 24
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let bridgeIcon = UIImageView(image: UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90"))
        bridgeIcon.tintColor = AppColor.primary
        bridgeIcon.contentMode = .scaleAspectFit
        bridgeIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(bridgeIcon)

        appNameLabel.text = "Youth Bridge"
        appNameLabel.font = AppFont.logoTitle
        appNameLabel.textColor = AppColor.primary

        appTaglineLabel.text = "청년들을 위한 정책 브릿지"
        appTaglineLabel.font = AppFont.bodyMedium
        appTaglineLabel.textColor = AppColor.textSecondary

        let textStack = UIStackView(arrangedSubviews: [appNameLabel, appTaglineLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let hStack = UIStackView(arrangedSubviews: [iconBg, textStack])
        hStack.axis = .horizontal
        hStack.spacing = 16
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hStack)

        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 48),
            iconBg.heightAnchor.constraint(equalToConstant: 48),
            bridgeIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            bridgeIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            bridgeIcon.widthAnchor.constraint(equalToConstant: 24),
            bridgeIcon.heightAnchor.constraint(equalToConstant: 24),

            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        ])

        let wrapper = paddedHorizontally(container)
        contentStack.addArrangedSubview(wrapper)
    }

    private func buildStatsSection() {
        statsCard.backgroundColor = AppColor.primary
        statsCard.layer.cornerRadius = 16

        let iconView = UIImageView(image: UIImage(systemName: "bookmark.fill"))
        iconView.tintColor = .white.withAlphaComponent(0.8)
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        scrappedCountLabel.text = "저장한 정책 0개"
        scrappedCountLabel.font = AppFont.heading2
        scrappedCountLabel.textColor = .white

        let subLabel = UILabel()
        subLabel.text = "저장한 정책을 아래에서 확인하세요"
        subLabel.font = AppFont.captionSmall
        subLabel.textColor = .white.withAlphaComponent(0.8)

        let textStack = UIStackView(arrangedSubviews: [scrappedCountLabel, subLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let hStack = UIStackView(arrangedSubviews: [iconView, textStack])
        hStack.axis = .horizontal
        hStack.spacing = 16
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(hStack)
        statsCard.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 20),
            hStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -20),
            hStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -20),
        ])

        contentStack.addArrangedSubview(paddedHorizontally(statsCard))
    }

    private func buildNotifSection() {
        notifCard.backgroundColor = AppColor.background
        notifCard.layer.cornerRadius = 16
        notifCard.layer.borderWidth = 1
        notifCard.layer.borderColor = AppColor.border.cgColor

        let iconView = UIImageView(image: UIImage(systemName: "bell.fill"))
        iconView.tintColor = AppColor.primary
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLbl = UILabel()
        titleLbl.text = "마감 알림"
        titleLbl.font = AppFont.policyTitle
        titleLbl.textColor = AppColor.textPrimary

        let subLbl = UILabel()
        subLbl.text = "저장한 정책 마감 7일 전 알림"
        subLbl.font = AppFont.captionSmall
        subLbl.textColor = AppColor.textSecondary

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        textStack.axis = .vertical
        textStack.spacing = 2

        notifToggle.onTintColor = AppColor.primary
        notifToggle.addTarget(self, action: #selector(notifToggleChanged), for: .valueChanged)

        let hStack = UIStackView(arrangedSubviews: [iconView, textStack, UIView(), notifToggle])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        notifCard.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: notifCard.topAnchor, constant: 16),
            hStack.leadingAnchor.constraint(equalTo: notifCard.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: notifCard.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: notifCard.bottomAnchor, constant: -16),
        ])

        contentStack.addArrangedSubview(paddedHorizontally(notifCard))
    }

    private func buildSavedSection() {
        savedSectionLabel.text = "저장한 정책"
        savedSectionLabel.font = AppFont.heading2
        savedSectionLabel.textColor = AppColor.textPrimary
        savedSectionLabel.translatesAutoresizingMaskIntoConstraints = false

        let labelWrapper = UIView()
        labelWrapper.addSubview(savedSectionLabel)
        NSLayoutConstraint.activate([
            savedSectionLabel.topAnchor.constraint(equalTo: labelWrapper.topAnchor),
            savedSectionLabel.leadingAnchor.constraint(equalTo: labelWrapper.leadingAnchor, constant: 16),
            savedSectionLabel.trailingAnchor.constraint(equalTo: labelWrapper.trailingAnchor, constant: -16),
            savedSectionLabel.bottomAnchor.constraint(equalTo: labelWrapper.bottomAnchor),
        ])
        contentStack.addArrangedSubview(labelWrapper)

        savedCollectionView.backgroundColor = .clear
        savedCollectionView.showsHorizontalScrollIndicator = false
        savedCollectionView.register(SavedPolicyCell.self, forCellWithReuseIdentifier: SavedPolicyCell.reuseID)
        savedCollectionView.dataSource = self
        savedCollectionView.delegate = self
        savedCollectionView.heightAnchor.constraint(equalToConstant: 132).isActive = true
        contentStack.addArrangedSubview(savedCollectionView)

        emptyLabel.text = "저장한 정책이 없습니다.\n홈에서 정책을 탐색하고 북마크해보세요!"
        emptyLabel.font = AppFont.body
        emptyLabel.textColor = AppColor.textTertiary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        contentStack.addArrangedSubview(paddedHorizontally(emptyLabel))
    }

    private func paddedHorizontally(_ view: UIView) -> UIView {
        let wrapper = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    @objc private func notifToggleChanged() {
        viewModel.onAction(.toggleNotifications(notifToggle.isOn))
    }
}

// MARK: - UICollectionViewDataSource/Delegate
extension MyPageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.state.scrappedPolicies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SavedPolicyCell.reuseID, for: indexPath) as? SavedPolicyCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: viewModel.state.scrappedPolicies[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.onAction(.tapPolicy(viewModel.state.scrappedPolicies[indexPath.item]))
    }
}

// MARK: - SavedPolicyCell
final class SavedPolicyCell: UICollectionViewCell {
    static let reuseID = "SavedPolicyCell"

    private let cardView = UIView()
    private let dDayLabel = UILabel()
    private let titleLabel = UILabel()
    private let orgLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with policy: Policy) {
        dDayLabel.text = policy.dDayText
        dDayLabel.textColor = policy.isUrgent ? AppColor.urgentRed : AppColor.textSecondary
        titleLabel.text = policy.name
        orgLabel.text = policy.operatingOrg
    }

    private func setup() {
        cardView.backgroundColor = AppColor.background
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColor.border.cgColor
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        dDayLabel.font = AppFont.captionSmall
        titleLabel.font = AppFont.bodyMedium
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 2
        orgLabel.font = AppFont.captionSmall
        orgLabel.textColor = AppColor.textSecondary

        let stack = UIStackView(arrangedSubviews: [dDayLabel, titleLabel, orgLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -14),
        ])
    }
}
