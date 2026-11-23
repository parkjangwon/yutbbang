import '../../domain/models/team.dart';
import 'game_state.dart';

/// 말을 눌렀을 때 할 일.
enum MalTapAction { none, select, itemTarget }

/// 상단 바의 두 줄 문구. 없으면 null.
typedef StatusLines = ({String? result, String? guide});

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

  bool get isYutDisplayVisible =>
      status == GameStatus.throwing ||
      status == GameStatus.selectingMal ||
      status == GameStatus.moving;

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
