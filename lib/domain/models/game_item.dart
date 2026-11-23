enum ItemType {
  reroll, // 다시 던지기
  shield, // 낙 방지권
  magnet, // 자석
  moonwalk, // 뒷걸음질
  typhoon, // 태풍
  banish, // 강제 귀가권
  freeze, // 얼음/수면탄
  swap, // 위치 교환
  fixedDice, // 황금 윷
}

class GameItem {
  final ItemType type;
  final String name;
  final String description;
  final String emoji;

  /// 조건이 맞으면 저절로 쓰이는 아이템(가방에서 직접 쓸 수 없음).
  final bool isAutoTriggered;

  /// 가방에서 눌렀을 때 먼저 보여줄 안내. 없으면 null.
  final String? tapHint;

  const GameItem({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    this.isAutoTriggered = false,
    this.tapHint,
  });

  static const GameItem reroll = GameItem(
    type: ItemType.reroll,
    name: '다시 던지기',
    description: '윷 결과가 마음에 들지 않을 때 한 번 더 던짐 (낙 방지용)',
    emoji: '🔄',
    isAutoTriggered: true,
    tapHint: '🔄 다시 던지기는 윷을 던진 후 자동으로 사용 여부를 물어봅니다.',
  );

  static const GameItem shield = GameItem(
    type: ItemType.shield,
    name: '낙 방지권',
    description: '낙이 나와도 턴이 끝나지 않고 \'도\'로 처리 (자동 적용)',
    emoji: '🛡️',
    isAutoTriggered: true,
    tapHint: '🛡️ 낙 방지권은 낙이 나왔을 때 자동으로 사용됩니다.',
  );

  static const GameItem magnet = GameItem(
    type: ItemType.magnet,
    name: '자석',
    description: '내 말 앞 3칸 이내에 있는 상대 말을 내 칸으로 끌어당겨서 잡음',
    emoji: '🧲',
  );

  static const GameItem moonwalk = GameItem(
    type: ItemType.moonwalk,
    name: '뒷걸음질',
    description: '도, 개, 걸이 나왔을 때 앞 대신 뒤로 갈 수 있음',
    emoji: '↩️',
    isAutoTriggered: true,
    tapHint: '↩️ 뒷걸음질은 말을 선택할 때 사용할지 자동으로 물어봅니다.',
  );

  static const GameItem typhoon = GameItem(
    type: ItemType.typhoon,
    name: '태풍',
    description: '맵에 나와 있는 모든 말(아군/적군 포함) 위치를 무작위로 뒤섞음',
    emoji: '🌪️',
  );

  static const GameItem banish = GameItem(
    type: ItemType.banish,
    name: '강제 귀가권',
    description: '맵에 있는 상대방의 말 하나를 즉시 출발지로 돌려보냄',
    emoji: '🏠',
    tapHint: '🏠 강제 귀가권: 상대방의 말 하나를 지정하여 출발지로 보냅니다.',
  );

  static const GameItem freeze = GameItem(
    type: ItemType.freeze,
    name: '얼음탄',
    description: '다음 상대방의 턴을 1회 강제로 건너뛰게 함',
    emoji: '❄️',
  );

  static const GameItem swap = GameItem(
    type: ItemType.swap,
    name: '위치 교환',
    description: '내 말 하나와 상대방의 말 하나의 위치를 서로 맞바꿈',
    emoji: '↔️',
    tapHint: '↔️ 위치 교환: 내 말과 상대방 말의 위치를 바꿉니다. 먼저 내 말을 선택하세요.',
  );

  static const GameItem fixedDice = GameItem(
    type: ItemType.fixedDice,
    name: '황금 윷',
    description: '다음 던지기 결과가 무조건 \'윷\' 또는 \'모\'로 나오게 함',
    emoji: '🌟',
    tapHint: '🌟 황금 윷: 다음 던지기 결과가 윷 또는 모로 고정됩니다!',
  );

  static const List<GameItem> allItems = [
    reroll,
    shield,
    magnet,
    moonwalk,
    typhoon,
    banish,
    freeze,
    swap,
    fixedDice,
  ];

  static GameItem fromType(ItemType type) {
    return allItems.firstWhere((item) => item.type == type);
  }
}
