import UIKit
import Combine

final class FilterViewController: UIViewController {

    var onApply: ((FilterState) -> Void)?

    private var viewModel: FilterViewModel!
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var applyButton: UIButton!

    @IBOutlet private weak var regionChipsContainer: UIView!
    @IBOutlet private weak var categoryBentoContainer: UIView!
    @IBOutlet private weak var statusControl: UISegmentedControl!

    // 카테고리별 아이콘·색상
    private static let categoryMeta: [(name: String, desc: String, icon: String, color: UIColor)] = [
        ("일자리·취업", "고용, 훈련, 창업 지원 등",    "briefcase.fill",      UIColor(hex: "#FF9500")),
        ("주거",        "월세, 대출, 기숙사 등",        "house.fill",          UIColor(hex: "#34C759")),
        ("금융",        "자산 형성, 채무 조정, 지원금",  "creditcard.fill",     UIColor(hex: "#007AFF")),
        ("교육",        "장학금, 교육비 지원",           "book.fill",           UIColor(hex: "#AF52DE")),
        ("건강·복지",   "의료비, 심리 상담, 문화 활동",  "heart.fill",          UIColor(hex: "#FF2D55")),
    ]

    init?(coder: NSCoder, currentFilter: FilterState) {
        super.init(coder: coder)
        viewModel = DIContainer.shared.makeFilterViewModel(current: currentFilter)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupUI()
        bindState()
        bindEffect()
    }

    private func bindState() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateUI() }
            .store(in: &cancellables)
    }

    private func bindEffect() {
        viewModel.effect
            .receive(on: DispatchQueue.main)
            .sink { [weak self] effect in
                switch effect {
                case .dismiss(let filter):
                    self?.onApply?(filter)
                    self?.dismiss(animated: true)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        title = "필터"
        navigationItem.leftBarButtonItem  = UIBarButtonItem(title: "닫기",  style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "초기화", style: .plain, target: self, action: #selector(resetTapped))
        navigationItem.leftBarButtonItem?.tintColor  = AppColor.textPrimary
        navigationItem.rightBarButtonItem?.tintColor = AppColor.primary
        view.backgroundColor = AppColor.background
    }

    // MARK: - UI
    private func setupUI() {
        applyButton?.backgroundColor = AppColor.primary
        applyButton?.setTitleColor(.white, for: .normal)
        applyButton?.titleLabel?.font = AppFont.actionButton
        applyButton?.layer.cornerRadius = 14
        
        statusControl?.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        
        if let regionChipsContainer = regionChipsContainer {
            for btn in regionChipsContainer.subviews.compactMap({ $0 as? UIButton }) {
                btn.addTarget(self, action: #selector(regionChipTapped(_:)), for: .touchUpInside)
            }
        }
        if let categoryBentoContainer = categoryBentoContainer {
            for btn in categoryBentoContainer.subviews.compactMap({ $0 as? UIButton }) {
                btn.addTarget(self, action: #selector(categoryBentoTapped(_:)), for: .touchUpInside)
            }
        }
    }

    // MARK: - Glass helpers
    private func applyGlassInactive(to btn: UIButton) {
        btn.backgroundColor = UIColor(hex: "#F0F4FF")
        btn.layer.borderColor = UIColor(hex: "#C7D2FE").cgColor
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
    }

    private func applyGlassActive(to btn: UIButton) {
        btn.backgroundColor = AppColor.primary
        btn.layer.borderColor = AppColor.primary.cgColor
        btn.setTitleColor(.white, for: .normal)
    }

    // MARK: - updateUI
    private func updateUI() {
        let state = viewModel.state

        if let regionChipsContainer = regionChipsContainer {
            for btn in regionChipsContainer.subviews.compactMap({ $0 as? UIButton }) {
                let region = btn.title(for: .normal) ?? ""
                if state.selectedRegions.contains(region) {
                    applyGlassActive(to: btn)
                } else {
                    applyGlassInactive(to: btn)
                }
            }
        }

        if let categoryBentoContainer = categoryBentoContainer {
            for btn in categoryBentoContainer.subviews.compactMap({ $0 as? UIButton }) {
                let cat = btn.accessibilityLabel ?? ""
                let meta = Self.categoryMeta.first { $0.name == cat }
                let isSelected = state.selectedCategories.contains(cat)
                btn.backgroundColor = isSelected ? (meta?.color ?? AppColor.primary).withAlphaComponent(0.12) : AppColor.background
                btn.layer.borderColor = isSelected ? (meta?.color ?? AppColor.primary).cgColor : AppColor.border.cgColor
            }
        }

        let summary = viewModel.selectionSummary
        applyButton?.setTitle(summary.isEmpty ? "필터 적용하기" : summary, for: .normal)
    }

    // MARK: - Actions
    @IBAction private func closeTapped()  { dismiss(animated: true) }
    @IBAction private func resetTapped()  { viewModel.onAction(.reset) }
    @IBAction private func applyTapped()  { viewModel.onAction(.apply) }

    @IBAction private func regionChipTapped(_ sender: UIButton) {
        guard let region = sender.title(for: .normal) else { return }
        viewModel.onAction(.toggleRegion(region))
    }

    @IBAction private func categoryBentoTapped(_ sender: UIButton) {
        guard let cat = sender.accessibilityLabel else { return }
        viewModel.onAction(.toggleCategory(cat))
    }

    @IBAction private func statusChanged(_ sender: UISegmentedControl) {
        let statuses: [FilterState.PolicyStatus] = [.active, .expired, .all]
        guard sender.selectedSegmentIndex >= 0 && sender.selectedSegmentIndex < statuses.count else { return }
        viewModel.onAction(.selectStatus(statuses[sender.selectedSegmentIndex]))
    }
}
