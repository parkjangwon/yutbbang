enum TeamSetup { oneVsOne, twoVsTwo, freeForAll }

class GameRuleConfig {
  final bool useBackDo;
  final bool nakPenaltyTurnEnd;
  final int malCount;
  final int aiDifficulty;
  final int teamCount;
  final List<String> teamNames;
  final int nakChancePercent;
  final bool useGaugeControl; // New: Gauge control mode like PangYa
  final bool backDoFlying; // 빽도 날기: 대기 중인 말이 빽도 시 바로 골인
  final bool autoCarrier; // 자동 임신: 중앙 도착 시 대기 중인 말 자동 업기
  final bool totalNak; // 전낙: 낙 시 해당 턴의 모든 이전 결과 무효화
  final bool roastedChestnutMode; // 군밤 모드: 지름길 구간에서 항상 최단 거리로 이동
  final List<int> teamControllers;

  const GameRuleConfig({
    this.useBackDo = true,
    this.nakPenaltyTurnEnd = true,
    this.malCount = 2,
    this.aiDifficulty = 5,
    this.teamCount = 2,
    this.teamNames = const ['A팀', 'B팀', 'C팀', 'D팀'],
    this.nakChancePercent = 15,
    this.useGaugeControl = false,
    this.backDoFlying = false,
    this.autoCarrier = false,
    this.totalNak = false,
    this.roastedChestnutMode = false,
    this.teamControllers = const [1, 0, 0, 0],
  });

  GameRuleConfig copyWith({
    bool? useBackDo,
    bool? nakPenaltyTurnEnd,
    int? malCount,
    int? aiDifficulty,
    int? teamCount,
    List<String>? teamNames,
    int? nakChancePercent,
    bool? useGaugeControl,
    bool? backDoFlying,
    bool? autoCarrier,
    bool? totalNak,
    bool? roastedChestnutMode,
    List<int>? teamControllers,
  }) {
    return GameRuleConfig(
      useBackDo: useBackDo ?? this.useBackDo,
      nakPenaltyTurnEnd: nakPenaltyTurnEnd ?? this.nakPenaltyTurnEnd,
      malCount: malCount ?? this.malCount,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      teamCount: teamCount ?? this.teamCount,
      teamNames: teamNames ?? this.teamNames,
      nakChancePercent: nakChancePercent ?? this.nakChancePercent,
      useGaugeControl: useGaugeControl ?? this.useGaugeControl,
      backDoFlying: backDoFlying ?? this.backDoFlying,
      autoCarrier: autoCarrier ?? this.autoCarrier,
      totalNak: totalNak ?? this.totalNak,
      roastedChestnutMode: roastedChestnutMode ?? this.roastedChestnutMode,
      teamControllers: teamControllers ?? this.teamControllers,
    );
  }
}
