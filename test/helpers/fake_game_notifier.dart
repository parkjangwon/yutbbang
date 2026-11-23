import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/team.dart';
import 'package:yutbbang/presentation/providers/game_provider.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';

/// 상태를 직접 주입하고, UI가 부른 액션을 기록하는 테스트용 Notifier.
class FakeGameNotifier extends GameNotifier {
  FakeGameNotifier(this._initial);

  final GameState _initial;
  final List<String> calls = [];

  @override
  GameState build() => _initial;

  void emit(GameState next) => state = next;

  @override
  void selectMal(int malId) => calls.add('selectMal($malId)');

  @override
  void handleMalSelectionForItem(int malId) =>
      calls.add('handleMalSelectionForItem($malId)');

  @override
  void confirmReroll(bool use) => calls.add('confirmReroll($use)');

  @override
  void useItem(ItemType itemType) => calls.add('useItem(${itemType.name})');

  @override
  void confirmMoonwalk(bool use) => calls.add('confirmMoonwalk($use)');

  @override
  void replaceItem(int slotIndex, int nodeId, {required int teamIndex}) =>
      calls.add('replaceItem($slotIndex, $nodeId, team: $teamIndex)');

  @override
  void discardPendingItem() => calls.add('discardPendingItem');

  @override
  void forfeit(int teamIndex) => calls.add('forfeit($teamIndex)');

  @override
  void chooseShortcut(bool useShortcut) =>
      calls.add('chooseShortcut($useShortcut)');

  @override
  void throwYut({bool forceNak = false}) => calls.add('throwYut');

  @override
  void startGauge() => calls.add('startGauge');

  @override
  void stopGauge() => calls.add('stopGauge');

  @override
  void exitGame() => calls.add('exitGame');

  GameRuleConfig? startedWith;

  @override
  void startGameWithConfig(GameRuleConfig gameConfig) {
    startedWith = gameConfig;
    calls.add('startGameWithConfig');
  }

  @override
  void updateConfig(GameRuleConfig config) {
    state = state.copyWith(config: config, activeConfig: config);
    calls.add('updateConfig');
  }
}

/// [FakeGameNotifier]로 gameProvider를 바꾼 override와 notifier를 함께 만든다.
(FakeGameNotifier, Override) fakeGame(GameState state) {
  final notifier = FakeGameNotifier(state);
  return (notifier, gameProvider.overrideWith(() => notifier));
}

GameState gameStateOf(
  GameStatus status,
  List<Team> teams, {
  int turnIndex = 0,
}) => GameState(
  config: const GameRuleConfig(),
  activeConfig: const GameRuleConfig(),
  teams: teams,
  status: status,
  turnIndex: turnIndex,
);
