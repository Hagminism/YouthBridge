import UIKit
import Combine

final class HomeViewController: UIViewController {

    private var viewModel: HomeViewModel!
    private var cancellables = Set<AnyCancellable>()

    private let tableView         = UITableView()
    private let refreshControl    = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let footerSpinner     = UIActivityIndicatorView(style: .medium)

    private let logoLabel    = UILabel()
    private let searchBar    = UIView()
    private let searchLabel  = UILabel()
    private let filterButton = UIButton(type: .system)
    private let sectionLabel = UILabel()

    // Keep a reference so tableView can be constrained to it
    private var headerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = DIContainer.shared.makeHomeViewModel()
        setupUI()
        bindState()
        bindEffect()
        viewModel.onAction(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Bind

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
                guard let self else { return }
                switch effect {
                case .navigateToSearch:
                    let vc = SearchViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                case .navigateToFilter(let current):
                    let vc = FilterViewController(currentFilter: current)
                    vc.onApply = { [weak self] filter in
                        self?.viewModel.onAction(.applyFilter(filter))
                    }
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .pageSheet
                    if let sheet = nav.sheetPresentationController {
                        sheet.detents = [.large()]
                        sheet.prefersGrabberVisible = true
                    }
                    self.present(nav, animated: true)
                case .navigateToDetail(let policy):
                    let vc = DetailViewController(policy: policy)
                    self.navigationController?.pushViewController(vc, animated: true)
                case .showError(let msg):
                    self.showAlert(msg)
                }
            }
            .store(in: &cancellables)
    }

    private func render(_ state: HomeState) {
        if state.isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            refreshControl.endRefreshing()
        }

        if state.isLoadingMore {
            footerSpinner.startAnimating()
        } else {
            footerSpinner.stopAnimating()
        }

        let policies = state.displayPolicies
        let urgentCount = policies.filter { $0.isUrgent }.count
        let total = policies.count
        if urgentCount > 0 {
            sectionLabel.text = "전체 정책 \(total)건 · 마감 임박 \(urgentCount)건"
        } else {
            sectionLabel.text = total > 0 ? "전체 정책 \(total)건" : "전체 정책"
        }

        tableView.reloadData()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = AppColor.backgroundSecondary
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupTopBar()
        setupTableView()
        setupActivityIndicator()
    }

    private func setupTopBar() {
        let header = UIView()
        header.backgroundColor = AppColor.background
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        headerView = header

        let border = UIView()
        border.backgroundColor = AppColor.border
        border.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(border)

        // Logo
        logoLabel.text = "Youth Bridge"
        logoLabel.font = AppFont.logoTitle
        logoLabel.textColor = AppColor.primary
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(logoLabel)

        // Search bar
        searchBar.backgroundColor = AppColor.backgroundSecondary
        searchBar.layer.cornerRadius = 12
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = AppColor.border.cgColor
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(searchBar)

        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = AppColor.textTertiary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.addSubview(iconView)

        searchLabel.text = "정책 이름이나 키워드를 검색하세요"
        searchLabel.font = AppFont.body
        searchLabel.textColor = AppColor.textDisabled
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchBar.addSubview(searchLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(searchBarTapped))
        searchBar.addGestureRecognizer(tap)

        // Filter button
        filterButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        filterButton.tintColor = AppColor.textSecondary
        filterButton.backgroundColor = AppColor.backgroundSecondary
        filterButton.layer.cornerRadius = 12
        filterButton.layer.borderWidth = 1
        filterButton.layer.borderColor = AppColor.border.cgColor
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(filterButton)

        // Section label — INSIDE header so it stays fixed with the header
        sectionLabel.text = "전체 정책"
        sectionLabel.font = AppFont.heading2
        sectionLabel.textColor = AppColor.textPrimary
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(sectionLabel)

        NSLayoutConstraint.activate([
            // Header: top of screen → grows to fit content
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.bottomAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 12),

            border.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            border.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5),

            logoLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            searchBar.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: filterButton.leadingAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            iconView.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 17),
            iconView.heightAnchor.constraint(equalToConstant: 17),

            searchLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            searchLabel.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -12),
            searchLabel.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),

            filterButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            filterButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 44),
            filterButton.heightAnchor.constraint(equalToConstant: 44),

            sectionLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            sectionLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            sectionLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
        ])
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle  = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(PolicyCardCell.self, forCellReuseIdentifier: PolicyCardCell.reuseID)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = AppColor.primary
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Bring header above tableView
        view.bringSubviewToFront(headerView)

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 56))
        footerSpinner.color = AppColor.primary
        footerSpinner.hidesWhenStopped = true
        footerSpinner.center = CGPoint(x: footer.bounds.midX, y: footer.bounds.midY)
        footer.addSubview(footerSpinner)
        tableView.tableFooterView = footer

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppColor.primary
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func searchBarTapped() { viewModel.onAction(.tapSearchBar) }
    @objc private func filterTapped()    { viewModel.onAction(.tapFilter) }
    @objc private func refreshPulled()   { viewModel.onAction(.refresh) }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.displayPolicies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PolicyCardCell.reuseID, for: indexPath) as? PolicyCardCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.state.displayPolicies[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.onAction(.tapPolicy(viewModel.state.displayPolicies[indexPath.row]))
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 140 }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY       = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight   = scrollView.frame.size.height
        if contentHeight > 0, offsetY > contentHeight - frameHeight - 200 {
            viewModel.onAction(.loadMore)
        }
    }
}
