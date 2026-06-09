import UIKit
import Combine

final class MyPageViewController: UIViewController {

    private var viewModel: MyPageViewModel!
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentStack: UIStackView!

    // Identity section
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var appNameLabel: UILabel!
    @IBOutlet private weak var appTaglineLabel: UILabel!

    // Stats section
    @IBOutlet private weak var statsCard: UIView!
    @IBOutlet private weak var scrappedCountLabel: UILabel!

    // Notification toggle
    @IBOutlet private weak var notifCard: UIView!
    @IBOutlet private weak var notifToggle: UISwitch!

    // Saved policies
    @IBOutlet private weak var savedSectionLabel: UILabel!
    @IBOutlet private weak var savedCollectionView: UICollectionView!
    @IBOutlet private weak var emptyLabel: UILabel!

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
                }
            }
            .store(in: &cancellables)
    }

    private func render(_ state: MyPageState) {
        scrappedCountLabel?.text = "저장한 정책 \(state.scrappedCount)개"
        notifToggle?.isOn = state.notificationsEnabled
        savedCollectionView?.reloadData()
        emptyLabel?.isHidden = !state.scrappedPolicies.isEmpty
        savedCollectionView?.isHidden = state.scrappedPolicies.isEmpty
    }

    private func setupUI() {
        // 스택뷰 자체의 높이 고정 제약조건(height = 600)을 해제하여 내부 콘텐츠에 맞게 가변적으로 늘어나게 설정
        if let heightConstraint = contentStack?.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.isActive = false
        }
        
        // 스택뷰 레이아웃 마진 설정으로 양옆 16pt, 상단 24pt, 하단 24pt 여백 부여 (상태바 침범 방지 및 좌우 여백 확보)
        if let contentStack = contentStack {
            contentStack.isLayoutMarginsRelativeArrangement = true
            contentStack.layoutMargins = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
            contentStack.spacing = 16
            
            // "마이페이지" 상단 타이틀 레이블 동적 추가 (중복 방지)
            if !contentStack.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "마이페이지" }) {
                let headerTitleLabel = UILabel()
                headerTitleLabel.text = "마이페이지"
                headerTitleLabel.font = AppFont.heading1
                headerTitleLabel.textColor = AppColor.textPrimary
                contentStack.insertArrangedSubview(headerTitleLabel, at: 0)
            }
        }
        
        // 각 카드 뷰의 Auto Layout 활성화 (translatesAutoresizingMaskIntoConstraints = false)
        statsCard?.translatesAutoresizingMaskIntoConstraints = false
        notifCard?.translatesAutoresizingMaskIntoConstraints = false
        
        if let statsCard = statsCard {
            statsCard.backgroundColor = AppColor.primary
            statsCard.layer.cornerRadius = 16
            
            // statsCard 내부 레이블 오토레이아웃 설정 보정
            if let scrappedCountLabel = scrappedCountLabel {
                scrappedCountLabel.translatesAutoresizingMaskIntoConstraints = false
                scrappedCountLabel.textColor = .white
                scrappedCountLabel.font = AppFont.heading2
                NSLayoutConstraint.activate([
                    scrappedCountLabel.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 20),
                    scrappedCountLabel.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -20),
                    scrappedCountLabel.centerYAnchor.constraint(equalTo: statsCard.centerYAnchor)
                ])
            }
        }

        if let notifCard = notifCard {
            notifCard.backgroundColor = AppColor.background
            notifCard.layer.cornerRadius = 16
            notifCard.layer.borderWidth = 1
            notifCard.layer.borderColor = AppColor.border.cgColor
            
            // notifCard 내부 토글 오토레이아웃 설정 보정
            if let notifToggle = notifToggle {
                notifToggle.translatesAutoresizingMaskIntoConstraints = false
                notifToggle.onTintColor = AppColor.primary
                
                NSLayoutConstraint.activate([
                    notifToggle.trailingAnchor.constraint(equalTo: notifCard.trailingAnchor, constant: -20),
                    notifToggle.centerYAnchor.constraint(equalTo: notifCard.centerYAnchor)
                ])
            }
            
            // "알림 설정" 타이틀 레이블 동적 생성 및 추가
            let notifLabel = UILabel()
            notifLabel.text = "알림 설정"
            notifLabel.font = AppFont.heading2
            notifLabel.textColor = AppColor.textPrimary
            notifLabel.translatesAutoresizingMaskIntoConstraints = false
            notifCard.addSubview(notifLabel)
            
            NSLayoutConstraint.activate([
                notifLabel.leadingAnchor.constraint(equalTo: notifCard.leadingAnchor, constant: 20),
                notifLabel.centerYAnchor.constraint(equalTo: notifCard.centerYAnchor)
            ])
        }

        if let savedCollectionView = savedCollectionView {
            if let savedContainer = savedCollectionView.superview {
                savedContainer.translatesAutoresizingMaskIntoConstraints = false
                savedCollectionView.translatesAutoresizingMaskIntoConstraints = false
                
                // container 스타일 지정 (카드 형태로 배경 및 테두리 설정)
                savedContainer.backgroundColor = AppColor.background
                savedContainer.layer.cornerRadius = 16
                savedContainer.layer.borderWidth = 1
                savedContainer.layer.borderColor = AppColor.border.cgColor
                
                // "저장된 정책" 타이틀 레이블 동적 생성 및 추가
                let titleLabel = UILabel()
                titleLabel.text = "저장된 정책"
                titleLabel.font = AppFont.heading2
                titleLabel.textColor = AppColor.textPrimary
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                savedContainer.addSubview(titleLabel)
                
                if let emptyLabel = emptyLabel {
                    emptyLabel.text = "저장한 정책이 없습니다."
                    emptyLabel.font = AppFont.bodyMedium
                    emptyLabel.textColor = AppColor.textTertiary
                    emptyLabel.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        emptyLabel.centerXAnchor.constraint(equalTo: savedContainer.centerXAnchor),
                        emptyLabel.centerYAnchor.constraint(equalTo: savedContainer.centerYAnchor)
                    ])
                }
                
                NSLayoutConstraint.activate([
                    titleLabel.topAnchor.constraint(equalTo: savedContainer.topAnchor, constant: 20),
                    titleLabel.leadingAnchor.constraint(equalTo: savedContainer.leadingAnchor, constant: 20),
                    
                    savedCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
                    savedCollectionView.leadingAnchor.constraint(equalTo: savedContainer.leadingAnchor, constant: 20),
                    savedCollectionView.trailingAnchor.constraint(equalTo: savedContainer.trailingAnchor, constant: -20),
                    savedCollectionView.bottomAnchor.constraint(equalTo: savedContainer.bottomAnchor, constant: -20),
                    savedContainer.heightAnchor.constraint(equalToConstant: 280)
                ])
            }
            
            savedCollectionView.backgroundColor = .clear
            savedCollectionView.showsHorizontalScrollIndicator = false
            savedCollectionView.register(SavedPolicyCell.self, forCellWithReuseIdentifier: SavedPolicyCell.reuseID)
            savedCollectionView.dataSource = self
            savedCollectionView.delegate = self
            
            if let layout = savedCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = 12
                layout.minimumLineSpacing = 12
            }
        }
        
        // 스택뷰 내부 카드 뷰들의 높이 제약조건 활성화
        if let statsCard = statsCard, let notifCard = notifCard {
            NSLayoutConstraint.activate([
                statsCard.heightAnchor.constraint(equalToConstant: 100),
                notifCard.heightAnchor.constraint(equalToConstant: 80)
            ])
        }
    }

    @IBAction private func notifToggleChanged() {
        guard let notifToggle = notifToggle else { return }
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
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

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

// MARK: - UICollectionViewDelegateFlowLayout
extension MyPageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 12) / 2
        return CGSize(width: width, height: 96)
    }
}
