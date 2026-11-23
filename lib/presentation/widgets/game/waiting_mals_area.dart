import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/team.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';
import '../../providers/game_view.dart';
import '../../theme/app_palette.dart';
import 'team_colors.dart';

/// 팀별 대기 말·골인 현황 패널. 세로 화면은 하단 가로줄, 가로 화면은 오른쪽 세로줄.
class WaitingMalsArea extends ConsumerWidget {
  final GameState state;
  final Axis direction;

  const WaitingMalsArea({
    super.key,
    required this.state,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontal = direction == Axis.horizontal;
    return Container(
      width: horizontal ? double.infinity : null,
      height: horizontal ? 104 : double.infinity,
      margin: horizontal
          ? const EdgeInsets.fromLTRB(12, 0, 12, 12)
          : const EdgeInsets.fromLTRB(0, 8, 12, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppPalette.cardShadow,
      ),
      child: Flex(
        direction: direction,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final team in state.teams)
            _TeamPanel(
              team: team,
              selectable: state.canSelectWaitingMals(team),
              onSelect: (malId) =>
                  ref.read(gameProvider.notifier).selectMal(malId),
            ),
        ],
      ),
    );
  }
}

class _TeamPanel extends StatelessWidget {
  final Team team;
  final bool selectable;
  final ValueChanged<int> onSelect;

  const _TeamPanel({
    required this.team,
    required this.selectable,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final color = teamColorOf(team.color);
    final waiting = team.mals.where((m) => m.isWaiting).toList();
    final canTap = selectable && waiting.isNotEmpty;

    if (team.hasForfeit) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '기권',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }

    return Semantics(
      button: canTap,
      label:
          '${team.name} 대기 ${waiting.length}개, 골인 ${team.finishedCount}개'
          '${canTap ? ', 눌러서 대기 말 출발' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: canTap ? () => onSelect(waiting.first.id) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: softTeamColorOf(team.color),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canTap ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: waiting.isEmpty ? 0.35 : 1,
                child: WaitingMalToken(
                  color: team.color,
                  label: team.color.letter,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: color.withValues(alpha: 0.3),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'x${waiting.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.ink,
                    ),
                  ),
                  Text(
                    '골인 ${team.finishedCount}/${team.mals.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 대기 말 아이콘(무광 원판 + 팀 글자).
class WaitingMalToken extends StatelessWidget {
  final TeamColor color;
  final String label;

  const WaitingMalToken({super.key, required this.color, this.label = ''});

  @override
  Widget build(BuildContext context) {
    final base = teamColorOf(color);
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color.lerp(base, Colors.white, 0.18)!, base],
        ),
        boxShadow: [
          BoxShadow(
            color: darkerTeamColorOf(color).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}
