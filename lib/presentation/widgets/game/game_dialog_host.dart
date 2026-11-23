import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/game_provider.dart';
import '../item_choice_dialog.dart';
import '../moonwalk_direction_dialog.dart';
import '../reroll_choice_dialog.dart';

/// 게임 상태가 선택을 요구하는 순간(false → true)에 한 번만 다이얼로그를 띄운다.
///
/// build 안에서 띄우면 다이얼로그가 떠 있는 동안 상태가 바뀔 때마다 겹겹이 쌓이므로,
/// 상태 변화를 구독해서 처리한다.
class GameDialogHost extends ConsumerWidget {
  final Widget child;

  const GameDialogHost({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onRaised(bool? previous, bool next, Widget Function() dialog) {
      if (next && previous != true) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => dialog(),
        );
      }
    }

    ref.listen(
      gameProvider.select((s) => s.showRerollChoice),
      (prev, next) => onRaised(prev, next, () => const RerollChoiceDialog()),
    );
    ref.listen(
      gameProvider.select(
        (s) => s.showItemChoice && s.pendingItemNodeId != null,
      ),
      (prev, next) => onRaised(
        prev,
        next,
        () =>
            ItemChoiceDialog(nodeId: ref.read(gameProvider).pendingItemNodeId!),
      ),
    );
    ref.listen(
      gameProvider.select(
        (s) => s.showMoonwalkChoice && s.selectedMalId != null,
      ),
      (prev, next) => onRaised(
        prev,
        next,
        () => MoonwalkDirectionDialog(
          malId: ref.read(gameProvider).selectedMalId!,
        ),
      ),
    );

    return child;
  }
}
