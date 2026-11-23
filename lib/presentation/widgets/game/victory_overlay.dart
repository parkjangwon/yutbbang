import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';
import '../../theme/app_palette.dart';
import 'team_colors.dart';

/// 승리 오버레이.
class VictoryOverlay extends ConsumerWidget {
  final GameState state;

  const VictoryOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final winner =
        state.teams.where((t) => t.isWinner).firstOrNull ?? state.teams.first;
    final winnerColor = teamColorOf(winner.color);
    return Container(
      color: AppPalette.ink.withValues(alpha: 0.55),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppPalette.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: softTeamColorOf(winner.color),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emoji_events, color: winnerColor, size: 72),
                ),
                const SizedBox(height: 20),
                Text(
                  '${winner.name} 우승!',
                  style: TextStyle(
                    color: winnerColor,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 18,
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
                    style: TextStyle(color: AppPalette.inkMuted, fontSize: 16),
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
