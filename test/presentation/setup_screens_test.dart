import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';
import 'package:yutbbang/presentation/screens/game_setup_screen.dart';
import 'package:yutbbang/presentation/screens/settings_screen.dart';

import '../helpers/fake_game_notifier.dart';
import '../helpers/fixtures.dart';

const ruleTitles = ['빽도 날기', '자동 임신', '전낙', '군밤 모드 🌰', '아이템 모드'];

Future<FakeGameNotifier> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (notifier, override) = fakeGame(
    gameStateOf(GameStatus.lobby, [
      team(0, [null]),
      team(1, [null]),
    ]),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: MaterialApp(home: screen),
    ),
  );
  return notifier;
}

Finder switchOf(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SwitchListTile));

void main() {
  group('게임 시작 설정', () {
    testWidgets('기본 구성(플레이어1 vs CPU)으로 시작한다', (tester) async {
      final n = await pumpScreen(tester, const GameSetupScreen());
      await tester.tap(find.text('배틀 시작!'));
      await tester.pump();
      expect(n.startedWith!.teamCount, 2);
      expect(n.startedWith!.teamControllers.take(2), [1, 0]);
    });

    testWidgets('플레이어 1을 B팀에 주면 A팀은 CPU가 된다', (tester) async {
      final n = await pumpScreen(tester, const GameSetupScreen());
      await tester.tap(find.text('플레이어 1').at(1));
      await tester.pump();
      await tester.tap(find.text('배틀 시작!'));
      await tester.pump();
      expect(n.startedWith!.teamControllers.take(2), [0, 1]);
    });

    testWidgets('팀 수·낙 확률·특수 규칙을 바꿔서 시작한다', (tester) async {
      final n = await pumpScreen(tester, const GameSetupScreen());
      await tester.tap(find.text('3팀'));
      await tester.pump();
      await tester.tap(find.text('어려움 (25%)'));
      await tester.pump();
      for (final title in ruleTitles) {
        await tester.tap(switchOf(title));
        await tester.pump();
      }
      await tester.tap(find.text('배틀 시작!'));
      await tester.pump();
      final c = n.startedWith!;
      expect(c.teamCount, 3);
      expect(c.nakChancePercent, 25);
      expect([
        c.backDoFlying,
        c.autoCarrier,
        c.totalNak,
        c.roastedChestnutMode,
        c.useItemMode,
      ], everyElement(isTrue));
    });

    testWidgets('4팀이면 팀 색 이름이 실제 색과 맞게 표시된다', (tester) async {
      await pumpScreen(tester, const GameSetupScreen());
      await tester.tap(find.text('4팀'));
      await tester.pump();
      expect(find.text('팀 C (자주)'), findsOneWidget);
      expect(find.text('팀 D (파랑)'), findsOneWidget);
    });

    testWidgets('컨트롤 모드를 켜면 낙 확률 칩 표기가 바뀐다', (tester) async {
      await pumpScreen(tester, const GameSetupScreen());
      expect(find.text('보통 (15%)'), findsOneWidget);
      await tester.tap(switchOf('컨트롤 모드'));
      await tester.pump();
      expect(find.text('낙 : 보통'), findsOneWidget);
    });
  });

  group('기본 설정', () {
    testWidgets('특수 규칙 스위치가 글로벌 설정을 바꾼다', (tester) async {
      final n = await pumpScreen(tester, const SettingsScreen());
      for (final title in ruleTitles) {
        await tester.tap(switchOf(title));
        await tester.pump();
      }
      final c = n.state.config;
      expect([
        c.backDoFlying,
        c.autoCarrier,
        c.totalNak,
        c.roastedChestnutMode,
        c.useItemMode,
      ], everyElement(isTrue));
    });

    testWidgets('낙 확률 칩이 글로벌 설정을 바꾼다', (tester) async {
      final n = await pumpScreen(tester, const SettingsScreen());
      await tester.tap(find.text('쉬움 (10%)'));
      await tester.pump();
      expect(n.state.config.nakChancePercent, 10);
    });
  });
}
