enum TeamColor { orange, green, red, blue }

class Mal {
  static const Object _unset = Object();
  final int id;
  final TeamColor color;
  final int? currentNodeId;
  final int? lastNodeId;
  final List<int> historyNodeIds; // To handle multiple Back-Dos correctly
  final bool isFinished;

  Mal({
    required this.id,
    required this.color,
    this.currentNodeId,
    this.lastNodeId,
    this.historyNodeIds = const [],
    this.isFinished = false,
  });

  Mal copyWith({
    Object? currentNodeId = _unset,
    Object? lastNodeId = _unset,
    List<int>? historyNodeIds,
    bool? isFinished,
  }) {
    return Mal(
      id: id,
      color: color,
      currentNodeId: currentNodeId == _unset
          ? this.currentNodeId
          : currentNodeId as int?,
      lastNodeId: lastNodeId == _unset ? this.lastNodeId : lastNodeId as int?,
      historyNodeIds: historyNodeIds ?? this.historyNodeIds,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class Team {
  final String name;
  final TeamColor color;
  final List<Mal> mals;
  final int controllerId; // 0 = CPU, 1-4 = Player
  final bool isHuman;
  final bool hasForfeit; // 기권 여부

  Team({
    required this.name,
    required this.color,
    required this.mals,
    this.controllerId = 1,
    this.isHuman = true,
    this.hasForfeit = false,
  });

  int get finishedCount => mals.where((m) => m.isFinished).length;
  bool get isWinner => !hasForfeit && finishedCount == mals.length;

  Team copyWith({
    String? name,
    TeamColor? color,
    List<Mal>? mals,
    int? controllerId,
    bool? isHuman,
    bool? hasForfeit,
  }) {
    return Team(
      name: name ?? this.name,
      color: color ?? this.color,
      mals: mals ?? this.mals,
      controllerId: controllerId ?? this.controllerId,
      isHuman: isHuman ?? this.isHuman,
      hasForfeit: hasForfeit ?? this.hasForfeit,
    );
  }
}
