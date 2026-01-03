import '../../domain/models/game_rule_config.dart';
import '../../domain/models/team.dart';
import '../../domain/models/yut_result.dart';
import '../../domain/models/game_item.dart';

enum GameStatus {
  lobby,
  throwing,
  selectingMal,
  awaitingShortcutDecision,
  moving,
  finished,
  awaitingBanishTarget, // 강제 귀가 대상 선택
  awaitingSwapSource, // 위치 교환 내 말 선택
  awaitingSwapTarget, // 위치 교환 상대 말 선택
}

class NakZone {
  final double start;
  final double end;
  const NakZone(this.start, this.end);
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
  final double gaugeValue;
  final bool isGaugeRunning;
  final List<NakZone> nakZones;
  final Set<int> itemTiles;
  final ItemType? pendingItem;
  final int? pendingItemNodeId;
  final int? pendingItemTeamIndex;
  final bool showItemChoice;
  final bool moonwalkActive;
  final bool showMoonwalkChoice;
  final bool showRerollChoice;
  final ItemType? justAcquiredItem;
  final String? justAcquiredItemTeamName;

  // New item-related states
  final bool isFixedDiceActive;

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
    this.gaugeValue = 0.0,
    this.isGaugeRunning = false,
    this.nakZones = const [],
    this.itemTiles = const {},
    this.pendingItem,
    this.pendingItemNodeId,
    this.pendingItemTeamIndex,
    this.showItemChoice = false,
    this.moonwalkActive = false,
    this.showMoonwalkChoice = false,
    this.showRerollChoice = false,
    this.justAcquiredItem,
    this.justAcquiredItemTeamName,
    this.isFixedDiceActive = false,
  });

  Team get currentTeam => teams[turnIndex % teams.length];

  static const Object _unset = Object();

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
    double? gaugeValue,
    bool? isGaugeRunning,
    List<NakZone>? nakZones,
    Set<int>? itemTiles,
    Object? pendingItem = _unset,
    Object? pendingItemNodeId = _unset,
    Object? pendingItemTeamIndex = _unset,
    bool? showItemChoice,
    bool? moonwalkActive,
    bool? showMoonwalkChoice,
    bool? showRerollChoice,
    Object? justAcquiredItem = _unset,
    Object? justAcquiredItemTeamName = _unset,
    bool? isFixedDiceActive,
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
      gaugeValue: gaugeValue ?? this.gaugeValue,
      isGaugeRunning: isGaugeRunning ?? this.isGaugeRunning,
      nakZones: nakZones ?? this.nakZones,
      itemTiles: itemTiles ?? this.itemTiles,
      pendingItem: pendingItem == _unset
          ? this.pendingItem
          : pendingItem as ItemType?,
      pendingItemNodeId: pendingItemNodeId == _unset
          ? this.pendingItemNodeId
          : pendingItemNodeId as int?,
      pendingItemTeamIndex: pendingItemTeamIndex == _unset
          ? this.pendingItemTeamIndex
          : pendingItemTeamIndex as int?,
      showItemChoice: showItemChoice ?? this.showItemChoice,
      moonwalkActive: moonwalkActive ?? this.moonwalkActive,
      showMoonwalkChoice: showMoonwalkChoice ?? this.showMoonwalkChoice,
      showRerollChoice: showRerollChoice ?? this.showRerollChoice,
      justAcquiredItem: justAcquiredItem == _unset
          ? this.justAcquiredItem
          : justAcquiredItem as ItemType?,
      justAcquiredItemTeamName: justAcquiredItemTeamName == _unset
          ? this.justAcquiredItemTeamName
          : justAcquiredItemTeamName as String?,
      isFixedDiceActive: isFixedDiceActive ?? this.isFixedDiceActive,
    );
  }
}
