import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../domain/models/game_rule_config.dart';
import '../../domain/models/team.dart';
import '../../domain/models/yut_result.dart';
import '../../domain/logic/yut_logic.dart';
import '../../domain/logic/ai_logic.dart';
import '../../domain/logic/path_finder.dart';
import '../../domain/logic/board_graph.dart';
import 'game_state.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(_initialState());

  static GameState _initialState() {
    const config = GameRuleConfig();
    return _buildInitialState(config, config);
  }

  static GameState _buildInitialState(
    GameRuleConfig globalConfig,
    GameRuleConfig gameConfig,
  ) {
    final colors = [
      TeamColor.orange,
      TeamColor.green,
      TeamColor.red,
      TeamColor.blue,
    ];
    final List<Team> teams = [];

    for (int i = 0; i < gameConfig.teamCount; i++) {
      final controllerId =
          i < gameConfig.teamControllers.length ? gameConfig.teamControllers[i] : 0;
      teams.add(
        Team(
          name: gameConfig.teamNames[i],
          color: colors[i],
          mals: List.generate(
            gameConfig.malCount,
            (mIdx) => Mal(id: i * 10 + mIdx, color: colors[i]),
          ),
          controllerId: controllerId,
          isHuman: controllerId > 0,
        ),
      );
    }

    return GameState(config: globalConfig, activeConfig: gameConfig, teams: teams);
  }

  void updateConfig(GameRuleConfig config) {
    state = state.copyWith(
      config: config,
      activeConfig: state.status == GameStatus.lobby ? config : state.activeConfig,
    );
  }

  void startGameWithConfig(GameRuleConfig gameConfig) {
    state = _buildInitialState(
      state.config,
      gameConfig,
    ).copyWith(status: GameStatus.throwing);
  }

  void throwYut(bool isSafe) {
    if (state.status != GameStatus.throwing) return;
    state = state.copyWith(status: GameStatus.moving);

    final throwRes = YutLogic.throwYut(
      isSafe: isSafe,
      useBackDo: state.activeConfig.useBackDo,
      nakChance: state.activeConfig.nakChancePercent / 100.0,
    );
    final result = throwRes.result;
    if (state.currentTeam.isHuman) {
      _triggerThrowHaptics(result);
      _triggerThrowSound(result);
    }

    state = state.copyWith(
      lastStickStates: throwRes.sticks,
      lastResult: result,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (result == YutResult.nak) {
        nextTurn();
        return;
      }

      if (result == YutResult.backDo) {
        final team = state.currentTeam;
        final piecesOnBoard = team.mals.any(
          (m) => m.currentNodeId != null && !m.isFinished,
        );
        if (!piecesOnBoard) {
          // DISCARD useless Back-do: don't add to currentThrows
          _finalizeMove();
          return;
        }
      }

      final newThrows = [...state.currentThrows, result];

      if (result.isBonusTurn) {
        state = state.copyWith(
          currentThrows: newThrows,
          status: GameStatus.throwing,
        );
        if (!state.currentTeam.isHuman)
          Future.delayed(
            const Duration(milliseconds: 1000),
            () => throwYut(true),
          );
      } else {
        state = state.copyWith(
          currentThrows: newThrows,
          status: GameStatus.selectingMal,
        );
        if (!state.currentTeam.isHuman)
          Future.delayed(
            const Duration(milliseconds: 1000),
            () => aiSelectAndMove(),
          );
      }
    });
  }

  void aiSelectAndMove() {
    if (!mounted || state.status != GameStatus.selectingMal) return;
    if (state.currentThrows.isEmpty) {
      nextTurn();
      return;
    }

    final result = state.currentThrows.first;
    final malId = AILogic.decideMove(
      difficulty: state.activeConfig.aiDifficulty,
      teams: state.teams,
      turnIndex: state.turnIndex,
      result: result,
    );

    if (malId != null) {
      final mal = state.currentTeam.mals.firstWhere((m) => m.id == malId);
      final node = BoardGraph.nodes[mal.currentNodeId ?? -1];
      final useShortcut = node?.shortcutNextId != null;
      moveMal(malId, result, useShortcut: useShortcut);
    } else {
      final newThrows = List<YutResult>.from(state.currentThrows)..removeAt(0);
      state = state.copyWith(currentThrows: newThrows);
      _finalizeMove();
    }
  }

  void selectMal(int malId) {
    if (state.status != GameStatus.selectingMal &&
        state.status != GameStatus.awaitingShortcutDecision)
      return;

    final team = state.currentTeam;
    final mal = team.mals.firstWhere(
      (m) => m.id == malId,
      orElse: () => team.mals.first,
    );
    if (mal.id != malId) return;

    final result = state.currentThrows.isNotEmpty
        ? state.currentThrows.first
        : null;
    if (result == null) return;

    if (result == YutResult.backDo && mal.currentNodeId == null) return;

    final node = BoardGraph.nodes[mal.currentNodeId ?? -1];
    if (mal.currentNodeId == 15) {
      moveMal(malId, result);
      return;
    }

    // Only ask for 1st corner (5), 2nd corner (10), and Center (20).
    // Node 15 (3rd corner) is excluded and always goes straight.
    final hasShortcut =
        node?.shortcutNextId != null && result != YutResult.backDo;
    final isDecisionPoint =
        (mal.currentNodeId == 5 ||
        mal.currentNodeId == 10 ||
        mal.currentNodeId == 20);

    if (hasShortcut && isDecisionPoint && state.currentTeam.isHuman) {
      state = state.copyWith(
        selectedMalId: malId,
        status: GameStatus.awaitingShortcutDecision,
      );
    } else {
      moveMal(malId, result);
    }
  }

  void chooseShortcut(bool useShortcut) {
    if (state.status != GameStatus.awaitingShortcutDecision ||
        state.selectedMalId == null)
      return;
    if (state.currentThrows.isEmpty) return;

    moveMal(
      state.selectedMalId!,
      state.currentThrows.first,
      useShortcut: useShortcut,
    );
  }

  void moveMal(int malId, YutResult result, {bool useShortcut = false}) {
    state = state.copyWith(status: GameStatus.moving);

    final team = state.currentTeam;
    final mal = team.mals.firstWhere((m) => m.id == malId);
    final startId = mal.currentNodeId ?? PathFinder.startNodeId;

    final path = PathFinder.calculatePath(
      startId,
      result,
      useShortcut: useShortcut,
      previousNodeId: mal.lastNodeId,
    );

    // If the move would finish but an opponent is on the landing node,
    // stop at the node so the capture can happen.
    if (path.length >= 2 && path.last == PathFinder.finishNodeId) {
      final landingNodeId = path[path.length - 2];
      final opponentOnLanding = state.teams.any(
        (t) =>
            t.color != team.color &&
            t.mals.any((m) => m.currentNodeId == landingNodeId),
      );
      if (opponentOnLanding) {
        path.removeLast();
      }
    }

    if (path.isEmpty) {
      final newThrows = List<YutResult>.from(state.currentThrows)..removeAt(0);
      state = state.copyWith(currentThrows: newThrows, selectedMalId: null);
      _finalizeMove();
      return;
    }

    state = state.copyWith(
      movingMalId: malId,
      currentPath: path,
      selectedMalId: null,
    );

    Future.delayed(Duration(milliseconds: 300 * path.length + 300), () {
      if (!mounted) return;
      _applyMoveResult(malId, path);
    });
  }

  void _applyMoveResult(int malId, List<int> path) {
    final destinationId = path.last;
    final landingNodeId = destinationId == PathFinder.finishNodeId && path.length >= 2
        ? path[path.length - 2]
        : destinationId;
    final teamIndex = state.turnIndex % state.teams.length;
    final nextTeams = List<Team>.from(state.teams);
    final team = nextTeams[teamIndex];
    final mal = team.mals.firstWhere((m) => m.id == malId);
    final previousNodeId = mal.currentNodeId;
    final lastStepFromId = path.length >= 2
        ? path[path.length - 2]
        : (previousNodeId ??
            (path.length == 1 && path.first == 1 ? 0 : null));

    bool caughtOpponent = false;
    bool caughtHuman = false;
    final bool catcherHuman = state.currentTeam.isHuman;
    final movedMalsIds = [malId];
    if (mal.currentNodeId != null) {
      movedMalsIds.addAll(
        team.mals
            .where((m) => m.id != malId && m.currentNodeId == mal.currentNodeId)
            .map((m) => m.id),
      );
    }

    final updatedMals = team.mals.map((m) {
      if (movedMalsIds.contains(m.id)) {
        if (destinationId == PathFinder.finishNodeId) {
          return m.copyWith(
            currentNodeId: null,
            lastNodeId: lastStepFromId,
            isFinished: true,
          );
        }
        if (destinationId == PathFinder.startNodeId) {
          return m.copyWith(currentNodeId: null, lastNodeId: lastStepFromId);
        }
        return m.copyWith(currentNodeId: destinationId, lastNodeId: lastStepFromId);
      }
      return m;
    }).toList();

    nextTeams[teamIndex] = team.copyWith(mals: updatedMals);

    if (landingNodeId != PathFinder.finishNodeId) {
      for (int i = 0; i < nextTeams.length; i++) {
        if (i == teamIndex) continue;
        final otherTeam = nextTeams[i];

        // Find if ANY opponent mal is at the landing spot
        final isOccupied = otherTeam.mals.any(
          (m) => m.currentNodeId == landingNodeId,
        );

        if (isOccupied) {
          caughtOpponent = true;
          if (otherTeam.isHuman) caughtHuman = true;
          // Reset EVERY mal on that node (handles stacked mals)
          final resetMals = otherTeam.mals.map((m) {
            if (m.currentNodeId == landingNodeId) {
              return m.copyWith(
                currentNodeId: null,
                lastNodeId: null,
                isFinished: false,
              ); // Back to start circle
            }
            return m;
          }).toList();
          nextTeams[i] = otherTeam.copyWith(mals: resetMals);
        }
      }
    }

    final newThrows = List<YutResult>.from(state.currentThrows)..removeAt(0);

    // UPDATE TEAMS STATE AND CLEAR PREVIOUS RESULT
    state = state.copyWith(
      teams: nextTeams,
      currentThrows: newThrows,
      movingMalId: null,
      currentPath: [],
      lastResult: null, // Clear the result after it has been used for movement
    );

    if (caughtOpponent) {
      if (catcherHuman) {
        HapticFeedback.mediumImpact();
        _triggerCaptureSound();
      }
      if (caughtHuman) {
        HapticFeedback.lightImpact();
        _triggerCaptureSound();
      }
      state = state.copyWith(
        status: GameStatus.throwing,
        lastResult: null, // Clear 'Catcher' result text before bonus throw
      );
      if (!state.currentTeam.isHuman)
        Future.delayed(
          const Duration(milliseconds: 1500),
          () => throwYut(true),
        );
    } else {
      _finalizeMove();
    }
  }

  void _finalizeMove() {
    if (state.teams.any((t) => t.isWinner)) {
      state = state.copyWith(status: GameStatus.finished);
      return;
    }

    if (state.currentThrows.isEmpty) {
      nextTurn();
    } else {
      state = state.copyWith(
        status: GameStatus.selectingMal,
        lastResult: null, // Clear result text when transitioning to selection
      );
      if (!state.currentTeam.isHuman)
        Future.delayed(
          const Duration(milliseconds: 1200),
          () => aiSelectAndMove(),
        );
    }
  }

  void nextTurn() {
    state = state.copyWith(
      turnIndex: (state.turnIndex + 1) % state.teams.length,
      currentThrows: [],
      status: GameStatus.throwing,
      movingMalId: null,
      currentPath: [],
      lastResult: null, // Explicitly clear for the new player
      selectedMalId: null,
    );
    if (!state.currentTeam.isHuman)
      Future.delayed(const Duration(milliseconds: 1500), () => throwYut(true));
  }

  void _triggerThrowHaptics(YutResult result) {
    switch (result) {
      case YutResult.yut:
      case YutResult.mo:
        HapticFeedback.heavyImpact();
        break;
      case YutResult.backDo:
        HapticFeedback.selectionClick();
        break;
      default:
        break;
    }
  }

  void _triggerThrowSound(YutResult result) {
    switch (result) {
      case YutResult.yut:
      case YutResult.mo:
      case YutResult.backDo:
        SystemSound.play(SystemSoundType.click);
        break;
      default:
        break;
    }
  }

  void _triggerCaptureSound() {
    SystemSound.play(SystemSoundType.alert);
  }
}

extension on YutResult {
  YutResult decrementMoves() {
    final count = moveCount > 0 ? moveCount - 1 : 0;
    return YutResult.values.firstWhere(
      (v) => v.moveCount == count && !v.isBonusTurn,
      orElse: () => YutResult.do_,
    );
  }
}
