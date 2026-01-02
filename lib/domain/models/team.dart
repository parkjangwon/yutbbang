enum TeamColor { orange, green, red, blue }

class Mal {
  static const Object _unset = Object();
  final int id;
  final TeamColor color;
  int? currentNodeId;
  int? lastNodeId;
  bool isFinished;

  Mal({
    required this.id,
    required this.color,
    this.currentNodeId,
    this.lastNodeId,
    this.isFinished = false,
  });

  Mal copyWith({
    Object? currentNodeId = _unset,
    Object? lastNodeId = _unset,
    bool? isFinished,
  }) {
    return Mal(
      id: id,
      color: color,
      currentNodeId: currentNodeId == _unset
          ? this.currentNodeId
          : currentNodeId as int?,
      lastNodeId: lastNodeId == _unset ? this.lastNodeId : lastNodeId as int?,
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

  Team({
    required this.name,
    required this.color,
    required this.mals,
    this.controllerId = 1,
    this.isHuman = true,
  });

  int get finishedCount => mals.where((m) => m.isFinished).length;
  bool get isWinner => finishedCount == mals.length;

  Team copyWith({
    String? name,
    TeamColor? color,
    List<Mal>? mals,
    int? controllerId,
    bool? isHuman,
  }) {
    return Team(
      name: name ?? this.name,
      color: color ?? this.color,
      mals: mals ?? this.mals,
      controllerId: controllerId ?? this.controllerId,
      isHuman: isHuman ?? this.isHuman,
    );
  }
}
