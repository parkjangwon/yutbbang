import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../providers/game_state.dart';
import '../theme/app_palette.dart';

class InteractiveThrowButton extends ConsumerWidget {
  const InteractiveThrowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final isGaugeMode = state.activeConfig.useGaugeControl;

    return Semantics(
      button: true,
      label: isGaugeMode ? '윷 던지기 (누르고 있다가 떼기)' : '윷 던지기',
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) {
          if (isGaugeMode && state.status == GameStatus.throwing) {
            ref.read(gameProvider.notifier).startGauge();
            HapticFeedback.lightImpact();
          }
        },
        onPointerUp: (_) {
          if (isGaugeMode && state.isGaugeRunning) {
            ref.read(gameProvider.notifier).stopGauge();
            HapticFeedback.mediumImpact();
          }
        },
        child: GestureDetector(
          onTap: () {
            if (!isGaugeMode && state.status == GameStatus.throwing) {
              ref.read(gameProvider.notifier).throwYut();
              HapticFeedback.lightImpact();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: state.isGaugeRunning ? 85 : 75,
            height: state.isGaugeRunning ? 85 : 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.throwButton,
              boxShadow: [
                BoxShadow(
                  color: AppPalette.throwButton.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isGaugeRunning ? Icons.bolt : Icons.casino,
                    color: Colors.white,
                    size: state.isGaugeRunning ? 40 : 30,
                  ),
                  Text(
                    isGaugeMode ? '누르고 있기' : '던지기',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
