import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/models/team.dart';
import '../../presentation/widgets/game/team_colors.dart';

/// 말(MalComponent)의 캔버스 그리기 helper.
abstract final class MalRenderer {
  /// 동전 모양 말 본체 + 테두리 + 업힌 개수 표시.
  static void paintCoin(
    Canvas canvas,
    Offset center,
    double radius,
    TeamColor teamColor,
    int stackCount,
  ) {
    final color = rawColor(teamColor);

    // Visual: Coin body
    canvas.drawCircle(
      center + const Offset(0, 4),
      radius,
      Paint()
        ..color = const Color(0x334A3B30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center + const Offset(0, 2),
      radius,
      Paint()..color = darkerColor(color),
    );
    canvas.drawCircle(center, radius, Paint()..color = color);

    // 무광 하이라이트(위쪽 살짝 밝게)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 0.9,
          colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // 팀 글자(색각 이상 사용자도 구분할 수 있게)
    final letter = TextPainter(
      text: TextSpan(
        text: teamColor.letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.9,
          shadows: const [Shadow(blurRadius: 1, color: Color(0x404A3B30))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    letter.paint(canvas, center - Offset(letter.width / 2, letter.height / 2));

    if (stackCount > 1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'x$stackCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            shadows: [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, center + Offset(radius - 8, -radius + 4));
    }
  }

  /// 선택 가능한 말 주위의 맥박 효과.
  static void paintSelectionPulse(
    Canvas canvas,
    Offset center,
    double radius, [
    Color color = Colors.white,
  ]) {
    final pulse =
        0.5 + 0.5 * math.sin(DateTime.now().millisecondsSinceEpoch / 200);
    canvas.drawCircle(
      center,
      radius + 2 + pulse * 6,
      Paint()
        ..color = color.withValues(alpha: 0.45 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  static Color rawColor(TeamColor color) => teamColorOf(color);

  static Color darkerColor(Color color) {
    return Color.fromARGB(
      255,
      (_channel8(color.r) * 0.7).toInt(),
      (_channel8(color.g) * 0.7).toInt(),
      (_channel8(color.b) * 0.7).toInt(),
    );
  }

  static int _channel8(double c) => (c * 255.0).round().clamp(0, 255);
}
