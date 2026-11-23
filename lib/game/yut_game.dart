import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/game_provider.dart';
import '../presentation/providers/game_state.dart';
import '../presentation/providers/game_view.dart';
import 'components/board_component.dart';
import 'components/mal_component.dart';
import 'components/yut_display_component.dart';

class YutGame extends FlameGame {
  final WidgetRef ref;
  final Set<int> _pendingMalIds = {};

  YutGame(this.ref);

  /// 배경은 Flutter 쪽 이미지가 그리므로 투명하게 둔다.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = '';
    // Use Priority to ensure board is loaded and rendered first
    await add(BoardComponent()..priority = 0);
    await add(YutDisplayComponent()..priority = 10);
  }

  @override
  void update(double dt) {
    super.update(dt);
    try {
      if (!isAttached) return;
      final gameState = ref.read(gameProvider);
      _syncMals(gameState);

      final yutDisplay = children.whereType<YutDisplayComponent>().firstOrNull;
      if (yutDisplay != null) {
        yutDisplay.updateSticks(
          gameState.lastStickStates,
          gameState.lastResult,
        );
        yutDisplay.opacity = gameState.isYutDisplayVisible ? 1.0 : 0.0;
      }
    } catch (e) {
      // Initial frame safety
    }
  }

  void _syncMals(GameState state) {
    final board = children.whereType<BoardComponent>().firstOrNull;
    if (board == null || !board.isLoaded || board.size.x < 100) return;

    for (final team in state.teams) {
      for (final mal in team.mals) {
        final stackCount = state.stackCountOf(mal);

        final existing = board.children
            .whereType<MalComponent>()
            .where((c) => c.mal.id == mal.id)
            .firstOrNull;

        if (existing == null) {
          if (_pendingMalIds.contains(mal.id)) continue;
          _pendingMalIds.add(mal.id);
          board.add(MalComponent(mal: mal, ref: ref)..priority = 5);
        } else {
          _pendingMalIds.remove(mal.id);

          existing.updateFromState(
            mal,
            stackCount,
            path: state.movingMalId == mal.id ? state.currentPath : null,
          );
        }
      }
    }
  }
}
