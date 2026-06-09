import UIKit
import Combine

final class MyPageViewController: UIViewController {

    private var viewModel: MyPageViewModel!
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentStack: UIStackView!

    // Identity section (not used storyboard outlets, built programmatically for exact layout match)
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var appNameLabel: UILabel!
    @IBOutlet private weak var appTaglineLabel: UILabel!

    // Card outlets (repurposed for menu-style cards)
    @IBOutlet private weak var statsCard: UIView!
    @IBOutlet private weak var scrappedCountLabel: UILabel!

    // Notification toggle
    @IBOutlet private weak var notifCard: UIView!
    @IBOutlet private weak var notifToggle: UISwitch!

    // Saved policies (repurposed for "Recently Viewed Policies")
    @IBOutlet private weak var savedCollectionView: UICollectionView!
    @IBOutlet private weak var emptyLabel: UILabel!

    private let recentTitleLabel = UILabel()
    private let recentTotalButton = UIButton(type: .system)

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
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
                    let vc = DIContainer.shared.makeDetailViewController(policy: policy)
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .showPermissionAlert:
                    let alert = UIAlertController(
                        title: "알림 권한 필요",
                        message: "알림을 받으려면 시스템 설정에서 알림 권한을 허용해야 합니다. 설정 화면으로 이동하시겠습니까?",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "이동", style: .default) { _ in
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                        }
                    })
                    self?.present(alert, animated: true, completion: nil)
                case .navigateToScrappedList:
                    let vc = DIContainer.shared.makeScrappedPoliciesViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            .store(in: &cancellables)
    }

    private func render(_ state: MyPageState) {
        if let countLabel = scrappedCountLabel {
            let countString = "\(state.scrappedCount)"
            let arrowString = " >"
            let attributedText = NSMutableAttributedString(
                string: countString,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                    .foregroundColor: AppColor.primaryBlue2
                ]
            )
            attributedText.append(NSAttributedString(
                string: arrowString,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: AppColor.textTertiary
                ]
            ))
            countLabel.attributedText = attributedText
        }
        notifToggle?.isOn = state.notificationsEnabled
        savedCollectionView?.reloadData()
        
        let hasRecents = !state.recentViewedPolicies.isEmpty
        emptyLabel?.isHidden = hasRecents
        savedCollectionView?.isHidden = !hasRecents
    }

    private func setupUI() {
        // 스택뷰 레이아웃 설정
        if let heightConstraint = contentStack?.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.isActive = false
        }
        
        if let contentStack = contentStack {
            contentStack.isLayoutMarginsRelativeArrangement = true
            contentStack.layoutMargins = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
            contentStack.spacing = 20
        }
        
        // 1. 프로필/로고 헤더 블록 구성
        buildLogoHeaderSection()

        // 2. "저장한 정책" 메뉴 카드 스타일링
        setupScrappedMenuCard()

        // 3. "푸시 알림 설정" 스위치 카드 스타일링
        setupNotificationSwitchCard()

        // 4. "최근 본 정책" 섹션 스타일링
        setupRecentViewedSection()
    }

    private func buildLogoHeaderSection() {
        guard let contentStack = contentStack else { return }
        
        // 중복 방지 체크
        if contentStack.arrangedSubviews.contains(where: { $0.tag == 999 }) { return }
        
        let headerContainer = UIView()
        headerContainer.tag = 999
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        contentStack.insertArrangedSubview(headerContainer, at: 0)
        
        // 로고 백그라운드 카드 (둥근 정사각형 & 그림자)
        let logoCard = UIView()
        logoCard.backgroundColor = AppColor.background
        logoCard.layer.cornerRadius = 24
        addCardShadow(to: logoCard)
        logoCard.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(logoCard)
        
        // 로고 이미지 (다리 마크)
        let logoImgView = UIImageView(image: UIImage(systemName: "bridge"))
        logoImgView.tintColor = AppColor.primaryBlue2
        logoImgView.contentMode = .scaleAspectFit
        logoImgView.translatesAutoresizingMaskIntoConstraints = false
        logoCard.addSubview(logoImgView)
        
        // 앱 이름 레이블
        let nameLabel = UILabel()
        nameLabel.text = "Youth Bridge"
        nameLabel.textColor = AppColor.primaryBlue2
        nameLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(nameLabel)
        
        // 태그라인 레이블
        let tagLabel = UILabel()
        tagLabel.text = "청년들을 위한 정책 브릿지"
        tagLabel.textColor = AppColor.textTertiary
        tagLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        tagLabel.textAlignment = .center
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(tagLabel)
        
        NSLayoutConstraint.activate([
            headerContainer.heightAnchor.constraint(equalToConstant: 200),
            
            logoCard.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            logoCard.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 10),
            logoCard.widthAnchor.constraint(equalToConstant: 80),
            logoCard.heightAnchor.constraint(equalToConstant: 80),
            
            logoImgView.centerXAnchor.constraint(equalTo: logoCard.centerXAnchor),
            logoImgView.centerYAnchor.constraint(equalTo: logoCard.centerYAnchor),
            logoImgView.widthAnchor.constraint(equalToConstant: 46),
            logoImgView.heightAnchor.constraint(equalToConstant: 46),
            
            nameLabel.topAnchor.constraint(equalTo: logoCard.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            
            tagLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            tagLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            tagLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor)
        ])
    }

    private func setupScrappedMenuCard() {
        guard let statsCard = statsCard else { return }
        statsCard.translatesAutoresizingMaskIntoConstraints = false
        statsCard.backgroundColor = AppColor.background
        statsCard.layer.cornerRadius = 16
        statsCard.layer.borderWidth = 0
        addCardShadow(to: statsCard)
        
        // 터치 제스처 추가
        let tap = UITapGestureRecognizer(target: self, action: #selector(scrappedCardTapped))
        statsCard.addGestureRecognizer(tap)
        
        // 내부 컴포넌트들 재배치 및 동적 생성
        statsCard.subviews.forEach { $0.removeFromSuperview() }
        
        // 왼쪽 파란색 배경 아이콘 컨테이너
        let iconBg = UIView()
        iconBg.backgroundColor = AppColor.primaryBlue2.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 20
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(iconBg)
        
        let bookmarkIcon = UIImageView(image: UIImage(systemName: "bookmark.fill"))
        bookmarkIcon.tintColor = AppColor.primaryBlue2
        bookmarkIcon.contentMode = .scaleAspectFit
        bookmarkIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(bookmarkIcon)
        
        // 중앙 타이틀 및 서브 타이틀
        let titleLabel = UILabel()
        titleLabel.text = "저장한 정책"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "북마크한 청년 정책 모아보기"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = AppColor.textTertiary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(subtitleLabel)
        
        // 우측 개수 레이블
        scrappedCountLabel = UILabel()
        scrappedCountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        scrappedCountLabel.textColor = AppColor.primary
        scrappedCountLabel.textAlignment = .right
        scrappedCountLabel.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(scrappedCountLabel)
        
        NSLayoutConstraint.activate([
            statsCard.heightAnchor.constraint(equalToConstant: 76),
            
            iconBg.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 16),
            iconBg.centerYAnchor.constraint(equalTo: statsCard.centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),
            
            bookmarkIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            bookmarkIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            bookmarkIcon.widthAnchor.constraint(equalToConstant: 20),
            bookmarkIcon.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: scrappedCountLabel.leadingAnchor, constant: -8),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(equalTo: scrappedCountLabel.leadingAnchor, constant: -8),
            
            scrappedCountLabel.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -20),
            scrappedCountLabel.centerYAnchor.constraint(equalTo: statsCard.centerYAnchor),
            scrappedCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }

    private func setupNotificationSwitchCard() {
        guard let notifCard = notifCard else { return }
        notifCard.translatesAutoresizingMaskIntoConstraints = false
        notifCard.backgroundColor = AppColor.background
        notifCard.layer.cornerRadius = 16
        notifCard.layer.borderWidth = 0
        addCardShadow(to: notifCard)
        
        notifCard.subviews.forEach { if $0 != notifToggle { $0.removeFromSuperview() } }
        
        // 왼쪽 연파란색 배경 아이콘 컨테이너
        let iconBg = UIView()
        iconBg.backgroundColor = AppColor.primaryBlue2.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 20
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        notifCard.addSubview(iconBg)
        
        let bellIcon = UIImageView(image: UIImage(systemName: "bell.fill"))
        bellIcon.tintColor = AppColor.primaryBlue2
        bellIcon.contentMode = .scaleAspectFit
        bellIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(bellIcon)
        
        // 중앙 타이틀 및 서브 타이틀
        let titleLabel = UILabel()
        titleLabel.text = "푸시 알림 설정"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        notifCard.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "마감 임박 및 정책 업데이트 알림"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = AppColor.textTertiary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        notifCard.addSubview(subtitleLabel)
        
        if let notifToggle = notifToggle {
            notifToggle.translatesAutoresizingMaskIntoConstraints = false
            notifToggle.onTintColor = AppColor.primaryBlue2
            notifToggle.addTarget(self, action: #selector(notifToggleChanged), for: .valueChanged)
            notifCard.addSubview(notifToggle)
            
            NSLayoutConstraint.activate([
                notifToggle.trailingAnchor.constraint(equalTo: notifCard.trailingAnchor, constant: -20),
                notifToggle.centerYAnchor.constraint(equalTo: notifCard.centerYAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            notifCard.heightAnchor.constraint(equalToConstant: 76),
            
            iconBg.leadingAnchor.constraint(equalTo: notifCard.leadingAnchor, constant: 16),
            iconBg.centerYAnchor.constraint(equalTo: notifCard.centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),
            
            bellIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            bellIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            bellIcon.widthAnchor.constraint(equalToConstant: 20),
            bellIcon.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.topAnchor.constraint(equalTo: notifCard.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: notifToggle?.leadingAnchor ?? notifCard.trailingAnchor, constant: -8),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(equalTo: notifToggle?.leadingAnchor ?? notifCard.trailingAnchor, constant: -8)
        ])
    }

    private func setupRecentViewedSection() {
        guard let savedCollectionView = savedCollectionView else { return }
        guard let container = savedCollectionView.superview else { return }
        
        container.translatesAutoresizingMaskIntoConstraints = false
        savedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // 컨테이너 스타일링 (테두리/배경 해제, 투명 처리)
        container.backgroundColor = .clear
        container.layer.borderWidth = 0
        container.subviews.forEach { if $0 != savedCollectionView && $0 != emptyLabel { $0.removeFromSuperview() } }
        
        // 헤더 타이틀 "최근 본 정책"
        recentTitleLabel.text = "최근 본 정책"
        recentTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        recentTitleLabel.textColor = AppColor.textPrimary
        recentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(recentTitleLabel)
        
        // 우측 "전체보기" 버튼
        recentTotalButton.setTitle("전체보기", for: .normal)
        recentTotalButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        recentTotalButton.setTitleColor(AppColor.primaryBlue2, for: .normal)
        recentTotalButton.tintColor = AppColor.primaryBlue2
        recentTotalButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(recentTotalButton)
        
        if let emptyLabel = emptyLabel {
            emptyLabel.text = "최근 본 정책이 없습니다."
            emptyLabel.font = AppFont.bodyMedium
            emptyLabel.textColor = AppColor.textTertiary
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(emptyLabel)
            
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                emptyLabel.topAnchor.constraint(equalTo: recentTitleLabel.bottomAnchor, constant: 60)
            ])
        }
        
        // 컬렉션 뷰 설정 (가로 스크롤)
        savedCollectionView.backgroundColor = .clear
        savedCollectionView.showsHorizontalScrollIndicator = false
        savedCollectionView.register(RecentPolicyCell.self, forCellWithReuseIdentifier: RecentPolicyCell.reuseID)
        savedCollectionView.dataSource = self
        savedCollectionView.delegate = self
        
        if let layout = savedCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 12
            layout.minimumLineSpacing = 12
        }
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 240),
            
            recentTitleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            recentTitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            recentTotalButton.centerYAnchor.constraint(equalTo: recentTitleLabel.centerYAnchor),
            recentTotalButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            savedCollectionView.topAnchor.constraint(equalTo: recentTitleLabel.bottomAnchor, constant: 12),
            savedCollectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            savedCollectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            savedCollectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func addCardShadow(to view: UIView) {
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
    }

    @objc private func scrappedCardTapped() {
        guard let statsCard = statsCard else { return }
        UIView.animate(withDuration: 0.1, animations: {
            statsCard.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                statsCard.transform = .identity
            }
            self.viewModel.onAction(.tapScrappedListCard)
        }
    }

    @objc @IBAction private func notifToggleChanged() {
        guard let notifToggle = notifToggle else { return }
        viewModel.onAction(.toggleNotifications(notifToggle.isOn))
    }
}

// MARK: - UICollectionViewDataSource/Delegate
extension MyPageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.state.recentViewedPolicies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentPolicyCell.reuseID, for: indexPath) as? RecentPolicyCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: viewModel.state.recentViewedPolicies[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.onAction(.tapPolicy(viewModel.state.recentViewedPolicies[indexPath.item]))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 140, height: 176)
    }
}

// MARK: - RecentPolicyCell
final class RecentPolicyCell: UICollectionViewCell {
    static let reuseID = "RecentPolicyCell"

    private let cardView = UIView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with policy: Policy) {
        titleLabel.text = policy.name
        categoryLabel.text = policy.category
        
        let color: UIColor
        let iconName: String
        switch policy.category {
        case "일자리":
            color = UIColor(hex: "#2563eb")
            iconName = "doc.text.fill"
        case "주거":
            color = UIColor(hex: "#10b981")
            iconName = "mappin.and.ellipse"
        case "건강·복지", "복지":
            color = UIColor(hex: "#ef4444")
            iconName = "heart.fill"
        case "교육":
            color = UIColor(hex: "#f59e0b")
            iconName = "book.fill"
        case "문화·예술", "문화":
            color = UIColor(hex: "#8b5cf6")
            iconName = "guitars.fill"
        default:
            color = UIColor(hex: "#6b7280")
            iconName = "sparkles"
        }
        
        categoryLabel.textColor = color
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = AppColor.textTertiary
        iconContainer.backgroundColor = AppColor.backgroundTertiary
    }

    private func setup() {
        cardView.backgroundColor = AppColor.background
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColor.border.cgColor
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        iconContainer.layer.cornerRadius = 12
        iconContainer.clipsToBounds = true
        cardView.addSubview(iconContainer)
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        categoryLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        cardView.addSubview(categoryLabel)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 2
        cardView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            iconContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            iconContainer.heightAnchor.constraint(equalToConstant: 76),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 26),

            categoryLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 10),
            categoryLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            categoryLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            titleLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -10)
        ])
    }
}
