import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';
import 'package:yutbbang/presentation/widgets/game/forfeit_button.dart';
import 'package:yutbbang/presentation/widgets/game/shortcut_choice_panel.dart';
import 'package:yutbbang/presentation/widgets/item_choice_dialog.dart';
import 'package:yutbbang/presentation/widgets/moonwalk_direction_dialog.dart';
import 'package:yutbbang/presentation/widgets/reroll_choice_dialog.dart';
import 'package:yutbbang/presentation/widgets/throw_button.dart';

import '../helpers/fake_game_notifier.dart';
import '../helpers/fixtures.dart';

final baseState = gameStateOf(GameStatus.throwing, [
  team(0, [3]).copyWith(items: const [ItemType.magnet, ItemType.swap]),
  team(1, [null], isHuman: false),
]);

Future<FakeGameNotifier> pump(
  WidgetTester tester,
  Widget Function(GameState) build, {
  GameState? state,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = state ?? baseState;
  final (notifier, override) = fakeGame(s);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: MaterialApp(
        home: Scaffold(body: Stack(children: [build(s)])),
      ),
    ),
  );
  return notifier;
}

/// 실제 게임처럼 showDialog로 띄운다(버튼이 Navigator.pop으로 닫으므로).
Future<FakeGameNotifier> pumpDialog(
  WidgetTester tester,
  Widget dialog, {
  GameState? state,
}) async {
  final n = await pump(
    tester,
    (_) => Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            showDialog<void>(context: context, builder: (_) => dialog),
        child: const Text('open'),
      ),
    ),
    state: state,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return n;
}

void main() {
  group('다시 던지기 다이얼로그', () {
    final asking = baseState.copyWith(lastResult: YutResult.nak);

    testWidgets('현재 결과를 보여준다', (tester) async {
      await pump(tester, (_) => const RerollChoiceDialog(), state: asking);
      expect(find.text('낙'), findsOneWidget);
    });

    testWidgets('그냥 진행', (tester) async {
      final n = await pumpDialog(
        tester,
        const RerollChoiceDialog(),
        state: asking,
      );
      await tester.tap(find.text('그냥 진행'));
      await tester.pumpAndSettle();
      expect(n.calls, ['confirmReroll(false)']);
      expect(find.byType(RerollChoiceDialog), findsNothing);
    });

    testWidgets('다시 던지기', (tester) async {
      final n = await pumpDialog(
        tester,
        const RerollChoiceDialog(),
        state: asking,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '다시 던지기'));
      expect(n.calls, ['confirmReroll(true)']);
    });
  });

  testWidgets('뒷걸음질 다이얼로그: 앞으로 = 사용 안 함', (tester) async {
    final n = await pumpDialog(tester, const MoonwalkDirectionDialog(malId: 0));
    await tester.tap(find.text('앞으로(취소)'));
    expect(n.calls, ['confirmMoonwalk(false)']);
  });

  testWidgets('뒷걸음질 다이얼로그: 뒤로 = 사용', (tester) async {
    final n = await pumpDialog(tester, const MoonwalkDirectionDialog(malId: 0));
    await tester.tap(find.text('뒤로(사용)'));
    expect(n.calls, ['confirmMoonwalk(true)']);
  });

  group('아이템 교체 다이얼로그', () {
    final full = baseState.copyWith(
      pendingItem: ItemType.freeze,
      pendingItemNodeId: 7,
      pendingItemTeamIndex: 0,
      showItemChoice: true,
    );

    testWidgets('기존 아이템을 누르면 그 칸을 새 아이템으로 교체', (tester) async {
      final n = await pumpDialog(
        tester,
        const ItemChoiceDialog(nodeId: 7),
        state: full,
      );
      await tester.tap(find.text('↔️'));
      expect(n.calls, ['replaceItem(1, 7, team: 0)']);
    });

    testWidgets('포기 버튼', (tester) async {
      final n = await pumpDialog(
        tester,
        const ItemChoiceDialog(nodeId: 7),
        state: full,
      );
      await tester.tap(find.text('새 아이템 포기'));
      expect(n.calls, ['discardPendingItem']);
    });
  });

  group('기권', () {
    testWidgets('확인을 거쳐 현재 팀을 기권시킨다', (tester) async {
      final n = await pump(tester, (s) => ForfeitButton(state: s));
      await tester.tap(find.byType(ForfeitButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();
      expect(n.calls, isEmpty);

      await tester.tap(find.byType(ForfeitButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '기권'));
      await tester.pumpAndSettle();
      expect(n.calls, ['forfeit(0)']);
    });

    testWidgets('확인 문구는 실제 동작(말이 판에서 사라짐)과 같다 (회귀)', (tester) async {
      await pump(tester, (s) => ForfeitButton(state: s));
      await tester.tap(find.byType(ForfeitButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('완주 처리'), findsNothing);
      expect(find.textContaining('모든 말이 판에서 사라지고'), findsOneWidget);
    });
  });

  testWidgets('지름길 패널: 두 선택지를 notifier로 전달', (tester) async {
    final s = baseState.copyWith(status: GameStatus.awaitingShortcutDecision);
    final n = await pump(
      tester,
      (s) => ShortcutChoicePanel(state: s),
      state: s,
    );
    final buttons = find.byWidgetPredicate((w) => w is ElevatedButton);
    expect(buttons, findsNWidgets(2));
    await tester.tap(buttons.first);
    await tester.tap(buttons.last);
    expect(n.calls.toSet(), {'chooseShortcut(true)', 'chooseShortcut(false)'});
  });

  group('던지기 버튼', () {
    testWidgets('일반 모드: 누르면 던진다', (tester) async {
      final n = await pump(tester, (_) => const InteractiveThrowButton());
      await tester.tap(find.byType(InteractiveThrowButton));
      expect(n.calls, ['throwYut']);
    });

    testWidgets('컨트롤 모드: 누르면 게이지 시작, 떼면 정지', (tester) async {
      final gauge = baseState.copyWith(
        activeConfig: const GameRuleConfig(useGaugeControl: true),
      );
      final n = await pump(
        tester,
        (_) => const InteractiveThrowButton(),
        state: gauge,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(InteractiveThrowButton)),
      );
      expect(n.calls, ['startGauge']);
      n.emit(gauge.copyWith(isGaugeRunning: true));
      await tester.pump();
      await gesture.up();
      expect(n.calls, ['startGauge', 'stopGauge']);
    });
  });
}
