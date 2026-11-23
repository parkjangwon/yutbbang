import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';

/// 승리 오버레이.
class VictoryOverlay extends ConsumerWidget {
  final GameState state;

  const VictoryOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final winner =
        state.teams.where((t) => t.isWinner).firstOrNull ?? state.teams.first;
    return Container(
      color: Colors.black87,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 120),
              const SizedBox(height: 20),
              Text(
                '${winner.name} 우승!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () =>
                    notifier.startGameWithConfig(state.activeConfig),
                child: const Text(
                  '한 판 더',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  notifier.exitGame();
                  Navigator.of(context).maybePop();
                },
                child: const Text(
                  '시작 화면으로',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
