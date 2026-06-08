import UIKit
import SafariServices
import Combine

final class DetailViewController: UIViewController {

    private var viewModel: DetailViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentStack: UIStackView!

    // Header info
    @IBOutlet private weak var dDayBadge: PaddedLabel!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var orgLabel: UILabel!

    // Info grid
    @IBOutlet private weak var ageLabel: UILabel!
    @IBOutlet private weak var regionLabel: UILabel!
    @IBOutlet private weak var periodLabel: UILabel!

    // AI Section
    @IBOutlet private weak var aiButton: UIButton!
    @IBOutlet private weak var aiIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var aiResultView: UITextView!
    @IBOutlet private weak var aiContainer: UIView!

    // Content
    @IBOutlet private weak var contentLabel: UILabel!

    // Bottom bar
    @IBOutlet private weak var scrapButton: UIButton!
    @IBOutlet private weak var applyButton: UIButton!
    @IBOutlet private weak var bottomBar: UIView!

    init?(coder: NSCoder, policy: Policy) {
        super.init(coder: coder)
        viewModel = DIContainer.shared.makeDetailViewModel(policy: policy)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

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
                    self.scrapButton?.setImage(img, for: .normal)
                    self.scrapButton?.tintColor = isScrapped ? AppColor.primary : AppColor.textSecondary
                }
            }
            .store(in: &cancellables)
    }

    private func render(_ state: DetailState) {
        let policy = state.policy

        let hasDeadline = !policy.applyPeriod.trimmingCharacters(in: .whitespaces).isEmpty
        dDayBadge?.isHidden = !hasDeadline
        if hasDeadline {
            dDayBadge?.text            = policy.dDayText
            dDayBadge?.textColor       = policy.isUrgent ? AppColor.urgentRed : AppColor.textSecondary
            dDayBadge?.backgroundColor = policy.isUrgent
                ? AppColor.urgentRed.withAlphaComponent(0.1) : AppColor.tagBackground
        }

        categoryLabel?.text = policy.category
        titleLabel?.text    = policy.name
        orgLabel?.text      = policy.operatingOrg
        periodLabel?.text   = policy.displayApplyPeriod
        contentLabel?.text  = policy.supportContent

        let scrapImg = UIImage(systemName: state.isScrapped ? "bookmark.fill" : "bookmark")
        scrapButton?.setImage(scrapImg, for: .normal)
        scrapButton?.tintColor = state.isScrapped ? AppColor.primary : AppColor.textSecondary

        applyButton?.isHidden = policy.linkUrl == nil

        if state.isSummarizing {
            aiButton?.configuration?.title = ""
            aiIndicator?.startAnimating()
            aiButton?.isUserInteractionEnabled = false
        } else {
            aiIndicator?.stopAnimating()
            aiButton?.isUserInteractionEnabled = true
            if state.aiSummary == nil {
                aiButton?.configuration?.title = "AI 3줄 요약 보기"
                aiButton?.configuration?.baseForegroundColor = AppColor.primary
                aiButton?.layer.borderColor = AppColor.primary.cgColor
            }
        }

        if let summary = state.aiSummary {
            aiResultView?.text = summary
            aiResultView?.isHidden = false
            aiButton?.configuration?.title = "AI 요약 완료 ✓"
            aiButton?.configuration?.baseForegroundColor = AppColor.textTertiary
            aiButton?.layer.borderColor = AppColor.border.cgColor
        }
    }

    // MARK: - NavBar
    private func setupNavBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
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

    // MARK: - Layout
    private func setupUI() {
        view.backgroundColor = AppColor.backgroundSecondary
        
        bottomBar?.backgroundColor = AppColor.backgroundSecondary.withAlphaComponent(0.9)
        bottomBar?.layer.borderWidth = 1
        bottomBar?.layer.borderColor = AppColor.border.cgColor

        scrapButton?.layer.cornerRadius = 12
        scrapButton?.layer.borderWidth = 1
        scrapButton?.layer.borderColor = AppColor.borderLight.cgColor
        scrapButton?.backgroundColor = AppColor.background
        scrapButton?.tintColor = AppColor.textSecondary

        applyButton?.backgroundColor = AppColor.primary
        applyButton?.layer.cornerRadius = 12

        // AI Section
        aiContainer?.backgroundColor = AppColor.aiSectionBG
        aiContainer?.layer.borderWidth = 1
        aiContainer?.layer.borderColor = AppColor.aiSectionBorder.cgColor
        aiContainer?.layer.cornerRadius = 12

        if let aiButton = aiButton {
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
        }

        aiIndicator?.hidesWhenStopped = true
        aiIndicator?.color = AppColor.primary
    }

    // MARK: - Actions
    @IBAction private func backTapped()       { navigationController?.popViewController(animated: true) }
    @IBAction private func shareTapped()      { viewModel.onAction(.tapShare) }
    @IBAction private func scrapTapped()      { viewModel.onAction(.tapScrap) }
    @IBAction private func applyTapped()      { viewModel.onAction(.tapExternalLink) }
    @IBAction private func aiSummaryTapped()  { viewModel.onAction(.tapAISummary) }

    @IBAction private func aiButtonHighlight() {
        guard let aiButton = aiButton else { return }
        UIView.animate(withDuration: 0.1) {
            aiButton.backgroundColor = AppColor.primary.withAlphaComponent(0.08)
        }
    }

    @IBAction private func aiButtonRelease() {
        guard let aiButton = aiButton else { return }
        UIView.animate(withDuration: 0.2) {
            aiButton.backgroundColor = .clear
        }
    }
}

