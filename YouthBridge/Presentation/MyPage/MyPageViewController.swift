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
        
        // 각 카드 뷰의 Auto Layout 활성화 (translatesAutoresizingMaskIntoConstraints = false)
        statsCard?.translatesAutoresizingMaskIntoConstraints = false
        notifCard?.translatesAutoresizingMaskIntoConstraints = false
        
        if let statsCard = statsCard {
            statsCard.backgroundColor = AppColor.primary
            statsCard.layer.cornerRadius = 16
            
            // statsCard 내부 레이블 오토레이아웃 설정 보정
            if let scrappedCountLabel = scrappedCountLabel {
                scrappedCountLabel.translatesAutoresizingMaskIntoConstraints = false
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
            
            // "알림 설정" 등의 내부 레이블이 있다면 오토레이아웃 보정
            if let label = notifCard.subviews.first(where: { $0 is UILabel }) as? UILabel {
                label.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: notifCard.leadingAnchor, constant: 20),
                    label.centerYAnchor.constraint(equalTo: notifCard.centerYAnchor)
                ])
            }
        }

        if let savedCollectionView = savedCollectionView {
            if let savedContainer = savedCollectionView.superview {
                savedContainer.translatesAutoresizingMaskIntoConstraints = false
                savedCollectionView.translatesAutoresizingMaskIntoConstraints = false
                
                // container 내의 타이틀 레이블(savedSectionLabel)과 emptyLabel 오토레이아웃 보정
                if let savedSectionLabel = savedSectionLabel {
                    savedSectionLabel.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        savedSectionLabel.topAnchor.constraint(equalTo: savedContainer.topAnchor, constant: 16),
                        savedSectionLabel.leadingAnchor.constraint(equalTo: savedContainer.leadingAnchor, constant: 16)
                    ])
                }
                
                if let emptyLabel = emptyLabel {
                    emptyLabel.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        emptyLabel.centerXAnchor.constraint(equalTo: savedContainer.centerXAnchor),
                        emptyLabel.centerYAnchor.constraint(equalTo: savedContainer.centerYAnchor)
                    ])
                }
                
                NSLayoutConstraint.activate([
                    savedCollectionView.topAnchor.constraint(equalTo: savedSectionLabel?.bottomAnchor ?? savedContainer.topAnchor, constant: 12),
                    savedCollectionView.leadingAnchor.constraint(equalTo: savedContainer.leadingAnchor, constant: 16),
                    savedCollectionView.trailingAnchor.constraint(equalTo: savedContainer.trailingAnchor, constant: -16),
                    savedCollectionView.bottomAnchor.constraint(equalTo: savedContainer.bottomAnchor, constant: -16),
                    savedContainer.heightAnchor.constraint(equalToConstant: 280)
                ])
            }
            
            savedCollectionView.backgroundColor = .clear
            savedCollectionView.showsHorizontalScrollIndicator = false
            savedCollectionView.register(SavedPolicyCell.self, forCellWithReuseIdentifier: SavedPolicyCell.reuseID)
            savedCollectionView.dataSource = self
            savedCollectionView.delegate = self
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
