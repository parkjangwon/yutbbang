import 'package:material_ui/material_ui.dart';

import '../../providers/game_state.dart';
import '../../providers/game_view.dart';
import '../../../domain/models/team.dart';
import '../../theme/app_palette.dart';
import 'team_colors.dart';

/// 현재 차례 팀 표시 (팀 색상 pill).
class TurnIndicator extends StatelessWidget {
  final Team team;

  const TurnIndicator({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final color = teamColorOf(team.color);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            team.isHuman ? Icons.person : Icons.memory,
            color: Colors.white,
            size: 20,
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.white.withValues(alpha: 0.5),
          ),
          Text(
            team.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
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
        color: AppPalette.sageSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nakLabel,
        style: const TextStyle(
          color: AppPalette.ink,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
