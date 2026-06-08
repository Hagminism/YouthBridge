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
        // Style static views
        statsCard?.backgroundColor = AppColor.primary
        statsCard?.layer.cornerRadius = 16

        notifCard?.backgroundColor = AppColor.background
        notifCard?.layer.cornerRadius = 16
        notifCard?.layer.borderWidth = 1
        notifCard?.layer.borderColor = AppColor.border.cgColor
        notifToggle?.onTintColor = AppColor.primary

        if let savedCollectionView = savedCollectionView {
            savedCollectionView.backgroundColor = .clear
            savedCollectionView.showsHorizontalScrollIndicator = false
            savedCollectionView.register(SavedPolicyCell.self, forCellWithReuseIdentifier: SavedPolicyCell.reuseID)
            savedCollectionView.dataSource = self
            savedCollectionView.delegate = self
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
