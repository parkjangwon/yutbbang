// 선물 상자 칸에서 아이템 획득·교체·포기.
import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/game_scene.dart';

void main() {
  group('아이템 획득', () {
    testWidgets('선물 상자 칸에 멈추면 아이템을 얻고 상자가 사라진다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          team(0, [1]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.do_],
        rules: const GameRuleConfig(useItemMode: true),
        itemTiles: {2, 9},
        random: FakeRandom(ints: [6]), // allItems[6] = 얼음탄
      );
      scene.notifier.selectMal(0);
      await tester.pump(const Duration(milliseconds: 700));
      expect(scene.state.teams[0].items, [ItemType.freeze]);
      expect(scene.state.itemTiles, {9});
      expect(scene.state.justAcquiredItem, ItemType.freeze);
      await scene.finish(tester);
    });

    testWidgets('가방이 꽉 차면 교체 여부를 묻고, 교체하면 상자가 사라진다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          withItems(team(0, [1]), [ItemType.magnet, ItemType.swap]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.do_],
        rules: const GameRuleConfig(useItemMode: true),
        itemTiles: {2},
        random: FakeRandom(ints: [6]),
      );
      scene.notifier.selectMal(0);
      await tester.pump(const Duration(milliseconds: 700));
      expect(scene.state.showItemChoice, isTrue);

      scene.notifier.replaceItem(1, 2, teamIndex: 0);
      expect(scene.state.teams[0].items, [ItemType.magnet, ItemType.freeze]);
      expect(scene.state.itemTiles, isEmpty);
      expect(scene.state.showItemChoice, isFalse);
      await scene.finish(tester);
    });

    testWidgets('새 아이템을 포기하면 상자는 칸에 남는다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          withItems(team(0, [1]), [ItemType.magnet, ItemType.swap]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.do_],
        rules: const GameRuleConfig(useItemMode: true),
        itemTiles: {2},
      );
      scene.notifier.selectMal(0);
      await tester.pump(const Duration(milliseconds: 700));
      scene.notifier.discardPendingItem();
      expect(scene.state.teams[0].items, [ItemType.magnet, ItemType.swap]);
      expect(scene.state.itemTiles, {2});
      await scene.finish(tester);
    });
  });
}
