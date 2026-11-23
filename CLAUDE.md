# 윷빵 (yutbbang) 작업 규칙

Flutter 윷놀이 게임. 구조와 규칙 설명은 `README.md`를 본다.

## 명령

```bash
flutter test               # 전체 테스트
flutter test --coverage    # 커버리지 (coverage/lcov.info)
flutter analyze            # 0건 유지
dart format lib test
flutter build web          # 로컬엔 Xcode가 없어 macOS 빌드 불가 → 웹으로 실행 확인
```

## 개발 방식: TDD

모든 기능 추가·버그 수정·리팩터링은 **RED → GREEN → REFACTOR**로 한다.

1. **RED**: 원하는 동작을 테스트로 먼저 쓰고, 실행해서 **기대한 이유로 실패하는지** 확인한다.
   - 버그는 먼저 재현 테스트를 쓰고 실패를 확인한 뒤 고친다. 테스트 이름에 `(회귀)`를 붙인다.
2. **GREEN**: 테스트를 통과하는 최소한의 코드만 쓴다.
3. **REFACTOR**: 테스트가 초록인 상태에서만 정리한다.
   - 테스트가 없는 기존 코드를 고칠 때는 현재 동작을 고정하는 테스트를 먼저 쓴다.

완료 기준: `flutter test` 전부 통과, `flutter analyze` 0건.

## 계층과 테스트 위치

| 계층 | 위치 | 규칙 | 테스트 |
|---|---|---|---|
| 게임 규칙 | `lib/domain/` | Flutter import 금지, 순수 함수(상태를 받아 새 상태 반환) | `test/domain/` |
| 저장소 | `lib/data/` | | `test/data/` |
| 상태 머신 | `lib/presentation/providers/` | `GameNotifier`는 순서 제어(타이머·CPU 예약)만. 규칙 계산은 domain에 둔다 | `test/presentation/notifier/` |
| 화면 파생 값 | `lib/presentation/providers/game_view.dart` | 위젯 안의 조건식(`if (state.status == ... && isHuman)`)은 여기에 extension 게터로 둔다 | `test/presentation/game_view_test.dart` |
| 위젯·화면 | `lib/presentation/` | 로직 없이 `GameStateView`와 notifier 호출만 | 위젯 테스트 |
| Flame | `lib/game/` | 좌표 계산은 `BoardLayout`(순수) | `test/game/` |

## 테스트 도구 (`test/helpers/`)

- `fixtures.dart`
  - `team(index, positions, ...)`: 말 위치로 팀 만들기. `null`은 대기 말.
  - `FakeRandom`: 정해진 난수 순서를 돌려준다.
- `fake_game_notifier.dart`
  - `fakeGame(state)`: 위젯 테스트용. 상태를 주입하고 `emit()`으로 바꾸며, UI가 부른 액션을 `calls`에 기록한다.
- `game_scene.dart`
  - `GameScene.start(tester, teams, ...)`: 실제 `GameNotifier`를 원하는 장면에서 시작한다. 끝에 `scene.finish(tester)`.
  - 타이머는 `testWidgets`의 fake async로 `tester.pump(Duration)` 해서 진행한다.
- 게임 결과에 영향을 주는 난수는 `gameRandomProvider`로만 얻는다(테스트에서 override). 화면 연출용 난수는 예외.

## 디자인

- 스타일: 모던 미니멀(`docs/design/concept-modern-minimal.jpg`). 색은 `AppPalette`, 테마는 `buildAppTheme()`만 쓴다. 위젯에 `Colors.brown` 같은 색을 직접 쓰지 않는다.
- 팀 색은 `teamColorOf` / `softTeamColorOf` / `darkerTeamColorOf`. 대비 기준은 `test/presentation/app_palette_test.dart`가 검사한다.
- 이미지 에셋 경로는 `AppAssets`에만 둔다. 생성 방법·프롬프트는 `assets/images/README.md`.

## 기타

- 브랜치 없이 `main`에서 작업한다.
- 앱 안 가이드(`lib/presentation/guide/guide_content.dart`)와 README의 규칙 설명은 코드 동작과 맞춘다. `test/presentation/guide_test.dart`가 아이템 이름 일치를 검사한다.
