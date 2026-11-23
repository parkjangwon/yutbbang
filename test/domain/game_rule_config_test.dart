import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';

void main() {
  group('조작자 배정 (0 = CPU, 1~4 = 플레이어 번호)', () {
    const base = GameRuleConfig(teamCount: 3, teamControllers: [1, 0, 2, 0]);

    test('팀에 플레이어를 배정한다', () {
      expect(base.withController(1, 3).teamControllers, [1, 3, 2, 0]);
    });

    test('같은 플레이어는 한 팀만 맡는다: 다른 팀에서 빼서 CPU로 바꾼다', () {
      expect(base.withController(1, 2).teamControllers, [1, 2, 0, 0]);
    });

    test('CPU는 여러 팀이 맡을 수 있다', () {
      expect(base.withController(0, 0).teamControllers, [0, 0, 2, 0]);
    });

    test('팀 수를 줄이면 빠진 팀은 CPU로 초기화', () {
      final c = base.withTeamCount(2);
      expect(c.teamCount, 2);
      expect(c.teamControllers, [1, 0, 0, 0]);
    });

    test('팀 수를 늘려도 기존 배정은 유지', () {
      final c = base.withTeamCount(4);
      expect(c.teamCount, 4);
      expect(c.teamControllers, [1, 0, 2, 0]);
    });
  });

  test('copyWith는 지정한 값만 바꾼다', () {
    const c = GameRuleConfig();
    final next = c.copyWith(malCount: 4, totalNak: true);
    expect(next.malCount, 4);
    expect(next.totalNak, isTrue);
    expect(next.aiDifficulty, c.aiDifficulty);
    expect(next.teamNames, c.teamNames);
  });
}
