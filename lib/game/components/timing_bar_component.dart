import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TimingBarComponent extends PositionComponent with HasGameRef {
  double _value = 0.5;
  double _direction = 1.0;
  final double _speed = 1.5;
  bool _isActive = false;

  late Sprite barSprite;
  late Sprite arrowSprite;

  @override
  Future<void> onLoad() async {
    barSprite = await gameRef.loadSprite('assets/images/ui/timing_bar.png');
    // Assuming the arrow is part of the same image or we'll just draw a triangle for now

    size = Vector2(300, 60);
    position = Vector2(gameRef.size.x / 2 - size.x / 2, gameRef.size.y - 150);
  }

  void start() => _isActive = true;
  void stop() => _isActive = false;

  double get value => _value;
  bool get isSafe => _value > 0.4 && _value < 0.6; // Central zone

  @override
  void update(double dt) {
    if (!_isActive) return;

    _value += _direction * _speed * dt;
    if (_value >= 1.0) {
      _value = 1.0;
      _direction = -1.0;
    } else if (_value <= 0.0) {
      _value = 0.0;
      _direction = 1.0;
    }
  }

  @override
  void render(Canvas canvas) {
    barSprite.render(canvas, size: size);

    // Draw indicator
    final indicatorX = _value * size.x;
    final paint = Paint()..color = Colors.yellow;
    canvas.drawRect(Rect.fromLTWH(indicatorX - 2, -10, 4, size.y + 20), paint);
  }
}
