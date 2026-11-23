import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';

/// 지름길 선택 오버레이.
class ShortcutChoicePanel extends StatelessWidget {
  final GameState state;

  const ShortcutChoicePanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Customize labels based on current position
    String straightLabel = "직진";
    String shortcutLabel = "지름길";

    // Attempt to find where the selected mal is
    final mal = state.currentTeam.mals
        .where((m) => m.id == state.selectedMalId)
        .firstOrNull;
    if (mal != null) {
      if (mal.currentNodeId == 5) {
        straightLabel = "직진";
        shortcutLabel = "대각선";
      } else if (mal.currentNodeId == 10) {
        straightLabel = "직진";
        shortcutLabel = "대각선";
      } else if (mal.currentNodeId == 20) {
        straightLabel = "좌측 하단";
        shortcutLabel = "우측 하단";
      }
    }

    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: const [
            BoxShadow(
              blurRadius: 40,
              color: Colors.black38,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "경로 선택",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "어느 방향으로 이동할까요?",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ShortcutDecisionButton(
              label: shortcutLabel,
              value: true,
              color: Colors.blueAccent,
              icon: Icons.alt_route,
            ),
            const SizedBox(height: 12),
            ShortcutDecisionButton(
              label: straightLabel,
              value: false,
              color: Colors.green.shade600,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}

class ShortcutDecisionButton extends ConsumerWidget {
  final String label;
  final bool value;
  final Color color;
  final IconData icon;

  const ShortcutDecisionButton({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        onPressed: () => ref.read(gameProvider.notifier).chooseShortcut(value),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}
