// 가방 아이템 사용과 자동 발동 아이템.
import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/game_scene.dart';

void main() {
  group('아이템 사용', () {
    testWidgets('얼음탄: 다음 팀을 얼리고 아이템을 소모', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [null]), [ItemType.freeze]),
        team(1, [null], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.freeze);
      expect(scene.state.teams[1].skipNextTurn, isTrue);
      expect(scene.state.teams[0].items, isEmpty);
      await scene.finish(tester);
    });

    testWidgets('자석: 잡을 말이 없으면 안내만 하고 아이템은 남는다', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [2]), [ItemType.magnet]),
        team(1, [15], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.magnet);
      expect(scene.state.itemMessage, '주변에 잡을 상대 말이 없습니다.');
      expect(scene.state.teams[0].items, [ItemType.magnet]);
      await scene.finish(tester);
    });

    testWidgets('강제 귀가권: 대상 선택 → 상대 말이 출발점으로', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [2]), [ItemType.banish]),
        team(1, [12], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.banish);
      expect(scene.state.status, GameStatus.awaitingBanishTarget);

      scene.notifier.handleMalSelectionForItem(0); // 내 말은 대상이 아니다
      expect(scene.state.status, GameStatus.awaitingBanishTarget);

      scene.notifier.handleMalSelectionForItem(10);
      expect(scene.state.teams[1].mals[0].currentNodeId, isNull);
      expect(scene.state.status, GameStatus.throwing);
      await scene.finish(tester);
    });

    testWidgets('위치 교환: 내 말 → 상대 말 순서로 골라 자리를 바꾼다', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [2]), [ItemType.swap]),
        team(1, [24], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.swap);
      scene.notifier.handleMalSelectionForItem(0);
      expect(scene.state.status, GameStatus.awaitingSwapTarget);
      scene.notifier.handleMalSelectionForItem(10);
      expect(scene.state.teams[0].mals[0].currentNodeId, 24);
      expect(scene.state.teams[1].mals[0].currentNodeId, 2);
      expect(scene.state.status, GameStatus.throwing);
      await scene.finish(tester);
    });

    testWidgets('황금 윷: 다음 던지기는 윷 또는 모', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [null]), [ItemType.fixedDice]),
        team(1, [null], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.fixedDice);
      expect(scene.state.isFixedDiceActive, isTrue);
      scene.notifier.throwYut();
      expect(scene.state.lastResult, anyOf(YutResult.yut, YutResult.mo));
      expect(scene.state.isFixedDiceActive, isFalse);
      await scene.finish(tester);
    });

    testWidgets('자동 발동 아이템은 가방에서 직접 쓸 수 없다', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [3]), [ItemType.shield, ItemType.moonwalk]),
        team(1, [null], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.shield);
      scene.notifier.useItem(ItemType.moonwalk);
      expect(scene.state.teams[0].items, [ItemType.shield, ItemType.moonwalk]);
      await scene.finish(tester);
    });

    testWidgets('낙 방지권: 낙이 나오면 자동으로 도가 된다', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [null]), [ItemType.shield]),
        team(1, [null], isHuman: false),
      ]);
      scene.notifier.throwYut(forceNak: true);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(scene.state.currentThrows, [YutResult.do_]);
      expect(scene.state.teams[0].items, isEmpty);
      await scene.finish(tester);
    });

    testWidgets('다시 던지기: 사람에게 묻고, 쓰면 다시 던지기 단계로', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [null]), [ItemType.reroll]),
        team(1, [null], isHuman: false),
      ]);
      scene.notifier.throwYut(forceNak: true);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(scene.state.showRerollChoice, isTrue);
      scene.notifier.confirmReroll(true);
      expect(scene.state.status, GameStatus.throwing);
      expect(scene.state.teams[0].items, isEmpty);
      await scene.finish(tester);
    });
  });
}
