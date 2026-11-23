import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';

class StickConfig {
  Vector2 position;
  double angle;
  Vector2 velocity;
  double angularVelocity;
  bool isFlat;
  double targetAngle;
  Vector2 targetPosition; // Fixed target to ensure NO overlaps

  StickConfig({
    required this.position,
    required this.angle,
    required this.velocity,
    required this.angularVelocity,
    required this.isFlat,
    required this.targetPosition,
    this.targetAngle = 0.0,
  });
}

/// 윷가락 이미지(배, 빽도 표시 배, 등). 없으면 캔버스로 그린다.
class YutStickSprites {
  final ui.Image flat;
  final ui.Image flatBackDo;
  final ui.Image round;

  const YutStickSprites({
    required this.flat,
    required this.flatBackDo,
    required this.round,
  });
}

/// 윷가락 하나를 캔버스에 그리는 helper.
abstract final class YutStickPainter {
  static const double stickWidth = 26.0;
  static const double stickHeight = 115.0;

  static void paint(
    Canvas canvas,
    StickConfig s, {
    required double shadowZ,
    required bool hasBackDoMark,
    YutStickSprites? sprites,
  }) {
    canvas.save();
    canvas.translate(s.position.x, s.position.y);
    canvas.rotate(s.angle);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: stickWidth,
      height: stickHeight,
    );
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(15));

    canvas.drawRRect(
      rRect.shift(Offset(shadowZ, shadowZ * 1.5)),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final normalizedAngle = (s.angle.abs() / pi) % 2;
    final showingFlat = (normalizedAngle > 0.5 && normalizedAngle < 1.5);

    if (sprites != null) {
      final image = showingFlat
          ? (hasBackDoMark ? sprites.flatBackDo : sprites.flat)
          : sprites.round;
      // 이미지 비율을 유지하고 높이를 맞춘다.
      final height = stickHeight * 1.1;
      final width = height * image.width / image.height;
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: height,
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
      return;
    }

    canvas.drawRRect(
      rRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: showingFlat
              ? [const Color(0xFFF5DEB3), const Color(0xFFFFE4B5)]
              : [const Color(0xFF4D260B), const Color(0xFF8B4513)],
        ).createShader(rect),
    );

    // Detail markers based on which side is showing
    if (showingFlat) {
      _paintFlatSide(canvas, hasBackDoMark);
    } else {
      _paintRoundSide(canvas);
    }
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  /// Flat side (belly): 3 horizontal lines (+ Back-Do X mark).
  static void _paintFlatSide(Canvas canvas, bool hasBackDoMark) {
    final markPaint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var step in [0.25, 0.5, 0.75]) {
      final y = -stickHeight / 2 + stickHeight * step;
      canvas.drawLine(
        Offset(-stickWidth * 0.35, y),
        Offset(stickWidth * 0.35, y),
        markPaint,
      );
    }

    // Back-Do mark: Single black X at center (only for stick 0)
    if (hasBackDoMark) {
      final xPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      const double xSize = 9.0;
      const centerY = 0.0; // Center of the stick
      canvas.drawLine(
        const Offset(-xSize, centerY - xSize),
        const Offset(xSize, centerY + xSize),
        xPaint,
      );
      canvas.drawLine(
        const Offset(xSize, centerY - xSize),
        const Offset(-xSize, centerY + xSize),
        xPaint,
      );
    }
  }

  /// Round side (back): 3 black X marks uniformly distributed.
  static void _paintRoundSide(Canvas canvas) {
    final xPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    const double xSize = 6.5;
    for (var step in [0.25, 0.5, 0.75]) {
      final y = -stickHeight / 2 + stickHeight * step;
      canvas.drawLine(
        Offset(-xSize, y - xSize),
        Offset(xSize, y + xSize),
        xPaint,
      );
      canvas.drawLine(
        Offset(xSize, y - xSize),
        Offset(-xSize, y + xSize),
        xPaint,
      );
    }
  }
}
