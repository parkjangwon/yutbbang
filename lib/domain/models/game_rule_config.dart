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
  final bool useItemMode; // 아이템 모드: 게임판에 아이템 타일 추가
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
    this.useItemMode = false,
    this.teamControllers = const [1, 0, 0, 0],
  });

  /// [teamIndex] 팀의 조작자를 바꾼다(0 = CPU, 1~4 = 플레이어 번호).
  /// 한 플레이어는 한 팀만 맡으므로, 같은 번호를 쓰던 다른 팀은 CPU가 된다.
  GameRuleConfig withController(int teamIndex, int controllerId) {
    final next = List<int>.from(teamControllers);
    if (controllerId > 0) {
      for (int i = 0; i < next.length; i++) {
        if (next[i] == controllerId) next[i] = 0;
      }
    }
    next[teamIndex] = controllerId;
    return copyWith(teamControllers: _normalized(next, teamCount));
  }

  /// 참여 팀 수를 바꾼다. 빠지는 팀의 조작자는 CPU로 초기화한다.
  GameRuleConfig withTeamCount(int count) => copyWith(
    teamCount: count,
    teamControllers: _normalized(teamControllers, count),
  );

  /// 참여하지 않는 팀은 CPU로, 중복된 플레이어 번호는 뒤쪽 팀을 CPU로.
  static List<int> _normalized(List<int> controllers, int teamCount) {
    final used = <int>{};
    return [
      for (int i = 0; i < controllers.length; i++)
        if (i >= teamCount || (controllers[i] > 0 && !used.add(controllers[i])))
          0
        else
          controllers[i],
    ];
  }

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
    bool? useItemMode,
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
      useItemMode: useItemMode ?? this.useItemMode,
      teamControllers: teamControllers ?? this.teamControllers,
    );
  }
}
