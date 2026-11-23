import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/logic/board_graph.dart';
import '../board_layout.dart';
import '../yut_game.dart';
import '../../presentation/providers/game_provider.dart';
import '../../presentation/providers/game_view.dart';
import '../../presentation/theme/app_palette.dart';
import 'mal_renderer.dart';

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

    // 판 바탕: 흰 카드 + 부드러운 그림자 + 얇은 테두리
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.drawRRect(
      card.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0x224A3B30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawRRect(card, Paint()..color = AppPalette.boardSurface);
    canvas.drawRRect(
      card,
      Paint()
        ..color = AppPalette.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 연결선: 얇은 선
    final linePaint = Paint()
      ..color = AppPalette.boardLine
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
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

    // 칸: 흰 원(꼭짓점·중앙은 모래색 큰 원)
    for (final node in BoardGraph.nodes.values) {
      final pos = layout.nodeOffset(node.x, node.y);
      final radius = layout.nodeRadius(node.id);
      final isMajor = BoardLayout.isMajorNode(node.id);

      canvas.drawCircle(
        pos + const Offset(0, 1.5),
        radius,
        Paint()..color = const Color(0x144A3B30),
      );
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = isMajor ? AppPalette.majorNodeFill : AppPalette.nodeFill,
      );
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = isMajor ? AppPalette.majorNodeBorder : AppPalette.nodeBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 아이템 타일 표시 (황금색)
    _renderItemTiles(canvas, layout);
    _renderDestinationPreviews(canvas, layout);
  }

  /// 말을 고르기 전, 움직일 수 있는 말들이 도착할 칸을 팀 색 점선 고리로 표시한다.
  void _renderDestinationPreviews(Canvas canvas, BoardLayout layout) {
    if (game is! YutGame) return;
    final state = (game as YutGame).ref.read(gameProvider);
    final previews = state.destinationPreviews;
    if (previews.isEmpty) return;

    final color = MalRenderer.rawColor(state.currentTeam.color);
    final ring = Paint()
      ..color = AppPalette.highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (final preview in previews) {
      final pos = layout.nodeOffsetById(preview.nodeId);
      if (pos == null) continue;
      final radius = layout.nodeRadius(preview.nodeId) + 6;
      // 점선 고리(12조각)
      const segments = 12;
      for (int i = 0; i < segments; i += 2) {
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: radius),
          i * 2 * math.pi / segments,
          2 * math.pi / segments,
          false,
          ring,
        );
      }
      if (preview.finishes) {
        final label = TextPainter(
          text: TextSpan(
            text: '골인',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          pos - Offset(label.width / 2, radius + label.height + 2),
        );
      }
    }
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
          ..color = AppPalette.highlight.withValues(alpha: 0.35)
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
