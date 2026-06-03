# Youth Bridge — 구현 계획 및 아키텍처

> 실제 구현 상세는 [IMPLEMENTATION.md](IMPLEMENTATION.md)를 참조.

## 1. 프로젝트 개요

- **앱명**: Youth Bridge (청년 브릿지)
- **플랫폼**: iOS (UIKit — **완전 프로그래매틱**, Storyboard 미사용)
- **언어**: Swift 5
- **목표**: 온통청년 API 기반 청년 정책 맞춤형 알리미

---

## 2. 기술 스택

| 영역 | 기술 |
|---|---|
| UI | UIKit — 완전 프로그래매틱 (Storyboard 미사용) |
| 비동기 통신 | Async/Await + URLSession |
| JSON 파싱 | Codable |
| 상태 바인딩 | Combine (`@Published`, `PassthroughSubject`) |
| AI 요약 | Google Gemini REST API (`gemini-2.5-flash`, URLSession 직접 호출) |
| 로컬 저장 | UserDefaults |
| 로컬 알림 | UNUserNotificationCenter |
| 외부 링크 | SFSafariViewController |
| 디자인 참조 | Figma (talkToFigma MCP 연동) |

---

## 3. 아키텍처: MVVM + MVI + Clean Architecture

### 레이어 구성

```
Presentation Layer
    ViewController  →  (Action)  →  ViewModel
    ViewController  ←  (State)   ←  ViewModel
    ViewController  ←  (Effect)  ←  ViewModel

Domain Layer
    UseCase → Repository (protocol)

Data Layer
    Repository (impl) → DataSource (Remote / Local)
    DataSource → DTO → Mapper → Entity
```

### 의존성 방향

```
Presentation → Domain ← Data
```

- Presentation은 UseCase만 알고, Repository 구현체를 모름
- Domain은 어떤 프레임워크에도 의존하지 않는 순수 Swift

---

## 4. MVI 이벤트 버스 패턴

Flutter의 sealed class + onAction 패턴을 Swift로 1:1 대응.

| Flutter | Swift |
|---|---|
| `sealed class Event` | `enum Action` (associated values) |
| `onAction(event) { switch }` | `func onAction(_ action: Action) { switch action { ... } }` |
| `BlocBase.emit(state)` | `@Published var state` (Combine) |
| `BlocListener` (일회성 이벤트) | `PassthroughSubject<Effect, Never>` |

### 3채널 분리

```
View ──[Action]──▶ ViewModel.onAction()    // 사용자 액션 (단방향 입력)
     ◀──[State]── ViewModel.$state         // UI 렌더링용 상태 (연속 스트림)
     ◀──[Effect]─ ViewModel.effect         // 네비게이션·토스트 등 일회성 이벤트
```

### 코드 구조 예시 (PolicyList 기준)

```swift
// Action — 사용자가 발생시키는 모든 액션
enum PolicyListAction {
    case fetchPolicies
    case selectRegion(String)
    case selectCategory(String)
    case tapPolicy(Policy)
    case toggleScrap(Policy)
    case tapFilter
}

// State — 불변 스냅샷 (UI 렌더링에만 사용)
struct PolicyListState {
    var isLoading: Bool = false
    var policies: [Policy] = []
    var errorMessage: String? = nil
    var selectedRegion: String = "전체"
    var selectedCategory: String = "전체"
}

// Effect — 일회성 사이드이펙트 (네비게이션 등)
enum PolicyListEffect {
    case navigateToDetail(Policy)
    case navigateToFilter
    case showError(String)
    case showToast(String)
}

// ViewModel — 단일 진입점 onAction
class PolicyListViewModel {
    @Published private(set) var state = PolicyListState()
    let effect = PassthroughSubject<PolicyListEffect, Never>()

    func onAction(_ action: PolicyListAction) {
        switch action {
        case .fetchPolicies:        fetchPolicies()
        case .selectRegion(let r):  updateRegion(r)
        case .selectCategory(let c): updateCategory(c)
        case .tapPolicy(let p):     effect.send(.navigateToDetail(p))
        case .toggleScrap(let p):   handleScrap(p)
        case .tapFilter:            effect.send(.navigateToFilter)
        }
    }
}

// ViewController — bindState (BlocBuilder) + bindEffect (BlocListener)
class PolicyListViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindState()
        bindEffect()
        viewModel.onAction(.fetchPolicies)
    }

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
                switch effect {
                case .navigateToDetail(let p): self?.pushDetail(p)
                case .navigateToFilter:        self?.presentFilter()
                case .showError(let msg):      self?.showAlert(msg)
                case .showToast(let msg):      self?.showToast(msg)
                }
            }
            .store(in: &cancellables)
    }
}
```

---

## 5. 폴더 구조

```
YouthBridge/
│
├── Presentation/                          # UI 레이어
│   ├── PolicyList/
│   │   ├── PolicyListViewController.swift
│   │   ├── PolicyListViewModel.swift
│   │   ├── PolicyListState.swift
│   │   └── PolicyListAction.swift         # Action + Effect enum
│   ├── Filter/
│   │   ├── FilterViewController.swift
│   │   ├── FilterViewModel.swift
│   │   ├── FilterState.swift
│   │   └── FilterAction.swift
│   ├── Detail/
│   │   ├── DetailViewController.swift
│   │   ├── DetailViewModel.swift
│   │   ├── DetailState.swift
│   │   └── DetailAction.swift
│   └── Scrap/
│       ├── ScrapViewController.swift
│       ├── ScrapViewModel.swift
│       ├── ScrapState.swift
│       └── ScrapAction.swift
│
├── Domain/                                # 비즈니스 로직 레이어 (프레임워크 의존 없음)
│   ├── Entities/
│   │   └── Policy.swift                   # 앱 내부 도메인 모델
│   ├── Repositories/                      # protocol 정의만
│   │   ├── PolicyRepository.swift
│   │   └── ScrapRepository.swift
│   └── UseCases/
│       ├── FetchPoliciesUseCase.swift
│       ├── FilterPoliciesUseCase.swift
│       ├── ScrapPolicyUseCase.swift
│       ├── GetScrappedPoliciesUseCase.swift
│       ├── SummarizePolicyUseCase.swift    # Gemini 요약
│       └── ScheduleNotificationUseCase.swift
│
├── Data/                                  # 데이터 레이어
│   ├── DTOs/                              # API 응답 모델 (Codable)
│   │   ├── PolicyDTO.swift
│   │   └── APIResponseDTO.swift
│   ├── Mappers/
│   │   └── PolicyMapper.swift             # DTO → Domain Entity 변환
│   ├── DataSources/
│   │   ├── Remote/
│   │   │   ├── PolicyRemoteDataSource.swift    # 온통청년 API
│   │   │   └── GeminiRemoteDataSource.swift    # Gemini API
│   │   └── Local/
│   │       └── ScrapLocalDataSource.swift      # UserDefaults
│   └── Repositories/                     # protocol 구현체
│       ├── PolicyRepositoryImpl.swift
│       └── ScrapRepositoryImpl.swift
│
├── Common/
│   ├── Extensions/
│   │   └── Date+Extensions.swift          # D-Day 계산 유틸
│   └── DI/
│       └── DIContainer.swift              # 의존성 주입
│
└── Resources/
    ├── Config.plist                       # API Key (gitignore 처리)
    └── Base.lproj/Main.storyboard
```

---

## 6. 화면 구성 (Storyboard)

```
NavigationController
    └── PolicyListViewController       메인 (UITableView + 필터바)
            ├── FilterViewController   Modal: UIPickerView × 2 (지역, 카테고리)
            ├── DetailViewController   Push: 상세 + AI 요약 + 외부링크
            └── ScrapViewController    Push: 스크랩 목록
```

| 화면 | 주요 컴포넌트 |
|---|---|
| PolicyList | UITableView, PolicyTableViewCell (정책명 / 카테고리 / D-Day 뱃지) |
| Filter | UIPickerView ×2 (지역, 카테고리), 적용 버튼 |
| Detail | UIScrollView, AI 요약 버튼, UIActivityIndicatorView, SFSafariViewController 연결, 스크랩 버튼 |
| Scrap | UITableView (저장된 정책만 표시) |

---

## 7. 데이터 매핑 (온통청년 API → Domain Entity)

| Domain Entity 필드 | API JSON 필드 | 설명 |
|---|---|---|
| `name` | `plcyNm` | 정책명 |
| `category` | `lclsfNm` | 일자리 / 주거 / 금융 등 |
| `supportContent` | `plcySprtCn` | 지원 내용 상세 (AI 요약 입력값) |
| `operatingOrg` | `operInstCdNm` | 운영기관 / 지역 |
| `applyPeriod` | `aplyYmd` | `"20260301 ~ 20260331"` 형식 |
| `externalUrl` | `refUrlAddr1` | 외부 링크 (없으면 `nil`) |

### D-Day 계산 로직

```swift
// "20260301 ~ 20260331" → 마감일 추출 → 오늘과의 차이
extension String {
    func extractDeadline() -> Date? { ... }
}
extension Date {
    var dDayText: String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: self).day ?? 0
        if days < 0  { return "마감" }
        if days == 0 { return "D-Day" }
        return "D-\(days)"
    }
}
```

---

## 8. 개발 로드맵

| 단계 | 작업 |
|---|---|
| Phase 1 | Storyboard UI 설계 — 4개 화면 레이아웃 + NavigationController |
| Phase 2 | Domain 레이어 — Entity, Repository protocol, UseCase |
| Phase 3 | Data 레이어 — DTO, Mapper, DataSource, Repository 구현체 |
| Phase 4 | Presentation 레이어 — ViewModel (onAction/State/Effect) + ViewController 바인딩 |
| Phase 5 | 기능 연결 — 필터링, D-Day, AI 요약, 스크랩, 로컬 알림 |
| Phase 6 | 마무리 — Auto Layout, 에러 처리, API Key 보안 (Config.plist + .gitignore) |

---

## 9. API Key 보안

```
Config.plist (gitignore)
    YOUTH_POLICY_API_KEY = "..."
    GEMINI_API_KEY = "..."
```

- `Config.plist`를 `.gitignore`에 추가
- 코드에서는 `Bundle.main.infoDictionary`로 읽기
- 절대 소스코드에 하드코딩 금지

---

## 10. MCP 연동 (Figma)

- **서버**: `cursor-talk-to-figma-mcp` (`.mcp.json`에 프로젝트 범위로 등록 완료)
- **사용 전 준비**: Figma 앱에서 "Cursor Talk To Figma" 플러그인 실행 → Start Server
- **용도**: Figma 디자인에서 컴포넌트 스펙(색상, 폰트, 레이아웃) 직접 참조하여 구현
