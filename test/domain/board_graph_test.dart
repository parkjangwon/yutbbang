import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/board_graph.dart';

void main() {
  group('BoardGraph', () {
    test('윷판은 29칸(0~28)이다', () {
      expect(BoardGraph.nodes.keys.toSet(), {for (int i = 0; i <= 28; i++) i});
    });

    test('바깥 둘레는 0→1→…→19→0 으로 이어진다', () {
      for (int i = 0; i < 19; i++) {
        expect(BoardGraph.nodes[i]!.nextId, i + 1, reason: 'node $i');
      }
      expect(BoardGraph.nodes[19]!.nextId, 0);
    });

    test('갈림길은 첫째(5)·둘째(10) 꼭짓점과 중앙(20)에만 있다', () {
      final withShortcut = BoardGraph.nodes.values
          .where((n) => n.shortcutNextId != null)
          .map((n) => n.id)
          .toSet();
      expect(withShortcut, {5, 10, 20});
      expect(BoardGraph.nodes[5]!.shortcutNextId, 21);
      expect(BoardGraph.nodes[10]!.shortcutNextId, 25);
    });

    test('중앙(20)의 기본 방향은 골인 쪽(27)이다', () {
      expect(BoardGraph.nodes[20]!.nextId, 27);
      expect(BoardGraph.nodes[20]!.shortcutNextId, 23);
    });

    test('대각선 끝은 각각 15번과 0번으로 이어진다', () {
      expect(BoardGraph.nodes[24]!.nextId, 15);
      expect(BoardGraph.nodes[28]!.nextId, 0);
    });

    test('모든 칸 좌표는 0~1 범위다', () {
      for (final n in BoardGraph.nodes.values) {
        expect(n.x, inInclusiveRange(0, 1));
        expect(n.y, inInclusiveRange(0, 1));
      }
    });

    group('nodesWithinDistance', () {
      test('거리 0이면 자기 자신만', () {
        expect(BoardGraph.nodesWithinDistance(3, 0), {3});
      });

      test('직선 구간은 앞쪽 칸만 포함한다', () {
        expect(BoardGraph.nodesWithinDistance(1, 3), {1, 2, 3, 4});
      });

      test('꼭짓점에서는 지름길 방향도 포함한다', () {
        expect(BoardGraph.nodesWithinDistance(5, 2), {5, 6, 7, 21, 22});
      });
    });
  });
}
