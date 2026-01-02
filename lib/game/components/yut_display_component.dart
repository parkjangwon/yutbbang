import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class YutDisplayComponent extends PositionComponent with HasGameRef, HasPaint {
  List<bool> sticks = [false, false, false, false];

  YutDisplayComponent() {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    _updateSizeAndPosition();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateSizeAndPosition();
  }

  void _updateSizeAndPosition() {
    if (isMounted) {
      // 화면 크기에 비례하는 윷 크기
      final minDim = gameRef.size.x < gameRef.size.y
          ? gameRef.size.x
          : gameRef.size.y;
      final yutWidth = minDim * 0.35; // 화면 최소 크기의 35%
      final yutHeight = yutWidth * 0.4; // 가로의 40% 높이
      size = Vector2(yutWidth, yutHeight);

      _updatePosition();
    }
  }

  void _updatePosition() {
    if (isMounted && gameRef.children.isNotEmpty) {
      // 보드 컴포넌트 찾기
      final board = gameRef.children
          .whereType<PositionComponent>()
          .where((c) => c.runtimeType.toString() == 'BoardComponent')
          .firstOrNull;

      if (board != null) {
        // 보드 중앙 하단 (보드 내부, 중앙 꼭지점 아래)
        final boardCenterX = board.position.x + board.size.x / 2;
        final boardBottomY =
            board.position.y + board.size.y * 0.75; // 보드 하단 25% 위치
        position = Vector2(boardCenterX, boardBottomY);
      } else {
        // Fallback
        position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.75);
      }
    }
  }

  void updateSticks(List<bool> newSticks) {
    sticks = newSticks;
  }

  @override
  void render(Canvas canvas) {
    final stickWidth = size.x / 4 - 10;
    final stickHeight = size.y;

    for (int i = 0; i < 4; i++) {
      final isFlat = sticks[i];
      final xPos = i * (size.x / 4) + 5;

      final rect = Rect.fromLTWH(xPos, 0, stickWidth, stickHeight);
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

      canvas.drawRRect(
        rRect.shift(const Offset(2, 4)),
        Paint()..color = Colors.black26,
      );
      final paint = Paint()
        ..color = isFlat ? const Color(0xFFF5DEB3) : const Color(0xFF8B4513);
      canvas.drawRRect(rRect, paint);

      if (isFlat) {
        // 삼선 위치를 윷 크기에 비례하도록 계산
        final line1Y = stickHeight * 0.2; // 20% 위치
        final line2Y = stickHeight * 0.5; // 50% 위치
        final line3Y = stickHeight * 0.8; // 80% 위치
        final lineMargin = stickWidth * 0.1; // 좌우 여백

        final markPaint = Paint()
          ..color = Colors.brown.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stickWidth * 0.05; // 윷 너비의 5%

        canvas.drawLine(
          Offset(xPos + lineMargin, line1Y),
          Offset(xPos + stickWidth - lineMargin, line1Y),
          markPaint,
        );
        canvas.drawLine(
          Offset(xPos + lineMargin, line2Y),
          Offset(xPos + stickWidth - lineMargin, line2Y),
          markPaint,
        );
        canvas.drawLine(
          Offset(xPos + lineMargin, line3Y),
          Offset(xPos + stickWidth - lineMargin, line3Y),
          markPaint,
        );

        if (i == 0) {
          // 빽도 표시: 검정 X 표시 3개 (각 마디마다)
          final xSize = stickWidth * 0.3; // X 크기를 윷 너비의 30%로
          final xPaint = Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = stickWidth * 0.08; // 윷 너비의 8%

          // 첫 번째 X (위쪽 마디)
          canvas.drawLine(
            Offset(xPos + stickWidth / 2 - xSize / 2, line1Y - xSize / 2),
            Offset(xPos + stickWidth / 2 + xSize / 2, line1Y + xSize / 2),
            xPaint,
          );
          canvas.drawLine(
            Offset(xPos + stickWidth / 2 + xSize / 2, line1Y - xSize / 2),
            Offset(xPos + stickWidth / 2 - xSize / 2, line1Y + xSize / 2),
            xPaint,
          );

          // 두 번째 X (중간 마디)
          canvas.drawLine(
            Offset(xPos + stickWidth / 2 - xSize / 2, line2Y - xSize / 2),
            Offset(xPos + stickWidth / 2 + xSize / 2, line2Y + xSize / 2),
            xPaint,
          );
          canvas.drawLine(
            Offset(xPos + stickWidth / 2 + xSize / 2, line2Y - xSize / 2),
            Offset(xPos + stickWidth / 2 - xSize / 2, line2Y + xSize / 2),
            xPaint,
          );

          // 세 번째 X (아래쪽 마디)
          canvas.drawLine(
            Offset(xPos + stickWidth / 2 - xSize / 2, line3Y - xSize / 2),
            Offset(xPos + stickWidth / 2 + xSize / 2, line3Y + xSize / 2),
            xPaint,
          );
          canvas.drawLine(
            Offset(xPos + stickWidth / 2 + xSize / 2, line3Y - xSize / 2),
            Offset(xPos + stickWidth / 2 - xSize / 2, line3Y + xSize / 2),
            xPaint,
          );
        }
      } else {
        final barkPaint = Paint()
          ..color = Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(xPos + stickWidth / 2, 10),
          Offset(xPos + stickWidth / 2, 90),
          barkPaint,
        );
      }
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}
