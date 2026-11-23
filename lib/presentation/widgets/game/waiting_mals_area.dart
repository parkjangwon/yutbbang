import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/team.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';
import 'team_colors.dart';

/// 하단 대기 말 영역 (팀별 패널).
class WaitingMalsArea extends ConsumerWidget {
  final GameState state;

  const WaitingMalsArea({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: state.teams.map((team) {
          // 기권한 팀 처리
          if (team.hasForfeit) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: teamColorOf(team.color).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '기권',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: teamColorOf(team.color),
                  ),
                ),
              ),
            );
          }

          final waitingMals = team.mals
              .where((m) => m.currentNodeId == null && !m.isFinished)
              .toList();
          if (waitingMals.isEmpty) return const SizedBox.shrink();

          final isSelectable =
              state.status == GameStatus.selectingMal &&
              team.color == state.currentTeam.color;

          return GestureDetector(
            onTap: () {
              // 선택 가능한 상태일 때만 첫 번째 대기 말 선택
              if (isSelectable) {
                ref.read(gameProvider.notifier).selectMal(waitingMals.first.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: teamColorOf(team.color)
                    .withValues(alpha: isSelectable ? 0.5 : 0.3),
                borderRadius: BorderRadius.circular(8),
                border: isSelectable
                    ? Border.all(color: teamColorOf(team.color), width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  WaitingMalToken(color: team.color),
                  const SizedBox(width: 8),
                  Text(
                    'x${waitingMals.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 입체감 있는 대기 말 아이콘.
class WaitingMalToken extends StatelessWidget {
  final TeamColor color;

  const WaitingMalToken({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: darkerTeamColorOf(color),
            ),
          ),
          // 메인 레이어
          Container(
            width: 50,
            height: 48,
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
          // 하이라이트
          Container(
            width: 42,
            height: 42,
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
