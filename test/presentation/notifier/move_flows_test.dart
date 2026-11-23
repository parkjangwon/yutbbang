// 말 이동 흐름: 지름길·뒷걸음질.
import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/game_scene.dart';

void main() {
  group('지름길', () {
    testWidgets('첫 꼭짓점의 말을 고르면 지름길을 묻고, 고르면 대각선으로 간다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          team(0, [5]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.geol],
      );
      scene.notifier.selectMal(0);
      expect(scene.state.status, GameStatus.awaitingShortcutDecision);

      scene.notifier.chooseShortcut(true);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(scene.state.teams[0].mals[0].currentNodeId, 20);
      await scene.finish(tester);
    });

    testWidgets('지름길을 거절하면 둘레를 따라간다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          team(0, [5]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.geol],
      );
      scene.notifier.selectMal(0);
      scene.notifier.chooseShortcut(false);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(scene.state.teams[0].mals[0].currentNodeId, 8);
      await scene.finish(tester);
    });

    testWidgets('군밤 모드면 묻지 않고 지름길', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          team(0, [10]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.gae],
        rules: const GameRuleConfig(roastedChestnutMode: true),
      );
      scene.notifier.selectMal(0);
      expect(scene.state.status, GameStatus.moving);
      await tester.pump(const Duration(milliseconds: 900));
      expect(scene.state.teams[0].mals[0].currentNodeId, 26);
      await scene.finish(tester);
    });
  });

  group('뒷걸음질', () {
    testWidgets('도·개·걸로 판 위 말을 고르면 방향을 묻고, 쓰면 뒤로 간다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          withItems(
            team(
              0,
              [4],
              history: [
                [1, 2, 3],
              ],
            ),
            [ItemType.moonwalk],
          ),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.gae],
      );
      scene.notifier.selectMal(0);
      expect(scene.state.showMoonwalkChoice, isTrue);

      scene.notifier.confirmMoonwalk(true);
      await tester.pump(const Duration(milliseconds: 900));
      expect(scene.state.teams[0].mals[0].currentNodeId, 2);
      expect(scene.state.teams[0].items, isEmpty);
      await scene.finish(tester);
    });

    testWidgets('쓰지 않으면 아이템은 남고 앞으로 간다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          withItems(
            team(
              0,
              [4],
              history: [
                [1, 2, 3],
              ],
            ),
            [ItemType.moonwalk],
          ),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.gae],
      );
      scene.notifier.selectMal(0);
      scene.notifier.confirmMoonwalk(false);
      await tester.pump(const Duration(milliseconds: 900));
      expect(scene.state.teams[0].mals[0].currentNodeId, 6);
      expect(scene.state.teams[0].items, [ItemType.moonwalk]);
      await scene.finish(tester);
    });
  });
}
