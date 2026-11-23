import 'package:material_ui/material_ui.dart';

import '../../providers/game_state.dart';
import '../../theme/app_palette.dart';

/// 최근 행동 기록(최대 3줄). CPU가 무엇을 했는지 따라갈 수 있게 한다.
class ActionLogView extends StatelessWidget {
  static const int visibleLines = 3;

  final GameState state;

  const ActionLogView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final log = state.actionLog;
    if (log.isEmpty) return const SizedBox.shrink();
    final lines = log.sublist(
      log.length > visibleLines ? log.length - visibleLines : 0,
    );

    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppPalette.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppPalette.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, line) in lines.indexed)
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: i == lines.length - 1
                        ? AppPalette.ink
                        : AppPalette.inkMuted,
                    fontWeight: i == lines.length - 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
