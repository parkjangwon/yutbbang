part of '../game_provider.dart';

/// 턴 넘기기와 기권.
mixin _TurnActions on _GameNotifierBase {
  @override
  void nextTurn() {
    _applyTurnAdvance(TurnResolver.next(state.teams, state.turnIndex));
  }

  /// [teamIndex] 팀 기권. 한 팀만 남으면 그 팀이 바로 승리한다.
  void forfeit(int teamIndex) {
    final teams = TurnResolver.forfeit(state.teams, teamIndex);
    state = state.copyWith(teams: teams, currentThrows: []);

    final survivor = TurnResolver.resolveSoleSurvivor(teams);
    if (survivor != null) {
      _applyTurnAdvance(survivor);
    } else {
      nextTurn();
    }
  }

  void _applyTurnAdvance(TurnAdvance advance) {
    for (int i = 0; i < advance.teams.length; i++) {
      if (state.teams[i].skipNextTurn && !advance.teams[i].skipNextTurn) {
        _log('${advance.teams[i].name}: ❄️ 얼어서 차례를 건너뜁니다');
      }
    }
    final nextIndex = advance.nextTurnIndex;
    if (nextIndex == null) {
      state = state.copyWith(teams: advance.teams, status: GameStatus.finished);
      return;
    }

    state = state.copyWith(
      teams: advance.teams,
      turnIndex: nextIndex,
      currentThrows: [],
      status: GameStatus.throwing,
      movingMalId: null,
      currentPath: [],
      lastResult: null,
      selectedMalId: null,
    );

    if (!_isHumanTurn) {
      _aiLater(1500, () {
        if (state.status == GameStatus.throwing) {
          _aiProcessItems();
          throwYut();
        }
      });
    }
  }
}
