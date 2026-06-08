import UIKit
import Combine

final class NotificationsViewController: UIViewController {

    private var viewModel: NotificationsViewModel!
    private var cancellables = Set<AnyCancellable>()
    @IBOutlet private weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = DIContainer.shared.makeNotificationsViewModel()
        setupNavBar()
        setupTableView()
        bindState()
        viewModel.onAction(.viewDidLoad)
    }

    private func setupNavBar() {
        title = "활동"
        view.backgroundColor = AppColor.backgroundSecondary
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupTableView() {
        guard let tableView = tableView else { return }
        tableView.backgroundColor = .clear
        tableView.separatorStyle  = .none
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseID)
        tableView.dataSource = self
        tableView.delegate   = self

        // Header
        let headerView = buildHeaderView()
        tableView.tableHeaderView = headerView
    }

    private func buildHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))

        let titleLbl = UILabel()
        titleLbl.text = "활동"
        titleLbl.font = AppFont.heading2
        titleLbl.textColor = AppColor.textPrimary

        let markBtn = UIButton(type: .system)
        markBtn.setTitle("모두 읽음으로 표시", for: .normal)
        markBtn.titleLabel?.font = AppFont.bodyMedium
        markBtn.tintColor = AppColor.primary
        markBtn.addTarget(self, action: #selector(markAllTapped), for: .touchUpInside)

        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        markBtn.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLbl)
        header.addSubview(markBtn)

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            titleLbl.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            markBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            markBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
        return header
    }

    private func bindState() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView?.reloadData() }
            .store(in: &cancellables)
    }

    @IBAction private func markAllTapped() { viewModel.onAction(.markAllRead) }
}

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseID, for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.state.items[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.onAction(.tapItem(viewModel.state.items[indexPath.row]))
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 150 }
}

// MARK: - NotificationCell
final class NotificationCell: UITableViewCell {
    static let reuseID = "NotificationCell"

    private let cardView   = UIView()
    private let urgentBar  = UIView()
    private let iconView   = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel  = UILabel()
    private let timeLabel  = UILabel()
    private let unreadDot  = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with item: NotificationItem) {
        titleLabel.text = item.title
        bodyLabel.text  = item.body
        timeLabel.text  = item.time
        unreadDot.isHidden = item.isRead
        urgentBar.isHidden = !item.isUrgent
        iconView.backgroundColor = item.isUrgent
            ? AppColor.urgentOrange.withAlphaComponent(0.3)
            : AppColor.primaryLight.withAlphaComponent(0.2)
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = AppColor.background
        cardView.layer.cornerRadius = 8
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColor.border.cgColor
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        urgentBar.backgroundColor = AppColor.urgentOrange
        urgentBar.isHidden = true
        cardView.addSubview(urgentBar)
        urgentBar.translatesAutoresizingMaskIntoConstraints = false

        iconView.layer.cornerRadius = 20
        cardView.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = AppFont.policyTitle
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 2

        bodyLabel.font = AppFont.bodyMedium
        bodyLabel.textColor = AppColor.textSecondary
        bodyLabel.numberOfLines = 2

        timeLabel.font = AppFont.captionSmall
        timeLabel.textColor = AppColor.textTertiary

        unreadDot.backgroundColor = AppColor.urgentOrange2
        unreadDot.layer.cornerRadius = 4
        unreadDot.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, timeLabel])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(textStack)
        cardView.addSubview(unreadDot)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            urgentBar.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 1),
            urgentBar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 1),
            urgentBar.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -1),
            urgentBar.heightAnchor.constraint(equalToConstant: 2),

            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            unreadDot.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            unreadDot.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            unreadDot.widthAnchor.constraint(equalToConstant: 8),
            unreadDot.heightAnchor.constraint(equalToConstant: 8),
        ])
    }
}
