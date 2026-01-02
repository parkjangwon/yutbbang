import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/game_state.dart';

class InteractiveThrowButton extends ConsumerWidget {
  const InteractiveThrowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final isGaugeMode = state.activeConfig.useGaugeControl;

    return Listener(
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                state.isGaugeRunning
                    ? Colors.orange.shade300
                    : Colors.orange.shade400,
                state.isGaugeRunning
                    ? Colors.orange.shade700
                    : Colors.orange.shade800,
              ],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: state.isGaugeRunning ? 30 : 15,
                spreadRadius: state.isGaugeRunning ? 8 : 0,
                color: Colors.orange.withOpacity(
                  state.isGaugeRunning ? 0.7 : 0.4,
                ),
                offset: Offset(0, state.isGaugeRunning ? 6 : 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(state.isGaugeRunning ? 0.9 : 0.4),
              width: state.isGaugeRunning ? 4 : 2,
            ),
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
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
