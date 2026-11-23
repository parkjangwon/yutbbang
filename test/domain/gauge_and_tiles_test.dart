import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/board_graph.dart';
import 'package:yutbbang/domain/logic/gauge_logic.dart';
import 'package:yutbbang/domain/logic/item_tile_generator.dart';
import 'package:yutbbang/domain/models/nak_zone.dart';

void main() {
  group('게이지', () {
    test('낙 확률이 높을수록 구간이 많고 좁고 빠르다', () {
      final easy = GaugeSettings.forNakChance(5);
      final normal = GaugeSettings.forNakChance(15);
      final hard = GaugeSettings.forNakChance(30);
      expect([easy.zoneCount, normal.zoneCount, hard.zoneCount], [1, 3, 4]);
      expect(hard.zoneWidth, lessThan(easy.zoneWidth));
      expect(hard.speedStep, greaterThan(easy.speedStep));
    });

    test('낙 구간은 0.1~0.9 안에 생기고, 어려움에서는 겹치지 않는다', () {
      for (int seed = 0; seed < 50; seed++) {
        final zones = GaugeLogic.generateNakZones(30, Random(seed));
        expect(zones, hasLength(4));
        for (final z in zones) {
          expect(z.start, greaterThanOrEqualTo(0.1));
          expect(z.end, lessThanOrEqualTo(0.9 + 1e-9));
        }
      }
    });

    test('게이지는 끝에서 방향을 바꿔 왕복한다', () {
      expect(GaugeLogic.step(0.5, 1, 0.1), (0.6, 1.0));
      expect(GaugeLogic.step(0.95, 1, 0.1), (1.0, -1.0));
      expect(GaugeLogic.step(0.05, -1, 0.1), (0.0, 1.0));
    });

    test('낙 구간 판정은 경계를 포함한다', () {
      const zones = [NakZone(0.3, 0.4)];
      expect(GaugeLogic.isInNakZone(0.3, zones), isTrue);
      expect(GaugeLogic.isInNakZone(0.4, zones), isTrue);
      expect(GaugeLogic.isInNakZone(0.41, zones), isFalse);
    });
  });

  group('아이템 타일', () {
    test('1~28번 중 8칸, 출발/골인(0)은 제외', () {
      for (int seed = 0; seed < 30; seed++) {
        final tiles = ItemTileGenerator.generate(Random(seed));
        expect(tiles, hasLength(8));
        expect(tiles.every((n) => n >= 1 && n <= 28), isTrue);
      }
    });

    test('가능하면 서로 인접하지 않게 배치한다', () {
      final tiles = ItemTileGenerator.generate(Random(3));
      for (final id in tiles) {
        final n = BoardGraph.nodes[id]!;
        expect(
          [n.nextId, n.prevId, n.shortcutNextId].any(tiles.contains),
          isFalse,
        );
      }
    });
  });
}
