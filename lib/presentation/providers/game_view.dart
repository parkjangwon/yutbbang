import '../../domain/logic/move_resolver.dart';
import '../../domain/logic/path_finder.dart';
import '../../domain/models/team.dart';
import 'game_state.dart';

/// 말을 눌렀을 때 할 일.
enum MalTapAction { none, select, itemTarget }

/// 상단 바의 두 줄 문구. 없으면 null.
typedef StatusLines = ({String? result, String? guide});

/// 말을 고르기 전 미리 보여줄 도착 칸. 골인이면 출발점(0번) 칸에 표시한다.
typedef DestinationPreview = ({int malId, int nodeId, bool finishes});

/// UI가 화면을 그릴 때 쓰는 파생 값. 상태를 바꾸지 않는다.
extension GameStateView on GameState {
  bool get _humanTurn => currentTeam.isHuman;

  bool get _isPickingMal =>
      status == GameStatus.selectingMal ||
      status == GameStatus.awaitingShortcutDecision;

  bool get _isPickingItemTarget =>
      status == GameStatus.awaitingBanishTarget ||
      status == GameStatus.awaitingSwapSource ||
      status == GameStatus.awaitingSwapTarget;

  bool get canHumanThrow => _humanTurn && status == GameStatus.throwing;

  bool get showShortcutChoice =>
      _humanTurn && status == GameStatus.awaitingShortcutDecision;

  bool get showForfeitButton => _humanTurn && status != GameStatus.finished;

  /// 윷은 던지는 동안에만 보인다. 말을 고르거나 말이 움직일 때는 판을 가리지 않게 숨긴다.
  bool get isYutDisplayVisible =>
      status == GameStatus.throwing ||
      (status == GameStatus.moving && movingMalId == null);

  String get nakBadgeLabel {
    final nak = activeConfig.nakChancePercent;
    if (!activeConfig.useGaugeControl) return '낙 확률 $nak%';
    final level = nak >= 25 ? '어려움' : (nak >= 15 ? '보통' : '쉬움');
    return '낙 구간: $level';
  }

  /// 사람 차례 말 선택 중, 움직일 수 있는 말(업힌 말은 하나로)의 도착 칸.
  /// 지름길 갈림길에서는 지름길을 타지 않는 기본 경로로 계산한다.
  List<DestinationPreview> get destinationPreviews {
    final result = pendingThrow;
    if (!_humanTurn || status != GameStatus.selectingMal || result == null) {
      return const [];
    }
    final team = currentTeam;
    final seenPositions = <int?>{};
    final previews = <DestinationPreview>[];
    for (final mal in MoveResolver.movableMals(
      team,
      result,
      backDoFlying: activeConfig.backDoFlying,
    )) {
      if (!seenPositions.add(mal.currentNodeId)) continue;
      final path = MoveResolver.planPath(
        teams: teams,
        team: team,
        mal: mal,
        result: result,
        backDoFlying: activeConfig.backDoFlying,
      );
      if (path.isEmpty) continue;
      final finishes = path.last == PathFinder.finishNodeId;
      final nodeId = finishes
          ? (path.length >= 2 ? path[path.length - 2] : 0)
          : path.last;
      if (nodeId < 0) continue;
      previews.add((malId: mal.id, nodeId: nodeId, finishes: finishes));
    }
    return previews;
  }

  /// 스크린리더용 팀별 현황.
  List<String> get boardSummary => [
    for (final team in teams)
      [
        '${team.name}: ',
        if (team.hasForfeit)
          '기권'
        else ...[
          for (final entry in _positionsOf(team).entries)
            '판 위 ${entry.key}번 칸${entry.value > 1 ? ' ${entry.value}개 업힘' : ''}, ',
          '대기 ${team.mals.where((m) => m.isWaiting).length}개, ',
          '골인 ${team.finishedCount}개',
        ],
      ].join(),
  ];

  static Map<int, int> _positionsOf(Team team) {
    final counts = <int, int>{};
    for (final mal in team.mals.where((m) => m.isOnBoard)) {
      counts.update(mal.currentNodeId!, (c) => c + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  MalTapAction malTapAction(Mal mal) {
    if (mal.isFinished) return MalTapAction.none;
    if (_isPickingItemTarget) return MalTapAction.itemTarget;
    return isMalHighlighted(mal) ? MalTapAction.select : MalTapAction.none;
  }

  /// 지금 골라서 움직일 수 있는 내 말인지(선택 강조 표시).
  bool isMalHighlighted(Mal mal) =>
      _humanTurn && _isPickingMal && mal.color == currentTeam.color;

  /// 하단 대기 패널을 눌러 대기 말을 고를 수 있는지.
  bool canSelectWaitingMals(Team team) =>
      _humanTurn &&
      status == GameStatus.selectingMal &&
      team.color == currentTeam.color;

  /// 말 위에 표시할 업힌 수. 대기 말은 대기 중인 우리 팀 말 수.
  int stackCountOf(Mal mal) {
    final team = teams.firstWhere((t) => t.color == mal.color);
    if (mal.currentNodeId != null) {
      return team.mals
          .where((m) => m.currentNodeId == mal.currentNodeId)
          .length;
    }
    if (mal.isFinished) return 1;
    return team.mals.where((m) => m.isWaiting).length;
  }

  StatusLines get statusLines {
    String? result;
    final last = lastResult;
    if (last != null && status != GameStatus.moving) {
      final labels = [
        for (final r in currentThrows) r.label,
        if (!currentThrows.contains(last)) last.label,
      ];
      result = '결과: ${labels.join(', ')}';
    }

    final guide = switch (status) {
      GameStatus.awaitingShortcutDecision => '지름길을 선택하세요',
      GameStatus.selectingMal => '움직일 말을 선택하세요',
      _ => null,
    };
    return (result: result, guide: guide);
  }
}
