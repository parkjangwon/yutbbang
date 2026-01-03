import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/team.dart';
import '../../domain/models/yut_result.dart';
import '../providers/game_provider.dart';
import '../providers/game_state.dart';
import '../../game/yut_game.dart';
import '../widgets/throw_button.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/item_inventory.dart';
import '../widgets/item_choice_dialog.dart';
import '../widgets/moonwalk_direction_dialog.dart';
import '../widgets/reroll_choice_dialog.dart';
import '../../domain/models/game_item.dart';

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

    // 아이템 선택 다이얼로그 표시
    if (state.showItemChoice && state.pendingItemNodeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              ItemChoiceDialog(nodeId: state.pendingItemNodeId!),
        );
      });
    }

    // 뒷걸음질 방향 선택 다이얼로그 표시 (자동 발동)
    if (state.showMoonwalkChoice && state.selectedMalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              MoonwalkDirectionDialog(malId: state.selectedMalId!),
        );
      });
    }

    // 다시 던지기 선택 다이얼로그 표시 (자동 발동)
    if (state.showRerollChoice == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const RerollChoiceDialog(),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5AB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 정보 바 (AppBar처럼) - 현재 팀 색상 반영
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getTeamColor(state.currentTeam.color).withOpacity(0.15),
                border: Border(
                  bottom: BorderSide(
                    color: _getTeamColor(
                      state.currentTeam.color,
                    ).withOpacity(0.3),
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
                      _buildTurnIndicator(state),
                      const SizedBox(height: 6),
                      _buildNakIndicator(state),
                    ],
                  ),
                  // 상태 텍스트 (선택 또는 결과)
                  Expanded(
                    child: Container(
                      height: 70, // Increased to give more vertical space
                      alignment: Alignment.center,
                      child: _buildStatusText(state),
                    ),
                  ),
                  _buildCloseButton(),
                ],
              ),
            ),

            // 2. 게임판 영역 (Expanded)
            Expanded(
              child: Stack(
                children: [
                  // Flame 게임
                  GameWidget(game: _game),

                  // 지름길 선택 오버레이
                  if (state.status == GameStatus.awaitingShortcutDecision &&
                      state.currentTeam.isHuman)
                    _buildShortcutChoiceUI(state),

                  // 기권 버튼 (좌측 하단)
                  if (state.currentTeam.isHuman &&
                      state.status != GameStatus.finished)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: _buildForfeitButton(state),
                    ),

                  // 던지기 버튼 (우측 하단)
                  if (state.currentTeam.isHuman &&
                      state.status == GameStatus.throwing)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: _buildThrowButton(),
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
                    _buildAcquisitionPopup(state.justAcquiredItem!),

                  // 승리 오버레이
                  if (state.status == GameStatus.finished)
                    _buildVictoryOverlay(state),

                  // 아이템 시스템 메시지 (토스트)
                  if (state.itemMessage != null)
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildToastMessage(state.itemMessage!),
                      ),
                    ),

                  // 보너스 알림 메시지 (말풍선 스타일)
                  if (state.bonusMessage != null)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.35,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildBonusMessageOverlay(state.bonusMessage!),
                      ),
                    ),
                ],
              ),
            ),

            // 3. 하단 대기 말 영역
            _buildWaitingMalsArea(state),
          ],
        ),
      ),
    );
  }

  Widget _buildToastMessage(String message) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * -20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusMessageOverlay(String message) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orangeAccent, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTurnIndicator(GameState state) {
    final team = state.currentTeam;
    final isMyTurn = team.isHuman;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _getTeamColor(team.color),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                blurRadius: isMyTurn ? 15 * value : 10,
                color: isMyTurn
                    ? _getTeamColor(team.color).withOpacity(0.6 * value)
                    : Colors.black26,
                offset: const Offset(0, 4),
                spreadRadius: isMyTurn ? 2 * value : 0,
              ),
            ],
            border: isMyTurn ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: child,
        );
      },
      onEnd:
          () {}, // Repeat logic could be added here if needed, but build will re-trigger
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            team.isHuman ? Icons.person : Icons.memory,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            team.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              team.controllerId == 0 ? 'CPU' : 'P${team.controllerId}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNakIndicator(GameState state) {
    String nakLabel;
    final nakChance = state.activeConfig.nakChancePercent;

    if (state.activeConfig.useGaugeControl) {
      if (nakChance >= 25) {
        nakLabel = '낙 : 어려움';
      } else if (nakChance >= 15) {
        nakLabel = '낙 : 보통';
      } else {
        nakLabel = '낙 : 쉬움';
      }
    } else {
      nakLabel = '낙 $nakChance%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nakLabel,
        style: const TextStyle(
          color: Colors.brown,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildForfeitButton(GameState state) {
    final isGameActive = state.status != GameStatus.finished;

    return GestureDetector(
      onTap: isGameActive ? () => _showForfeitDialog(state) : null,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isGameActive
                ? [Colors.red.shade400, Colors.red.shade800]
                : [Colors.grey.shade400, Colors.grey.shade600],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              spreadRadius: 0,
              color: isGameActive
                  ? Colors.red.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3),
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag, color: Colors.white, size: 30),
              const Text(
                '기권',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForfeitDialog(GameState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기권 확인'),
        content: Text(
          '${state.currentTeam.name} 팀이 기권하시겠습니까?\n모든 말이 완주 처리되어 게임에서 제외됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final teamIndex = state.turnIndex % state.teams.length;
              ref.read(gameProvider.notifier).forfeit(teamIndex);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('기권'),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
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

  Widget _buildStatusText(GameState state) {
    final showResult =
        state.lastResult != null && state.status != GameStatus.moving;
    final showGuide =
        state.status == GameStatus.selectingMal ||
        state.status == GameStatus.awaitingShortcutDecision;

    if (!showResult && !showGuide) return const SizedBox.shrink();

    String? resultText;
    String? guideText;

    if (showResult) {
      final resultLabels = state.currentThrows.map((e) => e.label).toList();
      if (state.lastResult != null &&
          !state.currentThrows.contains(state.lastResult)) {
        resultLabels.add(state.lastResult!.label);
      }
      resultText = '결과: ${resultLabels.join(', ')}';
    }

    if (showGuide) {
      guideText = state.status == GameStatus.awaitingShortcutDecision
          ? '지름길을 선택하세요'
          : '움직일 말을 선택하세요';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First line: Result (or empty space)
        SizedBox(
          height: 24, // Increased height
          child: resultText != null
              ? Text(
                  resultText,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.5,
                    height: 1.2, // Improved line height
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
        // Spacing between lines (only if both exist)
        if (resultText != null && guideText != null) const SizedBox(height: 6),
        // Second line: Guide (or empty space)
        SizedBox(
          height: 22, // Increased height
          child: guideText != null
              ? Text(
                  guideText,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.3,
                    height: 1.2, // Improved line height
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildWaitingMalsArea(GameState state) {
    // 하단 대기 말 영역
    return Container(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: state.teams.map((team) {
          // 기권한 팀 처리
          if (team.hasForfeit) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTeamColor(team.color).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '기권',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getTeamColor(team.color),
                  ),
                ),
              ),
            );
          }

          final waitingMals = team.mals
              .where((m) => m.currentNodeId == null && !m.isFinished)
              .toList();
          if (waitingMals.isEmpty) return const SizedBox.shrink();

          return GestureDetector(
            onTap: () {
              // 선택 가능한 상태일 때만 첫 번째 대기 말 선택
              if (state.status == GameStatus.selectingMal &&
                  team.color == state.currentTeam.color) {
                ref.read(gameProvider.notifier).selectMal(waitingMals.first.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTeamColor(team.color).withOpacity(
                  state.status == GameStatus.selectingMal &&
                          team.color == state.currentTeam.color
                      ? 0.5
                      : 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border:
                    state.status == GameStatus.selectingMal &&
                        team.color == state.currentTeam.color
                    ? Border.all(color: _getTeamColor(team.color), width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  // 입체감 있는 말 디자인
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
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
                            color: _getDarkerTeamColor(team.color),
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
                                _getTeamColor(team.color).withOpacity(0.9),
                                _getTeamColor(team.color),
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
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildSelectionMessage() {
    final state = ref.watch(gameProvider);
    String message = '';

    if (state.status == GameStatus.selectingMal) {
      message = '움직일 말을 선택하세요';
    } else if (state.status == GameStatus.awaitingShortcutDecision) {
      message = '지름길로 가시겠습니까?';
    } else if (state.status == GameStatus.awaitingBanishTarget) {
      message = '집으로 보낼 상대방 말을 선택하세요 🏠';
    } else if (state.status == GameStatus.awaitingSwapSource) {
      message = '위치를 바꿀 내 말을 선택하세요 ↔️';
    } else if (state.status == GameStatus.awaitingSwapTarget) {
      message = '교환할 상대방 말을 선택하세요 ↔️';
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.status.name.contains('awaiting')
                  ? Colors.amber
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayManager(GameState state) {
    // Priority 1: Shortcut Selection (Interactive)
    if (state.status == GameStatus.awaitingShortcutDecision &&
        state.currentTeam.isHuman) {
      return _buildShortcutChoiceUI(state);
    }

    // Priority 2: Result Display
    if (state.lastResult != null && state.status != GameStatus.moving) {
      return _buildResultUI(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultUI(GameState state) {
    // Collect all unique labels to show sequence
    final List<String> resultLabels = state.currentThrows
        .map((e) => e.label)
        .toList();
    if (state.lastResult != null &&
        !state.currentThrows.contains(state.lastResult)) {
      // If lastResult is not yet in currentThrows (during animation delay)
      resultLabels.add(state.lastResult!.label);
    } else if (resultLabels.isEmpty && state.lastResult != null) {
      resultLabels.add(state.lastResult!.label);
    }

    // Fallback: if somehow empty but we reached here
    if (resultLabels.isEmpty && state.lastResult != null) {
      resultLabels.add(state.lastResult!.label);
    }

    final displayText = resultLabels.join(", ");

    // 간단한 한 줄 텍스트
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade700.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.lastResult?.isBonusTurn == true)
                const SizedBox(width: 8),
              if (state.lastResult?.isBonusTurn == true)
                const Icon(Icons.star, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutChoiceUI(GameState state) {
    // Customize labels based on current position
    String straightLabel = "직진";
    String shortcutLabel = "지름길";

    // Attempt to find where the selected mal is
    final mal = state.currentTeam.mals
        .where((m) => m.id == state.selectedMalId)
        .firstOrNull;
    if (mal != null) {
      if (mal.currentNodeId == 5) {
        straightLabel = "직진";
        shortcutLabel = "대각선";
      } else if (mal.currentNodeId == 10) {
        straightLabel = "직진";
        shortcutLabel = "대각선";
      } else if (mal.currentNodeId == 20) {
        straightLabel = "좌측 하단";
        shortcutLabel = "우측 하단";
      }
    }

    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: const [
            BoxShadow(
              blurRadius: 40,
              color: Colors.black38,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "경로 선택",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "어느 방향으로 이동할까요?",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 30),
            _buildDecisionButton(
              shortcutLabel,
              true,
              Colors.blueAccent,
              Icons.alt_route,
            ),
            const SizedBox(height: 12),
            _buildDecisionButton(
              straightLabel,
              false,
              Colors.green.shade600,
              Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionButton(
    String label,
    bool value,
    Color color,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        onPressed: () => ref.read(gameProvider.notifier).chooseShortcut(value),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildThrowButton() {
    return const InteractiveThrowButton();
  }

  Widget _buildVictoryOverlay(GameState state) {
    final winner =
        state.teams.where((t) => t.isWinner).firstOrNull ?? state.teams.first;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 120),
            const SizedBox(height: 20),
            Text(
              '${winner.name} 우승!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "시작 화면으로",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonGlow(GameState state) {
    final teamColor = _getTeamColor(state.currentTeam.color);

    return LayoutBuilder(
      builder: (context, constraints) {
        // BoardComponent.dart의 _updateLayout 로직과 동일하게 크기 계산 (화면 중앙 배치)
        final minDim = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final boardDimension = minDim * 0.85;

        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              final pulse = (0.5 - (value - 0.5).abs() * 2);
              final opacity = 0.4 + (0.4 * pulse); // 0.4 ~ 0.8
              final glowScale = 1.0 + (0.2 * pulse);

              return IgnorePointer(
                child: Container(
                  width: boardDimension,
                  height: boardDimension,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    // 선(Border)을 제거하여 보드 내부 침범 방지
                    boxShadow: [
                      // 1. 초대형 외부 아우라 (두껍게 퍼짐)
                      BoxShadow(
                        color: teamColor.withOpacity(opacity * 0.3),
                        blurRadius: 60 * glowScale,
                        spreadRadius: 25, // 두껍게 밖으로 확장
                      ),
                      // 2. 중간 광채 (존재감)
                      BoxShadow(
                        color: teamColor.withOpacity(opacity * 0.6),
                        blurRadius: 30 * glowScale,
                        spreadRadius: 10,
                      ),
                      // 3. 소프트 엣지 (보드 경계면 발광)
                      BoxShadow(
                        color: teamColor.withOpacity(opacity),
                        blurRadius: 15 * glowScale,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
            onEnd: () {},
          ),
        );
      },
    );
  }

  Color _getTeamColor(TeamColor color) {
    switch (color) {
      case TeamColor.orange:
        return Colors.orange;
      case TeamColor.green:
        return Colors.green;
      case TeamColor.red:
        return Colors.red;
      case TeamColor.blue:
        return Colors.blue;
    }
  }

  Color _getDarkerTeamColor(TeamColor color) {
    switch (color) {
      case TeamColor.orange:
        return Colors.orange.shade800;
      case TeamColor.green:
        return Colors.green.shade800;
      case TeamColor.red:
        return Colors.red.shade800;
      case TeamColor.blue:
        return Colors.blue.shade800;
    }
  }

  Widget _buildAcquisitionPopup(ItemType type) {
    final state = ref.read(gameProvider);
    final item = GameItem.fromType(type);
    final teamName = state.justAcquiredItemTeamName ?? '누군가';

    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.amber, width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[$teamName] ${item.name} 획득!',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
