import 'package:material_ui/material_ui.dart';

import '../../providers/game_state.dart';
import 'game_status_text.dart';
import 'team_colors.dart';
import 'turn_indicator.dart';

/// 상단 정보 바 (AppBar처럼) - 현재 팀 색상 반영.
class GameTopBar extends StatelessWidget {
  final GameState state;

  const GameTopBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: teamColorOf(state.currentTeam.color).withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: teamColorOf(state.currentTeam.color).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TurnIndicator(team: state.currentTeam),
              const SizedBox(height: 6),
              NakIndicator(config: state.activeConfig),
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
          const GameCloseButton(),
        ],
      ),
    );
  }
}

class GameCloseButton extends StatelessWidget {
  const GameCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.brown, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
