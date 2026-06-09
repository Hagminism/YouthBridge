import UIKit
import Combine

final class SearchViewController: UIViewController {

    private var viewModel: SearchViewModel!
    private var cancellables = Set<AnyCancellable>()

    private let headerContainer = UIView()
    private let backButton = UIButton(type: .system)
    private let searchBar = UISearchBar()
    private let filterButton = UIButton(type: .system)

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = DIContainer.shared.makeSearchViewModel()
        setupTopBar()
        setupTableView()
        setupActivityIndicator()
        bindState()
        bindEffect()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    private func bindState() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.tableView?.reloadData()
                self?.updateFilterButton(active: state.isFilterActive)
            }
            .store(in: &cancellables)

        viewModel.$state
            .map(\.isSearching)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSearching in
                guard let self = self else { return }
                if isSearching { self.activityIndicator?.startAnimating() }
                else           { self.activityIndicator?.stopAnimating() }
            }
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

    private func setupTopBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = AppColor.backgroundSecondary

        headerContainer.backgroundColor = AppColor.background
        headerContainer.layer.masksToBounds = false
        headerContainer.layer.shadowColor = UIColor.black.cgColor
        headerContainer.layer.shadowOpacity = 0.04
        headerContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        headerContainer.layer.shadowRadius = 8
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)

        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = AppColor.textPrimary
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        // Search bar
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "정책 이름이나 키워드를 검색하세요"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Filter button
        filterButton.backgroundColor = AppColor.primary.withAlphaComponent(0.08)
        filterButton.layer.cornerRadius = 12
        filterButton.tintColor = AppColor.primary
        filterButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        filterButton.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [backButton, searchBar, filterButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),

            stack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
            stack.heightAnchor.constraint(equalToConstant: 48),

            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            filterButton.widthAnchor.constraint(equalToConstant: 44),
            filterButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func updateFilterButton(active: Bool) {
        // 홈 화면 필터 버튼 디자인과 일치하도록 파란색 틴트 및 연파란 배경을 항상 유지합니다.
        filterButton.tintColor = AppColor.primary
        filterButton.backgroundColor = AppColor.primary.withAlphaComponent(0.08)
    }

    private func setupTableView() {
        guard let tableView = tableView else { return }
        tableView.backgroundColor = AppColor.background
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(PolicyCardCell.self, forCellReuseIdentifier: PolicyCardCell.reuseID)

        if let superview = tableView.superview {
            // 스토리보드에서 자동 생성된 top constraint 비활성화하여 겹침 방지
            if let oldTop = superview.constraints.first(where: { 
                ($0.firstItem as? UITableView == tableView && $0.firstAttribute == .top) || 
                ($0.secondItem as? UITableView == tableView && $0.secondAttribute == .top)
            }) {
                oldTop.isActive = false
            }
            
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor)
            ])
        }
    }

    private func setupActivityIndicator() {
        guard let activityIndicator = activityIndicator else { return }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppColor.primary
    }

    // MARK: - Actions

    @objc private func backTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.backButton.transform = .identity
            }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func filterTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.filterButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.filterButton.transform = .identity
            }
            let vc = DIContainer.shared.makeFilterViewController(current: self.viewModel.state.appliedFilter)
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
        }
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        viewModel.onAction(.search(searchBar.text ?? ""))
        searchBar.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.onAction(.updateKeyword(searchText))
    }
}

// MARK: - UITableViewDataSource / Delegate
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.state.showResults ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfItemsInSection section: Int) -> Int {
        let state = viewModel.state
        if state.showResults { return state.results.count }
        return section == 0 ? state.recentKeywords.count : state.trendingKeywords.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let state = viewModel.state
        if state.showResults { return state.results.count }
        return section == 0 ? state.recentKeywords.count : state.trendingKeywords.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if viewModel.state.showResults { return "검색 결과 \(viewModel.state.results.count)개" }
        return section == 0 ? "최근 검색어" : "인기 검색어"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let state = viewModel.state
        if state.showResults {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PolicyCardCell.reuseID, for: indexPath) as? PolicyCardCell else {
                return UITableViewCell()
            }
            cell.configure(with: state.results[indexPath.row])
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        if indexPath.section == 0 {
            config.text = state.recentKeywords[indexPath.row]
            config.image = UIImage(systemName: "clock")
            config.imageProperties.tintColor = AppColor.primary
            config.textProperties.color = AppColor.textPrimary
        } else {
            config.text = state.trendingKeywords[indexPath.row]
            config.image = UIImage(systemName: "magnifyingglass")
            config.imageProperties.tintColor = AppColor.primary
            config.textProperties.color = AppColor.textPrimary
        }
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let state = viewModel.state
        if state.showResults {
            viewModel.onAction(.tapResult(state.results[indexPath.row]))
        } else if indexPath.section == 0 {
            let kw = state.recentKeywords[indexPath.row]
            searchBar.text = kw
            viewModel.onAction(.search(kw))
            searchBar.resignFirstResponder()
        } else {
            let kw = state.trendingKeywords[indexPath.row]
            searchBar.text = kw
            viewModel.onAction(.selectTrending(kw))
            searchBar.resignFirstResponder()
        }
    }

    // MARK: - Swipe to delete (최근 검색어만)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !viewModel.state.showResults, indexPath.section == 0 else { return nil }
        let kw = viewModel.state.recentKeywords[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            self?.viewModel.onAction(.deleteHistoryItem(kw))
            completion(true)
        }
        delete.backgroundColor = AppColor.urgentRed
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.state.showResults ? UITableView.automaticDimension : 44
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.state.showResults ? 160 : 44
    }
}
