import 'game_item.dart';

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

  /// 판 위에 올라와 있고 아직 완주하지 않은 말인지.
  bool get isOnBoard => currentNodeId != null && !isFinished;

  /// 출발 전 대기 상태(판 밖, 미완주)인지.
  bool get isWaiting => currentNodeId == null && !isFinished;

  /// 잡히거나 기권해서 출발점(판 밖)으로 돌아간 말.
  Mal sentHome() => copyWith(
    currentNodeId: null,
    lastNodeId: null,
    historyNodeIds: const [],
    isFinished: false,
  );

  /// 완주 처리된 말.
  Mal markedFinished() => copyWith(
    currentNodeId: null,
    lastNodeId: null,
    historyNodeIds: const [],
    isFinished: true,
  );

  /// 특정 칸으로 순간 이동(태풍·위치 교환 등). 이동 기록은 그 칸 하나로 초기화.
  Mal teleportedTo(int nodeId) =>
      copyWith(currentNodeId: nodeId, historyNodeIds: [nodeId]);

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
  final List<ItemType> items; // 아이템 인벤토리 (최대 2개)
  final bool skipNextTurn; // 얼음탄용 상태

  Team({
    required this.name,
    required this.color,
    required this.mals,
    this.controllerId = 1,
    this.isHuman = true,
    this.hasForfeit = false,
    this.items = const [],
    this.skipNextTurn = false,
  });

  /// 팀당 최대 보유 아이템 수.
  static const int maxItems = 2;

  int get finishedCount => mals.where((m) => m.isFinished).length;
  bool get hasMalOnBoard => mals.any((m) => m.isOnBoard);
  bool get isInventoryFull => items.length >= maxItems;

  Team withItemRemoved(ItemType item) =>
      copyWith(items: List<ItemType>.from(items)..remove(item));

  Team mapMals(Mal Function(Mal mal) transform) =>
      copyWith(mals: mals.map(transform).toList());
  bool get isWinner => !hasForfeit && finishedCount == mals.length;

  Team copyWith({
    String? name,
    TeamColor? color,
    List<Mal>? mals,
    int? controllerId,
    bool? isHuman,
    bool? hasForfeit,
    List<ItemType>? items,
    bool? skipNextTurn,
  }) {
    return Team(
      name: name ?? this.name,
      color: color ?? this.color,
      mals: mals ?? this.mals,
      controllerId: controllerId ?? this.controllerId,
      isHuman: isHuman ?? this.isHuman,
      hasForfeit: hasForfeit ?? this.hasForfeit,
      items: items ?? this.items,
      skipNextTurn: skipNextTurn ?? this.skipNextTurn,
    );
  }
}
