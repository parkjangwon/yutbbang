part of '../game_provider.dart';

/// 말 선택, 지름길 선택, 뒷걸음질, 이동 적용.
mixin _MoveActions on _GameNotifierBase {
  @override
  void aiSelectAndMove() {
    if (state.status != GameStatus.selectingMal) return;
    final result = state.pendingThrow;
    if (result == null) {
      nextTurn();
      return;
    }

    final malId = AILogic.decideMove(
      difficulty: _rules.aiDifficulty,
      teams: state.teams,
      turnIndex: state.turnIndex,
      result: result,
      random: _random,
    );

    if (malId == null) {
      _discardPendingThrow();
      _finalizeMove();
      return;
    }
    // CPU는 지름길이 있으면 항상 탄다.
    final mal = state.currentTeam.mals.firstWhere((m) => m.id == malId);
    final node = BoardGraph.nodes[mal.currentNodeId ?? -1];
    moveMal(malId, result, useShortcut: node?.shortcutNextId != null);
  }

  @override
  void selectMal(int malId) {
    if (state.status != GameStatus.selectingMal &&
        state.status != GameStatus.awaitingShortcutDecision) {
      return;
    }
    final team = state.currentTeam;
    final mal = team.mals.where((m) => m.id == malId).firstOrNull;
    final result = state.pendingThrow;
    if (mal == null || result == null) return;

    // 대기 말의 빽도는 빽도 날기 규칙이고, 판 위에 말이 없을 때만 가능하다.
    if (result == YutResult.backDo && mal.currentNodeId == null) {
      if (!_rules.backDoFlying || team.hasMalOnBoard) return;
    }

    // 세 번째 꼭짓점(15)은 선택 없이 직진.
    if (mal.currentNodeId == 15) {
      moveMal(malId, result);
      return;
    }

    // 뒷걸음질: 판 위의 말이 도·개·걸일 때 방향을 묻는다.
    final canMoonwalk =
        team.items.contains(ItemType.moonwalk) &&
        (result == YutResult.do_ ||
            result == YutResult.gae ||
            result == YutResult.geol) &&
        team.isHuman &&
        !state.moonwalkActive &&
        mal.currentNodeId != null;
    if (canMoonwalk) {
      state = state.copyWith(selectedMalId: malId, showMoonwalkChoice: true);
      return;
    }
    if (state.moonwalkActive) {
      state = state.copyWith(selectedMalId: malId);
      return;
    }

    if (!MoveResolver.isShortcutDecisionPoint(mal, result)) {
      moveMal(malId, result);
    } else if (_rules.roastedChestnutMode || !team.isHuman) {
      // 군밤 모드와 CPU는 항상 지름길.
      moveMal(malId, result, useShortcut: true);
    } else {
      state = state.copyWith(
        selectedMalId: malId,
        status: GameStatus.awaitingShortcutDecision,
      );
    }
  }

  /// 뒷걸음질 사용 여부 결정. 쓰면 아이템을 소모하고 뒤로 간다.
  void confirmMoonwalk(bool use) {
    final malId = state.selectedMalId;
    final result = state.pendingThrow;
    if (malId == null || result == null) return;

    if (use) {
      _consumeItem(_teamIndex, ItemType.moonwalk);
      state = state.copyWith(showMoonwalkChoice: false, moonwalkActive: true);
      selectMalWithDirection(malId, forward: false);
      return;
    }

    state = state.copyWith(showMoonwalkChoice: false);
    final mal = state.currentTeam.mals.firstWhere((m) => m.id == malId);
    if (MoveResolver.isShortcutDecisionPoint(mal, result)) {
      state = state.copyWith(status: GameStatus.awaitingShortcutDecision);
    } else {
      moveMal(malId, result);
    }
  }

  /// 뒷걸음질 모드에서 방향을 정해 이동한다. 모드가 아니면 일반 선택과 같다.
  void selectMalWithDirection(int malId, {required bool forward}) {
    if (!state.moonwalkActive) {
      selectMal(malId);
      return;
    }
    final result = state.pendingThrow;
    if (result == null) return;
    state = state.copyWith(moonwalkActive: false);
    moveMal(malId, result, isReverse: !forward);
  }

  void chooseShortcut(bool useShortcut) {
    final malId = state.selectedMalId;
    final result = state.pendingThrow;
    if (state.status != GameStatus.awaitingShortcutDecision ||
        malId == null ||
        result == null) {
      return;
    }
    moveMal(malId, result, useShortcut: useShortcut);
  }

  /// 경로를 계산해 이동 애니메이션을 시작하고, 끝나면 결과를 적용한다.
  @override
  void moveMal(
    int malId,
    YutResult result, {
    bool useShortcut = false,
    bool isReverse = false,
  }) {
    state = state.copyWith(status: GameStatus.moving);

    final team = state.currentTeam;
    final path = MoveResolver.planPath(
      teams: state.teams,
      team: team,
      mal: team.mals.firstWhere((m) => m.id == malId),
      result: result,
      backDoFlying: _rules.backDoFlying,
      useShortcut: useShortcut,
      isReverse: isReverse,
    );

    if (path.isEmpty) {
      _discardPendingThrow();
      state = state.copyWith(selectedMalId: null);
      _finalizeMove();
      return;
    }

    state = state.copyWith(
      movingMalId: malId,
      currentPath: path,
      selectedMalId: null,
    );
    // 한 칸당 300ms 애니메이션 + 여유 300ms.
    _later(Duration(milliseconds: 300 * path.length + 300), () {
      _applyMoveResult(malId, path, result, isReverse: isReverse);
    });
  }

  void _applyMoveResult(
    int malId,
    List<int> path,
    YutResult result, {
    bool isReverse = false,
  }) {
    final teamIndex = _teamIndex;
    final catcherHuman = _isHumanTurn;
    final outcome = MoveResolver.apply(
      teams: state.teams,
      teamIndex: teamIndex,
      malId: malId,
      path: path,
      result: result,
      autoCarrier: _rules.autoCarrier,
      isReverse: isReverse,
    );
    _setTeams(outcome.teams);
    final teamName = state.teams[teamIndex].name;
    if (outcome.finished) _log('$teamName 말 골인!');
    for (final caught in outcome.caughtTeamIndexes) {
      _log(
        '${_GameNotifierBase._subject(teamName)} ${state.teams[caught].name} 말을 잡았습니다',
      );
    }

    final landing = outcome.landingNodeId;
    if (_rules.useItemMode &&
        landing != null &&
        state.itemTiles.contains(landing)) {
      _handleItemAcquisition(teamIndex, landing);
    }

    state = state.copyWith(
      currentThrows: state.currentThrows.skip(1).toList(),
      movingMalId: null,
      currentPath: [],
      lastResult: null,
    );

    if (!outcome.caughtOpponent) {
      _finalizeMove();
      return;
    }

    // 상대 말을 잡으면 한 번 더 던진다.
    if (catcherHuman) _triggerCaptureFeedback();
    if (outcome.caughtHuman) _triggerCaptureFeedback();
    _displayBonusTurn('상대 말을 잡았습니다! 한번 더! 🎯');
    state = state.copyWith(status: GameStatus.throwing);
    if (!_isHumanTurn) {
      _aiLater(1500, throwYut);
    }
  }

  /// 이동이 끝난 뒤: 승자가 있으면 종료, 남은 윷 결과가 없으면 턴 종료,
  /// 있으면 다음 말 선택.
  @override
  void _finalizeMove() {
    if (state.teams.any((t) => t.isWinner)) {
      state = state.copyWith(status: GameStatus.finished);
      return;
    }
    if (state.currentThrows.isEmpty) {
      nextTurn();
      return;
    }
    state = state.copyWith(status: GameStatus.selectingMal);
    _promptMalSelection();
  }

  /// 움직일 수 있는 말이 모두 같은 칸(대기 포함)에 있으면 자동으로 고른다.
  @override
  void _checkAutoMove() {
    if (state.status != GameStatus.selectingMal || !_isHumanTurn) return;
    if (state.moonwalkActive) return;
    final result = state.pendingThrow;
    if (result == null) return;

    final movable = MoveResolver.movableMals(
      state.currentTeam,
      result,
      backDoFlying: _rules.backDoFlying,
    );
    if (movable.isEmpty) return;
    final firstPos = movable.first.currentNodeId;
    if (!movable.every((m) => m.currentNodeId == firstPos)) return;

    final malId = movable.first.id;
    _later(const Duration(milliseconds: 600), () {
      if (state.status == GameStatus.selectingMal && !state.moonwalkActive) {
        selectMal(malId);
      }
    });
  }

  void _discardPendingThrow() {
    state = state.copyWith(currentThrows: state.currentThrows.skip(1).toList());
  }
}
