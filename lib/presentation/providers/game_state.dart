import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_rule_config.dart';
import '../../domain/models/team.dart';
import '../../domain/models/yut_result.dart';

enum GameStatus {
  lobby,
  throwing,
  selectingMal,
  awaitingShortcutDecision, // NEw: Wait for user to pick path
  moving,
  finished,
}

class GameState {
  final GameRuleConfig config;
  final GameRuleConfig activeConfig;
  final List<Team> teams;
  final int turnIndex;
  final GameStatus status;
  final List<YutResult> currentThrows;
  final List<bool> lastStickStates;
  final int? selectedMalId;
  final int? movingMalId;
  final List<int> currentPath;
  final YutResult? lastResult;

  GameState({
    required this.config,
    required this.activeConfig,
    required this.teams,
    this.turnIndex = 0,
    this.status = GameStatus.lobby,
    this.currentThrows = const [],
    this.lastStickStates = const [false, false, false, false],
    this.selectedMalId,
    this.movingMalId,
    this.currentPath = const [],
    this.lastResult,
  });

  Team get currentTeam => teams[turnIndex % teams.length];

  GameState copyWith({
    GameRuleConfig? config,
    GameRuleConfig? activeConfig,
    List<Team>? teams,
    int? turnIndex,
    GameStatus? status,
    List<YutResult>? currentThrows,
    List<bool>? lastStickStates,
    int? selectedMalId,
    int? movingMalId,
    List<int>? currentPath,
    YutResult? lastResult,
  }) {
    return GameState(
      config: config ?? this.config,
      activeConfig: activeConfig ?? this.activeConfig,
      teams: teams ?? this.teams,
      turnIndex: turnIndex ?? this.turnIndex,
      status: status ?? this.status,
      currentThrows: currentThrows ?? this.currentThrows,
      lastStickStates: lastStickStates ?? this.lastStickStates,
      selectedMalId: selectedMalId ?? this.selectedMalId,
      movingMalId: movingMalId ?? this.movingMalId,
      currentPath: currentPath ?? this.currentPath,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}
