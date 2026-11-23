import 'package:material_ui/material_ui.dart';

import '../../theme/app_palette.dart';

/// 아이템 시스템 메시지 (토스트).
class GameToastMessage extends StatelessWidget {
  final String message;

  const GameToastMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * -20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppPalette.ink.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppPalette.cardShadow,
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 보너스 알림 메시지 (말풍선 스타일).
class BonusMessageOverlay extends StatelessWidget {
  final String message;

  const BonusMessageOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppPalette.cardShadow,
                border: Border.all(color: AppPalette.terracottaSoft, width: 2),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: AppPalette.terracotta,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
