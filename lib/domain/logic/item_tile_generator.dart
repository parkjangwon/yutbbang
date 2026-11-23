import 'dart:math';

import 'board_graph.dart';

/// 아이템 모드에서 선물 상자 타일 위치를 정한다.
class ItemTileGenerator {
  /// 전체 칸 중 아이템 타일 비율.
  static const double tileRatio = 0.3;

  /// 1~28번 칸 중 약 30%(8개)를 고른다. 가능하면 서로 인접하지 않게 고르고,
  /// 인접 제약으로 개수를 못 채우면 나머지는 무작위로 채운다.
  static Set<int> generate(Random random) {
    final candidates = List.generate(28, (i) => i + 1)..shuffle(random);
    final targetCount = (candidates.length * tileRatio).round();
    final tiles = <int>{};

    for (final nodeId in candidates) {
      if (tiles.length >= targetCount) break;
      final node = BoardGraph.nodes[nodeId];
      if (node == null) continue;
      final neighbors = [node.nextId, node.prevId, node.shortcutNextId];
      if (!neighbors.any(tiles.contains)) tiles.add(nodeId);
    }
    for (final nodeId in candidates) {
      if (tiles.length >= targetCount) break;
      tiles.add(nodeId);
    }
    return tiles;
  }
}
