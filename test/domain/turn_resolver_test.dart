import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/turn_resolver.dart';

import '../helpers/fixtures.dart';

void main() {
  group('TurnResolver.next', () {
    test('다음 팀으로 넘어가고 마지막 팀 다음은 첫 팀', () {
      final teams = [
        team(0, [null]),
        team(1, [null]),
        team(2, [null]),
      ];
      expect(TurnResolver.next(teams, 0).nextTurnIndex, 1);
      expect(TurnResolver.next(teams, 2).nextTurnIndex, 0);
    });

    test('기권한 팀은 건너뛴다', () {
      final teams = [
        team(0, [null]),
        team(1, [null], hasForfeit: true),
        team(2, [null]),
      ];
      expect(TurnResolver.next(teams, 0).nextTurnIndex, 2);
    });

    test('얼음탄 맞은 팀은 한 번 건너뛰고 얼음이 풀린다', () {
      final teams = [
        team(0, [null]),
        team(1, [null], skipNextTurn: true),
        team(2, [null]),
      ];
      final adv = TurnResolver.next(teams, 0);
      expect(adv.nextTurnIndex, 2);
      expect(adv.teams[1].skipNextTurn, isFalse);
    });

    test('2팀 게임에서 상대가 얼면 내 차례가 다시 온다', () {
      final teams = [
        team(0, [null]),
        team(1, [null], skipNextTurn: true),
      ];
      expect(TurnResolver.next(teams, 0).nextTurnIndex, 0);
    });

    test('한 팀만 남으면 그 팀이 승리하고 게임 종료', () {
      final teams = [
        team(0, [3, null]),
        team(1, [null], hasForfeit: true),
      ];
      final adv = TurnResolver.next(teams, 1);
      expect(adv.isGameOver, isTrue);
      expect(adv.teams[0].isWinner, isTrue);
    });
  });

  group('TurnResolver.forfeit', () {
    test('기권한 팀의 말은 모두 판에서 치워진다', () {
      final teams = [
        team(0, [3, 7]),
        team(1, [null]),
      ];
      final next = TurnResolver.forfeit(teams, 0);
      expect(next[0].hasForfeit, isTrue);
      expect(next[0].mals.every((m) => m.currentNodeId == null), isTrue);
      expect(next[0].isWinner, isFalse);
    });
  });
}
