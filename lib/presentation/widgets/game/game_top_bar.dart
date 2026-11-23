import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/game_provider.dart';
import '../../providers/game_state.dart';
import '../../screens/yut_guide_screen.dart';
import 'game_status_text.dart';
import '../../theme/app_palette.dart';
import 'turn_indicator.dart';

/// 상단 정보 바 (AppBar처럼) - 현재 팀 색상 반영.
class GameTopBar extends StatelessWidget {
  final GameState state;

  const GameTopBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TurnIndicator(team: state.currentTeam),
              const SizedBox(height: 6),
              NakIndicator(state: state),
            ],
          ),
          // 상태 텍스트 (선택 또는 결과)
          Expanded(
            child: Container(
              height: 70, // Increased to give more vertical space
              alignment: Alignment.center,
              child: GameStatusText(state: state),
            ),
          ),
          const GameHelpButton(),
          const SizedBox(width: 8),
          const GameCloseButton(),
        ],
      ),
    );
  }
}

/// 게임 중 가이드 열기.
class GameHelpButton extends StatelessWidget {
  const GameHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _CircleIconButton(
      icon: Icons.help_outline,
      tooltip: '게임 방법',
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const YutGuideScreen())),
    );
  }
}

/// 게임 나가기. 진행 중인 판이 사라지므로 확인을 받는다.
class GameCloseButton extends ConsumerWidget {
  const GameCloseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CircleIconButton(
      icon: Icons.close,
      tooltip: '게임 나가기',
      onPressed: () async {
        final leave = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('게임을 나갈까요?'),
            content: const Text('진행 중인 판은 저장되지 않습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('계속하기'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('나가기'),
              ),
            ],
          ),
        );
        if (leave != true || !context.mounted) return;
        ref.read(gameProvider.notifier).exitGame();
        Navigator.of(context).maybePop();
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        shape: BoxShape.circle,
        boxShadow: AppPalette.cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppPalette.ink, size: 24),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
