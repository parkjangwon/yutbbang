import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/item_effects.dart';

import '../helpers/fixtures.dart';

void main() {
  group('자석', () {
    test('내 말 앞 3칸 이내 상대 말을 출발점으로 보낸다', () {
      final teams = [
        team(0, [2]),
        team(1, [4, 5, 6]),
      ];
      final next = ItemEffects.magnet(teams, 0)!;
      expect(malOf(next, 10).currentNodeId, isNull);
      expect(malOf(next, 11).currentNodeId, isNull);
      expect(malOf(next, 12).currentNodeId, 6);
    });

    test('꼭짓점에서는 지름길 쪽 상대도 끌어당긴다', () {
      final teams = [
        team(0, [5]),
        team(1, [22]),
      ];
      expect(malOf(ItemEffects.magnet(teams, 0)!, 10).currentNodeId, isNull);
    });

    test('범위 안에 상대가 없으면 null', () {
      final teams = [
        team(0, [2]),
        team(1, [10]),
      ];
      expect(ItemEffects.magnet(teams, 0), isNull);
    });

    test('잡히는 상대 말 수를 센다', () {
      final teams = [
        team(0, [2, 3]),
        team(1, [4, 5, 12]),
      ];
      expect(ItemEffects.magnetCatchCount(teams, 0), 2);
    });
  });

  group('태풍', () {
    test('판 위의 말만 옮기고 대기·완주 말은 그대로', () {
      final teams = [
        team(0, [3, null], finished: {1}),
        team(1, [8, null]),
      ];
      final next = ItemEffects.typhoon(teams, Random(7))!;
      expect(malOf(next, 0).currentNodeId, isNotNull);
      expect(malOf(next, 1).isFinished, isTrue);
      expect(malOf(next, 11).currentNodeId, isNull);
      expect(malOf(next, 10).historyNodeIds, [malOf(next, 10).currentNodeId]);
    });

    test('판 위에 말이 없으면 null', () {
      expect(
        ItemEffects.typhoon([
          team(0, [null]),
          team(1, [null]),
        ], Random()),
        isNull,
      );
    });
  });

  group('강제 귀가', () {
    test('판 위의 상대 말을 출발점으로 보낸다', () {
      final teams = [
        team(0, [1]),
        team(1, [9]),
      ];
      expect(
        malOf(ItemEffects.banish(teams, 0, 10)!, 10).currentNodeId,
        isNull,
      );
    });

    test('내 말이나 대기 중인 상대 말은 대상이 아니다', () {
      final teams = [
        team(0, [1]),
        team(1, [null]),
      ];
      expect(ItemEffects.banish(teams, 0, 0), isNull);
      expect(ItemEffects.banish(teams, 0, 10), isNull);
    });
  });

  test('얼음탄은 다음 순서 팀을 얼린다', () {
    final teams = [
      team(0, [null]),
      team(1, [null]),
      team(2, [null]),
    ];
    final next = ItemEffects.freeze(teams, 2);
    expect(next[0].skipNextTurn, isTrue);
    expect(next[1].skipNextTurn, isFalse);
  });

  group('위치 교환', () {
    test('내 말과 상대 말의 칸을 맞바꾼다', () {
      final teams = [
        team(0, [2]),
        team(1, [24]),
      ];
      final next = ItemEffects.swap(teams, 0, 0, 10)!;
      expect(malOf(next, 0).currentNodeId, 24);
      expect(malOf(next, 10).currentNodeId, 2);
    });

    test('어느 한쪽이라도 판 위에 없으면 null', () {
      final teams = [
        team(0, [null, 2]),
        team(1, [null, 24]),
      ];
      expect(ItemEffects.swap(teams, 0, 0, 11), isNull);
      expect(ItemEffects.swap(teams, 0, 1, 10), isNull);
    });
  });
}
