import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/team.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';
import '../../providers/game_view.dart';
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
      height: horizontal ? 96 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withValues(alpha: 0.05),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: canTap ? 0.5 : 0.3),
            borderRadius: BorderRadius.circular(8),
            border: canTap ? Border.all(color: color, width: 2) : null,
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
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'x${waiting.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '골인 ${team.finishedCount}/${team.mals.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

/// 입체감 있는 대기 말 아이콘.
class WaitingMalToken extends StatelessWidget {
  final TeamColor color;
  final String label;

  const WaitingMalToken({super.key, required this.color, this.label = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 그림자 레이어
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: darkerTeamColorOf(color),
            ),
          ),
          // 메인 레이어
          Container(
            width: 44,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  teamColorOf(color).withValues(alpha: 0.9),
                  teamColorOf(color),
                ],
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          // 하이라이트
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
