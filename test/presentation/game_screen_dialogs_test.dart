import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';
import 'package:yutbbang/presentation/screens/game_screen.dart';
import 'package:yutbbang/presentation/widgets/reroll_choice_dialog.dart';

import '../helpers/fake_game_notifier.dart';
import '../helpers/fixtures.dart';

void main() {
  late FakeGameNotifier notifier;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final (n, override) = fakeGame(
      gameStateOf(GameStatus.moving, [
        team(0, [3]),
        team(1, [null]),
      ]),
    );
    notifier = n;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [override],
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('다시 던지기 다이얼로그는 상태가 여러 번 바뀌어도 한 번만 뜬다', (tester) async {
    await pumpScreen(tester);
    final asking = notifier.state.copyWith(
      showRerollChoice: true,
      lastResult: YutResult.nak,
    );
    notifier.emit(asking);
    await tester.pump();
    await tester.pump();

    // 다이얼로그가 떠 있는 동안 다른 이유로 화면이 다시 그려진다.
    notifier.emit(asking.copyWith(itemMessage: '얼음탄! 상대의 다음 턴을 얼렸습니다.'));
    await tester.pump();
    await tester.pump();
    notifier.emit(asking.copyWith(itemMessage: null));
    await tester.pump();
    await tester.pump();

    expect(find.byType(RerollChoiceDialog), findsOneWidget);
  });

  testWidgets('다이얼로그를 닫은 뒤 다시 요청되면 다시 뜬다', (tester) async {
    await pumpScreen(tester);
    final asking = notifier.state.copyWith(
      showRerollChoice: true,
      lastResult: YutResult.do_,
    );
    notifier.emit(asking);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('그냥 진행'));
    notifier.emit(asking.copyWith(showRerollChoice: false));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RerollChoiceDialog), findsNothing);

    notifier.emit(asking);
    await tester.pump();
    await tester.pump();
    expect(find.byType(RerollChoiceDialog), findsOneWidget);
  });
}
