import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/logic/board_graph.dart';

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
  }
}
