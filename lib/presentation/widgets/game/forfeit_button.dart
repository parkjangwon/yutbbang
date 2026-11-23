import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';
import '../../theme/app_palette.dart';

/// 기권 버튼 (좌측 하단) + 확인 다이얼로그.
class ForfeitButton extends ConsumerWidget {
  final GameState state;

  const ForfeitButton({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGameActive = state.status != GameStatus.finished;

    return Semantics(
      button: true,
      label: '기권',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isGameActive ? () => _showForfeitDialog(context, ref) : null,
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.danger,
            boxShadow: [
              BoxShadow(
                color: AppPalette.danger.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag, color: Colors.white, size: 30),
                Text(
                  '기권',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
    );
  }

  void _showForfeitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기권 확인'),
        content: Text(
          '${state.currentTeam.name} 팀이 기권하시겠습니까?\n모든 말이 판에서 사라지고 게임에서 제외됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).forfeit(state.currentTeamIndex);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('기권'),
          ),
        ],
      ),
    );
  }
}
