// UI/UX 개선 사항 (레이아웃, 내비게이션, 정보 표시, 접근성).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/team.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';
import 'package:yutbbang/presentation/screens/game_screen.dart';
import 'package:yutbbang/presentation/screens/game_setup_screen.dart';
import 'package:yutbbang/presentation/screens/lobby_screen.dart';
import 'package:yutbbang/presentation/screens/settings_screen.dart';
import 'package:yutbbang/presentation/screens/yut_guide_screen.dart';
import 'package:yutbbang/presentation/widgets/game/action_log_view.dart';
import 'package:yutbbang/presentation/widgets/game/game_top_bar.dart';
import 'package:yutbbang/presentation/widgets/game/turn_indicator.dart';
import 'package:yutbbang/presentation/widgets/game/victory_overlay.dart';
import 'package:yutbbang/presentation/widgets/game/waiting_mals_area.dart';
import 'package:yutbbang/presentation/widgets/item_inventory.dart';
import 'package:yutbbang/presentation/widgets/throw_button.dart';

import '../helpers/fake_game_notifier.dart';
import '../helpers/fixtures.dart';

GameState itemGame({bool itemMode = true}) => gameStateOf(GameStatus.throwing, [
  team(0, [3, null]).copyWith(items: const [ItemType.magnet]),
  team(1, [null, null], isHuman: false, finished: {1}),
]).copyWith(activeConfig: GameRuleConfig(useItemMode: itemMode));

Future<FakeGameNotifier> pumpApp(
  WidgetTester tester,
  Widget home, {
  GameState? state,
  Size size = const Size(430, 900),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (notifier, override) = fakeGame(state ?? itemGame());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
  return notifier;
}

bool overlaps(Rect a, Rect b) => a.overlaps(b);

void main() {
  group('레이아웃', () {
    for (final (name, size) in [
      ('세로', const Size(430, 900)),
      ('가로', const Size(900, 430)),
      ('태블릿 가로', const Size(1280, 800)),
    ]) {
      testWidgets('$name 화면에서 던지기 버튼이 가방에 가려지지 않는다 (회귀)', (tester) async {
        await pumpApp(tester, const GameScreen(), size: size);
        final button = tester.getRect(find.byType(InteractiveThrowButton));
        final bag = tester.getRect(find.byType(ItemInventory));
        expect(
          overlaps(button, bag),
          isFalse,
          reason: 'button=$button bag=$bag',
        );
        expect(button.right, lessThanOrEqualTo(size.width));
        expect(button.bottom, lessThanOrEqualTo(size.height));
      });
    }

    testWidgets('가로 화면에서는 대기 패널이 옆으로 가서 게임판 높이를 차지하지 않는다', (tester) async {
      await pumpApp(tester, const GameScreen(), size: const Size(900, 430));
      final board = tester.getRect(find.byKey(const Key('game-board-area')));
      final waiting = tester.getRect(find.byType(WaitingMalsArea));
      expect(waiting.left, greaterThanOrEqualTo(board.right));
      expect(board.height, greaterThan(300));
    });

    testWidgets('게임 시작 화면에서 스크롤 없이 시작 버튼이 보인다', (tester) async {
      await pumpApp(tester, const GameSetupScreen());
      final start = tester.getRect(find.text('배틀 시작!'));
      expect(start.bottom, lessThanOrEqualTo(900));
      expect(start.top, greaterThanOrEqualTo(0));
    });
  });

  group('내비게이션', () {
    testWidgets('게임 중 X는 확인을 받고 나간다', (tester) async {
      final n = await pumpApp(tester, const Scaffold(body: GameCloseButton()));
      await tester.tap(find.byType(GameCloseButton));
      await tester.pumpAndSettle();
      expect(find.text('게임을 나갈까요?'), findsOneWidget);

      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();
      expect(n.calls, isEmpty);

      await tester.tap(find.byType(GameCloseButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();
      expect(n.calls, ['exitGame']);
    });

    testWidgets('로비에서 바로 게임 방법을 볼 수 있다', (tester) async {
      await pumpApp(tester, const LobbyScreen());
      await tester.tap(find.text('게임 방법'));
      await tester.pumpAndSettle();
      expect(find.byType(YutGuideScreen), findsOneWidget);
    });

    testWidgets('게임 중에도 상단 도움말 버튼으로 가이드를 연다', (tester) async {
      await pumpApp(tester, GameTopBar(state: itemGame()));
      await tester.tap(find.byTooltip('게임 방법'));
      await tester.pumpAndSettle();
      expect(find.byType(YutGuideScreen), findsOneWidget);
    });

    testWidgets('승리 화면에서 같은 설정으로 한 판 더', (tester) async {
      final state = itemGame().copyWith(status: GameStatus.finished);
      final n = await pumpApp(
        tester,
        Scaffold(body: VictoryOverlay(state: state)),
      );
      await tester.tap(find.text('한 판 더'));
      await tester.pump();
      expect(n.startedWith, same(state.activeConfig));
    });

    testWidgets('기본 설정에는 뒤로가기와 겹치는 닫기 버튼이 없다', (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(),
        size: const Size(800, 4000),
      );
      expect(find.text('닫기'), findsNothing);
    });

    testWidgets('기본 설정에서 CPU 속도를 고른다', (tester) async {
      final n = await pumpApp(
        tester,
        const SettingsScreen(),
        size: const Size(800, 4000),
      );
      await tester.tap(find.text('빠름'));
      await tester.pump();
      expect(n.state.config.cpuSpeed, CpuSpeed.fast);
    });
  });

  group('정보 표시', () {
    testWidgets('대기 패널에 팀별 골인 수를 보여준다', (tester) async {
      await pumpApp(tester, Scaffold(body: WaitingMalsArea(state: itemGame())));
      expect(find.text('골인 0/2'), findsOneWidget);
      expect(find.text('골인 1/2'), findsOneWidget);
    });

    testWidgets('행동 기록은 최근 3개를 보여준다', (tester) async {
      final state = itemGame().copyWith(
        actionLog: const ['1', '2', 'B팀: 윷', 'B팀: 개', 'B팀이 A팀 말을 잡았습니다'],
      );
      await pumpApp(tester, Scaffold(body: ActionLogView(state: state)));
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.text('B팀이 A팀 말을 잡았습니다'), findsOneWidget);
    });

    testWidgets('빈 가방 칸은 ?가 아니라 빈 칸으로 보인다', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: Stack(children: [ItemInventory()])),
      );
      expect(find.text('?'), findsNothing);
      expect(find.bySemanticsLabel('빈 칸'), findsOneWidget);
    });

    testWidgets('가방 제목은 읽기 쉬운 크기(14 이상)', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: Stack(children: [ItemInventory()])),
      );
      final title = tester.widget<Text>(find.textContaining('가방'));
      expect(title.style!.fontSize, greaterThanOrEqualTo(14));
    });

    testWidgets('낙 배지는 뜻이 드러나는 문구', (tester) async {
      await pumpApp(tester, Scaffold(body: NakIndicator(state: itemGame())));
      expect(find.text('낙 확률 15%'), findsOneWidget);
    });
  });

  group('접근성', () {
    testWidgets('주요 버튼에 스크린리더 라벨이 있다', (tester) async {
      await pumpApp(tester, const GameScreen());
      expect(find.bySemanticsLabel('윷 던지기'), findsOneWidget);
      expect(find.bySemanticsLabel('기권'), findsOneWidget);
      expect(find.bySemanticsLabel('가방: 자석'), findsOneWidget);
    });

    testWidgets('게임판 상황을 스크린리더로 읽을 수 있다', (tester) async {
      await pumpApp(tester, const GameScreen());
      expect(
        find.bySemanticsLabel(RegExp('A팀: 판 위 3번 칸, 대기 1개, 골인 0개')),
        findsOneWidget,
      );
    });

    testWidgets('대기 말 아이콘에 팀 글자를 넣어 색 없이도 구분된다', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: WaitingMalToken(color: TeamColor.green, label: 'B'),
        ),
      );
      expect(find.text('B'), findsOneWidget);
    });
  });
}
