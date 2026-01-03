import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
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
  GameNotifier() : super(_initialState()) {
    _loadConfig();
  }

  Timer? _gaugeTimer;
  double _gaugeDirection = 1.0;

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
      final controllerId = i < gameConfig.teamControllers.length
          ? gameConfig.teamControllers[i]
          : 0;
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

    return GameState(
      config: globalConfig,
      activeConfig: gameConfig,
      teams: teams,
    );
  }

  void updateConfig(GameRuleConfig config) {
    state = state.copyWith(
      config: config,
      activeConfig: state.status == GameStatus.lobby
          ? config
          : state.activeConfig,
    );
    _saveConfig(config);
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final useBackDo = prefs.getBool('useBackDo') ?? true;
    final useGaugeControl = prefs.getBool('useGaugeControl') ?? false;
    final backDoFlying = prefs.getBool('backDoFlying') ?? false;
    final autoCarrier = prefs.getBool('autoCarrier') ?? false;
    final totalNak = prefs.getBool('totalNak') ?? false;
    final roastedChestnutMode = prefs.getBool('roastedChestnutMode') ?? false;
    final aiDifficulty = prefs.getInt('aiDifficulty') ?? 5;
    final nakChancePercent = prefs.getInt('nakChancePercent') ?? 15;

    final newConfig = state.config.copyWith(
      useBackDo: useBackDo,
      useGaugeControl: useGaugeControl,
      backDoFlying: backDoFlying,
      autoCarrier: autoCarrier,
      totalNak: totalNak,
      roastedChestnutMode: roastedChestnutMode,
      aiDifficulty: aiDifficulty,
      nakChancePercent: nakChancePercent,
    );

    state = state.copyWith(
      config: newConfig,
      activeConfig: state.status == GameStatus.lobby
          ? newConfig
          : state.activeConfig,
    );
  }

  Future<void> _saveConfig(GameRuleConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useBackDo', config.useBackDo);
    await prefs.setBool('useGaugeControl', config.useGaugeControl);
    await prefs.setBool('backDoFlying', config.backDoFlying);
    await prefs.setBool('autoCarrier', config.autoCarrier);
    await prefs.setBool('totalNak', config.totalNak);
    await prefs.setBool('roastedChestnutMode', config.roastedChestnutMode);
    await prefs.setInt('aiDifficulty', config.aiDifficulty);
    await prefs.setInt('nakChancePercent', config.nakChancePercent);
  }

  void startGameWithConfig(GameRuleConfig gameConfig) {
    state = _buildInitialState(
      state.config,
      gameConfig,
    ).copyWith(status: GameStatus.throwing);
  }

  void throwYut({bool forceNak = false}) {
    if (state.status != GameStatus.throwing) return;
    state = state.copyWith(status: GameStatus.moving);

    final isGaugeMode = state.activeConfig.useGaugeControl;
    final throwRes = YutLogic.throwYut(
      forceNak: forceNak,
      randomNakChance: isGaugeMode
          ? 0.0
          : (state.activeConfig.nakChancePercent / 100.0),
      useBackDo: state.activeConfig.useBackDo,
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
        // 전낙 규칙: 낙이 발생하면 이전 윷/모 결과도 모두 취소하고 턴 종료
        if (state.activeConfig.totalNak && state.currentThrows.isNotEmpty) {
          state = state.copyWith(currentThrows: []);
          nextTurn();
          return;
        }

        // 일반 낙 규칙 (기존): 윷/모를 던진 후 낙이 나오면 이전 결과는 유효
        if (state.currentThrows.isEmpty) {
          nextTurn();
        } else {
          state = state.copyWith(status: GameStatus.selectingMal);
          if (!state.currentTeam.isHuman)
            Future.delayed(
              const Duration(milliseconds: 1500),
              () => aiSelectAndMove(),
            );
        }
        return;
      }

      final newThrows = [...state.currentThrows, result];

      if (result == YutResult.backDo) {
        final team = state.currentTeam;
        final piecesOnBoard = team.mals.any(
          (m) => m.currentNodeId != null && !m.isFinished,
        );

        // 빽도 날기 규칙: 판 위에 말이 있어도 대기 중인 말이 빽도로 즉시 골인 가능하면 유효 처리
        bool canFly =
            state.activeConfig.backDoFlying &&
            team.mals.any((m) => m.currentNodeId == null && !m.isFinished);

        if (!piecesOnBoard && !canFly) {
          // 버리는 빽도 (판 위에 말도 없고 날기도 안되는 경우)
          state = state.copyWith(currentThrows: state.currentThrows);
          _finalizeMove();
          return;
        }
      }

      if (result.isBonusTurn) {
        state = state.copyWith(
          currentThrows: newThrows,
          status: GameStatus.throwing,
        );
        if (!state.currentTeam.isHuman)
          Future.delayed(const Duration(milliseconds: 1000), () => throwYut());
      } else {
        state = state.copyWith(
          currentThrows: newThrows,
          status: GameStatus.selectingMal,
        );
        if (!state.currentTeam.isHuman)
          Future.delayed(
            const Duration(milliseconds: 1500),
            () => aiSelectAndMove(),
          );
        else {
          // Check for auto-move if only one mal is movable
          _checkAutoMove();
        }
      }
    });
  }

  void startGauge() {
    if (state.status != GameStatus.throwing || state.isGaugeRunning) return;
    if (!state.currentTeam.isHuman) {
      // CPU는 게이지 UI를 건너뛰지만, 확률 기반 낙은 적용
      final nakChance = state.activeConfig.nakChancePercent / 100.0;
      final random = Random();
      final forceNak = random.nextDouble() < nakChance;
      throwYut(forceNak: forceNak);
      return;
    }

    _gaugeDirection = 1.0;

    // 1. Generate Random Nak Zones based on difficulty (nakChancePercent)
    final nakChance = state.activeConfig.nakChancePercent;
    int zoneCount = 1;
    double zoneWidth = 0.15;
    double speedStep = 0.035;

    if (nakChance >= 25) {
      zoneCount = 4;
      zoneWidth = 0.08;
      speedStep = 0.055;
    } else if (nakChance >= 15) {
      zoneCount = 3;
      zoneWidth = 0.1;
      speedStep = 0.045;
    }

    final List<NakZone> zones = [];
    final random = Random();
    for (int i = 0; i < zoneCount; i++) {
      double start = 0;
      bool overlap = true;
      int attempts = 0;
      while (overlap && attempts < 50) {
        start = 0.1 + random.nextDouble() * (0.8 - zoneWidth);
        overlap = false;
        if (nakChance >= 25) {
          final end = start + zoneWidth;
          for (var z in zones) {
            if (!(end < z.start || start > z.end)) {
              overlap = true;
              break;
            }
          }
        }
        attempts++;
      }
      zones.add(NakZone(start, start + zoneWidth));
    }

    state = state.copyWith(
      isGaugeRunning: true,
      gaugeValue: 0.0,
      nakZones: zones,
    );

    _gaugeTimer?.cancel();
    _gaugeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      double nextValue = state.gaugeValue + (speedStep * _gaugeDirection);
      if (nextValue >= 1.0) {
        nextValue = 1.0;
        _gaugeDirection = -1.0;
      } else if (nextValue <= 0.0) {
        nextValue = 0.0;
        _gaugeDirection = 1.0;
      }
      state = state.copyWith(gaugeValue: nextValue);
    });
  }

  void stopGauge() {
    if (!state.isGaugeRunning) return;
    _gaugeTimer?.cancel();
    _gaugeTimer = null;

    final value = state.gaugeValue;
    // Check if within any NakZone
    bool forceNak = state.nakZones.any(
      (z) => value >= z.start && value <= z.end,
    );

    state = state.copyWith(isGaugeRunning: false);
    throwYut(forceNak: forceNak);
  }

  @override
  void dispose() {
    _gaugeTimer?.cancel();
    super.dispose();
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

    // Only ask for 1st corner (5) and 2nd corner (10).
    // Node 15 (3rd corner) and Node 20 (Center) are excluded and always go straight/towards finish.
    final hasShortcut =
        node?.shortcutNextId != null && result != YutResult.backDo;
    final isDecisionPoint = (mal.currentNodeId == 5 || mal.currentNodeId == 10);

    if (hasShortcut && isDecisionPoint) {
      if (state.activeConfig.roastedChestnutMode) {
        // 군밤 모드: 지름길에서 항상 최단 거리 선택
        moveMal(malId, result, useShortcut: true);
      } else if (state.currentTeam.isHuman) {
        state = state.copyWith(
          selectedMalId: malId,
          status: GameStatus.awaitingShortcutDecision,
        );
      } else {
        // AI or non-human handles it in aiSelectAndMove
        moveMal(malId, result, useShortcut: true);
      }
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

    List<int> path;
    // 빽도 날기 규칙 적용
    if (state.activeConfig.backDoFlying &&
        result == YutResult.backDo &&
        startId == PathFinder.startNodeId) {
      path = [PathFinder.finishNodeId];
    } else {
      path = PathFinder.calculatePath(
        startId,
        result,
        useShortcut: useShortcut,
        previousNodeIds: mal.historyNodeIds,
      );
    }

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
      _applyMoveResult(malId, path, result);
    });
  }

  void _applyMoveResult(int malId, List<int> path, YutResult result) {
    final destinationId = path.last;
    final landingNodeId =
        destinationId == PathFinder.finishNodeId && path.length >= 2
        ? path[path.length - 2]
        : destinationId;
    final teamIndex = state.turnIndex % state.teams.length;
    final nextTeams = List<Team>.from(state.teams);
    final team = nextTeams[teamIndex];
    final mal = team.mals.firstWhere((m) => m.id == malId);
    final previousNodeId = mal.currentNodeId;
    final lastStepFromId = path.length >= 2
        ? path[path.length - 2]
        : (previousNodeId ?? (path.length == 1 && path.first == 1 ? 0 : null));

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
            historyNodeIds: [],
            isFinished: true,
          );
        }
        if (destinationId == PathFinder.startNodeId) {
          return m.copyWith(
            currentNodeId: null,
            lastNodeId: lastStepFromId,
            historyNodeIds: [],
          );
        }

        List<int> newHistory = List<int>.from(m.historyNodeIds);
        if (result == YutResult.backDo) {
          if (newHistory.isNotEmpty) newHistory.removeLast();
        } else {
          if (previousNodeId != null) {
            newHistory.add(previousNodeId);
          }
          if (path.length > 1) {
            for (int k = 0; k < path.length - 1; k++) {
              final intermediateNodeId = path[k];
              if (newHistory.isEmpty || newHistory.last != intermediateNodeId) {
                newHistory.add(intermediateNodeId);
              }
            }
          }
        }

        return m.copyWith(
          currentNodeId: destinationId,
          lastNodeId: lastStepFromId,
          historyNodeIds: newHistory,
        );
      }
      return m;
    }).toList();

    // 자동 임신 (Auto-Carrying) 규칙 적용: 중앙 도착 시 대기마 합류
    if (state.activeConfig.autoCarrier && destinationId == 20) {
      final startIndex = updatedMals.indexWhere(
        (m) => m.currentNodeId == null && !m.isFinished,
      );
      if (startIndex != -1) {
        updatedMals[startIndex] = updatedMals[startIndex].copyWith(
          currentNodeId: 20,
          historyNodeIds: [20],
        );
      }
    }

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
                historyNodeIds: [],
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
        HapticFeedback.heavyImpact();
        _triggerCaptureSound();
      }
      if (caughtHuman) {
        HapticFeedback.heavyImpact();
        _triggerCaptureSound();
      }
      state = state.copyWith(
        status: GameStatus.throwing,
        // lastResult: null, // Keep status text visible longer to avoid flicker
      );
      if (!state.currentTeam.isHuman)
        Future.delayed(const Duration(milliseconds: 1500), () => throwYut());
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
        // lastResult: null, // Keep previous result status until it actually changes
      );
      if (!state.currentTeam.isHuman) {
        Future.delayed(
          const Duration(milliseconds: 1500),
          () => aiSelectAndMove(),
        );
      } else {
        _checkAutoMove();
      }
    }
  }

  void _checkAutoMove() {
    if (state.status != GameStatus.selectingMal || !state.currentTeam.isHuman)
      return;
    if (state.currentThrows.isEmpty) return;

    final result = state.currentThrows.first;
    final team = state.currentTeam;

    // Find movable mals
    final movableMals = team.mals.where((m) {
      if (m.isFinished) return false;
      if (result == YutResult.backDo && m.currentNodeId == null) return false;
      return true;
    }).toList();

    // If only one mal (or one stack) is movable, auto-select it
    // Note: yutnori often groups pieces at the same position.
    final distinctPositions = movableMals.map((m) => m.currentNodeId).toSet();

    if (distinctPositions.length == 1) {
      // All movable pieces are at the same spot (or there's only one piece)
      final malToMove = movableMals.first;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && state.status == GameStatus.selectingMal) {
          selectMal(malToMove.id);
        }
      });
    }
  }

  void nextTurn() {
    state = state.copyWith(
      turnIndex: (state.turnIndex + 1) % state.teams.length,
      currentThrows: [],
      status: GameStatus.throwing,
      movingMalId: null,
      currentPath: [],
      // lastResult: null, // Removed: clearing here ruins continuity
      selectedMalId: null,
    );
    if (!state.currentTeam.isHuman)
      Future.delayed(const Duration(milliseconds: 1500), () => throwYut());
  }

  void _triggerThrowHaptics(YutResult result) {
    switch (result) {
      case YutResult.yut:
      case YutResult.mo:
        HapticFeedback.heavyImpact();
        break;
      case YutResult.backDo:
        HapticFeedback.heavyImpact();
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
