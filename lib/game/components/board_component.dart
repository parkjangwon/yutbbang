import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/logic/board_graph.dart';
import '../yut_game.dart';
import '../../presentation/providers/game_provider.dart';

class BoardComponent extends PositionComponent with HasGameRef {
  static const double nodePaddingRatio =
      0.1; // Use ratio instead of fixed pixels for consistency

  @override
  Future<void> onLoad() async {
    _updateLayout();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateLayout();
  }

  void _updateLayout() {
    final gameSize = gameRef.size;
    final minDim = gameSize.x < gameSize.y ? gameSize.x : gameSize.y;
    final boardDimension = minDim * 0.85;

    size = Vector2.all(boardDimension);
    position = (gameSize - size) / 2;
  }

  // Very specific positioning logic
  Vector2 getRelativeNodePos(double nx, double ny) {
    final padding = size.x * nodePaddingRatio;
    final availableSize = size.x - 2 * padding;

    final x = padding + nx * availableSize;
    final y = padding + ny * availableSize;
    return Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    // Board Border & Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      Paint()..color = const Color(0xFFFAF9F6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      Paint()
        ..color = Colors.brown.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Connection Lines
    final linePaint = Paint()
      ..color = Colors.brown.shade100
      ..strokeWidth = 3;
    for (final node in BoardGraph.nodes.values) {
      final start = getRelativeNodePos(node.x, node.y).toOffset();
      void drawTo(int? targetId) {
        if (targetId == null) return;
        final nextNode = BoardGraph.nodes[targetId];
        if (nextNode != null) {
          final end = getRelativeNodePos(nextNode.x, nextNode.y).toOffset();
          canvas.drawLine(start, end, linePaint);
        }
      }

      drawTo(node.nextId);
      drawTo(node.shortcutNextId);
    }

    // Nodes (Circles) - Exactly representing the board rules
    final nodePaint = Paint()..color = Colors.white;
    final nodeBorderPaint = Paint()
      ..color = Colors.brown.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final specialPaint = Paint()..color = const Color(0xFFFFF4E0);

    for (final node in BoardGraph.nodes.values) {
      final pos = getRelativeNodePos(node.x, node.y).toOffset();
      final isBig = [0, 5, 10, 15, 20].contains(node.id);
      final radius = isBig ? (size.x * 0.05) : (size.x * 0.035);

      canvas.drawCircle(pos, radius, isBig ? specialPaint : nodePaint);
      canvas.drawCircle(pos, radius, nodeBorderPaint);
    }

    // 아이템 타일 표시 (황금색)
    _renderItemTiles(canvas);
  }

  void _renderItemTiles(Canvas canvas) {
    // YutGame에서 게임 상태 가져오기
    if (gameRef is! YutGame) return;

    try {
      final yutGame = gameRef as YutGame;
      final gameState = yutGame.ref.read(gameProvider);

      if (!gameState.activeConfig.useItemMode) return;

      // 아이템 타일 렌더링
      for (final nodeId in gameState.itemTiles) {
        final node = BoardGraph.nodes[nodeId];
        if (node == null) continue;

        final pos = getRelativeNodePos(node.x, node.y).toOffset();
        final isBig = [0, 5, 10, 15, 20].contains(node.id);
        final radius = isBig ? (size.x * 0.05) : (size.x * 0.035);

        // 황금색 외곽 글로우
        final glowPaint = Paint()
          ..color = Colors.amber.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(pos, radius, glowPaint);

        // 선물 상자 이모지 (🎁) 그리기
        final textPainter = TextPainter(
          text: TextSpan(
            text: '🎁',
            style: TextStyle(fontSize: radius * 1.5),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // 중앙에 배치
        textPainter.paint(
          canvas,
          pos - Offset(textPainter.width / 2, textPainter.height / 2),
        );

        // 반짝이는 효과 (작은 별들)
        _drawSparkle(
          canvas,
          Offset(pos.dx - radius * 0.4, pos.dy - radius * 0.4),
          radius * 0.3,
        );
        _drawSparkle(
          canvas,
          Offset(pos.dx + radius * 0.4, pos.dy + radius * 0.4),
          radius * 0.3,
        );
      }
    } catch (e) {
      // 초기 프레임 안전성
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * 3.14159 / 180;
      final x =
          center.dx + size * 0.5 * (i % 2 == 0 ? 1 : 0.3) * (i < 2 ? 1 : -1);
      final y =
          center.dy +
          size * 0.5 * (i % 2 == 1 ? 1 : 0.3) * ((i == 1 || i == 2) ? 1 : -1);

      if (i == 0) {
        path.moveTo(center.dx, center.dy - size);
      }
      path.lineTo(
        center.dx +
            (i == 0
                ? 0
                : i == 1
                ? size * 0.2
                : i == 2
                ? 0
                : -size * 0.2),
        center.dy +
            (i == 0
                ? -size
                : i == 1
                ? 0
                : i == 2
                ? size
                : 0),
      );
    }
    path.close();

    // 간단한 십자 별 모양
    final sparkleSize = size * 0.6;
    canvas.drawLine(
      Offset(center.dx, center.dy - sparkleSize),
      Offset(center.dx, center.dy + sparkleSize),
      paint..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(center.dx - sparkleSize, center.dy),
      Offset(center.dx + sparkleSize, center.dy),
      paint..strokeWidth = 2,
    );
  }
}
