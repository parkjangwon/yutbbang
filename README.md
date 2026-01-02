# 윷빵 (yutbbang)

전통 윷놀이를 모바일/데스크톱에서 즐길 수 있도록 만든 Flutter 게임입니다.  
Flame으로 게임판을 렌더링하고 Riverpod으로 상태를 관리합니다.

## 주요 기능

- 윷/모 보너스 턴, 빽도, 낙 처리
- 말 잡기/겹치기, 지름길 선택
- 로컬 멀티(플레이어 1~4) + CPU 대전
- 게임 시작 설정(팀/말/규칙/낙 확률)과 글로벌 설정(난이도/낙 확률)
- 게임 가이드 화면 제공

## 시작하기

### 요구 사항

- Flutter SDK (Dart SDK 포함)
- macOS/Windows/Linux 또는 Android/iOS 환경

### 실행

```bash
flutter pub get
flutter run
```

### macOS 실행 예시

```bash
flutter run -d macos
```

## 설정 안내

### 게임 시작 설정(인스턴트)

해당 판에만 적용되는 설정입니다.

- 팀 수/팀 이름
- 팀별 CPU 또는 플레이어 선택
- 말 수, 빽도 사용, 낙 확률

### 글로벌 설정(저장)

전체 게임에 적용되는 기본 설정입니다.

- CPU 난이도
- 낙 확률
- 윷놀이 가이드 보기

## 프로젝트 구조

- `lib/main.dart`: 앱 엔트리
- `lib/presentation/screens/`: 화면(UI)
- `lib/presentation/providers/`: 상태 관리(Riverpod)
- `lib/domain/logic/`: 게임 규칙 로직
- `lib/domain/models/`: 도메인 모델
- `lib/game/`: Flame 게임 컴포넌트
- `assets/`: 이미지 리소스

## 참고

앱 내 "윷놀이 가이드"에서 규칙과 게임 설명을 확인할 수 있습니다.
