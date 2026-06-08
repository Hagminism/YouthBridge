import UIKit
import Combine

final class SearchViewController: UIViewController {

    private var viewModel: SearchViewModel!
    private var cancellables = Set<AnyCancellable>()

    private let searchController  = UISearchController(searchResultsController: nil)
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    private let filterBarButton   = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = DIContainer.shared.makeSearchViewModel()
        setupNavBar()
        setupTableView()
        setupActivityIndicator()
        bindState()
        bindEffect()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.searchBar.becomeFirstResponder()
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

    private func setupNavBar() {
        title = "검색"
        view.backgroundColor = AppColor.background
        navigationController?.setNavigationBarHidden(false, animated: false)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "정책 이름이나 키워드를 검색하세요"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        // Filter button
        let filterImage = UIImage(systemName: "slider.horizontal.3")
        filterBarButton.image = filterImage
        filterBarButton.tintColor = AppColor.textSecondary
        filterBarButton.target = self
        filterBarButton.action = #selector(filterTapped)
        navigationItem.rightBarButtonItem = filterBarButton
    }

    private func updateFilterButton(active: Bool) {
        filterBarButton.tintColor = active ? AppColor.primary : AppColor.textSecondary
    }

    private func setupTableView() {
        guard let tableView = tableView else { return }
        tableView.backgroundColor = AppColor.background
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UINib(nibName: "PolicyCardCell", bundle: nil),  forCellReuseIdentifier: PolicyCardCell.reuseID)
    }

    private func setupActivityIndicator() {
        guard let activityIndicator = activityIndicator else { return }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppColor.primary
    }

    // MARK: - Actions

    @IBAction private func filterTapped() {
        let vc = DIContainer.shared.makeFilterViewController(current: viewModel.state.appliedFilter)
        vc.onApply = { [weak self] filter in
            self?.viewModel.onAction(.applyFilter(filter))
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.onAction(.updateKeyword(searchController.searchBar.text ?? ""))
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        viewModel.onAction(.search(searchBar.text ?? ""))
    }
}

// MARK: - UITableViewDataSource / Delegate
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.state.showResults ? 1 : 2
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
            searchController.searchBar.text = kw
            viewModel.onAction(.search(kw))
        } else {
            viewModel.onAction(.selectTrending(state.trendingKeywords[indexPath.row]))
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
