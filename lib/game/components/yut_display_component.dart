import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/yut_result.dart';

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

class YutDisplayComponent extends PositionComponent with HasGameRef, HasPaint {
  List<StickConfig> _sticks = [];
  List<bool>? _lastProcessedStates;
  final Random _random = Random();
  bool _isAnimating = false;
  double _animationTime = 0.0;
  static const double throwDuration = 1.3;

  YutDisplayComponent() {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    _initIdleSticks();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_isAnimating) {
      _initIdleSticks();
    }
  }

  void _initIdleSticks() {
    final centerX = gameRef.size.x / 2;

    // Responsive positioning based on aspect ratio
    final aspectRatio = gameRef.size.x / gameRef.size.y;
    final centerY = aspectRatio > 0.7
        ? gameRef.size.y *
              0.72 // Wide screen: inside board, below center
        : gameRef.size.y * 0.82; // Narrow screen: outside board, at bottom

    _sticks = List.generate(4, (i) {
      final pos = Vector2(centerX + (i - 1.5) * 45, centerY);
      return StickConfig(
        position: pos.clone(),
        targetPosition: pos.clone(),
        angle: 0.0,
        velocity: Vector2.zero(),
        angularVelocity: 0.0,
        isFlat: false,
      );
    });
  }

  void updateSticks(List<bool> newStickStates, YutResult? result) {
    if (newStickStates.isEmpty) {
      _lastProcessedStates = null;
      _isAnimating = false;
      _initIdleSticks();
      return;
    }

    if (_lastProcessedStates == null) {
      _lastProcessedStates = newStickStates;
      _isAnimating = false;
      _syncInitialSticks(newStickStates);
      return;
    }

    if (_lastProcessedStates == newStickStates) return;
    _lastProcessedStates = newStickStates;

    _isAnimating = true;
    _animationTime = 0.0;

    final centerX = gameRef.size.x / 2;

    // Responsive positioning
    final aspectRatio = gameRef.size.x / gameRef.size.y;
    final startY = aspectRatio > 0.7
        ? gameRef.size.y * 0.72
        : gameRef.size.y * 0.82;
    final targetY = aspectRatio > 0.7
        ? gameRef.size.y * 0.45
        : gameRef.size.y * 0.45;

    // Use slots to guarantee NO OVERLAP
    List<int> slots = [0, 1, 2, 3]..shuffle(_random);

    // Nak special: one stick flies off-screen
    final isNak = result?.isFail ?? false;
    final nakStickIndex = isNak ? _random.nextInt(4) : -1;

    for (int i = 0; i < 4; i++) {
      _sticks[i].position = Vector2(centerX + (i - 1.5) * 45, startY);
      _sticks[i].angle = 0.0;
      _sticks[i].isFlat = newStickStates[i];

      if (i == nakStickIndex) {
        // This stick flies off-screen
        final offScreenX = _random.nextBool()
            ? -100.0 // Left side
            : gameRef.size.x + 100.0; // Right side
        final offScreenY = gameRef.size.y + 200.0; // Below screen

        _sticks[i].targetPosition = Vector2(offScreenX, offScreenY);
        _sticks[i].velocity = Vector2(
          (offScreenX - _sticks[i].position.x) / throwDuration,
          -600.0, // Lower arc
        );
        _sticks[i].angularVelocity =
            (_random.nextDouble() * 20 + 15) * (_random.nextBool() ? 1 : -1);
      } else {
        // Normal landing
        final slotX = centerX + (slots[i] - 1.5) * 65;
        _sticks[i].targetPosition = Vector2(
          slotX,
          targetY + (_random.nextDouble() - 0.5) * 60,
        );

        _sticks[i].velocity = Vector2(
          (_sticks[i].targetPosition.x - _sticks[i].position.x) / throwDuration,
          -800.0,
        );
        _sticks[i].angularVelocity =
            (_random.nextDouble() * 10 + 10) * (_random.nextBool() ? 1 : -1);
      }

      _sticks[i].targetAngle = _sticks[i].isFlat ? pi : 0.0;
    }
  }

  void _syncInitialSticks(List<bool> states) {
    final centerX = gameRef.size.x / 2;

    // Responsive positioning
    final aspectRatio = gameRef.size.x / gameRef.size.y;
    final centerY = aspectRatio > 0.7
        ? gameRef.size.y * 0.72
        : gameRef.size.y * 0.82;

    for (int i = 0; i < 4; i++) {
      _sticks[i].position = Vector2(centerX + (i - 1.5) * 45, centerY);
      _sticks[i].targetPosition = _sticks[i].position.clone();
      _sticks[i].isFlat = states[i];
      _sticks[i].angle = states[i] ? pi : 0.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isAnimating) return;

    _animationTime += dt;
    const double gravity = 1250.0;

    for (var s in _sticks) {
      if (_animationTime < throwDuration * 0.6) {
        // Initial arc phase
        s.position += s.velocity * dt;
        s.velocity.y += gravity * dt;
        s.angle += s.angularVelocity * dt;
      } else {
        // Alignment phase: Smoothly move to targetPosition and targetAngle
        double progress =
            (_animationTime - throwDuration * 0.6) / (throwDuration * 0.4);
        progress = Curves.easeOutCubic.transform(progress.clamp(0, 1));

        // Linear interpolation for position
        s.position = s.position + (s.targetPosition - s.position) * (dt * 15);

        // Angular alignment
        double currentRot = s.angle;
        double targetRot =
            (currentRot / (2 * pi)).round() * (2 * pi) + s.targetAngle;
        s.angle = currentRot + (targetRot - currentRot) * (dt * 10);
        s.angularVelocity *= 0.8;
      }
    }

    if (_animationTime >= throwDuration) {
      _isAnimating = false;
      for (var s in _sticks) {
        s.velocity = Vector2.zero();
        s.angularVelocity = 0;
        s.position = s.targetPosition.clone();
        s.angle = s.targetAngle;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    if (_sticks.isEmpty) return;

    const double stickWidth = 26.0;
    const double stickHeight = 115.0;

    for (int i = 0; i < 4; i++) {
      final s = _sticks[i];
      canvas.save();
      canvas.translate(s.position.x, s.position.y);
      canvas.rotate(s.angle);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: stickWidth,
        height: stickHeight,
      );
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(15));

      double shadowZ = _isAnimating
          ? (1.0 - (_animationTime / throwDuration)).clamp(0, 1) * 20
          : 3.0;
      canvas.drawRRect(
        rRect.shift(Offset(shadowZ, shadowZ * 1.5)),
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      double normalizedAngle = (s.angle.abs() / pi) % 2;
      bool showingFlat = (normalizedAngle > 0.5 && normalizedAngle < 1.5);

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
        // Flat side (belly): 3 horizontal lines
        final markPaint = Paint()
          ..color = Colors.brown.withOpacity(0.35)
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
        if (i == 0) {
          final xPaint = Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4;
          const double xSize = 9.0;
          final centerY = 0.0; // Center of the stick
          canvas.drawLine(
            Offset(-xSize, centerY - xSize),
            Offset(xSize, centerY + xSize),
            xPaint,
          );
          canvas.drawLine(
            Offset(xSize, centerY - xSize),
            Offset(-xSize, centerY + xSize),
            xPaint,
          );
        }
      } else {
        // Round side (back): 3 black X marks uniformly distributed
        final xPaint = Paint()
          ..color = Colors.black.withOpacity(0.6)
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
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = Colors.white12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.restore();
    }
  }
}
