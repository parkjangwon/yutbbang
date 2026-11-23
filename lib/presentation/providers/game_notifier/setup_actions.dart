part of '../game_provider.dart';

/// 설정 저장·복원과 게임 시작.
mixin _SetupActions on _GameNotifierBase {
  static const _teamColors = [
    TeamColor.orange,
    TeamColor.green,
    TeamColor.red,
    TeamColor.blue,
  ];

  /// 로비 상태. 말 id는 `팀 인덱스 * 10 + 말 번호`.
  static GameState _buildInitialState(
    GameRuleConfig globalConfig,
    GameRuleConfig gameConfig,
  ) {
    final teams = [
      for (int i = 0; i < gameConfig.teamCount; i++) _buildTeam(i, gameConfig),
    ];
    return GameState(
      config: globalConfig,
      activeConfig: gameConfig,
      teams: teams,
    );
  }

  static Team _buildTeam(int index, GameRuleConfig config) {
    final color = _teamColors[index];
    final controllerId = index < config.teamControllers.length
        ? config.teamControllers[index]
        : 0;
    return Team(
      name: config.teamNames[index],
      color: color,
      mals: List.generate(
        config.malCount,
        (m) => Mal(id: index * 10 + m, color: color),
      ),
      controllerId: controllerId,
      isHuman: controllerId > 0,
    );
  }

  /// 글로벌 설정 변경. 로비에서는 다음 판 설정에도 바로 반영한다.
  void updateConfig(GameRuleConfig config) {
    _applyGlobalConfig(config);
    _configRepository.save(config);
  }

  Future<void> _loadConfig() async {
    final repository = _configRepository;
    final loaded = await repository.load(
      () => ref.mounted ? state.config : const GameRuleConfig(),
    );
    if (ref.mounted) _applyGlobalConfig(loaded);
  }

  void _applyGlobalConfig(GameRuleConfig config) {
    state = state.copyWith(
      config: config,
      activeConfig: state.status == GameStatus.lobby
          ? config
          : state.activeConfig,
    );
  }

  /// [gameConfig]로 새 판을 시작한다. 첫 차례가 CPU면 2초 뒤 자동으로 던진다.
  void startGameWithConfig(GameRuleConfig gameConfig) {
    state = _buildInitialState(state.config, gameConfig).copyWith(
      status: GameStatus.throwing,
      itemTiles: gameConfig.useItemMode
          ? ItemTileGenerator.generate(_random)
          : <int>{},
    );

    if (!_isHumanTurn) {
      _later(const Duration(milliseconds: 2000), () {
        if (state.status == GameStatus.throwing) {
          _aiProcessItems();
          throwYut();
        }
      });
    }
  }
}
