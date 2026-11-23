import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';
import 'package:yutbbang/presentation/widgets/item_inventory.dart';

import '../helpers/fake_game_notifier.dart';
import '../helpers/fixtures.dart';

Future<FakeGameNotifier> pumpInventory(
  WidgetTester tester,
  List<ItemType> items, {
  bool itemMode = true,
  bool human = true,
}) async {
  final state = gameStateOf(GameStatus.throwing, [
    team(0, [3], isHuman: human).copyWith(items: items),
    team(1, [null]),
  ]).copyWith(activeConfig: GameRuleConfig(useItemMode: itemMode));
  final (notifier, override) = fakeGame(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(
        home: Scaffold(body: Stack(children: [ItemInventory()])),
      ),
    ),
  );
  return notifier;
}

void main() {
  testWidgets('아이템 모드가 아니면 가방을 그리지 않는다', (tester) async {
    await pumpInventory(tester, const [], itemMode: false);
    expect(find.textContaining('가방'), findsNothing);
  });

  testWidgets('빈 칸은 ?로 표시', (tester) async {
    await pumpInventory(tester, const [ItemType.magnet]);
    expect(find.text('🧲'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('수동 아이템을 누르면 사용한다', (tester) async {
    final n = await pumpInventory(tester, const [ItemType.magnet]);
    await tester.tap(find.text('🧲'));
    await tester.pump();
    expect(n.calls, ['useItem(magnet)']);
  });

  testWidgets('대상 선택 아이템은 안내를 보여주고 사용한다', (tester) async {
    final n = await pumpInventory(tester, const [ItemType.banish]);
    await tester.tap(find.text('🏠'));
    await tester.pump();
    expect(find.textContaining('출발지로 보냅니다'), findsOneWidget);
    expect(n.calls, ['useItem(banish)']);
  });

  testWidgets('자동 발동 아이템은 안내만 하고 사용하지 않는다', (tester) async {
    final n = await pumpInventory(tester, const [ItemType.shield]);
    await tester.tap(find.text('🛡️'));
    await tester.pump();
    expect(find.textContaining('자동으로 사용됩니다'), findsOneWidget);
    expect(n.calls, isEmpty);
  });

  testWidgets('CPU 차례에는 눌러도 아무 일 없다', (tester) async {
    final n = await pumpInventory(tester, const [
      ItemType.magnet,
    ], human: false);
    await tester.tap(find.text('🧲'));
    await tester.pump();
    expect(n.calls, isEmpty);
  });

  testWidgets('길게 누르면 설명을 보여준다', (tester) async {
    await pumpInventory(tester, const [ItemType.typhoon]);
    await tester.longPress(find.text('🌪️'));
    await tester.pumpAndSettle();
    expect(find.text(GameItem.typhoon.description), findsOneWidget);
  });
}
