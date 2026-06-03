# iOS 프로그래밍 기말 프로젝트

## **[PRD] 청년 정책 맞춤형 지역 알리미: "Youth Bridge"**

### **1. 프로젝트 개요 (Project Overview)**

- **프로젝트명**: **Youth Bridge (청년 브릿지)**
- **목표**: 20대 청년들이 본인 거주 지역에서 시행 중인 다양한 혜택(지원금, 교육, 주거 등)을 놓치지 않도록 맞춤형 정보를 제공하고 마감 기한을 관리함.
- **핵심 가치**: 정보의 지역화(Localization), 혜택의 가시화(Support Info), 기한의 긴박함(D-Day).

### **2. 사용자 분석 및 타겟 (User Persona)**

- **주 사용자**: 거주 지역의 청년 정책(월세 지원, 면접 수당, 통장 지원 등)을 찾고 싶지만, 정보가 너무 흩어져 있어 접근이 어려운 20대 대학생 및 사회초년생.

### **3. 핵심 기능 요구사항 (Functional Requirements)**

#### **3.1 지역 및 조건 필터링 (Filtering)**

- **기능**: 사용자가 원하는 지역(시/도)이나 정책 카테고리(일자리, 주거, 교육 등)를 선택하여 리스트를 필터링함.
- **데이터 매핑**: `zipCd`(우편번호/지역코드) 또는 `operInstCdNm`(운영기관명)을 기준으로 필터링 로직 구현.
- **UI**: Storyboard의 `UIPickerView` 또는 `Filter 전용 ViewController` 활용.

#### **3.2 정책 리스트 및 지원 내용 표시 (List View)**

- **기능**: 필터링된 정책들을 리스트 형태로 노출하고, 정책이 '무엇을', '얼마나' 지원하는지 핵심 요약을 보여줌.
- **데이터 매핑**:
    - 정책명: `plcyNm`
    - 지원 내용(요약): `plcyExplnCn`
    - 카테고리: `lclsfNm` (일자리, 주거 등)
- **UI**: `UITableView`와 커스텀 `UITableViewCell`.

#### **3.3 시행 기간 및 D-Day 카운트다운 (Time Management)**

- **기능**: 정책의 신청 기간을 보여주고, 현재 날짜 기준 마감일까지 남은 일수(D-Day)를 계산하여 시각적으로 표시함.
- **데이터 매핑**: `aplyYmd`(신청일자) 또는 `bizPrdEndYmd`(사업종료일) 사용.
- **로직**: AI에게 "YYYYMMDD 형식의 문자열을 Date 객체로 변환하고 현재 날짜와의 차이를 구하는 Swift 코드를 짜줘"라고 요청.

#### **3.4 상세 정보 및 외부 링크 연결 (Detail & Action)**

- **기능**: 리스트 클릭 시 상세 페이지로 이동하며, 지원 정책의 상세 내용(`plcySprtCn`)을 확인하고 관련 링크가 있을 경우 외부 웹사이트로 연결함.
- **데이터 매핑**:
    - 상세 설명: `plcySprtCn`
    - 연결 링크: `refUrlAddr1` 또는 `aplyUrlAddr`
- **UI**: `SFSafariViewController`를 사용하여 앱 내 브라우저 실행.

#### 3.5 생성형 AI 정책 요약 (AI Summarization)

- **기능**: 공공기관의 길고 딱딱한 정책 설명(`plcySprtCn`)을 Gemini/GPT API를 사용하여 20대 타겟의 핵심 3줄 요약으로 변환함.
- **입력 데이터**: `plcySprtCn` (지원 내용 상세)
- **출력 데이터**: AI가 생성한 요약 텍스트 (예: 혜택 금액, 대상 자격, 신청 방법 등 핵심 위주)
- **UI**: 상세 화면(`DetailViewController`) 내 'AI 3줄 요약' 버튼 및 요약 텍스트 출력용 `UILabel` 또는 `UITextView`

#### **3.6 사용자 정보 로컬 저장 (Local Data Management)**

- **기능**: 별도의 로그인/회원가입 기능 없이 기기의 로컬 캐시를 기반으로 사용자 정보 및 설정(필터 등)을 저장하여 진입 장벽을 낮춤.
- **로직**: `UserDefaults` 또는 `CoreData`를 활용하여 데이터를 앱 내에 안전하고 영구적으로 보관.

#### **3.7 정책 스크랩 및 마감 기한 알림 (Scrap & Local Notification)**

- **기능**: 사용자가 관심 있는 정책을 스크랩하고, 해당 정책의 마감 기한(D-Day)이 다가오면(예: 7일 전) 기기에 로컬 알림(Push)을 발송함.
- **로직**: `UNUserNotificationCenter`를 사용하여 지정된 마감일 기준 특정 시간 전에 알림이 발생하도록 스케줄링.
- **UI**: 리스트 및 상세 화면 내 스크랩(북마크) 버튼 및 마감 알림 설정 토글.

### **4. 기술 스택 및 개발 환경 (Technical Stack)**

- **Platform**: iOS (UIKit)
- **UI Framework**: **Storyboard** 기반 (Interface Builder)
- **Language**: Swift 5
- **Data Handling**: Codable을 이용한 JSON 파싱, URLSession 통신
- **AI 활용**: ViewController 로직 생성, 날짜 계산 함수, API 연동 코드 생성
- **AI API**: Google Gemini API (또는 OpenAI GPT API)
- **AI SDK**: **GoogleGenerativeAI Swift SDK** (Swift Package Manager를 통해 연동)
- **Networking**: 비동기 처리(Async/Await)를 통한 API 통신

### **5. 데이터 매핑 가이드 (JSON to App)**

| **앱 UI 요소** | **JSON 필드명** | **설명** |
| --- | --- | --- |
| **정책 제목** | `plcyNm` | 리스트 및 상세화면 타이틀 |
| **지원 항목/분류** | `lclsfNm` | 일자리, 주거, 금융 등 카테고리 |
| **핵심 지원 내용** | `plcySprtCn` | 얼마만큼 무엇을 지원하는지에 대한 상세 내용 |
| **지역 정보** | `operInstCdNm` | 시행 기관 및 지역 확인용 |
| **신청 기한** | `aplyYmd` | "20260301 ~ 20260331" 형태의 기간 |
| **D-Day** | `aplyYmd` 파싱 |  마감 날짜에서 오늘 날짜를 뺀 값 계산 |
| **신청 링크** | `refUrlAddr1` | 값이 있을 경우 "더 알아보기" 버튼 활성화 |
| AI 요약 텍스트 | `plcySprtCn` (가공) | 원본 데이터를 AI API에 전달하여 3줄 요약문으로 변환 후 출력 |
| 요약 상태 표시 | N/A | AI 응답 대기 중 `UIActivityIndicatorView`를 통해 로딩 상태 표시 |

### **6. 개발 로드맵 (Development Roadmap)**

#### **1단계 (UI 설계)**

Storyboard에서 메인 리스트(Table View), 필터 화면, 상세 정보 화면 레이아웃 구성.

#### **2단계 (데이터 모델링)**

제공된 JSON 구조에 맞춰 Swift `struct` 설계 (AI 활용).

#### **3단계 (네트워킹)**

API 호출 및 JSON 데이터를 모델 객체에 저장하는 로직 구현 (AI 활용).

#### **4단계 (기능 구현)**

지역 필터링 로직, D-Day 계산 알고리즘, 웹뷰 연결 기능, 사용자 정보 로컬 저장 및 스크랩/마감 기한 알림 기능 구현.

#### **5단계 (마무리)**

디자인 다듬기(Auto Layout), 에러 처리 및 최종 보고서 작성.

### **7. AI 프롬프트 예시 (Storyboard 기반)**

- **UI 로직 질문**
    
    "Storyboard에서 `UITableView`를 만들고 `Policy` 배열 데이터를 연결해서 `plcyNm`을 제목으로 띄우는 ViewController 코드를 Swift로 작성해줘."
    
- **날짜 계산 질문**
    
    "JSON에서 `"20260301 ~ 20260331"` 이런 형식의 문자열을 받아. 여기서 뒷부분 날짜를 추출해서 오늘부터 마감일까지 며칠 남았는지(D-Day) 리턴하는 함수를 Swift로 짜줘."
    
- **웹뷰 연결 질문**
    
    "상세 화면에서 버튼을 눌렀을 때 `refUrlAddr1` 주소가 있으면 `SFSafariViewController`로 사이트를 열어주는 코드를 알려줘."
    
- **기술 구현 질문 (ViewController 로직)**
    
    "iOS 스토리보드 기반 앱이야. **GoogleGenerativeAI SDK**를 사용하여 `DetailViewController`에서 특정 버튼을 눌렀을 때, `detailText` 변수에 담긴 긴 문장을 요약해서 `summaryLabel`에 띄워주는 Swift 코드를 작성해줘. API 호출 동안 로딩 인디케이터도 보여주고 싶어."
    
- **프롬프트 엔지니어링 (AI 답변 품질 최적화)**
    
    "Gemini API에게 보낼 시스템 프롬프트를 짜줘. 조건은 다음과 같아:
    
    1. 입력받은 청년 정책 내용을 분석할 것.
    2. 20대 대학생이 이해하기 쉬운 말투를 사용할 것.
    3. 반드시 '지원 금액', '신청 자격', '주의 사항' 위주로 딱 3줄로만 요약할 것.
    4. 가독성을 위해 적절한 이모지를 섞어줄 것."
- **API 보안 관련 질문**
    
    "iOS 앱 개발 시 API Key를 코드에 직접 노출하지 않고 안전하게 관리하거나 감추는 방법을 스토리보드 프로젝트 기준으로 설명해줘.”
    
- **스크랩 및 로컬 알림 구현 질문**
    
    "특정 정책의 데이터를 `UserDefaults`에 스크랩 목록으로 저장하고 불러오는 Swift 코드를 짜줘. 그리고 `UNUserNotificationCenter`를 활용해서 특정 날짜(마감일)의 7일 전에 기기에 로컬 알림을 예약하는 방법도 알려줘."
