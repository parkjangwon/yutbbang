import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/yut_game.dart';
import '../providers/game_provider.dart';
import '../providers/game_state.dart';
import '../providers/game_view.dart';
import '../widgets/game/action_log_view.dart';
import '../widgets/game/forfeit_button.dart';
import '../widgets/game/game_dialog_host.dart';
import '../widgets/game/game_messages.dart';
import '../widgets/game/game_top_bar.dart';
import '../widgets/game/item_acquisition_popup.dart';
import '../widgets/game/shortcut_choice_panel.dart';
import '../widgets/game/victory_overlay.dart';
import '../widgets/game/waiting_mals_area.dart';
import '../widgets/app_background.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/item_inventory.dart';
import '../widgets/throw_button.dart';

/// 게임 화면.
///
/// 세로: 상단 바 / 게임판 / 하단 대기 패널.
/// 가로: 상단 바 / [게임판 | 오른쪽 대기 패널] — 판이 세로 공간을 최대한 쓰도록.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final YutGame _game = YutGame(ref);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final board = KeyedSubtree(
      key: const Key('game-board-area'),
      child: _BoardArea(game: _game, state: state, landscape: landscape),
    );

    return GameDialogHost(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                GameTopBar(state: state),
                Expanded(
                  child: landscape
                      ? Row(
                          children: [
                            Expanded(child: board),
                            SizedBox(
                              width: 216,
                              child: WaitingMalsArea(
                                state: state,
                                direction: Axis.vertical,
                              ),
                            ),
                          ],
                        )
                      : board,
                ),
                if (!landscape) WaitingMalsArea(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardArea extends StatelessWidget {
  final YutGame game;
  final GameState state;
  final bool landscape;

  const _BoardArea({
    required this.game,
    required this.state,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 게임판은 캔버스라 스크린리더용 요약을 따로 붙인다.
        Semantics(
          label: state.boardSummary.join('\n'),
          child: GameWidget(game: game),
        ),

        Positioned(
          top: 8,
          left: 12,
          right: landscape ? null : 12,
          child: ActionLogView(state: state),
        ),

        if (state.showShortcutChoice) ShortcutChoicePanel(state: state),

        if (state.showForfeitButton)
          Positioned(bottom: 20, left: 20, child: ForfeitButton(state: state)),

        if (state.canHumanThrow)
          const Positioned(
            bottom: 20,
            right: 20,
            child: InteractiveThrowButton(),
          ),

        if (state.isGaugeRunning)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: YutGaugeWidget(
                value: state.gaugeValue,
                nakZones: state.nakZones,
              ),
            ),
          ),

        const ItemInventory(),

        if (state.justAcquiredItem != null)
          ItemAcquisitionPopup(
            type: state.justAcquiredItem!,
            teamName: state.justAcquiredItemTeamName,
          ),

        if (state.status == GameStatus.finished)
          Positioned.fill(child: VictoryOverlay(state: state)),

        if (state.itemMessage != null)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(child: GameToastMessage(message: state.itemMessage!)),
          ),

        if (state.bonusMessage != null)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: BonusMessageOverlay(message: state.bonusMessage!),
            ),
          ),
      ],
    );
  }
}
