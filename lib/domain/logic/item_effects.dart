import 'dart:math';

import '../models/team.dart';
import 'board_graph.dart';
import 'team_list_ops.dart';

/// 아이템 효과 계산. 효과가 없으면 null을 돌려준다. 상태를 바꾸지 않는 순수 로직.
class ItemEffects {
  /// 자석이 끌어당기는 거리(내 말 기준 앞쪽 칸 수).
  static const int magnetRange = 3;

  /// 자석: 내 말 앞 3칸 이내(같은 칸 포함)의 상대 말을 모두 출발점으로 보낸다.
  static List<Team>? magnet(List<Team> teams, int teamIndex) {
    final reach = magnetReach(teams[teamIndex]);
    if (reach.isEmpty) return null;

    var caught = false;
    var next = teams;
    for (int i = 0; i < teams.length; i++) {
      if (i == teamIndex) continue;
      if (!teams[i].mals.any((m) => reach.contains(m.currentNodeId))) continue;
      caught = true;
      next = next.updatedAt(
        i,
        (t) => t.mapMals(
          (m) => reach.contains(m.currentNodeId) ? m.sentHome() : m,
        ),
      );
    }
    return caught ? next : null;
  }

  /// 팀의 판 위 말들 기준으로 자석이 닿는 칸 전체.
  static Set<int> magnetReach(Team team) => {
    for (final mal in team.mals.where((m) => m.isOnBoard))
      ...BoardGraph.nodesWithinDistance(mal.currentNodeId!, magnetRange),
  };

  /// 자석을 쓰면 잡히는 상대 말 수.
  static int magnetCatchCount(List<Team> teams, int teamIndex) {
    final reach = magnetReach(teams[teamIndex]);
    var count = 0;
    for (int i = 0; i < teams.length; i++) {
      if (i == teamIndex) continue;
      count += teams[i].mals
          .where((m) => reach.contains(m.currentNodeId))
          .length;
    }
    return count;
  }

  /// 태풍: 판 위 모든 말(아군 포함)을 무작위 칸으로 옮긴다.
  static List<Team>? typhoon(List<Team> teams, Random random) {
    if (!teams.any((t) => t.hasMalOnBoard)) return null;
    final allNodes = BoardGraph.nodes.keys.toList();
    return [
      for (final team in teams)
        team.mapMals(
          (m) => m.isOnBoard
              ? m.teleportedTo(allNodes[random.nextInt(allNodes.length)])
              : m,
        ),
    ];
  }

  /// 강제 귀가: 상대 말 [targetMalId]를 출발점으로 보낸다.
  static List<Team>? banish(List<Team> teams, int teamIndex, int targetMalId) {
    final targetTeamIndex = _opponentTeamIndexOf(teams, teamIndex, targetMalId);
    if (targetTeamIndex == null) return null;
    return teams.updatedAt(
      targetTeamIndex,
      (t) => t.mapMals((m) => m.id == targetMalId ? m.sentHome() : m),
    );
  }

  /// 얼음탄: 다음 순서 팀의 다음 턴을 건너뛰게 한다.
  static List<Team> freeze(List<Team> teams, int teamIndex) {
    return teams.updatedAt(
      (teamIndex + 1) % teams.length,
      (t) => t.copyWith(skipNextTurn: true),
    );
  }

  /// 위치 교환: 내 말 [myMalId]와 상대 말 [targetMalId]의 칸을 맞바꾼다.
  static List<Team>? swap(
    List<Team> teams,
    int teamIndex,
    int myMalId,
    int targetMalId,
  ) {
    final myMal = teams[teamIndex].mals
        .where((m) => m.id == myMalId && m.isOnBoard)
        .firstOrNull;
    final targetTeamIndex = _opponentTeamIndexOf(teams, teamIndex, targetMalId);
    if (myMal == null || targetTeamIndex == null) return null;

    final myPos = myMal.currentNodeId!;
    final otherPos = teams[targetTeamIndex].mals
        .firstWhere((m) => m.id == targetMalId)
        .currentNodeId!;

    return teams
        .updatedAt(
          teamIndex,
          (t) =>
              t.mapMals((m) => m.id == myMalId ? m.teleportedTo(otherPos) : m),
        )
        .updatedAt(
          targetTeamIndex,
          (t) =>
              t.mapMals((m) => m.id == targetMalId ? m.teleportedTo(myPos) : m),
        );
  }

  /// [malId]가 판 위에 있는 상대 팀 말이면 그 팀 인덱스.
  static int? _opponentTeamIndexOf(List<Team> teams, int teamIndex, int malId) {
    final index = teams.teamIndexOfMal(malId);
    if (index == -1 || teams[index].color == teams[teamIndex].color) {
      return null;
    }
    final mal = teams[index].mals.firstWhere((m) => m.id == malId);
    return mal.isOnBoard ? index : null;
  }
}
