import '../models/team.dart';
import '../models/yut_result.dart';
import 'board_graph.dart';
import 'path_finder.dart';
import 'team_list_ops.dart';

/// 말 이동 한 번의 결과.
class MoveOutcome {
  final List<Team> teams;

  /// 말이 실제로 멈춘 칸. 판 밖(완주·출발점)으로 나가면 완주 직전 칸 또는 null.
  final int? landingNodeId;
  final bool caughtOpponent;
  final bool caughtHuman;

  const MoveOutcome({
    required this.teams,
    required this.landingNodeId,
    required this.caughtOpponent,
    required this.caughtHuman,
  });
}

/// 말 이동 경로 계산과 이동 결과(업기·잡기·자동 임신) 적용. 상태를 바꾸지 않는 순수 로직.
class MoveResolver {
  /// 이번 윷 결과로 움직일 수 있는 말.
  ///
  /// 빽도: 판 위에 말이 있으면 그 말들만, 없으면 빽도 날기가 켜졌을 때만 대기 말.
  static List<Mal> movableMals(
    Team team,
    YutResult result, {
    required bool backDoFlying,
  }) {
    if (result == YutResult.backDo) {
      final onBoard = team.mals.where((m) => m.isOnBoard).toList();
      if (onBoard.isNotEmpty) return onBoard;
      return backDoFlying ? team.mals.where((m) => m.isWaiting).toList() : [];
    }
    return team.mals.where((m) => !m.isFinished).toList();
  }

  /// 지름길을 탈지 물어봐야 하는 칸(첫 번째·두 번째 꼭짓점)인지.
  /// 세 번째 꼭짓점(15)과 중앙(20)은 묻지 않고 정해진 방향으로 간다.
  static bool isShortcutDecisionPoint(Mal mal, YutResult result) {
    final nodeId = mal.currentNodeId;
    if (nodeId != 5 && nodeId != 10) return false;
    return result != YutResult.backDo &&
        BoardGraph.nodes[nodeId]?.shortcutNextId != null;
  }

  /// [mal]이 이동할 경로. 빈 리스트면 움직일 수 없다.
  ///
  /// 완주하는 이동인데 완주 직전 칸에 상대 말이 있으면 그 칸에 멈춰서 잡는다.
  static List<int> planPath({
    required List<Team> teams,
    required Team team,
    required Mal mal,
    required YutResult result,
    required bool backDoFlying,
    bool useShortcut = false,
    bool isReverse = false,
  }) {
    final startId = mal.currentNodeId ?? PathFinder.startNodeId;

    // 빽도 날기: 대기 말이 빽도로 바로 골인.
    if (backDoFlying &&
        result == YutResult.backDo &&
        startId == PathFinder.startNodeId) {
      return [PathFinder.finishNodeId];
    }

    final path = PathFinder.calculatePath(
      startId,
      result,
      useShortcut: useShortcut,
      previousNodeIds: mal.historyNodeIds,
      isReverse: isReverse,
    );

    if (path.length >= 2 && path.last == PathFinder.finishNodeId) {
      final landingNodeId = path[path.length - 2];
      final opponentOnLanding = teams.any(
        (t) =>
            t.color != team.color &&
            t.mals.any((m) => m.currentNodeId == landingNodeId),
      );
      if (opponentOnLanding) path.removeLast();
    }
    return path;
  }

  /// [path]를 따라 이동한 결과를 계산한다.
  ///
  /// - 같은 칸에 있던 우리 팀 말은 함께 움직인다(업기).
  /// - 자동 임신 규칙이면 중앙(20)에 도착할 때 대기 말 하나가 합류한다.
  /// - 멈춘 칸에 상대 말이 있으면 모두 출발점으로 돌려보낸다(잡기).
  static MoveOutcome apply({
    required List<Team> teams,
    required int teamIndex,
    required int malId,
    required List<int> path,
    required YutResult result,
    required bool autoCarrier,
    bool isReverse = false,
  }) {
    final destinationId = path.last;
    final isFinishing = destinationId == PathFinder.finishNodeId;
    final int? landingNodeId = isFinishing
        ? (path.length >= 2 ? path[path.length - 2] : null)
        : destinationId;

    final team = teams[teamIndex];
    final mal = team.mals.firstWhere((m) => m.id == malId);
    final previousNodeId = mal.currentNodeId;
    final lastStepFromId = path.length >= 2
        ? path[path.length - 2]
        : (previousNodeId ?? (path.length == 1 && path.first == 1 ? 0 : null));

    final movedIds = {malId};
    if (previousNodeId != null) {
      movedIds.addAll(
        team.mals
            .where((m) => m.currentNodeId == previousNodeId)
            .map((m) => m.id),
      );
    }

    final updatedMals = team.mals.map((m) {
      if (!movedIds.contains(m.id)) return m;
      if (isFinishing) {
        return m.copyWith(
          currentNodeId: null,
          lastNodeId: lastStepFromId,
          historyNodeIds: const [],
          isFinished: true,
        );
      }
      if (destinationId == PathFinder.startNodeId) {
        return m.copyWith(
          currentNodeId: null,
          lastNodeId: lastStepFromId,
          historyNodeIds: const [],
        );
      }
      return m.copyWith(
        currentNodeId: destinationId,
        lastNodeId: lastStepFromId,
        historyNodeIds: _nextHistory(
          m.historyNodeIds,
          path,
          result,
          previousNodeId,
          isReverse: isReverse,
        ),
      );
    }).toList();

    if (autoCarrier && destinationId == BoardGraph.centerNodeId) {
      final waitingIndex = updatedMals.indexWhere((m) => m.isWaiting);
      if (waitingIndex != -1) {
        updatedMals[waitingIndex] = updatedMals[waitingIndex].teleportedTo(
          BoardGraph.centerNodeId,
        );
      }
    }

    var nextTeams = teams.updatedAt(
      teamIndex,
      (t) => t.copyWith(mals: updatedMals),
    );

    bool caughtOpponent = false;
    bool caughtHuman = false;
    // 판 밖(완주·출발점)에 있는 말은 잡을 수 없다.
    if (landingNodeId != null && landingNodeId >= 0) {
      for (int i = 0; i < nextTeams.length; i++) {
        if (i == teamIndex) continue;
        final other = nextTeams[i];
        if (!other.mals.any((m) => m.currentNodeId == landingNodeId)) continue;
        caughtOpponent = true;
        if (other.isHuman) caughtHuman = true;
        nextTeams = nextTeams.updatedAt(
          i,
          (t) => t.mapMals(
            (m) => m.currentNodeId == landingNodeId ? m.sentHome() : m,
          ),
        );
      }
    }

    return MoveOutcome(
      teams: nextTeams,
      landingNodeId: landingNodeId,
      caughtOpponent: caughtOpponent,
      caughtHuman: caughtHuman,
    );
  }

  /// 이동 기록 갱신. 뒤로 가면 기록을 지우고, 앞으로 가면 지나온 칸을 쌓는다.
  /// 이 기록으로 빽도·뒷걸음질이 왔던 길을 정확히 되돌아간다.
  static List<int> _nextHistory(
    List<int> history,
    List<int> path,
    YutResult result,
    int? previousNodeId, {
    required bool isReverse,
  }) {
    final next = List<int>.from(history);
    if (result == YutResult.backDo || isReverse) {
      for (int k = 0; k < result.moveCount.abs() && next.isNotEmpty; k++) {
        next.removeLast();
      }
      return next;
    }
    if (previousNodeId != null) next.add(previousNodeId);
    for (int k = 0; k < path.length - 1; k++) {
      if (next.isEmpty || next.last != path[k]) next.add(path[k]);
    }
    return next;
  }
}
