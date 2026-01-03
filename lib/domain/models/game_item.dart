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

  const GameItem({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
  });

  static const GameItem reroll = GameItem(
    type: ItemType.reroll,
    name: '다시 던지기',
    description: '윷 결과가 마음에 들지 않을 때 한 번 더 던짐 (낙 방지용)',
    emoji: '🔄',
  );

  static const GameItem shield = GameItem(
    type: ItemType.shield,
    name: '낙 방지권',
    description: '낙이 나와도 턴이 끝나지 않고 \'도\'로 처리 (자동 적용)',
    emoji: '🛡️',
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
  );

  static const GameItem fixedDice = GameItem(
    type: ItemType.fixedDice,
    name: '황금 윷',
    description: '다음 던지기 결과가 무조건 \'윷\' 또는 \'모\'로 나오게 함',
    emoji: '🌟',
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
