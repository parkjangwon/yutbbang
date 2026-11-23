import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/game/board_layout.dart';

void main() {
  group('BoardLayout', () {
    // 세로 화면 400x800 → 판 한 변 = 짧은 변 400 * 0.85 = 340
    const layout = BoardLayout(Size(400, 800));

    test('판은 짧은 변의 85% 정사각형이고 화면 가운데 놓인다', () {
      expect(layout.boardSide, closeTo(340, 1e-9));
      expect(layout.boardOrigin.dx, closeTo(30, 1e-9));
      expect(layout.boardOrigin.dy, closeTo(230, 1e-9));
    });

    test('노드 좌표(0~1)는 판 안쪽 10% 여백을 두고 배치된다', () {
      // 여백 34, 사용 폭 272
      expect(layout.nodeOffset(0, 0), const Offset(34, 34));
      expect(layout.nodeOffset(1, 1), const Offset(306, 306));
      expect(layout.nodeOffset(0.5, 0.5), const Offset(170, 170));
    });

    test('노드 id로 위치를 구한다 (출발점 0번 = 오른쪽 아래)', () {
      expect(layout.nodeOffsetById(0), const Offset(306, 306));
      expect(layout.nodeOffsetById(10), const Offset(34, 34));
      expect(layout.nodeOffsetById(99), isNull);
    });

    test('꼭짓점·중앙은 큰 원, 나머지는 작은 원', () {
      for (final id in [0, 5, 10, 15, 20]) {
        expect(BoardLayout.isMajorNode(id), isTrue, reason: 'node $id');
      }
      expect(BoardLayout.isMajorNode(3), isFalse);
      expect(layout.nodeRadius(5), closeTo(340 * 0.05, 1e-9));
      expect(layout.nodeRadius(3), closeTo(340 * 0.035, 1e-9));
    });

    test('대기 위치는 팀 수로 나눈 화면 하단 구역의 가운데, 화면 아래 300px', () {
      // 2팀: 구역 폭 200 → 팀0 x=100, 팀1 x=300 (화면 좌표) → 판 기준으로 변환
      expect(
        layout.homeOffset(teamIndex: 0, teamCount: 2),
        const Offset(70, 870),
      );
      expect(
        layout.homeOffset(teamIndex: 1, teamCount: 2),
        const Offset(270, 870),
      );
    });

    test('가로 화면에서는 높이 기준으로 판 크기를 정한다', () {
      const wide = BoardLayout(Size(1000, 600));
      expect(wide.boardSide, closeTo(510, 1e-9));
    });

    test('판이 그려질 만큼 크지 않으면 준비되지 않은 상태', () {
      expect(const BoardLayout(Size(100, 100)).isReady, isFalse);
      expect(layout.isReady, isTrue);
    });
  });
}
