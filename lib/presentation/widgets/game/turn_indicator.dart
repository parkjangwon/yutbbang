import 'package:material_ui/material_ui.dart';

import '../../providers/game_state.dart';
import '../../providers/game_view.dart';
import '../../../domain/models/team.dart';
import 'team_colors.dart';

/// 현재 차례 팀 표시 (팀 색상 pill).
class TurnIndicator extends StatelessWidget {
  final Team team;

  const TurnIndicator({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = team.isHuman;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: teamColorOf(team.color),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                blurRadius: isMyTurn ? 15 * value : 10,
                color: isMyTurn
                    ? teamColorOf(team.color).withValues(alpha: 0.6 * value)
                    : Colors.black26,
                offset: const Offset(0, 4),
                spreadRadius: isMyTurn ? 2 * value : 0,
              ),
            ],
            border: isMyTurn ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: child,
        );
      },
      onEnd: () {}, // Repeat logic could be added here if needed, but build will re-trigger
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            team.isHuman ? Icons.person : Icons.memory,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            team.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              team.controllerId == 0 ? 'CPU' : 'P${team.controllerId}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 낙 난이도/확률 표시.
class NakIndicator extends StatelessWidget {
  final GameState state;

  const NakIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final nakLabel = state.nakBadgeLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nakLabel,
        style: const TextStyle(
          color: Colors.brown,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
