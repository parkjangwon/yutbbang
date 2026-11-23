import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/game/board_layout.dart';
import 'package:yutbbang/game/yut_stick_layout.dart';

/// 게임판 영역(GameWidget) 크기들: 세로 폰, 가로 폰, 가로 태블릿.
const sizes = {
  '세로 폰': Size(430, 684),
  '가로 폰': Size(684, 335),
  '가로 태블릿': Size(1064, 705),
};

/// 판 위에 겹쳐 있는 버튼(기권: 왼쪽 아래, 던지기: 오른쪽 아래, 75px, 여백 20).
List<Rect> buttonsOf(Size s) => [
  Rect.fromLTWH(20, s.height - 95, 75, 75),
  Rect.fromLTWH(s.width - 95, s.height - 95, 75, 75),
];

void main() {
  sizes.forEach((name, size) {
    group(name, () {
      final layout = YutStickLayout(size);
      final board = BoardLayout(size);
      final boardRect = board.boardOrigin & Size.square(board.boardSide);

      test('쉬는 윷가락 4개는 판과 겹치지 않는다', () {
        for (final r in layout.restRects) {
          expect(
            r.overlaps(boardRect),
            isFalse,
            reason: 'stick=$r board=$boardRect',
          );
        }
      });

      test('쉬는 윷가락은 화면 안에 있고 기권·던지기 버튼과 겹치지 않는다', () {
        final screen = Offset.zero & size;
        for (final r in layout.restRects) {
          expect(
            screen.contains(r.topLeft) && screen.contains(r.bottomRight),
            isTrue,
            reason: '$r',
          );
          for (final b in buttonsOf(size)) {
            expect(r.overlaps(b), isFalse, reason: 'stick=$r button=$b');
          }
        }
      });

      test('윷가락끼리 겹치지 않는다', () {
        final rects = layout.restRects;
        for (int i = 0; i < rects.length; i++) {
          for (int j = i + 1; j < rects.length; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse);
          }
        }
      });
    });
  });

  test('세로 화면은 판 아래, 가로 화면은 판 왼쪽에 둔다', () {
    final portrait = YutStickLayout(sizes['세로 폰']!);
    final pBoard = BoardLayout(sizes['세로 폰']!);
    expect(
      portrait.restCenter.dy,
      greaterThan(pBoard.boardOrigin.dy + pBoard.boardSide),
    );

    final landscape = YutStickLayout(sizes['가로 폰']!);
    final lBoard = BoardLayout(sizes['가로 폰']!);
    expect(landscape.restCenter.dx, lessThan(lBoard.boardOrigin.dx));
  });
}
