import 'dart:math';
import 'dart:ui';

import 'board_layout.dart';
import 'components/yut_stick_painter.dart';

/// 윷가락이 쉬는 자리(던지기 전, 던진 뒤 내려앉는 곳). 판을 가리지 않게 정한다.
///
/// 1. 판 아래 공간이 충분하면 판 아래(세로 화면)
/// 2. 아니면 판 왼쪽 빈 공간(가로 화면). 오른쪽은 가방·던지기 버튼 자리라 피한다.
/// 3. 둘 다 없으면 판 아래 끝(겹침 감수)
class YutStickLayout {
  /// 윷가락 사이 간격(중심 기준).
  static const double spacing = 45;

  /// 윷가락 하나가 차지하는 영역(이미지 높이 = stickHeight × 1.1, 여유 포함).
  static const Size stickSize = Size(
    YutStickPainter.stickWidth + 4,
    YutStickPainter.stickHeight * 1.1 + 4,
  );

  /// 화면 가장자리·판과의 최소 여백.
  static const double margin = 8;

  /// 화면 아래 기권·던지기 버튼 높이(여백 20 + 버튼 75).
  static const double bottomButtonsHeight = 95;

  final Size area;

  const YutStickLayout(this.area);

  double get _groupWidth => spacing * 3 + stickSize.width;

  Rect get _board {
    final layout = BoardLayout(area);
    return layout.boardOrigin & Size.square(layout.boardSide);
  }

  Offset get restCenter {
    final board = _board;
    final below = area.height - board.bottom;
    if (below >= stickSize.height + margin * 2) {
      return Offset(area.width / 2, board.bottom + below / 2);
    }
    final left = board.left;
    if (left >= _groupWidth + margin * 2) {
      // 아래 버튼 위쪽에서 세로 가운데
      final usable = area.height - bottomButtonsHeight;
      final y = max(stickSize.height / 2 + margin, usable / 2);
      return Offset(left / 2, y);
    }
    return Offset(area.width / 2, area.height - stickSize.height / 2 - margin);
  }

  /// 윷가락 4개의 중심 좌표(왼쪽부터).
  List<Offset> get restPositions {
    final c = restCenter;
    return [
      for (int i = 0; i < 4; i++) Offset(c.dx + (i - 1.5) * spacing, c.dy),
    ];
  }

  List<Rect> get restRects => [
    for (final p in restPositions)
      Rect.fromCenter(
        center: p,
        width: stickSize.width,
        height: stickSize.height,
      ),
  ];
}
