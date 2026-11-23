part of '../game_provider.dart';

/// 아이템 획득(선물 상자 칸)과 사용.
mixin _ItemActions on _GameNotifierBase {
  /// [nodeId] 칸의 선물 상자를 연다. 인벤토리가 꽉 차면
  /// 사람은 교체 여부를 고르고, CPU는 50% 확률로 아무 칸과 바꾼다.
  @override
  void _handleItemAcquisition(int teamIndex, int nodeId) {
    final item =
        GameItem.allItems[_random.nextInt(GameItem.allItems.length)].type;
    final team = state.teams[teamIndex];

    if (!team.isInventoryFull) {
      state = state.copyWith(
        teams: state.teams.updatedAt(
          teamIndex,
          (t) => t.copyWith(items: [...t.items, item]),
        ),
        itemTiles: {...state.itemTiles}..remove(nodeId),
        justAcquiredItem: item,
        justAcquiredItemTeamName: team.name,
      );
      _later(const Duration(milliseconds: 2500), () {
        state = state.copyWith(
          justAcquiredItem: null,
          justAcquiredItemTeamName: null,
        );
      });
      return;
    }

    if (team.isHuman) {
      state = state.copyWith(
        pendingItem: item,
        pendingItemNodeId: nodeId,
        pendingItemTeamIndex: teamIndex,
        showItemChoice: true,
      );
    } else if (_random.nextDouble() > 0.5) {
      final slot = _random.nextInt(Team.maxItems);
      _replaceSlot(teamIndex, slot, item, nodeId);
    }
  }

  /// 인벤토리가 꽉 찼을 때 [slotIndex] 칸을 새 아이템으로 바꾼다.
  void replaceItem(int slotIndex, int nodeId, {required int teamIndex}) {
    final item = state.pendingItem;
    if (item == null) return;
    _replaceSlot(teamIndex, slotIndex, item, nodeId);
    _clearPendingItem();
  }

  /// 새 아이템을 포기한다. 선물 상자는 칸에 그대로 남는다.
  void discardPendingItem() => _clearPendingItem();

  void _replaceSlot(int teamIndex, int slot, ItemType item, int nodeId) {
    state = state.copyWith(
      teams: state.teams.updatedAt(
        teamIndex,
        (t) => t.copyWith(items: List.of(t.items)..[slot] = item),
      ),
      itemTiles: {...state.itemTiles}..remove(nodeId),
    );
  }

  void _clearPendingItem() {
    state = state.copyWith(
      pendingItem: null,
      pendingItemNodeId: null,
      pendingItemTeamIndex: null,
      showItemChoice: false,
    );
  }

  /// 사람 플레이어가 가방에서 아이템을 쓴다. 성공했을 때만 소모한다.
  /// 낙 방지권·뒷걸음질은 자동 발동이라 직접 쓸 수 없다.
  void useItem(ItemType itemType) {
    final teamIndex = _teamIndex;
    if (!state.currentTeam.items.contains(itemType) || !_isHumanTurn) return;

    final success = switch (itemType) {
      ItemType.reroll => _useReroll(),
      ItemType.magnet => _useMagnet(teamIndex),
      ItemType.typhoon => _useTyphoon(teamIndex),
      ItemType.banish => _useBanish(teamIndex),
      ItemType.freeze => _useFreeze(teamIndex),
      ItemType.swap => _useSwap(teamIndex),
      ItemType.fixedDice => _useFixedDice(teamIndex),
      ItemType.shield || ItemType.moonwalk => false,
    };
    if (success) _consumeItem(teamIndex, itemType);
  }

  bool _useReroll() {
    if (state.status != GameStatus.selectingMal &&
        state.status != GameStatus.throwing) {
      _displayItemMessage('지금은 다시 던지기를 사용할 수 없습니다.');
      return false;
    }
    state = state.copyWith(
      currentThrows: [],
      lastResult: null,
      status: GameStatus.throwing,
      selectedMalId: null,
    );
    _displayItemMessage('다시 던지기! 윷을 다시 던집니다.');
    return true;
  }

  @override
  bool _useMagnet(int teamIndex) {
    if (!state.teams[teamIndex].hasMalOnBoard) {
      _displayItemMessage('판 위에 내 말이 있어야 자석을 사용할 수 있습니다.');
      return false;
    }
    final teams = ItemEffects.magnet(state.teams, teamIndex);
    if (teams == null) {
      _displayItemMessage('주변에 잡을 상대 말이 없습니다.');
      return false;
    }
    _setTeams(teams);
    HapticFeedback.heavyImpact();
    _displayItemMessage('자석으로 상대 말을 끌어당겼습니다!');
    return true;
  }

  @override
  bool _useTyphoon(int teamIndex) {
    final teams = ItemEffects.typhoon(state.teams, _random);
    if (teams == null) {
      _displayItemMessage('판 위에 말이 없어서 태풍을 사용할 수 없습니다.');
      return false;
    }
    _setTeams(teams);
    HapticFeedback.heavyImpact();
    _displayItemMessage('태풍이 몰아쳐 말들의 위치가 뒤섞였습니다!');
    return true;
  }

  /// 강제 귀가: 대상 선택 모드로 들어간다. 실제 효과는 [handleMalSelectionForItem].
  bool _useBanish(int teamIndex) {
    if (!state.teams.hasOpponentOnBoard(teamIndex)) {
      _displayItemMessage('시작점으로 보낼 상대 말이 없습니다.');
      return false;
    }
    state = state.copyWith(status: GameStatus.awaitingBanishTarget);
    _displayItemMessage('시작점으로 보낼 상대 말을 선택하세요.');
    return true;
  }

  @override
  bool _useFreeze(int teamIndex) {
    _setTeams(ItemEffects.freeze(state.teams, teamIndex));
    _displayItemMessage('얼음탄! 상대의 다음 턴을 얼렸습니다.');
    return true;
  }

  /// 위치 교환: 내 말 → 상대 말 순서로 고르는 모드로 들어간다.
  bool _useSwap(int teamIndex) {
    if (!state.teams[teamIndex].hasMalOnBoard) {
      _displayItemMessage('위치를 바꿀 내 말이 판 위에 없습니다.');
      return false;
    }
    if (!state.teams.hasOpponentOnBoard(teamIndex)) {
      _displayItemMessage('위치를 바꿀 상대 말이 판 위에 없습니다.');
      return false;
    }
    state = state.copyWith(
      status: GameStatus.awaitingSwapSource,
      selectedMalId: null,
    );
    _displayItemMessage('위치를 바꿀 내 말을 먼저 선택하세요.');
    return true;
  }

  @override
  bool _useFixedDice(int teamIndex) {
    if (state.status != GameStatus.throwing) {
      _displayItemMessage('지금은 황금 윷을 사용할 수 없습니다.');
      return false;
    }
    if (state.isFixedDiceActive) {
      _displayItemMessage('이미 황금 윷 효과가 활성화되어 있습니다.');
      return false;
    }
    state = state.copyWith(isFixedDiceActive: true);
    _displayItemMessage("황금 윷 활성화! 다음 던지기는 '윷' 이상 확정입니다.");
    return true;
  }

  /// 강제 귀가·위치 교환 대상 선택 중에 말을 눌렀을 때.
  void handleMalSelectionForItem(int malId) {
    final teamIndex = _teamIndex;
    switch (state.status) {
      case GameStatus.awaitingBanishTarget:
        if (_banishMal(teamIndex, malId)) {
          state = state.copyWith(status: GameStatus.throwing);
        }
      case GameStatus.awaitingSwapSource:
        final isMyMalOnBoard = state.currentTeam.mals.any(
          (m) => m.id == malId && m.isOnBoard,
        );
        if (!isMyMalOnBoard) return;
        state = state.copyWith(
          selectedMalId: malId,
          status: GameStatus.awaitingSwapTarget,
        );
        HapticFeedback.mediumImpact();
      case GameStatus.awaitingSwapTarget:
        final myMalId = state.selectedMalId;
        if (myMalId == null || !_swapMals(teamIndex, myMalId, malId)) return;
        state = state.copyWith(
          status: GameStatus.throwing,
          selectedMalId: null,
        );
      default:
        return;
    }
  }

  @override
  bool _banishMal(int teamIndex, int malId) {
    final teams = ItemEffects.banish(state.teams, teamIndex, malId);
    if (teams == null) return false;
    _setTeams(teams);
    _triggerCaptureFeedback();
    return true;
  }

  @override
  bool _swapMals(int teamIndex, int myMalId, int targetMalId) {
    final teams = ItemEffects.swap(
      state.teams,
      teamIndex,
      myMalId,
      targetMalId,
    );
    if (teams == null) return false;
    _setTeams(teams);
    HapticFeedback.heavyImpact();
    return true;
  }
}
