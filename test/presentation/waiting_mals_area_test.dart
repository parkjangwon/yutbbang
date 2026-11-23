import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';
import 'package:yutbbang/presentation/widgets/game/waiting_mals_area.dart';

import '../helpers/fake_game_notifier.dart';
import '../helpers/fixtures.dart';

Future<FakeGameNotifier> pumpArea(WidgetTester tester, GameState state) async {
  final (notifier, override) = fakeGame(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: MaterialApp(
        home: Scaffold(body: WaitingMalsArea(state: state)),
      ),
    ),
  );
  return notifier;
}

void main() {
  testWidgets('사람 차례에 대기 패널을 누르면 첫 대기 말을 고른다', (tester) async {
    final state = gameStateOf(GameStatus.selectingMal, [
      team(0, [null, null]),
      team(1, [3], isHuman: false),
    ]);
    final notifier = await pumpArea(tester, state);
    await tester.tap(find.text('x2'));
    expect(notifier.calls, ['selectMal(0)']);
  });

  testWidgets('CPU가 말을 고르는 중에는 대기 패널을 눌러도 무시 (회귀)', (tester) async {
    final state = gameStateOf(GameStatus.selectingMal, [
      team(0, [null, null], isHuman: false),
      team(1, [3]),
    ]);
    final notifier = await pumpArea(tester, state);
    await tester.tap(find.text('x2'));
    expect(notifier.calls, isEmpty);
  });

  testWidgets('기권한 팀은 "기권"으로 표시', (tester) async {
    final state = gameStateOf(GameStatus.throwing, [
      team(0, [null]),
      team(1, [null], hasForfeit: true),
    ]);
    await pumpArea(tester, state);
    expect(find.text('기권'), findsOneWidget);
  });
}
