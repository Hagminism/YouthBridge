import UIKit
import SafariServices
import Combine

final class DetailViewController: UIViewController {

    private var viewModel: DetailViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()

    // Header info
    private let dDayBadge    = PaddedLabel()
    private let categoryLabel = UILabel()
    private let titleLabel   = UILabel()
    private let orgLabel     = UILabel()

    // Info grid
    private let ageLabel     = UILabel()
    private let regionLabel  = UILabel()
    private let periodLabel  = UILabel()

    // AI Section
    private let aiButton     = UIButton(type: .custom)
    private let aiIndicator  = UIActivityIndicatorView(style: .medium)
    private let aiResultView = UITextView()
    private let aiContainer  = UIView()

    // Content
    private let contentLabel = UILabel()

    // Bottom bar
    private let scrapButton  = UIButton(type: .custom)
    private let applyButton  = UIButton(type: .system)
    private let bottomBar    = UIView()

    init(policy: Policy) {
        super.init(nibName: nil, bundle: nil)
        viewModel = DIContainer.shared.makeDetailViewModel(policy: policy)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindState()
        bindEffect()
        viewModel.onAction(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNavBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavBar()
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
                case .openURL(let url):
                    let safari = SFSafariViewController(url: url)
                    self.present(safari, animated: true)
                case .shareText(let text):
                    let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                    self.present(vc, animated: true)
                case .showError(let msg):
                    let alert = UIAlertController(title: "오류", message: msg, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)
                case .scrapToggled(let isScrapped):
                    let img = UIImage(systemName: isScrapped ? "bookmark.fill" : "bookmark")
                    self.scrapButton.setImage(img, for: .normal)
                    self.scrapButton.tintColor = isScrapped ? AppColor.primary : AppColor.textSecondary
                }
            }
            .store(in: &cancellables)
    }

    private func render(_ state: DetailState) {
        let policy = state.policy

        let hasDeadline = !policy.applyPeriod.trimmingCharacters(in: .whitespaces).isEmpty
        dDayBadge.isHidden = !hasDeadline
        if hasDeadline {
            dDayBadge.text            = policy.dDayText
            dDayBadge.textColor       = policy.isUrgent ? AppColor.urgentRed : AppColor.textSecondary
            dDayBadge.backgroundColor = policy.isUrgent
                ? AppColor.urgentRed.withAlphaComponent(0.1) : AppColor.tagBackground
        }

        categoryLabel.text = policy.category
        titleLabel.text    = policy.name
        orgLabel.text      = policy.operatingOrg
        periodLabel.text   = policy.displayApplyPeriod
        contentLabel.text  = policy.supportContent

        let scrapImg = UIImage(systemName: state.isScrapped ? "bookmark.fill" : "bookmark")
        scrapButton.setImage(scrapImg, for: .normal)
        scrapButton.tintColor = state.isScrapped ? AppColor.primary : AppColor.textSecondary

        if policy.linkUrl == nil {
            applyButton.isEnabled = false
            applyButton.backgroundColor = AppColor.tagBackground
            applyButton.setTitle("신청 링크 없음", for: .disabled)
            applyButton.setTitleColor(AppColor.textDisabled, for: .disabled)
        } else {
            applyButton.isEnabled = true
            applyButton.backgroundColor = AppColor.primary
            applyButton.setTitle("지금 신청하기", for: .normal)
            applyButton.setTitleColor(.white, for: .normal)
        }

        if state.isSummarizing {
            aiButton.configuration?.title = ""
            aiIndicator.startAnimating()
            aiButton.isUserInteractionEnabled = false
        } else {
            aiIndicator.stopAnimating()
            aiButton.isUserInteractionEnabled = true
            if state.aiSummary == nil {
                aiButton.configuration?.title = "AI 3줄 요약 보기"
                aiButton.configuration?.baseForegroundColor = AppColor.primary
                aiButton.layer.borderColor = AppColor.primary.cgColor
            }
        }

        if let summary = state.aiSummary {
            aiResultView.text = summary
            aiResultView.isHidden = false
            aiButton.configuration?.title = "AI 요약 완료 ✓"
            aiButton.configuration?.baseForegroundColor = AppColor.textTertiary
            aiButton.layer.borderColor = AppColor.border.cgColor
        }
    }

    // MARK: - NavBar
    private func setupNavBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: AppColor.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: AppColor.textPrimary]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = AppColor.textPrimary
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self, action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = AppColor.textPrimary
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain, target: self, action: #selector(shareTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = AppColor.textPrimary
        view.backgroundColor = AppColor.backgroundSecondary
    }

    private func restoreNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.background
        appearance.titleTextAttributes = [.foregroundColor: AppColor.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: AppColor.textPrimary]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = nil
    }

    // MARK: - Layout
    private func setupUI() {
        // Bottom bar
        bottomBar.backgroundColor = AppColor.backgroundSecondary.withAlphaComponent(0.9)
        bottomBar.layer.borderWidth = 1
        bottomBar.layer.borderColor = AppColor.border.cgColor
        view.addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        scrapButton.layer.cornerRadius = 12
        scrapButton.layer.borderWidth = 1
        scrapButton.layer.borderColor = AppColor.borderLight.cgColor
        scrapButton.backgroundColor = AppColor.background
        scrapButton.tintColor = AppColor.textSecondary
        scrapButton.addTarget(self, action: #selector(scrapTapped), for: .touchUpInside)
        bottomBar.addSubview(scrapButton)
        scrapButton.translatesAutoresizingMaskIntoConstraints = false

        applyButton.backgroundColor = AppColor.primary
        applyButton.setTitle("지금 신청하기", for: .normal)
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.titleLabel?.font = AppFont.actionButton
        applyButton.layer.cornerRadius = 12
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        bottomBar.addSubview(applyButton)
        applyButton.translatesAutoresizingMaskIntoConstraints = false

        // Scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        buildContentStack()

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 90),

            scrapButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            scrapButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 16),
            scrapButton.widthAnchor.constraint(equalToConstant: 56),
            scrapButton.heightAnchor.constraint(equalToConstant: 56),

            applyButton.leadingAnchor.constraint(equalTo: scrapButton.trailingAnchor, constant: 8),
            applyButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            applyButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 16),
            applyButton.heightAnchor.constraint(equalToConstant: 56),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    private func buildContentStack() {
        // Badge row: category left | spacer | D-Day right
        dDayBadge.font = AppFont.dDayBadge
        dDayBadge.layer.cornerRadius = 9999
        dDayBadge.clipsToBounds = true
        dDayBadge.textAlignment = .center
        dDayBadge.setContentHuggingPriority(.required, for: .horizontal)

        categoryLabel.font = AppFont.bodyMedium
        categoryLabel.textColor = AppColor.textTertiary

        let badgeSpacer = UIView()
        badgeSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let badgeRow = UIStackView(arrangedSubviews: [categoryLabel, badgeSpacer, dDayBadge])
        badgeRow.axis = .horizontal
        badgeRow.spacing = 8
        badgeRow.alignment = .center

        contentStack.addArrangedSubview(badgeRow)

        // Title
        titleLabel.font = AppFont.heading1
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        // Org
        orgLabel.font = AppFont.body
        orgLabel.textColor = AppColor.textSecondary
        contentStack.addArrangedSubview(orgLabel)

        // Info grid
        contentStack.addArrangedSubview(buildInfoGrid())

        // AI Summary section
        contentStack.addArrangedSubview(buildAISection())

        // Content section
        contentStack.addArrangedSubview(buildContentSection())
    }

    private func buildInfoGrid() -> UIView {
        let grid = UIView()
        grid.layer.borderWidth = 1
        grid.layer.borderColor = AppColor.border.cgColor
        grid.layer.cornerRadius = 12
        grid.backgroundColor = AppColor.background

        let periodRow = buildInfoRow(icon: "calendar", title: "신청 기간", valueLabel: periodLabel)

        let stack = UIStackView(arrangedSubviews: [periodRow])
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        grid.addSubview(stack)

        periodLabel.font = AppFont.policyTitle
        periodLabel.textColor = AppColor.textPrimary

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: grid.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: grid.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: grid.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: grid.bottomAnchor, constant: -16),
        ])
        return grid
    }

    private func buildInfoRow(icon: String, title: String, valueLabel: UILabel) -> UIStackView {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = AppColor.textTertiary
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = AppFont.captionSmall
        titleLbl.textColor = AppColor.textTertiary

        let vStack = UIStackView(arrangedSubviews: [titleLbl, valueLabel])
        vStack.axis = .vertical
        vStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [iconView, vStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        return row
    }

    private func buildAISection() -> UIView {
        aiContainer.backgroundColor = AppColor.aiSectionBG
        aiContainer.layer.borderWidth = 1
        aiContainer.layer.borderColor = AppColor.aiSectionBorder.cgColor
        aiContainer.layer.cornerRadius = 12

        let header = UIStackView(arrangedSubviews: [makeAIIcon(), makeAITitleLabel()])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .center

        var btnConfig = UIButton.Configuration.plain()
        btnConfig.title = "AI 3줄 요약 보기"
        btnConfig.baseForegroundColor = AppColor.primary
        btnConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        btnConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attrs = incoming
            attrs.font = AppFont.body
            return attrs
        }
        aiButton.configuration = btnConfig
        aiButton.layer.borderWidth = 1.5
        aiButton.layer.borderColor = AppColor.primary.cgColor
        aiButton.layer.cornerRadius = 10
        aiButton.clipsToBounds = true
        aiButton.addTarget(self, action: #selector(aiSummaryTapped),   for: .touchUpInside)
        aiButton.addTarget(self, action: #selector(aiButtonHighlight), for: [.touchDown, .touchDragEnter])
        aiButton.addTarget(self, action: #selector(aiButtonRelease),   for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])

        // Indicator sits inside the button, centered over the text
        aiIndicator.hidesWhenStopped = true
        aiIndicator.color = AppColor.primary
        aiIndicator.translatesAutoresizingMaskIntoConstraints = false
        aiButton.addSubview(aiIndicator)
        NSLayoutConstraint.activate([
            aiIndicator.centerXAnchor.constraint(equalTo: aiButton.centerXAnchor),
            aiIndicator.centerYAnchor.constraint(equalTo: aiButton.centerYAnchor),
        ])

        aiResultView.isHidden = true
        aiResultView.isEditable = false
        aiResultView.isScrollEnabled = false
        aiResultView.font = AppFont.body
        aiResultView.textColor = AppColor.textSecondary
        aiResultView.backgroundColor = .clear

        let buttonRow = UIStackView(arrangedSubviews: [aiButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.alignment = .center

        let inner = UIStackView(arrangedSubviews: [header, buttonRow, aiResultView])
        inner.axis = .vertical
        inner.spacing = 12
        inner.translatesAutoresizingMaskIntoConstraints = false
        aiContainer.addSubview(inner)

        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: aiContainer.topAnchor, constant: 16),
            inner.leadingAnchor.constraint(equalTo: aiContainer.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: aiContainer.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: aiContainer.bottomAnchor, constant: -16),
        ])
        return aiContainer
    }

    private func makeAIIcon() -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: "sparkles"))
        iv.tintColor = AppColor.primary
        iv.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return iv
    }

    private func makeAITitleLabel() -> UILabel {
        let lbl = UILabel()
        lbl.text = "AI 요약 Insights"
        lbl.font = AppFont.policyTitle
        lbl.textColor = AppColor.primary
        return lbl
    }

    private func buildContentSection() -> UIView {
        let container = UIView()
        container.backgroundColor = AppColor.background
        container.layer.borderWidth = 1
        container.layer.borderColor = AppColor.border.cgColor
        container.layer.cornerRadius = 12

        let titleLbl = UILabel()
        titleLbl.text = "지원 내용"
        titleLbl.font = AppFont.heading2
        titleLbl.textColor = AppColor.textPrimary

        contentLabel.font = AppFont.body
        contentLabel.textColor = AppColor.textSecondary
        contentLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLbl, contentLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        ])
        return container
    }

    // MARK: - Actions
    @objc private func backTapped()       { navigationController?.popViewController(animated: true) }
    @objc private func shareTapped()      { viewModel.onAction(.tapShare) }
    @objc private func scrapTapped()      { viewModel.onAction(.tapScrap) }
    @objc private func applyTapped()      { viewModel.onAction(.tapExternalLink) }
    @objc private func aiSummaryTapped()  { viewModel.onAction(.tapAISummary) }

    @objc private func aiButtonHighlight() {
        UIView.animate(withDuration: 0.1) {
            self.aiButton.backgroundColor = AppColor.primary.withAlphaComponent(0.08)
        }
    }

    @objc private func aiButtonRelease() {
        UIView.animate(withDuration: 0.2) {
            self.aiButton.backgroundColor = .clear
        }
    }
}
