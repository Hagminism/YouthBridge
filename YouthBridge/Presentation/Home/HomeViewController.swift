import UIKit
import Combine

final class HomeViewController: UIViewController {

    private var viewModel: HomeViewModel!
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet private weak var logoLabel: UILabel!
    @IBOutlet private weak var searchBar: UIView!
    @IBOutlet private weak var searchLabel: UILabel!
    @IBOutlet private weak var filterButton: UIButton!
    @IBOutlet private weak var sectionLabel: UILabel!
    @IBOutlet private weak var headerView: UIView!

    private let refreshControl    = UIRefreshControl()
    private let footerSpinner     = UIActivityIndicatorView(style: .medium)

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
                    let vc = DIContainer.shared.makeSearchViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                case .navigateToFilter(let current):
                    let vc = DIContainer.shared.makeFilterViewController(current: current)
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
                    let vc = DIContainer.shared.makeDetailViewController(policy: policy)
                    self.navigationController?.pushViewController(vc, animated: true)
                case .showError(let msg):
                    self.showAlert(msg)
                }
            }
            .store(in: &cancellables)
    }

    private func render(_ state: HomeState) {
        if let activityIndicator = activityIndicator {
            if state.isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
                refreshControl.endRefreshing()
            }
        }

        if state.isLoadingMore {
            footerSpinner.startAnimating()
        } else {
            footerSpinner.stopAnimating()
        }

        let policies = state.displayPolicies
        let urgentCount = policies.filter { $0.isUrgent }.count
        let total = policies.count
        if let sectionLabel = sectionLabel {
            if urgentCount > 0 {
                sectionLabel.text = "전체 정책 \(total)건 · 마감 임박 \(urgentCount)건"
            } else {
                sectionLabel.text = total > 0 ? "전체 정책 \(total)건" : "전체 정책"
            }
        }

        tableView?.reloadData()
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
        // 1. HeaderView 스타일링 (그림자 및 배경)
        if let headerView = headerView {
            headerView.backgroundColor = AppColor.background
            headerView.layer.masksToBounds = false
            headerView.layer.shadowColor = UIColor.black.cgColor
            headerView.layer.shadowOpacity = 0.04
            headerView.layer.shadowOffset = CGSize(width: 0, height: 4)
            headerView.layer.shadowRadius = 8
        }

        // 2. LogoLabel 스타일링
        if let logoLabel = logoLabel {
            logoLabel.font = AppFont.logoTitle
            logoLabel.textColor = AppColor.primary
        }

        // 3. SearchBar 컨테이너 스타일링
        if let searchBar = searchBar {
            searchBar.backgroundColor = AppColor.backgroundTertiary
            searchBar.layer.cornerRadius = 12
            searchBar.layer.borderWidth = 1
            searchBar.layer.borderColor = AppColor.border.cgColor
            searchBar.clipsToBounds = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(searchBarTapped))
            searchBar.addGestureRecognizer(tap)
            
            // 돋보기 아이콘 색상 조절
            let searchIcon = searchBar.subviews.compactMap { $0 as? UIImageView }.first
            searchIcon?.tintColor = AppColor.textTertiary
        }

        // 4. SearchLabel 플레이스홀더 스타일링
        if let searchLabel = searchLabel {
            searchLabel.font = AppFont.bodyMedium
            searchLabel.textColor = AppColor.textTertiary
        }

        // 5. FilterButton 스타일링
        if let filterButton = filterButton {
            filterButton.backgroundColor = AppColor.primary.withAlphaComponent(0.08)
            filterButton.layer.cornerRadius = 12
            filterButton.tintColor = AppColor.primary
            filterButton.setTitle("", for: .normal)
            filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        }

        // 6. SectionLabel 스타일링
        if let sectionLabel = sectionLabel {
            sectionLabel.font = AppFont.heading2
            sectionLabel.textColor = AppColor.textPrimary
        }
    }

    private func setupTableView() {
        guard let tableView = tableView else { return }
        tableView.backgroundColor = .clear
        tableView.separatorStyle  = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(PolicyCardCell.self, forCellReuseIdentifier: PolicyCardCell.reuseID)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = AppColor.primary
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 56))
        footerSpinner.color = AppColor.primary
        footerSpinner.hidesWhenStopped = true
        footerSpinner.center = CGPoint(x: footer.bounds.midX, y: footer.bounds.midY)
        footer.addSubview(footerSpinner)
        tableView.tableFooterView = footer
    }

    private func setupActivityIndicator() {
        guard let activityIndicator = activityIndicator else { return }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppColor.primary
    }

    // MARK: - Actions

    @objc private func searchBarTapped() {
        guard let searchBar = searchBar else { return }
        UIView.animate(withDuration: 0.1, animations: {
            searchBar.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                searchBar.transform = .identity
            }
            self.viewModel.onAction(.tapSearchBar)
        }
    }

    @objc private func filterTapped() {
        guard let filterButton = filterButton else { return }
        UIView.animate(withDuration: 0.1, animations: {
            filterButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                filterButton.transform = .identity
            }
            self.viewModel.onAction(.tapFilter)
        }
    }

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
