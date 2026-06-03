# Youth Bridge — 구현 현황

> 실제 빌드 기준 as-built 문서. PRD·ARCHITECTURE 문서와 다른 부분(Storyboard → 프로그래매틱 UIKit 등)은 이 문서가 우선한다.

---

## 1. 실제 기술 스택

| 영역 | 적용 기술 | 비고 |
|---|---|---|
| UI | UIKit — **완전 프로그래매틱** | Storyboard 미사용 |
| 아키텍처 | MVVM + MVI + Clean Architecture | Action → State + Effect |
| 반응형 바인딩 | Combine (`@Published`, `PassthroughSubject`) | |
| 비동기 처리 | Swift Concurrency (async/await) | |
| DI | `DIContainer` 싱글턴 | |
| AI 요약 | Gemini REST API (`gemini-2.5-flash`) | URLSession 직접 호출 |
| 로컬 저장 | `UserDefaults` | 스크랩 목록, 검색 기록 |
| 로컬 알림 | `UNUserNotificationCenter` | 마감 7일 전 |
| 외부 링크 | `SFSafariViewController` | |
| API Key 보안 | `Config.plist` (`.gitignore` 적용) | |

---

## 2. 실제 폴더 구조

```
YouthBridge/
├── Application/
│   └── AppDelegate.swift
│
├── Presentation/
│   ├── Home/
│   │   ├── HomeViewController.swift       # 메인 피드 (헤더 + 긴급공고 + 전체목록)
│   │   ├── HomeViewModel.swift
│   │   └── HomeState.swift                # HomeState + FilterState
│   ├── Detail/
│   │   └── DetailViewController.swift     # 상세 + AI 요약 + 스크랩 + 외부링크
│   ├── Filter/
│   │   ├── FilterViewController.swift     # 지역 / 카테고리 / 정책상태 필터
│   │   └── FilterViewModel.swift
│   ├── Search/
│   │   ├── SearchViewController.swift     # 검색 + 최근검색어 + 인기검색어
│   │   └── SearchViewModel.swift
│   ├── Scrap/
│   │   ├── ScrapViewController.swift      # 스크랩 목록
│   │   └── ScrapViewModel.swift
│   └── Common/
│       ├── Cells/
│       │   └── PolicyCardCell.swift       # 공통 정책 카드 셀
│       └── AppTabBarController.swift
│
├── Domain/
│   ├── Entities/
│   │   └── Policy.swift                   # 도메인 모델 + computed properties
│   ├── Repositories/
│   │   ├── PolicyRepository.swift         # protocol
│   │   └── ScrapRepository.swift          # protocol
│   └── UseCases/
│       ├── FetchPoliciesUseCase.swift
│       ├── SummarizePolicyUseCase.swift
│       ├── ScrapPolicyUseCase.swift
│       ├── GetScrappedPoliciesUseCase.swift
│       └── ScheduleNotificationUseCase.swift
│
├── Data/
│   ├── DTOs/
│   │   └── PolicyDTO.swift                # API 응답 Codable 모델
│   ├── Mappers/
│   │   └── PolicyMapper.swift             # DTO → Entity
│   ├── DataSources/
│   │   ├── Remote/
│   │   │   ├── PolicyRemoteDataSource.swift    # 온통청년 API
│   │   │   └── GeminiRemoteDataSource.swift    # Gemini REST API
│   │   └── Local/
│   │       └── ScrapLocalDataSource.swift      # UserDefaults
│   └── Repositories/
│       ├── PolicyRepositoryImpl.swift
│       └── ScrapRepositoryImpl.swift
│
├── Common/
│   ├── Extensions/
│   ├── Design/
│   │   ├── AppColor.swift
│   │   └── AppFont.swift
│   └── DI/
│       └── DIContainer.swift
│
└── Resources/
    └── Config.plist                       # gitignore 처리된 API Key 저장소
```

---

## 3. 화면별 구현 상세

### 3.1 Home (홈)

**파일**: `HomeViewController.swift`, `HomeViewModel.swift`, `HomeState.swift`

**주요 기능**
- 상단 고정 헤더: 그라디언트 배경, 통계 텍스트 (진행 중 N개 / 마감 임박 N개)
- 긴급 공고 섹션: 마감 7일 이내 정책 수평 스크롤
- 전체 목록: 페이지네이션 (20개/페이지, 스크롤 하단 도달 시 추가 로드)
- 필터: `FilterViewController` 모달 → `HomeViewModel.onAction(.applyFilter(...))`

**레이아웃 핵심**
```swift
// headerView는 view에 직접 addSubview, tableView는 headerView.bottomAnchor 아래에 배치
// contentInsetAdjustmentBehavior = .never 로 safe area 자동 조정 차단
// bringSubviewToFront(headerView) 로 스크롤 시 헤더가 테이블 위에 유지
tableView.contentInsetAdjustmentBehavior = .never
view.bringSubviewToFront(headerView)
```

**정책 상태 필터링** (클라이언트 사이드)
```swift
// HomeState.swift
var displayPolicies: [Policy] {
    switch appliedFilter.policyStatus {
    case .active:  return allPolicies.filter { !$0.isExpired }
    case .expired: return allPolicies.filter { $0.isExpired }
    case .all:     return allPolicies
    }
}
```

---

### 3.2 PolicyCardCell (공통 카드 셀)

**파일**: `PolicyCardCell.swift`

**두 레이어 구조** (그림자 + 콘텐츠 분리)
```
shadowContainer (masksToBounds = false → 그림자 렌더링)
    └── cardView (masksToBounds = true → 콘텐츠 클리핑)
            ├── urgentBar (상단 색상 바, 카드 모서리에서 자연스럽게 클리핑)
            ├── dDayBadge
            ├── titleLabel
            ├── categoryLabel
            ├── periodLabel
            └── actionLabel ("상세 보기 ›" 고정)
```

**그림자 경로 최적화** (layoutSubviews에서 매번 갱신)
```swift
override func layoutSubviews() {
    super.layoutSubviews()
    shadowContainer.layer.shadowPath = UIBezierPath(
        roundedRect: shadowContainer.bounds, cornerRadius: 14
    ).cgPath
}
```

**D-Day 배지 로직**
```swift
func configure(with policy: Policy) {
    let hasDeadline = !policy.applyPeriod.trimmingCharacters(in: .whitespaces).isEmpty
    if !hasDeadline {
        dDayBadge.text = "상시"
        urgentBar.isHidden = true
        // 파란색 배지
    } else if policy.isExpired {
        dDayBadge.text = "마감"
        // 회색 배지
    } else if dDay <= 7 {
        dDayBadge.text = "D-\(dDay)"
        // 빨간색 긴급 배지 + urgentBar 표시
    } else {
        dDayBadge.text = "D-\(dDay)"
        // 기본 배지
    }
    actionLabel.text = "상세 보기 ›"  // 항상 동일
}
```

**InkWell 리플 효과**
- `rippleView`: 흰색 반투명 원, `cardView` 위에 절대 위치
- `touchesBegan`: 터치 위치에 원 생성 → scale 확대 애니메이션
- `touchesEnded/Cancelled`: fade out 애니메이션

---

### 3.3 Detail (상세)

**파일**: `DetailViewController.swift`

**레이아웃**
- `UIScrollView` + `contentView` (스크롤 영역)
- 상단: 카테고리 배지(왼쪽) + D-Day 배지(오른쪽, 마감 없으면 숨김)
- 정책명, 운영기관, 신청기간, 지원내용
- AI 요약 버튼 → 요약 결과 레이블
- "신청하러 가기" 버튼 (외부 링크)

**AI 버튼 구현** (`UIButton.Configuration` 사용 — `contentEdgeInsets` deprecated 대응)
```swift
var btnConfig = UIButton.Configuration.plain()
btnConfig.title = "AI 3줄 요약 보기"
btnConfig.baseForegroundColor = AppColor.primary
btnConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
aiButton.configuration = btnConfig

// 로딩 인디케이터를 버튼 중앙에 배치
aiButton.addSubview(aiIndicator)
NSLayoutConstraint.activate([
    aiIndicator.centerXAnchor.constraint(equalTo: aiButton.centerXAnchor),
    aiIndicator.centerYAnchor.constraint(equalTo: aiButton.centerYAnchor),
])
```

**AI 상태 전환**
```swift
// 로딩 시작
aiButton.configuration?.title = ""
aiIndicator.startAnimating()

// 완료
aiIndicator.stopAnimating()
aiButton.configuration?.title = "AI 3줄 요약 보기"
aiSummaryLabel.text = result
```

**신청기간 포맷**
- `Policy.displayApplyPeriod`: `"20251222 ~ 20261211"` → `"2025.12.22 ~ 2026.12.11"`
- 빈 문자열 → `"기간이 정해져있지 않습니다"`

---

### 3.4 Filter (필터)

**파일**: `FilterViewController.swift`, `FilterViewModel.swift`

**섹션 구성**
1. **지역 선택**: 5열 그리드 칩 버튼 (글래스 스타일, 활성/비활성 토글)
2. **카테고리**: 2열 벤토 카드 (아이콘 + 색상 배경)
3. **정책 상태**: `UISegmentedControl` — `["진행 중", "마감", "전체"]`

**화면 너비 계산** (`UIScreen.main` deprecated 대응)
```swift
private var availableWidth: CGFloat {
    let w = view.bounds.width
    if w > 0 { return w }
    return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.screen.bounds.width ?? 390
}
```

**FilterState**
```swift
struct FilterState {
    var selectedRegions: [String] = []
    var selectedCategories: [String] = []
    var policyStatus: PolicyStatus = .active  // 기본값: 진행 중

    var isDefault: Bool {
        selectedRegions.isEmpty && selectedCategories.isEmpty && policyStatus == .active
    }
    enum PolicyStatus { case active, expired, all }
}
```

---

### 3.5 Search (검색)

**파일**: `SearchViewController.swift`, `SearchViewModel.swift`

**기능**
- `UISearchController` 연동 (네비게이션 바 내장)
- 최근 검색어: `UserDefaults` 저장, 최대 10개, 스와이프 삭제
- 인기 검색어: 하드코딩 트렌딩 키워드 (`["#청년수당", "#월세지원", ...]`)
- 검색 결과: `PolicyCardCell` 재사용
- 필터 버튼: 활성 필터 적용 시 파란색으로 변경

**최근 검색어 스와이프 삭제**
```swift
func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard !viewModel.state.showResults, indexPath.section == 0 else { return nil }
    let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
        self?.viewModel.onAction(.deleteHistoryItem(kw))
        completion(true)
    }
    return UISwipeActionsConfiguration(actions: [delete])
}
```

**필터 연동**
```swift
// SearchState에 appliedFilter 포함
case .applyFilter(let filter):
    state.appliedFilter = filter
    if !state.keyword.isEmpty { performSearch(state.keyword) }
```

---

## 4. Domain — Policy Entity

**파일**: `Policy.swift`

**주요 Computed Properties**

```swift
struct Policy {
    // API 매핑 필드 생략...

    // 마감 여부
    var isExpired: Bool { ... }  // applyPeriod 종료일 < 오늘

    // D-Day 숫자
    var dDay: Int? { ... }       // nil = 상시

    // 포맷된 신청기간
    var displayApplyPeriod: String {
        let trimmed = applyPeriod.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "기간이 정해져있지 않습니다" }
        let parts = trimmed.components(separatedBy: "~")
        guard parts.count == 2 else { return trimmed }
        let input = DateFormatter(); input.dateFormat = "yyyyMMdd"
        let output = DateFormatter(); output.dateFormat = "yyyy.MM.dd"
        func fmt(_ s: String) -> String {
            let raw = s.trimmingCharacters(in: .whitespaces)
            return input.date(from: raw).map { output.string(from: $0) } ?? raw
        }
        return "\(fmt(parts[0])) ~ \(fmt(parts[1]))"
    }
}
```

---

## 5. Data — Gemini API 연동

**파일**: `GeminiRemoteDataSource.swift`

**모델**: `gemini-2.5-flash`
**엔드포인트**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`

**핵심 구현 사항**
- `URLComponents`로 URL 빌드 (API 키 특수문자 인코딩 문제 방지)
- 입력 콘텐츠 400자로 자름 (TPM 제한 대응)
- 429 응답 시 6초 대기 후 최대 2회 재시도

```swift
private static let maxContentLength = 400
private static let maxRetries = 2

private func sendWithRetry(request: URLRequest, retriesLeft: Int) async throws -> String {
    let (data, response) = try await URLSession.shared.data(for: request)
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
    if statusCode == 429, retriesLeft > 0 {
        try await Task.sleep(nanoseconds: 6_000_000_000)
        return try await sendWithRetry(request: request, retriesLeft: retriesLeft - 1)
    }
    // 응답 파싱...
}
```

---

## 6. 주요 버그 수정 이력

| 증상 | 원인 | 해결 방법 |
|---|---|---|
| AI 요약 "불러오지 못했습니다" | URL 인코딩 오류, 모델 deprecated | `URLComponents` 사용, 모델 → `gemini-2.5-flash` |
| AI 429 오류 (RPM 초과) | 입력 텍스트 과다, 요청 과잉 | 400자 truncation + 재시도 로직 |
| urgentBar 모서리 삐져나옴 | `masksToBounds=true`가 그림자도 차단 | `shadowContainer`(그림자 전용) + `cardView`(클리핑 전용) 분리 |
| 헤더가 스크롤 시 내려감 | `sectionLabel`이 view에 독립 배치, safe area 변화 시 재배치 | `sectionLabel`을 `headerView` 내부로 이동, content-based 높이 |
| 빌드 오류: UISearchResultsUpdater | 프로토콜 이름 오타 | `UISearchResultsUpdater` → `UISearchResultsUpdating` |
| 경고: UIScreen.main deprecated | iOS 26에서 deprecated | `UIWindowScene` 통해 `screen.bounds.width` 획득 |
| 경고: contentEdgeInsets deprecated | iOS 15에서 deprecated | `UIButton.Configuration` + `NSDirectionalEdgeInsets` |
| AI 인디케이터 버튼 오른쪽 배치 | `setTitle` + `imageView` 기본 레이아웃 | `UIButton.Configuration`으로 타이틀만 사용, 인디케이터를 `centerX/Y` 제약으로 버튼 중앙 배치 |

---

## 7. API 명세

### 온통청년 정책 API

- **Base URL**: `https://www.youthcenter.go.kr/go/ythip/getPlcy`
- **주요 파라미터**: `apiKeyNm`, `pageNum`, `pageSize`, `rtnType=json`
- **필터링**: 클라이언트 사이드 (`zipCd` prefix → 지역, `lclsfNm` keywords → 카테고리, `isExpired` → 상태)
- **페이지 크기**: 20 (`HomeState.pageSize`)

### Gemini API

- **Base URL**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- **인증**: Query parameter `key`
- **입력**: `plcySprtCn` (최대 400자)
- **출력**: 20대 타겟 핵심 3줄 요약

---

## 8. API Key 관리

```
Config.plist (gitignore 처리)
    YOUTH_POLICY_API_KEY = "..."
    GEMINI_API_KEY = "..."
```

코드에서 읽기:
```swift
Bundle.main.object(forInfoDictionaryKey: "YOUTH_POLICY_API_KEY") as? String
```

---

## 9. 네비게이션 구조

```
AppTabBarController
    ├── Tab 0: HomeViewController (NavigationController 포함)
    │   ├── → DetailViewController (push)
    │   └── → FilterViewController (modal, pageSheet)
    ├── Tab 1: SearchViewController (NavigationController 포함)
    │   ├── → DetailViewController (push)
    │   └── → FilterViewController (modal, pageSheet)
    └── Tab 2: ScrapViewController (NavigationController 포함)
        └── → DetailViewController (push)
```

**네비게이션 바 처리**
- Home: `viewWillAppear`에서 `setNavigationBarHidden(true)` — 커스텀 헤더 사용
- Detail: `viewWillAppear`에서 `setNavigationBarHidden(false)` — 뒤로가기 버튼 표시
- Filter: `UINavigationController` 래핑하여 `pageSheet` 모달로 표시
