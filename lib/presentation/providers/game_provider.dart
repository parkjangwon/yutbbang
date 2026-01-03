import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/game_rule_config.dart';
import '../../domain/models/team.dart';
import '../../domain/models/yut_result.dart';
import '../../domain/models/game_item.dart';
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
    final useItemMode = prefs.getBool('useItemMode') ?? false;
    final aiDifficulty = prefs.getInt('aiDifficulty') ?? 5;
    final nakChancePercent = prefs.getInt('nakChancePercent') ?? 15;

    final newConfig = state.config.copyWith(
      useBackDo: useBackDo,
      useGaugeControl: useGaugeControl,
      backDoFlying: backDoFlying,
      autoCarrier: autoCarrier,
      totalNak: totalNak,
      roastedChestnutMode: roastedChestnutMode,
      useItemMode: useItemMode,
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
    await prefs.setBool('useItemMode', config.useItemMode);
    await prefs.setInt('aiDifficulty', config.aiDifficulty);
    await prefs.setInt('nakChancePercent', config.nakChancePercent);
  }

  void startGameWithConfig(GameRuleConfig gameConfig) {
    final initialState = _buildInitialState(state.config, gameConfig);

    // 아이템 모드가 활성화된 경우 아이템 타일 생성
    Set<int> itemTiles = {};
    if (gameConfig.useItemMode) {
      itemTiles = _generateItemTiles();
    }

    state = initialState.copyWith(
      status: GameStatus.throwing,
      itemTiles: itemTiles,
    );

    // 첫 번째 턴이 AI인 경우 자동 시작 (관전 모드 대응)
    if (!state.currentTeam.isHuman) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && state.status == GameStatus.throwing) {
          _aiProcessItems();
          throwYut();
        }
      });
    }
  }

  Set<int> _generateItemTiles() {
    // 모든 유효한 노드 (1~28번)
    final allNodes = List.generate(29, (i) => i).where((i) => i > 0).toList();
    final random = Random();
    final itemTiles = <int>{};

    // 30% 비율로 아이템 타일 생성 (약 8~9개)
    final itemCount = (allNodes.length * 0.3).round();

    // 1. 모든 노드를 섞음
    allNodes.shuffle(random);

    // 2. 인접 노드 제약을 지키며 우선 선택
    for (final nodeId in allNodes) {
      if (itemTiles.length >= itemCount) break;

      final node = BoardGraph.nodes[nodeId];
      if (node == null) continue;

      // 인접한 노드들에 이미 아이템이 있는지 확인
      bool hasNeighborItem = false;
      final neighbors = [
        node.nextId,
        node.prevId,
        node.shortcutNextId,
      ].whereType<int>();

      for (final neighborId in neighbors) {
        if (itemTiles.contains(neighborId)) {
          hasNeighborItem = true;
          break;
        }
      }

      if (!hasNeighborItem) {
        itemTiles.add(nodeId);
      }
    }

    // 3. 만약 제약 때문에 목표 개수를 못 채웠다면, 나머지는 랜덤하게 채움 (이미 섞여있으므로 순서대로)
    for (final nodeId in allNodes) {
      if (itemTiles.length >= itemCount) break;
      itemTiles.add(nodeId);
    }

    return itemTiles;
  }

  void _handleItemAcquisition(int teamIndex, int nodeId) {
    // 랜덤 아이템 생성
    final random = Random();
    final randomItem =
        GameItem.allItems[random.nextInt(GameItem.allItems.length)].type;

    final nextTeams = List<Team>.from(state.teams);
    final team = nextTeams[teamIndex];

    // 인벤토리 확인
    if (team.items.length < 2) {
      // 바로 추가
      final newItems = List<ItemType>.from(team.items)..add(randomItem);
      nextTeams[teamIndex] = team.copyWith(items: newItems);

      // 타일에서 아이템 제거
      final newItemTiles = Set<int>.from(state.itemTiles)..remove(nodeId);

      state = state.copyWith(
        teams: nextTeams,
        itemTiles: newItemTiles,
        justAcquiredItem: randomItem,
        justAcquiredItemTeamName: team.name,
      );

      // 팝업 제거 타이머
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          state = state.copyWith(
            justAcquiredItem: null,
            justAcquiredItemTeamName: null,
          );
        }
      });
    } else {
      if (team.isHuman) {
        // 인벤토리 꽉 찬 경우 - 플레이어 선택 UI 표시
        state = state.copyWith(
          pendingItem: randomItem,
          pendingItemNodeId: nodeId,
          pendingItemTeamIndex: teamIndex,
          showItemChoice: true,
        );
      } else {
        // AI 자동 선택 (난이도에 따라 새 아이템 취사선택)
        // 50% 확률로 랜덤하게 기존 아이템 하나와 교체
        if (random.nextDouble() > 0.5) {
          final slot = random.nextInt(2);
          final newItems = List<ItemType>.from(team.items);
          newItems[slot] = randomItem;
          nextTeams[teamIndex] = team.copyWith(items: newItems);
          final newItemTiles = Set<int>.from(state.itemTiles)..remove(nodeId);
          state = state.copyWith(teams: nextTeams, itemTiles: newItemTiles);
        }
      }
    }
  }

  void replaceItem(int slotIndex, int nodeId, {required int teamIndex}) {
    // 인벤토리의 특정 슬롯 아이템을 새 아이템으로 교체
    if (state.pendingItem == null) return;

    final nextTeams = List<Team>.from(state.teams);
    final team = nextTeams[teamIndex];

    final newItems = List<ItemType>.from(team.items);
    newItems[slotIndex] = state.pendingItem!;

    nextTeams[teamIndex] = team.copyWith(items: newItems);

    // 타일에서 아이템 제거
    final newItemTiles = Set<int>.from(state.itemTiles)..remove(nodeId);

    state = state.copyWith(
      teams: nextTeams,
      itemTiles: newItemTiles,
      pendingItem: null,
      pendingItemNodeId: null,
      pendingItemTeamIndex: null, // Clear after use
      showItemChoice: false,
    );
  }

  void discardPendingItem() {
    // 새 아이템 포기 (타일에서는 제거하지 않음)
    state = state.copyWith(
      pendingItem: null,
      pendingItemNodeId: null,
      pendingItemTeamIndex: null, // Clear after use
      showItemChoice: false,
    );
  }

  void _displayItemMessage(String message) {
    state = state.copyWith(itemMessage: message);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && state.itemMessage == message) {
        state = state.copyWith(itemMessage: null);
      }
    });
  }

  void _displayBonusTurn(String message) {
    state = state.copyWith(bonusMessage: message);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && state.bonusMessage == message) {
        state = state.copyWith(bonusMessage: null);
      }
    });
  }

  void useItem(ItemType itemType) {
    final teamIndex = state.turnIndex % state.teams.length;
    final team = state.teams[teamIndex];

    // 아이템이 인벤토리에 있는지 확인
    if (!team.items.contains(itemType)) return;

    // 내 턴이 아니면 사용 불가
    if (!state.currentTeam.isHuman) return;

    bool success = false;
    // 아이템별 사용 로직
    switch (itemType) {
      case ItemType.reroll:
        success = _useReroll(teamIndex);
        break;
      case ItemType.shield:
        // Shield는 자동 적용되므로 수동 사용 불가
        return;
      case ItemType.magnet:
        success = _useMagnet(teamIndex);
        break;
      case ItemType.moonwalk:
        // 뒷걸음질은 자동 발동되므로 수동 사용 불가
        return;
      case ItemType.typhoon:
        success = _useTyphoon(teamIndex);
        break;
      case ItemType.banish:
        success = _useBanish(teamIndex);
        break;
      case ItemType.freeze:
        success = _useFreeze(teamIndex);
        break;
      case ItemType.swap:
        success = _useSwap(teamIndex);
        break;
      case ItemType.fixedDice:
        success = _useFixedDice(teamIndex);
        break;
    }

    if (success) {
      // 사용 성공 시에만 아이템 제거
      final currentTeams = List<Team>.from(state.teams);
      final currentTeam = currentTeams[teamIndex];
      final newItems = List<ItemType>.from(currentTeam.items)..remove(itemType);
      currentTeams[teamIndex] = currentTeam.copyWith(items: newItems);
      state = state.copyWith(teams: currentTeams);
    }
  }

  bool _useReroll(int teamIndex) {
    // 다시 던지기: 현재 결과 무시하고 다시 던지기
    if (state.status != GameStatus.selectingMal &&
        state.status != GameStatus.throwing) {
      _displayItemMessage("지금은 다시 던지기를 사용할 수 없습니다.");
      return false;
    }

    state = state.copyWith(
      currentThrows: [],
      lastResult: null,
      status: GameStatus.throwing,
      selectedMalId: null,
    );
    _displayItemMessage("다시 던지기! 윷을 다시 던집니다.");
    return true;
  }

  bool _useMagnet(int teamIndex) {
    // 자석: 내 말 앞 3칸 이내 상대 말 잡기
    final team = state.teams[teamIndex];
    final nextTeams = List<Team>.from(state.teams);

    bool caughtAny = false;

    // 내 말이 판 위에 있는지 확인
    if (team.mals.every((m) => m.currentNodeId == null || m.isFinished)) {
      _displayItemMessage("판 위에 내 말이 있어야 자석을 사용할 수 있습니다.");
      return false;
    }

    // 내 말들의 위치 확인
    for (final myMal in team.mals) {
      if (myMal.currentNodeId == null || myMal.isFinished) continue;

      // 앞 3칸 이내 노드 찾기
      final nearbyNodes = _getNodesWithinDistance(myMal.currentNodeId!, 3);

      // 상대 말 찾기
      for (int i = 0; i < nextTeams.length; i++) {
        if (i == teamIndex) continue;

        final otherTeam = nextTeams[i];
        final caughtMals = otherTeam.mals.map((m) {
          if (m.currentNodeId != null &&
              nearbyNodes.contains(m.currentNodeId)) {
            caughtAny = true;
            return m.copyWith(
              currentNodeId: null,
              lastNodeId: null,
              historyNodeIds: [],
              isFinished: false,
            );
          }
          return m;
        }).toList();

        nextTeams[i] = otherTeam.copyWith(mals: caughtMals);
      }
    }

    if (caughtAny) {
      state = state.copyWith(teams: nextTeams);
      HapticFeedback.heavyImpact();
      _displayItemMessage("자석으로 상대 말을 끌어당겼습니다!");
      return true;
    } else {
      _displayItemMessage("주변에 잡을 상대 말이 없습니다.");
      return false;
    }
  }

  List<int> _getNodesWithinDistance(int startNodeId, int maxDistance) {
    final result = <int>{startNodeId};
    final queue = <(int, int)>[(startNodeId, 0)]; // (nodeId, distance)
    final visited = <int>{};

    while (queue.isNotEmpty) {
      final (nodeId, distance) = queue.removeAt(0);
      if (visited.contains(nodeId) || distance > maxDistance) continue;
      visited.add(nodeId);
      result.add(nodeId);

      final node = BoardGraph.nodes[nodeId];
      if (node == null) continue;

      if (node.nextId != null && distance < maxDistance) {
        queue.add((node.nextId!, distance + 1));
      }
      if (node.shortcutNextId != null && distance < maxDistance) {
        queue.add((node.shortcutNextId!, distance + 1));
      }
    }

    return result.toList();
  }

  bool _useTyphoon(int teamIndex) {
    // 태풍: 모든 말의 위치를 랜덤하게 섞음
    final allMalsOnBoard = state.teams
        .expand((t) => t.mals)
        .where((m) => m.currentNodeId != null && !m.isFinished)
        .toList();

    if (allMalsOnBoard.isEmpty) {
      _displayItemMessage("판 위에 말이 없어서 태풍을 사용할 수 없습니다.");
      return false;
    }

    final random = Random();
    final allNodes = BoardGraph.nodes.keys.toList();
    final nextTeams = List<Team>.from(state.teams);

    for (int i = 0; i < nextTeams.length; i++) {
      final team = nextTeams[i];
      final newMals = team.mals.map((m) {
        if (m.currentNodeId != null && !m.isFinished) {
          final newNodeId = allNodes[random.nextInt(allNodes.length)];
          return m.copyWith(
            currentNodeId: newNodeId,
            historyNodeIds: [newNodeId],
          );
        }
        return m;
      }).toList();
      nextTeams[i] = team.copyWith(mals: newMals);
    }

    state = state.copyWith(teams: nextTeams);
    HapticFeedback.heavyImpact();
    _displayItemMessage("태풍이 몰아쳐 말들의 위치가 뒤섞였습니다!");
    return true;
  }

  bool _useBanish(int teamIndex) {
    // 상대 말 하나를 강제로 시작점으로 보냄
    bool hasOpponentOnBoard = false;
    for (int i = 0; i < state.teams.length; i++) {
      if (i == teamIndex) continue;
      if (state.teams[i].mals.any(
        (m) => m.currentNodeId != null && !m.isFinished,
      )) {
        hasOpponentOnBoard = true;
        break;
      }
    }

    if (!hasOpponentOnBoard) {
      _displayItemMessage("시작점으로 보낼 상대 말이 없습니다.");
      return false;
    }

    state = state.copyWith(status: GameStatus.awaitingBanishTarget);
    _displayItemMessage("시작점으로 보낼 상대 말을 선택하세요.");
    return true;
  }

  bool _useFreeze(int teamIndex) {
    // 다음 상대방 팀 턴 스킵 설정
    final nextTeams = List<Team>.from(state.teams);
    final nextTargetIndex = (teamIndex + 1) % nextTeams.length;
    nextTeams[nextTargetIndex] = nextTeams[nextTargetIndex].copyWith(
      skipNextTurn: true,
    );
    state = state.copyWith(teams: nextTeams);
    _displayItemMessage("얼음탄! 상대의 다음 턴을 얼렸습니다.");
    return true;
  }

  bool _useSwap(int teamIndex) {
    // 내 말과 상대 말의 위치를 바꿈
    bool hasMyMal = state.teams[teamIndex].mals.any(
      (m) => m.currentNodeId != null && !m.isFinished,
    );
    bool hasOpponentMal = false;
    for (int i = 0; i < state.teams.length; i++) {
      if (i == teamIndex) continue;
      if (state.teams[i].mals.any(
        (m) => m.currentNodeId != null && !m.isFinished,
      )) {
        hasOpponentMal = true;
        break;
      }
    }

    if (!hasMyMal) {
      _displayItemMessage("위치를 바꿀 내 말이 판 위에 없습니다.");
      return false;
    }
    if (!hasOpponentMal) {
      _displayItemMessage("위치를 바꿀 상대 말이 판 위에 없습니다.");
      return false;
    }

    state = state.copyWith(
      status: GameStatus.awaitingSwapSource,
      selectedMalId: null,
    );
    _displayItemMessage("위치를 바꿀 내 말을 먼저 선택하세요.");
    return true;
  }

  bool _useFixedDice(int teamIndex) {
    if (state.status != GameStatus.throwing) {
      _displayItemMessage("지금은 황금 윷을 사용할 수 없습니다.");
      return false;
    }
    if (state.isFixedDiceActive) {
      _displayItemMessage("이미 황금 윷 효과가 활성화되어 있습니다.");
      return false;
    }
    state = state.copyWith(isFixedDiceActive: true);
    _displayItemMessage("황금 윷 활성화! 다음 던지기는 '윷' 이상 확정입니다.");
    return true;
  }

  void handleMalSelectionForItem(int malId) {
    final teamIndex = state.turnIndex % state.teams.length;
    final nextTeams = List<Team>.from(state.teams);
    final currentTeam = nextTeams[teamIndex];

    if (state.status == GameStatus.awaitingBanishTarget) {
      // 상대방 말 체크
      final targetTeamIndex = nextTeams.indexWhere(
        (t) => t.mals.any((m) => m.id == malId && t.color != currentTeam.color),
      );
      if (targetTeamIndex == -1) return;

      final targetTeam = nextTeams[targetTeamIndex];
      final targetMal = targetTeam.mals.firstWhere((m) => m.id == malId);
      if (targetMal.currentNodeId == null || targetMal.isFinished) return;

      final updatedMals = targetTeam.mals.map((m) {
        if (m.id == malId) {
          return m.copyWith(
            currentNodeId: null,
            lastNodeId: null,
            historyNodeIds: [],
            isFinished: false,
          );
        }
        return m;
      }).toList();
      nextTeams[targetTeamIndex] = targetTeam.copyWith(mals: updatedMals);

      state = state.copyWith(teams: nextTeams, status: GameStatus.throwing);
      _triggerCaptureSound();
      HapticFeedback.heavyImpact();
    } else if (state.status == GameStatus.awaitingSwapSource) {
      // 내 말 체크
      final myMal = currentTeam.mals.firstWhere(
        (m) => m.id == malId,
        orElse: () => currentTeam.mals.first,
      );
      if (myMal.id != malId || myMal.currentNodeId == null || myMal.isFinished)
        return;

      state = state.copyWith(
        selectedMalId: malId,
        status: GameStatus.awaitingSwapTarget,
      );
      HapticFeedback.mediumImpact();
    } else if (state.status == GameStatus.awaitingSwapTarget) {
      // 상대방 말 체크
      final targetTeamIndex = nextTeams.indexWhere(
        (t) => t.mals.any((m) => m.id == malId && t.color != currentTeam.color),
      );
      if (targetTeamIndex == -1) return;

      final targetTeam = nextTeams[targetTeamIndex];
      final otherMal = targetTeam.mals.firstWhere((m) => m.id == malId);
      if (otherMal.currentNodeId == null || otherMal.isFinished) return;

      final myMalId = state.selectedMalId;
      if (myMalId == null) return;

      final myMal = currentTeam.mals.firstWhere((m) => m.id == myMalId);

      final myPos = myMal.currentNodeId;
      final otherPos = otherMal.currentNodeId;

      if (myPos == null || otherPos == null) return;

      // Swap positions
      final updatedMyMals = currentTeam.mals.map((m) {
        if (m.id == myMalId) {
          return m.copyWith(
            currentNodeId: otherPos,
            historyNodeIds: [otherPos],
          );
        }
        return m;
      }).toList();
      nextTeams[teamIndex] = currentTeam.copyWith(mals: updatedMyMals);

      final updatedOtherMals = targetTeam.mals.map((m) {
        if (m.id == malId) {
          return m.copyWith(currentNodeId: myPos, historyNodeIds: [myPos]);
        }
        return m;
      }).toList();
      nextTeams[targetTeamIndex] = targetTeam.copyWith(mals: updatedOtherMals);

      state = state.copyWith(
        teams: nextTeams,
        status: GameStatus.throwing,
        selectedMalId: null,
      );
      HapticFeedback.heavyImpact();
    }
  }

  void throwYut({bool forceNak = false}) {
    if (state.status != GameStatus.throwing) return;
    state = state.copyWith(status: GameStatus.moving);

    final isGaugeMode = state.activeConfig.useGaugeControl;
    final result;
    final List<bool> sticks;

    if (state.isFixedDiceActive) {
      // 황금 윷: 무조건 윷 또는 모 (50:50 확률)
      final random = Random();
      final isYut = random.nextBool();
      result = isYut ? YutResult.yut : YutResult.mo;
      sticks = isYut ? [true, true, true, true] : [false, false, false, false];
    } else {
      final throwRes = YutLogic.throwYut(
        forceNak: forceNak,
        randomNakChance: isGaugeMode
            ? 0.0
            : (state.activeConfig.nakChancePercent / 100.0),
        useBackDo: state.activeConfig.useBackDo,
      );
      result = throwRes.result;
      sticks = throwRes.sticks;
    }

    if (state.currentTeam.isHuman) {
      _triggerThrowHaptics(result);
      _triggerThrowSound(result);
    }

    state = state.copyWith(
      lastStickStates: sticks,
      lastResult: result,
      isFixedDiceActive: false, // 사용 후 해제
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      // 다시 던지기 아이템 자동 발동 체크
      final teamIndex = state.turnIndex % state.teams.length;
      final team = state.teams[teamIndex];
      if (team.items.contains(ItemType.reroll)) {
        if (team.isHuman) {
          state = state.copyWith(showRerollChoice: true);
          return;
        } else if (result == YutResult.nak) {
          // AI는 낙이 나왔을 때만 다시 던지기 사용
          confirmReroll(true);
          return;
        }
      }

      _processThrowResult(result);
    });
  }

  void _processThrowResult(YutResult result) {
    if (result == YutResult.nak) {
      // Shield 아이템 자동 적용 체크
      final teamIndex = state.turnIndex % state.teams.length;
      final team = state.teams[teamIndex];

      if (team.items.contains(ItemType.shield)) {
        // Shield 사용하여 낙을 '도'로 변경
        final newItems = List<ItemType>.from(team.items)
          ..remove(ItemType.shield);
        final nextTeams = List<Team>.from(state.teams);
        nextTeams[teamIndex] = team.copyWith(items: newItems);

        // 결과를 '도'로 변경
        final newThrows = [...state.currentThrows, YutResult.do_];

        state = state.copyWith(
          teams: nextTeams,
          currentThrows: newThrows,
          lastResult: YutResult.do_,
          status: GameStatus.selectingMal,
        );

        if (!state.currentTeam.isHuman) {
          Future.delayed(
            const Duration(milliseconds: 1500),
            () => aiSelectAndMove(),
          );
        }
        return;
      }

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

    YutResult actualResult = result;
    final newThrows = [...state.currentThrows, actualResult];

    if (actualResult == YutResult.backDo) {
      final team = state.currentTeam;
      final piecesOnBoard = team.mals.any(
        (m) => m.currentNodeId != null && !m.isFinished,
      );

      // 빽도 날기 규칙: 판 위에 말이 없는 경우 대기 중인 말이 빽도로 즉시 골인 가능
      bool canFly =
          state.activeConfig.backDoFlying &&
          !piecesOnBoard &&
          team.mals.any((m) => m.currentNodeId == null && !m.isFinished);

      if (!piecesOnBoard && !canFly) {
        // 버리는 빽도 (판 위에 말도 없고 날기도 안되는 경우)
        state = state.copyWith(currentThrows: state.currentThrows);
        _finalizeMove();
        return;
      }
    }

    if (actualResult.isBonusTurn) {
      _displayBonusTurn("한번 더!");
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
      if (!state.currentTeam.isHuman) {
        Future.delayed(
          const Duration(milliseconds: 1500),
          () => aiSelectAndMove(),
        );
      } else {
        // Check for auto-move if only one mal is movable
        _checkAutoMove();
      }
    }
  }

  void confirmReroll(bool use) {
    state = state.copyWith(showRerollChoice: false);

    if (use) {
      final teamIndex = state.turnIndex % state.teams.length;
      final team = state.teams[teamIndex];

      // 아이템 제거
      final newItems = List<ItemType>.from(team.items)..remove(ItemType.reroll);
      final nextTeams = List<Team>.from(state.teams);
      nextTeams[teamIndex] = team.copyWith(items: newItems);

      state = state.copyWith(
        teams: nextTeams,
        status: GameStatus.throwing,
        lastResult: null,
      );
      HapticFeedback.mediumImpact();

      // AI인 경우 자동으로 다시 던지기 수행
      if (!team.isHuman) {
        Future.delayed(const Duration(milliseconds: 1000), () => throwYut());
      }
    } else {
      // 아이템 사용 안 함 -> 원래 결과 처리 진행
      if (state.lastResult != null) {
        _processThrowResult(state.lastResult!);
      }
    }
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

    if (result == YutResult.backDo && mal.currentNodeId == null) {
      if (!state.activeConfig.backDoFlying) return;
      // 판 위에 말이 있는 경우 빽도 날기 불가 (판 위의 말을 먼저 움직여야 함)
      final anyOnBoard = team.mals.any(
        (m) => m.currentNodeId != null && !m.isFinished,
      );
      if (anyOnBoard) return;
    }

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

    // --- 뒷걸음질 자동 발동 체크 ---
    final hasMoonwalk = team.items.contains(ItemType.moonwalk);
    final isMoonwalkableResult =
        (result == YutResult.do_ ||
        result == YutResult.gae ||
        result == YutResult.geol);

    // 이미 뒷걸음질 모드이거나 AI인 경우는 제외
    // 또한 말이 이미 판 위에 있는 경우에만 뒷걸음질 가능
    if (hasMoonwalk &&
        isMoonwalkableResult &&
        state.currentTeam.isHuman &&
        !state.moonwalkActive &&
        mal.currentNodeId != null) {
      state = state.copyWith(selectedMalId: malId, showMoonwalkChoice: true);
      return;
    }

    if (state.moonwalkActive) {
      // 뒷걸음질 활성화 상태에서 말을 고르면 다이얼로그를 띄우기 위해 상태만 업데이트
      state = state.copyWith(selectedMalId: malId);
      return;
    }

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

  void confirmMoonwalk(bool use) {
    if (state.selectedMalId == null) return;

    final malId = state.selectedMalId!;
    final result = state.currentThrows.first;

    if (use) {
      // 아이템 소모
      final teamIndex = state.turnIndex % state.teams.length;
      final team = state.teams[teamIndex];
      final newItems = List<ItemType>.from(team.items)
        ..remove(ItemType.moonwalk);
      final nextTeams = List<Team>.from(state.teams);
      nextTeams[teamIndex] = team.copyWith(items: newItems);

      state = state.copyWith(teams: nextTeams, showMoonwalkChoice: false);

      // 뒤로 이동 (moveMal은 forward 파라미터가 없으므로 selectMalWithDirection 사용)
      state = state.copyWith(moonwalkActive: true);
      selectMalWithDirection(malId, forward: false);

      // selectMalWithDirection 내부에서 moonwalkActive를 끄도록 수정 필요
    } else {
      // 사용 안함 -> 그냥 원래대로 이동
      state = state.copyWith(showMoonwalkChoice: false);

      final mal = state.currentTeam.mals.firstWhere((m) => m.id == malId);
      final node = BoardGraph.nodes[mal.currentNodeId ?? -1];
      final isDecisionPoint =
          (mal.currentNodeId == 5 || mal.currentNodeId == 10);
      final hasShortcut =
          node?.shortcutNextId != null && result != YutResult.backDo;

      if (hasShortcut && isDecisionPoint) {
        state = state.copyWith(status: GameStatus.awaitingShortcutDecision);
      } else {
        moveMal(malId, result);
      }
    }
  }

  void selectMalWithDirection(int malId, {required bool forward}) {
    // 뒷걸음질 방향 선택
    if (!state.moonwalkActive) {
      selectMal(malId);
      return;
    }

    final result = state.currentThrows.isNotEmpty
        ? state.currentThrows.first
        : null;
    if (result == null) return;

    // moonwalkActive 비활성화
    state = state.copyWith(moonwalkActive: false);

    // 말 이동 (forward가 false면 reverse)
    moveMal(malId, result, isReverse: !forward);
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

  void moveMal(
    int malId,
    YutResult result, {
    bool useShortcut = false,
    bool isReverse = false,
  }) {
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
        isReverse: isReverse,
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
      _applyMoveResult(malId, path, result, isReverse: isReverse);
    });
  }

  void _applyMoveResult(
    int malId,
    List<int> path,
    YutResult result, {
    bool isReverse = false,
  }) {
    final destinationId = path.last;
    final landingNodeId =
        destinationId == PathFinder.finishNodeId && path.length >= 2
        ? path[path.length - 2]
        : (destinationId == PathFinder.finishNodeId ? null : destinationId);
    final teamIndex = state.turnIndex % state.teams.length;
    var nextTeams = List<Team>.from(state.teams);
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

    ItemType? pendingItem;
    int? pendingNodeId;
    int? pendingItemTeamIndex; // Declare here
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
        if (result == YutResult.backDo || isReverse) {
          // Remove moves from history (but no more than what's there)
          int stepsToRemove = result.moveCount.abs();
          for (int k = 0; k < stepsToRemove; k++) {
            if (newHistory.isNotEmpty) newHistory.removeLast();
          }
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

    // 포획 및 말 이동 결과 먼저 반영
    if (landingNodeId != PathFinder.finishNodeId) {
      for (int i = 0; i < nextTeams.length; i++) {
        if (i == teamIndex) continue;
        final otherTeam = nextTeams[i];

        final isOccupied = otherTeam.mals.any(
          (m) => m.currentNodeId == landingNodeId,
        );

        if (isOccupied) {
          caughtOpponent = true;
          if (otherTeam.isHuman) caughtHuman = true;
          final resetMals = otherTeam.mals.map((m) {
            if (m.currentNodeId == landingNodeId) {
              return m.copyWith(
                currentNodeId: null,
                lastNodeId: null,
                historyNodeIds: [],
                isFinished: false,
              );
            }
            return m;
          }).toList();
          nextTeams[i] = otherTeam.copyWith(mals: resetMals);
        }
      }
    }

    // 아이템 로직 실행 전에 이동 상태를 먼저 커밋 (데이터 정합성 보장)
    state = state.copyWith(teams: nextTeams);
    // 재참조 (포획 등으로 변경된 상태 반영)
    nextTeams = List<Team>.from(state.teams);

    final newThrows = List<YutResult>.from(state.currentThrows)..removeAt(0);
    // 아이템 획득 로직
    if (state.activeConfig.useItemMode &&
        state.itemTiles.contains(landingNodeId) &&
        landingNodeId != PathFinder.finishNodeId) {
      _handleItemAcquisition(teamIndex, landingNodeId!);
      // 아이템 획득 후 최신화된 teams 정보 가져오기
      nextTeams = List<Team>.from(state.teams);
    }

    // UPDATE TEAMS STATE AND CLEAR PREVIOUS RESULT
    state = state.copyWith(
      teams: nextTeams,
      currentThrows: newThrows,
      movingMalId: null,
      currentPath: [],
      lastResult: null,
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
      _displayBonusTurn("상대 말을 잡았습니다! 한번 더! 🎯");
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

  List<Mal> _getMovableMalsForCurrentThrow(Team team, YutResult result) {
    if (result == YutResult.backDo) {
      // 1. 판 위에 말이 있으면 판 위의 말만 이동 가능
      final onBoard = team.mals
          .where((m) => m.currentNodeId != null && !m.isFinished)
          .toList();
      if (onBoard.isNotEmpty) return onBoard;

      // 2. 판 위에 말이 없고 빽도 날기가 활성화된 경우 대기마 이동 가능
      if (state.activeConfig.backDoFlying) {
        return team.mals
            .where((m) => m.currentNodeId == null && !m.isFinished)
            .toList();
      }
      return [];
    }
    return team.mals.where((m) => !m.isFinished).toList();
  }

  void _checkAutoMove() {
    if (state.status != GameStatus.selectingMal || !state.currentTeam.isHuman)
      return;
    if (state.currentThrows.isEmpty) return;

    // 뒷걸음질 아이템이 활성화된 경우 자동 이동 방지 (방향 선택 필요)
    if (state.moonwalkActive) return;

    final result = state.currentThrows.first;
    final team = state.currentTeam;

    // 움직일 수 있는 말 찾기
    final movableMals = _getMovableMalsForCurrentThrow(team, result);

    if (movableMals.isEmpty) return;

    // 모든 움직일 수 있는 말의 위치가 동일한지 확인 (null 포함)
    final firstPos = movableMals.first.currentNodeId;
    final allSamePos = movableMals.every((m) => m.currentNodeId == firstPos);

    if (allSamePos) {
      // 모든 말이 같은 위치(예: 시작점 또는 업힌 상태)라면 자동 선택
      final malToMove = movableMals.first;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted &&
            state.status == GameStatus.selectingMal &&
            !state.moonwalkActive) {
          selectMal(malToMove.id);
        }
      });
    }
  }

  void nextTurn() {
    // 기권하지 않은 팀 찾기
    final activeTeams = state.teams.where((t) => !t.hasForfeit).toList();

    // 모든 팀이 기권했거나 승자가 나온 경우
    if (activeTeams.isEmpty || activeTeams.length == 1) {
      if (activeTeams.length == 1) {
        // 남은 팀 1개면 승리 처리
        final winnerIndex = state.teams.indexWhere((t) => !t.hasForfeit);
        final nextTeams = List<Team>.from(state.teams);
        final winner = nextTeams[winnerIndex];

        final winnerMals = winner.mals.map((m) {
          return m.copyWith(
            currentNodeId: null,
            lastNodeId: null,
            historyNodeIds: [],
            isFinished: true,
          );
        }).toList();

        nextTeams[winnerIndex] = winner.copyWith(mals: winnerMals);
        state = state.copyWith(teams: nextTeams, status: GameStatus.finished);
      } else {
        state = state.copyWith(status: GameStatus.finished);
      }
      return;
    }

    // 다음 기권하지 않은 팀 찾기 (얼음탄 체크 포함)
    int nextTurnIndex = (state.turnIndex + 1) % state.teams.length;
    int attempts = 0;
    final nextTeams = List<Team>.from(state.teams);
    bool stateModified = false;

    while (attempts < state.teams.length) {
      final team = nextTeams[nextTurnIndex];
      if (team.hasForfeit) {
        nextTurnIndex = (nextTurnIndex + 1) % state.teams.length;
        attempts++;
        continue;
      }

      if (team.skipNextTurn) {
        nextTeams[nextTurnIndex] = team.copyWith(skipNextTurn: false);
        stateModified = true;
        print('Skipping turn for ${team.name} (Frozen)');
        nextTurnIndex = (nextTurnIndex + 1) % state.teams.length;
        attempts++;
        continue;
      }

      break; // 유효한 팀 발견
    }

    if (stateModified) {
      state = state.copyWith(teams: nextTeams);
    }

    // 안전장치: 기권하지 않은 팀을 찾지 못한 경우
    if (state.teams[nextTurnIndex].hasForfeit) {
      state = state.copyWith(status: GameStatus.finished);
      return;
    }

    state = state.copyWith(
      turnIndex: nextTurnIndex,
      currentThrows: [],
      status: GameStatus.throwing,
      movingMalId: null,
      currentPath: [],
      lastResult: null, // 턴 전환 시 이전 결과 제거
      selectedMalId: null,
    );

    if (!state.currentTeam.isHuman) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (state.status == GameStatus.throwing) {
          _aiProcessItems(); // 아이템 사용 검토
          throwYut();
        }
      });
    }
  }

  void forfeit(int teamIndex) {
    // 해당 팀을 기권 처리하고 모든 말을 게임판에서 제거
    final nextTeams = List<Team>.from(state.teams);
    final team = nextTeams[teamIndex];

    // 모든 말을 제거 (currentNodeId = null, isFinished = false로 초기화)
    final clearedMals = team.mals.map((m) {
      return m.copyWith(
        currentNodeId: null,
        lastNodeId: null,
        historyNodeIds: [],
        isFinished: false,
      );
    }).toList();

    nextTeams[teamIndex] = team.copyWith(hasForfeit: true, mals: clearedMals);

    state = state.copyWith(teams: nextTeams, currentThrows: []);

    // 기권하지 않은 팀 수 확인
    final activeTeams = state.teams.where((t) => !t.hasForfeit).toList();

    if (activeTeams.length == 1) {
      // 남은 팀이 1개면 즉시 승리 처리
      final winnerIndex = state.teams.indexWhere((t) => !t.hasForfeit);
      final winner = state.teams[winnerIndex];

      // 승리 팀의 모든 말을 완주 처리
      final winnerMals = winner.mals.map((m) {
        return m.copyWith(
          currentNodeId: null,
          lastNodeId: null,
          historyNodeIds: [],
          isFinished: true,
        );
      }).toList();

      nextTeams[winnerIndex] = winner.copyWith(mals: winnerMals);

      state = state.copyWith(teams: nextTeams, status: GameStatus.finished);
    } else if (activeTeams.isEmpty) {
      // 모든 팀이 기권한 경우 (이론상 발생하지 않아야 함)
      state = state.copyWith(status: GameStatus.finished);
    } else {
      // 여러 팀이 남아있으면 게임 계속
      nextTurn();
    }
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

  void _aiProcessItems() {
    final teamIndex = state.turnIndex % state.teams.length;
    final team = state.teams[teamIndex];
    if (team.isHuman || team.items.isEmpty) return;

    final difficulty = state.activeConfig.aiDifficulty;
    // 난이도에 비례하여 아이템 사용 확률 (예: 난이도 5면 40% 확률)
    if (Random().nextDouble() > (difficulty / 12.0)) return;

    final nextTeams = List<Team>.from(state.teams);
    final itemsCopy = List<ItemType>.from(team.items);

    for (final item in itemsCopy) {
      bool used = false;
      switch (item) {
        case ItemType.fixedDice: // 황금 윷
          // 판 위에 내 말이 없으면 사용
          if (team.mals.every((m) => m.currentNodeId == null)) {
            _useFixedDice(teamIndex);
            used = true;
          }
          break;
        case ItemType.freeze: // 얼음탄
          // 다음 상대 팀의 말이 골인에 가까우면 사용
          final nextTeamIdx = (teamIndex + 1) % state.teams.length;
          final nextTeam = state.teams[nextTeamIdx];
          if (nextTeam.mals.any(
            (m) => m.currentNodeId != null && m.currentNodeId! > 15,
          )) {
            _useFreeze(teamIndex);
            used = true;
          }
          break;
        case ItemType.banish: // 강제 귀가
          // 가장 멀리 간 상대 말 찾기
          int? bestTargetId;
          int maxPos = -1;
          for (var t in state.teams) {
            if (t.color == team.color) continue;
            for (var m in t.mals) {
              if (m.currentNodeId != null && m.currentNodeId! > maxPos) {
                maxPos = m.currentNodeId!;
                bestTargetId = m.id;
              }
            }
          }
          if (bestTargetId != null && maxPos > 10) {
            state = state.copyWith(status: GameStatus.awaitingBanishTarget);
            handleMalSelectionForItem(bestTargetId);
            used = true;
          }
          break;
        case ItemType.magnet: // 자석
          // 주위에 상대 말이 2개 이상이면 사용
          int catchCount = 0;
          for (var myMal in team.mals) {
            if (myMal.currentNodeId == null || myMal.isFinished) continue;
            final nearby = _getNodesWithinDistance(myMal.currentNodeId!, 3);
            for (var t in state.teams) {
              if (t.color == team.color) continue;
              catchCount += t.mals
                  .where(
                    (m) =>
                        m.currentNodeId != null &&
                        nearby.contains(m.currentNodeId),
                  )
                  .length;
            }
          }
          if (catchCount >= 2) {
            _useMagnet(teamIndex);
            used = true;
          }
          break;
        case ItemType.swap: // 위치 교환
          // 내 말은 시작점에 있고, 상대 말은 골인 직전일 때
          int? myStartMalId = team.mals
              .firstWhere(
                (m) => m.currentNodeId != null && m.currentNodeId! < 5,
                orElse: () => team.mals.first,
              )
              .id;
          int? enemyTargetId;
          int maxPos = -1;
          for (var t in state.teams) {
            if (t.color == team.color) continue;
            for (var m in t.mals) {
              if (m.currentNodeId != null && m.currentNodeId! > maxPos) {
                maxPos = m.currentNodeId!;
                enemyTargetId = m.id;
              }
            }
          }
          if (maxPos > 20 && myStartMalId != null && enemyTargetId != null) {
            state = state.copyWith(status: GameStatus.awaitingSwapSource);
            handleMalSelectionForItem(myStartMalId);
            handleMalSelectionForItem(enemyTargetId);
            used = true;
          }
          break;
        case ItemType.typhoon: // 태풍
          // 내가 대세에서 밀리고 있을 때 (상대 팀 중 하나가 완주가 많거나 멀리 갔을 때)
          bool losing = false;
          for (var t in state.teams) {
            if (t.color == team.color) continue;
            if (t.mals.where((m) => m.isFinished).length >
                team.mals.where((m) => m.isFinished).length)
              losing = true;
            if (t.mals.any(
              (m) => m.currentNodeId != null && m.currentNodeId! > 20,
            ))
              losing = true;
          }
          if (losing) {
            _useTyphoon(teamIndex);
            used = true;
          }
          break;
        default:
          break;
      }

      if (used) {
        final currentTeams = List<Team>.from(state.teams);
        final currentTeam = currentTeams[teamIndex];
        final updatedItems = List<ItemType>.from(currentTeam.items)
          ..remove(item);
        currentTeams[teamIndex] = currentTeam.copyWith(items: updatedItems);
        state = state.copyWith(teams: currentTeams);
        break; // 한 턴에 하나만 사용
      }
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
