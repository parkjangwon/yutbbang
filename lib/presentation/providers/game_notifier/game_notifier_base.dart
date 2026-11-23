part of '../game_provider.dart';

/// 공통 필드·헬퍼와, 다른 part가 서로 호출하는 메서드의 선언.
abstract class _GameNotifierBase extends Notifier<GameState> {
  Timer? _gaugeTimer;
  double _gaugeDirection = 1.0;

  Random get _random => ref.read(gameRandomProvider);
  ConfigRepository get _configRepository => ref.read(configRepositoryProvider);

  int get _teamIndex => state.currentTeamIndex;
  bool get _isHumanTurn => state.currentTeam.isHuman;
  GameRuleConfig get _rules => state.activeConfig;

  // --- part 간 호출용 선언 ---
  void throwYut({bool forceNak = false});
  void confirmReroll(bool use);
  void selectMal(int malId);
  void moveMal(
    int malId,
    YutResult result, {
    bool useShortcut = false,
    bool isReverse = false,
  });
  void aiSelectAndMove();
  void nextTurn();
  void _finalizeMove();
  void _checkAutoMove();
  void _handleItemAcquisition(int teamIndex, int nodeId);
  bool _useFixedDice(int teamIndex);
  bool _useFreeze(int teamIndex);
  bool _useMagnet(int teamIndex);
  bool _useTyphoon(int teamIndex);
  bool _banishMal(int teamIndex, int malId);
  bool _swapMals(int teamIndex, int myMalId, int targetMalId);
  void _aiProcessItems();

  // --- 공통 헬퍼 ---

  /// [delay] 뒤에 [action]을 실행한다. 그 사이 provider가 사라졌으면 건너뛴다.
  void _later(Duration delay, void Function() action) {
    Future.delayed(delay, () {
      if (ref.mounted) action();
    });
  }

  void _setTeams(List<Team> teams) => state = state.copyWith(teams: teams);

  /// 현재 팀 인벤토리에서 아이템 하나를 소모한다.
  void _consumeItem(int teamIndex, ItemType item) {
    _setTeams(state.teams.updatedAt(teamIndex, (t) => t.withItemRemoved(item)));
  }

  /// CPU 차례면 잠시 뒤 말을 고르게 한다. 사람 차례면 자동 이동을 검사한다.
  void _promptMalSelection() {
    if (_isHumanTurn) {
      _checkAutoMove();
    } else {
      _later(const Duration(milliseconds: 1500), aiSelectAndMove);
    }
  }

  void _displayItemMessage(String message) {
    state = state.copyWith(itemMessage: message);
    _later(const Duration(milliseconds: 2000), () {
      if (state.itemMessage == message) {
        state = state.copyWith(itemMessage: null);
      }
    });
  }

  void _displayBonusTurn(String message) {
    state = state.copyWith(bonusMessage: message);
    _later(const Duration(milliseconds: 2500), () {
      if (state.bonusMessage == message) {
        state = state.copyWith(bonusMessage: null);
      }
    });
  }

  void _cancelGauge() {
    _gaugeTimer?.cancel();
    _gaugeTimer = null;
  }

  // --- 햅틱·효과음 ---

  void _triggerThrowFeedback(YutResult result) {
    if (result.isBonusTurn || result == YutResult.backDo) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _triggerCaptureFeedback() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
}
