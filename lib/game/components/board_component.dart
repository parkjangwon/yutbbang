import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/logic/board_graph.dart';
import '../board_layout.dart';
import '../yut_game.dart';
import '../../presentation/providers/game_provider.dart';

class BoardComponent extends PositionComponent with HasGameReference {
  BoardLayout get layout => BoardLayout(game.size.toSize());

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
    final current = layout;
    size = Vector2.all(current.boardSide);
    position = current.boardOrigin.toVector2();
  }

  @override
  void render(Canvas canvas) {
    final layout = this.layout;
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
      final start = layout.nodeOffset(node.x, node.y);
      void drawTo(int? targetId) {
        if (targetId == null) return;
        final nextNode = BoardGraph.nodes[targetId];
        if (nextNode != null) {
          final end = layout.nodeOffset(nextNode.x, nextNode.y);
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
      final pos = layout.nodeOffset(node.x, node.y);
      final radius = layout.nodeRadius(node.id);
      final isMajor = BoardLayout.isMajorNode(node.id);

      canvas.drawCircle(pos, radius, isMajor ? specialPaint : nodePaint);
      canvas.drawCircle(pos, radius, nodeBorderPaint);
    }

    // 아이템 타일 표시 (황금색)
    _renderItemTiles(canvas, layout);
  }

  void _renderItemTiles(Canvas canvas, BoardLayout layout) {
    // YutGame에서 게임 상태 가져오기
    if (game is! YutGame) return;

    try {
      final yutGame = game as YutGame;
      final gameState = yutGame.ref.read(gameProvider);

      if (!gameState.activeConfig.useItemMode) return;

      // 아이템 타일 렌더링
      for (final nodeId in gameState.itemTiles) {
        final pos = layout.nodeOffsetById(nodeId);
        if (pos == null) continue;
        final radius = layout.nodeRadius(nodeId);

        // 황금색 외곽 글로우
        final glowPaint = Paint()
          ..color = Colors.amber.withValues(alpha: 0.5)
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
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

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
