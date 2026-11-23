import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_item.dart';

void main() {
  test('아이템은 9종이고 타입별로 하나씩', () {
    expect(
      GameItem.allItems.map((i) => i.type).toSet(),
      ItemType.values.toSet(),
    );
  });

  test('자동 발동 아이템은 다시 던지기·낙 방지권·뒷걸음질', () {
    final auto = GameItem.allItems
        .where((i) => i.isAutoTriggered)
        .map((i) => i.type);
    expect(auto.toSet(), {ItemType.reroll, ItemType.shield, ItemType.moonwalk});
  });

  test('자동 발동 아이템은 가방에서 누르면 사용법만 안내한다', () {
    for (final item in GameItem.allItems.where((i) => i.isAutoTriggered)) {
      expect(item.tapHint, isNotNull, reason: item.name);
      expect(item.tapHint, startsWith(item.emoji));
    }
  });

  test('대상을 골라야 하는 아이템과 황금 윷은 사용 전에 안내한다', () {
    for (final type in [ItemType.swap, ItemType.banish, ItemType.fixedDice]) {
      expect(GameItem.fromType(type).tapHint, isNotNull, reason: '$type');
    }
    for (final type in [ItemType.magnet, ItemType.typhoon, ItemType.freeze]) {
      expect(GameItem.fromType(type).tapHint, isNull, reason: '$type');
    }
  });
}
