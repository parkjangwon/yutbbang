import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../providers/game_state.dart';
import '../providers/game_view.dart';
import '../../game/yut_game.dart';
import '../widgets/throw_button.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/item_inventory.dart';
import '../widgets/game/forfeit_button.dart';
import '../widgets/game/game_dialog_host.dart';
import '../widgets/game/game_messages.dart';
import '../widgets/game/game_top_bar.dart';
import '../widgets/game/item_acquisition_popup.dart';
import '../widgets/game/shortcut_choice_panel.dart';
import '../widgets/game/victory_overlay.dart';
import '../widgets/game/waiting_mals_area.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late YutGame _game;

  @override
  void initState() {
    super.initState();
    _game = YutGame(ref);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);

    return GameDialogHost(
      child: Scaffold(
        backgroundColor: const Color(0xFFF3E5AB),
        body: SafeArea(
          child: Column(
            children: [
              // 1. 상단 정보 바 (AppBar처럼) - 현재 팀 색상 반영
              GameTopBar(state: state),

              // 2. 게임판 영역 (Expanded)
              Expanded(
                child: Stack(
                  children: [
                    // Flame 게임
                    GameWidget(game: _game),

                    // 지름길 선택 오버레이
                    if (state.showShortcutChoice)
                      ShortcutChoicePanel(state: state),

                    // 기권 버튼 (좌측 하단)
                    if (state.showForfeitButton)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: ForfeitButton(state: state),
                      ),

                    // 던지기 버튼 (우측 하단)
                    if (state.canHumanThrow)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: const InteractiveThrowButton(),
                      ),

                    // 게이지 UI (팡야 방식)
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

                    // 아이템 인벤토리
                    const ItemInventory(),

                    // 아이템 획득 팝업 (토스트 스타일)
                    if (state.justAcquiredItem != null)
                      ItemAcquisitionPopup(
                        type: state.justAcquiredItem!,
                        teamName: state.justAcquiredItemTeamName,
                      ),

                    // 승리 오버레이
                    if (state.status == GameStatus.finished)
                      VictoryOverlay(state: state),

                    // 아이템 시스템 메시지 (토스트)
                    if (state.itemMessage != null)
                      Positioned(
                        top: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GameToastMessage(message: state.itemMessage!),
                        ),
                      ),

                    // 보너스 알림 메시지 (말풍선 스타일)
                    if (state.bonusMessage != null)
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.35,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: BonusMessageOverlay(
                            message: state.bonusMessage!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 3. 하단 대기 말 영역
              WaitingMalsArea(state: state),
            ],
          ),
        ),
      ),
    );
  }
}
