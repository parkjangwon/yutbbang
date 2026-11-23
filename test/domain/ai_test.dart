import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/ai_item_logic.dart';
import 'package:yutbbang/domain/logic/ai_logic.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/yut_result.dart';

import '../helpers/fixtures.dart';

void main() {
  group('AILogic.decideMove (난이도 10 = 항상 최선)', () {
    int? decide(List teams, YutResult r) => AILogic.decideMove(
      difficulty: 10,
      teams: teams.cast(),
      turnIndex: 0,
      result: r,
      random: Random(0),
    );

    test('상대를 잡을 수 있는 말을 고른다', () {
      final teams = [team(0, [3, null], isHuman: false), team(1, [4])];
      expect(decide(teams, YutResult.do_), 0);
    });

    test('골인할 수 있는 말을 고른다 (회귀: 골인 판정)', () {
      final teams = [team(0, [10, 19], isHuman: false), team(1, [null])];
      expect(decide(teams, YutResult.do_), 1);
    });

    test('움직일 말이 없으면 null', () {
      final teams = [team(0, [null], finished: {0}), team(1, [null])];
      expect(decide(teams, YutResult.do_), isNull);
    });
  });

  group('AiItemLogic.decide', () {
    AiItemDecision? decide(List teams, {double roll = 0.0, int difficulty = 10}) =>
        AiItemLogic.decide(
          teams: teams.cast(),
          teamIndex: 0,
          difficulty: difficulty,
          random: FakeRandom(doubles: [roll]),
        );

    test('사람 팀이나 아이템이 없으면 쓰지 않는다', () {
      expect(decide([team(0, [null]), team(1, [null])]), isNull);
    });

    test('확률 검사(난이도/12)를 통과하지 못하면 쓰지 않는다', () {
      final t = team(0, [null], isHuman: false).copyWith(items: [ItemType.fixedDice]);
      expect(decide([t, team(1, [null])], roll: 0.9, difficulty: 6), isNull);
      expect(decide([t, team(1, [null])], roll: 0.4, difficulty: 6)?.item, ItemType.fixedDice);
    });

    test('자동 발동 아이템은 쓰지 않는다', () {
      final t = team(0, [3], isHuman: false)
          .copyWith(items: [ItemType.shield, ItemType.reroll]);
      expect(decide([t, team(1, [null])]), isNull);
    });

    test('강제 귀가는 가장 멀리 간 상대 말을 노린다', () {
      final t = team(0, [3], isHuman: false).copyWith(items: [ItemType.banish]);
      final d = decide([t, team(1, [12, 16])])!;
      expect(d.item, ItemType.banish);
      expect(d.targetMalId, 11);
    });

    test('위치 교환은 내 말이 판 위(1~4번)에 있을 때만 (회귀: 게임 멈춤)', () {
      final waiting = team(0, [null], isHuman: false).copyWith(items: [ItemType.swap]);
      expect(decide([waiting, team(1, [24])]), isNull);

      final onBoard = team(0, [2], isHuman: false).copyWith(items: [ItemType.swap]);
      final d = decide([onBoard, team(1, [24])])!;
      expect(d.sourceMalId, 0);
      expect(d.targetMalId, 10);
    });

    test('자석은 상대 말 2개 이상을 잡을 수 있을 때', () {
      final t = team(0, [2], isHuman: false).copyWith(items: [ItemType.magnet]);
      expect(decide([t, team(1, [4, 12])]), isNull);
      expect(decide([t, team(1, [4, 5])])?.item, ItemType.magnet);
    });
  });
}
