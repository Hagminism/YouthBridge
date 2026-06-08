import UIKit
import Combine

final class FilterViewController: UIViewController {

    var onApply: ((FilterState) -> Void)?

    private var viewModel: FilterViewModel!
    private var cancellables = Set<AnyCancellable>()

    private let scrollView  = UIScrollView()
    private let contentView = UIView()
    private let applyButton = UIButton(type: .system)

    private var regionChipsContainer: UIView!
    private var categoryBentoContainer: UIView!
    private var statusControl: UISegmentedControl!

    // 카테고리별 아이콘·색상
    private static let categoryMeta: [(name: String, desc: String, icon: String, color: UIColor)] = [
        ("일자리·취업", "고용, 훈련, 창업 지원 등",    "briefcase.fill",      UIColor(hex: "#FF9500")),
        ("주거",        "월세, 대출, 기숙사 등",        "house.fill",          UIColor(hex: "#34C759")),
        ("금융",        "자산 형성, 채무 조정, 지원금",  "creditcard.fill",     UIColor(hex: "#007AFF")),
        ("교육",        "장학금, 교육비 지원",           "book.fill",           UIColor(hex: "#AF52DE")),
        ("건강·복지",   "의료비, 심리 상담, 문화 활동",  "heart.fill",          UIColor(hex: "#FF2D55")),
    ]

    init(currentFilter: FilterState) {
        super.init(nibName: nil, bundle: nil)
        viewModel = DIContainer.shared.makeFilterViewModel(current: currentFilter)
    }
    required init?(coder: NSCoder) { fatalError() }

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
        [scrollView, applyButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        view.addSubview(applyButton)
        scrollView.addSubview(contentView)

        applyButton.backgroundColor = AppColor.primary
        applyButton.setTitle("필터 적용하기", for: .normal)
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.titleLabel?.font = AppFont.actionButton
        applyButton.layer.cornerRadius = 14
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            applyButton.heightAnchor.constraint(equalToConstant: 54),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -12),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        buildContent()
    }

    private func buildContent() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])

        stack.addArrangedSubview(buildSectionHeader("지역 선택"))
        regionChipsContainer = buildRegionGrid()
        stack.addArrangedSubview(regionChipsContainer)
        stack.addArrangedSubview(makeDivider())
        stack.addArrangedSubview(buildSectionHeader("카테고리"))
        categoryBentoContainer = buildCategoryBento()
        stack.addArrangedSubview(categoryBentoContainer)
        stack.addArrangedSubview(makeDivider())
        stack.addArrangedSubview(buildSectionHeader("정책 상태"))
        statusControl = UISegmentedControl(items: ["진행 중", "마감", "전체"])
        statusControl.selectedSegmentIndex = 0
        statusControl.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        stack.addArrangedSubview(statusControl)
    }

    private var availableWidth: CGFloat {
        let w = view.bounds.width
        if w > 0 { return w }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 390
    }

    // MARK: - Region Grid (5열, 화면 꽉 채우기)
    private func buildRegionGrid() -> UIView {
        let regions = FilterViewModel.regions
        let columns = 5
        let spacing: CGFloat = 8
        let totalWidth = availableWidth - 32
        let btnWidth = (totalWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let btnHeight: CGFloat = 44

        let container = UIView()
        var col = 0
        var row = 0

        for region in regions {
            let btn = makeGlassChipButton(title: region)
            btn.addTarget(self, action: #selector(regionChipTapped(_:)), for: .touchUpInside)
            let x = CGFloat(col) * (btnWidth + spacing)
            let y = CGFloat(row) * (btnHeight + spacing)
            btn.frame = CGRect(x: x, y: y, width: btnWidth, height: btnHeight)
            container.addSubview(btn)
            col += 1
            if col == columns { col = 0; row += 1 }
        }

        let rows = Int(ceil(Double(regions.count) / Double(columns)))
        let totalH = CGFloat(rows) * btnHeight + CGFloat(rows - 1) * spacing
        container.heightAnchor.constraint(equalToConstant: totalH).isActive = true
        return container
    }

    // MARK: - Category Bento (아이콘 + 색 배경)
    private func buildCategoryBento() -> UIView {
        let spacing: CGFloat = 10
        let totalWidth = availableWidth - 32
        let btnWidth = (totalWidth - spacing) / 2
        let btnHeight: CGFloat = 120

        let container = UIView()

        for (i, meta) in Self.categoryMeta.enumerated() {
            let btn = makeCategoryButton(meta: meta)
            btn.addTarget(self, action: #selector(categoryBentoTapped(_:)), for: .touchUpInside)
            let col = i % 2
            let row = i / 2
            btn.frame = CGRect(
                x: CGFloat(col) * (btnWidth + spacing),
                y: CGFloat(row) * (btnHeight + spacing),
                width: btnWidth, height: btnHeight
            )
            container.addSubview(btn)
        }

        let rows = Int(ceil(Double(Self.categoryMeta.count) / 2.0))
        let totalH = CGFloat(rows) * btnHeight + CGFloat(rows - 1) * spacing
        container.heightAnchor.constraint(equalToConstant: totalH).isActive = true
        return container
    }

    // MARK: - Button Factories

    private func makeGlassChipButton(title: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = AppFont.bodyMedium
        btn.layer.cornerRadius = 10
        btn.layer.borderWidth = 1
        // 기본: 비활성 glass 스타일
        applyGlassInactive(to: btn)
        return btn
    }

    private func makeCategoryButton(meta: (name: String, desc: String, icon: String, color: UIColor)) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.accessibilityLabel = meta.name
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = AppColor.border.cgColor
        btn.backgroundColor = AppColor.background
        btn.clipsToBounds = true

        // 아이콘
        let iconBg = UIView()
        iconBg.backgroundColor = meta.color.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 10
        iconBg.isUserInteractionEnabled = false
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        btn.addSubview(iconBg)

        let iconView = UIImageView(image: UIImage(systemName: meta.icon))
        iconView.tintColor = meta.color
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)

        // 텍스트
        let titleLbl = UILabel()
        titleLbl.text = meta.name
        titleLbl.font = AppFont.policyTitle
        titleLbl.textColor = AppColor.textPrimary

        let descLbl = UILabel()
        descLbl.text = meta.desc
        descLbl.font = AppFont.captionSmall
        descLbl.textColor = AppColor.textSecondary
        descLbl.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLbl, descLbl])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        btn.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: btn.topAnchor, constant: 12),
            iconBg.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 12),
            iconBg.widthAnchor.constraint(equalToConstant: 32),
            iconBg.heightAnchor.constraint(equalToConstant: 32),

            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            textStack.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -8),
            textStack.bottomAnchor.constraint(equalTo: btn.bottomAnchor, constant: -12),
        ])
        return btn
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = AppColor.border
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func buildSectionHeader(_ title: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = title
        lbl.font = AppFont.sectionTitle
        lbl.textColor = AppColor.textPrimary
        return lbl
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

        for btn in regionChipsContainer.subviews.compactMap({ $0 as? UIButton }) {
            let region = btn.title(for: .normal) ?? ""
            if state.selectedRegions.contains(region) {
                applyGlassActive(to: btn)
            } else {
                applyGlassInactive(to: btn)
            }
        }

        for btn in categoryBentoContainer.subviews.compactMap({ $0 as? UIButton }) {
            let cat = btn.accessibilityLabel ?? ""
            let meta = Self.categoryMeta.first { $0.name == cat }
            let isSelected = state.selectedCategories.contains(cat)
            btn.backgroundColor = isSelected ? (meta?.color ?? AppColor.primary).withAlphaComponent(0.12) : AppColor.background
            btn.layer.borderColor = isSelected ? (meta?.color ?? AppColor.primary).cgColor : AppColor.border.cgColor
        }

        let summary = viewModel.selectionSummary
        applyButton.setTitle(summary.isEmpty ? "필터 적용하기" : summary, for: .normal)
    }

    // MARK: - Actions
    @objc private func closeTapped()  { dismiss(animated: true) }
    @objc private func resetTapped()  { viewModel.onAction(.reset) }
    @objc private func applyTapped()  { viewModel.onAction(.apply) }

    @objc private func regionChipTapped(_ sender: UIButton) {
        guard let region = sender.title(for: .normal) else { return }
        viewModel.onAction(.toggleRegion(region))
    }

    @objc private func categoryBentoTapped(_ sender: UIButton) {
        guard let cat = sender.accessibilityLabel else { return }
        viewModel.onAction(.toggleCategory(cat))
    }

    @objc private func statusChanged(_ sender: UISegmentedControl) {
        let statuses: [FilterState.PolicyStatus] = [.active, .expired, .all]
        viewModel.onAction(.selectStatus(statuses[sender.selectedSegmentIndex]))
    }
}
