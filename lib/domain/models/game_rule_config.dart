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
      teamControllers: teamControllers ?? this.teamControllers,
    );
  }
}
