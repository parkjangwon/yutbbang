import 'dart:math';

import 'package:yutbbang/domain/models/team.dart';

const _colors = TeamColor.values;

/// [positions]는 말별 위치. null = 대기, 숫자 = 판 위 칸, 'F' 대신 [finished]로 완주 표시.
Team team(
  int index,
  List<int?> positions, {
  bool isHuman = true,
  Set<int> finished = const {},
  List<List<int>> history = const [],
  bool hasForfeit = false,
  bool skipNextTurn = false,
}) {
  final color = _colors[index];
  return Team(
    name: '${String.fromCharCode(65 + index)}팀',
    color: color,
    isHuman: isHuman,
    controllerId: isHuman ? 1 : 0,
    hasForfeit: hasForfeit,
    skipNextTurn: skipNextTurn,
    mals: [
      for (int m = 0; m < positions.length; m++)
        Mal(
          id: index * 10 + m,
          color: color,
          currentNodeId: finished.contains(m) ? null : positions[m],
          isFinished: finished.contains(m),
          historyNodeIds: m < history.length ? history[m] : const [],
        ),
    ],
  );
}

Mal malOf(List<Team> teams, int malId) =>
    teams.expand((t) => t.mals).firstWhere((m) => m.id == malId);

/// 정해진 값을 돌려주는 Random. 값이 떨어지면 마지막 값을 반복한다.
class FakeRandom implements Random {
  FakeRandom({this.doubles = const [0.0], this.bools = const [false], this.ints = const [0]});

  final List<double> doubles;
  final List<bool> bools;
  final List<int> ints;
  int _d = 0, _b = 0, _i = 0;

  @override
  double nextDouble() => doubles[min(_d++, doubles.length - 1)];

  @override
  bool nextBool() => bools[min(_b++, bools.length - 1)];

  @override
  int nextInt(int max) => ints[min(_i++, ints.length - 1)] % max;
}
