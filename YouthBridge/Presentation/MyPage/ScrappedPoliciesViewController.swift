import UIKit
import Combine

final class ScrappedPoliciesViewController: UIViewController {

    private let tableView = UITableView()
    private var scrappedPolicies: [Policy] = []
    private var scrapUseCase: ScrapPolicyUseCase!
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        scrapUseCase = DIContainer.shared.scrapPolicyUseCase
        setupNavBar()
        setupTableView()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func setupNavBar() {
        title = "저장한 정책"
        view.backgroundColor = AppColor.backgroundSecondary
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.background
        appearance.titleTextAttributes = [.foregroundColor: AppColor.textPrimary]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = AppColor.textPrimary
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self, action: #selector(backTapped)
        )
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(PolicyCardCell.self, forCellReuseIdentifier: PolicyCardCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadData() {
        scrappedPolicies = scrapUseCase.getScrapped()
        tableView.reloadData()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension ScrappedPoliciesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scrappedPolicies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PolicyCardCell.reuseID, for: indexPath) as? PolicyCardCell else {
            return UITableViewCell()
        }
        cell.configure(with: scrappedPolicies[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectItemAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let policy = scrappedPolicies[indexPath.row]
        let vc = DIContainer.shared.makeDetailViewController(policy: policy)
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
