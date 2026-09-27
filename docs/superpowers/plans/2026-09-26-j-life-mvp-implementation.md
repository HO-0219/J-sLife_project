# J의 삶 MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 서버 없이 동작하는 Flutter 생활 관리 MVP를 만들고, 커스텀 대시보드·로컬 금액 통계·광고/PRO 준비 구조를 제공한다.

**Architecture:** 기능별 feature 폴더와 공통 domain 모델을 사용한다. 저장소, 알림, 광고와 결제는 인터페이스 뒤에 두고 MVP에서는 로컬 및 비활성 구현을 사용한다.

**Tech Stack:** Flutter, Dart, Material 3, Riverpod, Drift/SQLite, flutter_local_notifications, fl_chart

**Spec:** `docs/superpowers/specs/2026-09-26-j-life-product-design.md`

## Global Constraints

- Android 우선이지만 Flutter 공통 코드는 iOS 호환성을 해치지 않는다.
- 회원가입, 서버, 금융 API, 알림 읽기와 타 앱 내부 데이터 접근을 사용하지 않는다.
- 실제 광고 SDK와 인앱결제 SDK는 연결하지 않는다.
- 광고 및 결제 교체 지점과 화면 상태는 구현한다.
- 제목과 기준 날짜만으로 항목을 등록할 수 있어야 한다.

## Review Focus

- 월말·윤년 반복은 존재하는 마지막 날짜로 보정한다.
- 금액이 없는 항목은 통계에서 제외한다.
- 항목 수정 후에도 과거 완료 금액 스냅샷은 바뀌지 않는다.
- PRO에서는 광고 영역과 여백이 모두 제거된다.
- 사용자 대시보드 순서와 숨김 상태는 앱 재시작 후 유지된다.

---

### Task 1: Flutter 앱 기반과 디자인 시스템

**Files:** `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/theme/app_theme.dart`, `test/app_smoke_test.dart`

**Interfaces:** `JLifeApp`, `AppTheme.light`

- [ ] 기본 프로젝트와 의존성을 선언한다.
- [ ] 앱 시작 및 Material 3 테마 위젯 테스트를 작성한다.
- [ ] 앱 셸과 하단 내비게이션을 구현한다.
- [ ] `flutter test`로 검증한다.

### Task 2: 생활 항목 도메인과 반복 계산

**Files:** `lib/features/items/domain/life_item.dart`, `life_history.dart`, `recurrence.dart`, `test/features/items/domain/recurrence_test.dart`

**Interfaces:** `calculateNextDue(DateTime completedAt, RepeatRule rule) -> DateTime?`

- [ ] 일반 반복, 월말과 윤년 실패 테스트를 작성한다.
- [ ] 불변 모델과 반복 계산을 구현한다.
- [ ] 도메인 테스트를 실행한다.

### Task 3: 로컬 저장과 앱 상태

**Files:** `lib/features/items/data/life_repository.dart`, `memory_life_repository.dart`, `lib/features/items/application/life_controller.dart`, 관련 테스트

**Interfaces:** `LifeRepository.watchItems`, `saveItem`, `completeItem`, `deleteItem`; `LifeController`

- [ ] CRUD와 완료 스냅샷 테스트를 작성한다.
- [ ] 저장소 인터페이스 및 로컬 MVP 구현을 추가한다.
- [ ] Riverpod 상태와 완료 흐름을 구현한다.
- [ ] 테스트를 실행한다.

### Task 4: 홈·목록·등록·상세 화면

**Files:** `lib/features/dashboard/presentation/home_screen.dart`, `lib/features/items/presentation/*.dart`, 위젯 테스트

**Interfaces:** `HomeScreen`, `ItemsScreen`, `ItemEditorScreen`, `ItemDetailScreen`

- [ ] 빈 상태와 항목 등록 흐름 테스트를 작성한다.
- [ ] 오늘·임박·나중 구간과 항목 카드를 구현한다.
- [ ] 최소 입력 폼과 상세·완료 UX를 구현한다.
- [ ] 위젯 테스트를 실행한다.

### Task 5: 금액 통계와 그래프

**Files:** `lib/features/statistics/domain/statistics.dart`, `lib/features/statistics/presentation/statistics_screen.dart`, 관련 테스트

**Interfaces:** `buildMonthlySummary(items, histories, month) -> MonthlySummary`

- [ ] 예정/확정 수입·지출 및 금액 없음 테스트를 작성한다.
- [ ] 통계 계산과 요약 모델을 구현한다.
- [ ] 요약 카드, 막대그래프와 카테고리 비중 UI를 구현한다.
- [ ] 테스트를 실행한다.

### Task 6: 프리셋과 대시보드 커스텀

**Files:** `lib/features/customization/domain/*.dart`, `lib/features/customization/presentation/customize_screen.dart`, 관련 테스트

**Interfaces:** `DashboardConfig`, `DashboardPreset`, `CustomizationController`

- [ ] 프리셋 적용, 카드 숨김과 순서 변경 테스트를 작성한다.
- [ ] 기본 생활·돈/구독·차량·집 프리셋을 구현한다.
- [ ] 카드 토글과 재정렬 화면을 구현한다.
- [ ] 테스트를 실행한다.

### Task 7: 광고·결제 준비 경계와 설정

**Files:** `lib/features/monetization/domain/*.dart`, `lib/features/monetization/presentation/ad_slot.dart`, `lib/features/settings/presentation/settings_screen.dart`, 관련 테스트

**Interfaces:** `EntitlementService`, `AdPolicy`, `AdSlot`

- [ ] 무료/PRO 광고 정책 테스트를 작성한다.
- [ ] SDK 없는 개발용 권한 서비스와 광고 플레이스홀더를 구현한다.
- [ ] PRO 기능 안내 및 구매 준비 화면을 구현한다.
- [ ] 실제 SDK가 없다는 문구와 비활성 동작을 명확히 한다.

### Task 8: 전체 검증과 문서

**Files:** `README.md`, 전체 테스트

**Interfaces:** 없음

- [ ] 정적 분석과 전체 테스트를 실행한다.
- [ ] 지원 범위, 실행법, SDK 미연동 상태와 향후 연결 지점을 문서화한다.
- [ ] Flutter SDK가 없는 환경에서는 실행하지 못한 검증을 정확히 기록한다.

