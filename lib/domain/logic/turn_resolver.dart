import '../models/team.dart';
import 'team_list_ops.dart';

/// 턴 넘기기 결과. [nextTurnIndex]가 null이면 게임 종료.
class TurnAdvance {
  final List<Team> teams;
  final int? nextTurnIndex;

  const TurnAdvance(this.teams, this.nextTurnIndex);

  bool get isGameOver => nextTurnIndex == null;
}

/// 턴 순서·기권·얼음탄 처리. 상태를 바꾸지 않는 순수 로직.
class TurnResolver {
  /// [turnIndex] 다음 차례를 찾는다.
  ///
  /// - 기권한 팀은 건너뛴다.
  /// - 얼음탄에 맞은 팀은 한 번 건너뛰고 얼음 상태를 해제한다.
  /// - 기권하지 않은 팀이 하나만 남으면 그 팀이 승리(모든 말 완주 처리)한다.
  static TurnAdvance next(List<Team> teams, int turnIndex) {
    final survivor = resolveSoleSurvivor(teams);
    if (survivor != null) return survivor;

    var nextTeams = teams;
    int index = (turnIndex + 1) % teams.length;
    for (int attempts = 0; attempts < teams.length; attempts++) {
      final team = nextTeams[index];
      if (team.hasForfeit) {
        index = (index + 1) % teams.length;
        continue;
      }
      if (team.skipNextTurn) {
        nextTeams = nextTeams.updatedAt(
          index,
          (t) => t.copyWith(skipNextTurn: false),
        );
        index = (index + 1) % teams.length;
        continue;
      }
      break;
    }

    if (nextTeams[index].hasForfeit) return TurnAdvance(nextTeams, null);
    return TurnAdvance(nextTeams, index);
  }

  /// [teamIndex] 팀을 기권 처리한다. 판 위의 말은 모두 치운다.
  static List<Team> forfeit(List<Team> teams, int teamIndex) {
    return teams.updatedAt(
      teamIndex,
      (t) => t.mapMals((m) => m.sentHome()).copyWith(hasForfeit: true),
    );
  }

  /// 기권하지 않은 팀이 1개 이하이면 게임 종료 결과를, 아니면 null을 돌려준다.
  static TurnAdvance? resolveSoleSurvivor(List<Team> teams) {
    final activeCount = teams.where((t) => !t.hasForfeit).length;
    if (activeCount > 1) return null;
    if (activeCount == 0) return TurnAdvance(teams, null);

    final winnerIndex = teams.indexWhere((t) => !t.hasForfeit);
    return TurnAdvance(
      teams.updatedAt(winnerIndex, (t) => t.mapMals((m) => m.markedFinished())),
      null,
    );
  }
}
