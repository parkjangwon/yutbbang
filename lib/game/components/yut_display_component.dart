import 'dart:math';

import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../domain/models/yut_result.dart';
import '../../presentation/theme/app_assets.dart';
import '../yut_stick_layout.dart';
import 'yut_stick_painter.dart';

class YutDisplayComponent extends PositionComponent
    with HasGameReference, HasPaint {
  List<StickConfig> _sticks = [];
  List<bool>? _lastProcessedStates;
  final Random _random = Random();
  bool _isAnimating = false;
  double _animationTime = 0.0;
  static const double throwDuration = 1.3;

  YutDisplayComponent() {
    anchor = Anchor.center;
  }

  YutStickSprites? _sprites;

  @override
  Future<void> onLoad() async {
    _initIdleSticks();
    try {
      final images = await Future.wait([
        game.images.load(AppAssets.yutFlat),
        game.images.load(AppAssets.yutFlatBackDo),
        game.images.load(AppAssets.yutRound),
      ]);
      _sprites = YutStickSprites(
        flat: images[0],
        flatBackDo: images[1],
        round: images[2],
      );
    } catch (_) {
      // 이미지를 못 불러오면 캔버스로 그린 윷가락을 쓴다.
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_isAnimating) {
      _initIdleSticks();
    }
  }

  /// 윷가락이 쉬는 자리(판을 가리지 않는 곳).
  List<Vector2> get _restPositions =>
      YutStickLayout(game.size.toSize()).restPositions
          .map((o) => Vector2(o.dx, o.dy))
          .toList();

  void _initIdleSticks() {
    final rest = _restPositions;
    _sticks = List.generate(4, (i) {
      final pos = rest[i];
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

    // Haptic feedback: Throw start
    HapticFeedback.heavyImpact();

    // 쉬는 자리에서 던져 올려, 다시 쉬는 자리(판 밖)에 내려앉는다.
    final rest = _restPositions;

    // Use slots to guarantee NO OVERLAP
    List<int> slots = [0, 1, 2, 3]..shuffle(_random);

    // Nak special: one stick flies off-screen
    final isNak = result?.isFail ?? false;
    final nakStickIndex = isNak ? _random.nextInt(4) : -1;

    for (int i = 0; i < 4; i++) {
      _sticks[i].position = rest[i].clone();
      _sticks[i].angle = 0.0;
      _sticks[i].isFlat = newStickStates[i];

      if (i == nakStickIndex) {
        // This stick flies off-screen
        final offScreenX = _random.nextBool()
            ? -100.0 // Left side
            : game.size.x + 100.0; // Right side
        final offScreenY = game.size.y + 200.0; // Below screen

        _sticks[i].targetPosition = Vector2(offScreenX, offScreenY);
        _sticks[i].velocity = Vector2(
          (offScreenX - _sticks[i].position.x) / throwDuration,
          -600.0, // Lower arc
        );
        _sticks[i].angularVelocity =
            (_random.nextDouble() * 20 + 15) * (_random.nextBool() ? 1 : -1);
      } else {
        // Normal landing
        final slot = rest[slots[i]];
        _sticks[i].targetPosition = Vector2(
          slot.x,
          slot.y + (_random.nextDouble() - 0.5) * 8,
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
    final rest = _restPositions;
    for (int i = 0; i < 4; i++) {
      _sticks[i].position = rest[i].clone();
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

      // Haptic feedback: Landing
      HapticFeedback.heavyImpact();

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

    final shadowZ = _isAnimating
        ? (1.0 - (_animationTime / throwDuration)).clamp(0, 1) * 20
        : 3.0;
    for (int i = 0; i < 4; i++) {
      YutStickPainter.paint(
        canvas,
        _sticks[i],
        shadowZ: shadowZ.toDouble(),
        hasBackDoMark: i == 0,
        sprites: _sprites,
      );
    }
  }
}
