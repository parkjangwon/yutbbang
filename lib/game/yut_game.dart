import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/yut_result.dart';
import '../presentation/providers/game_provider.dart';
import '../presentation/providers/game_state.dart';
import 'components/board_component.dart';
import 'components/mal_component.dart';
import 'components/yut_display_component.dart';

class YutGame extends FlameGame {
  final WidgetRef ref;
  final Set<int> _pendingMalIds = {};

  YutGame(this.ref);

  @override
  Color backgroundColor() => const Color(0xFFF3E5AB);

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
        yutDisplay.updateSticks(gameState.lastStickStates);
        yutDisplay.opacity =
            (gameState.status == GameStatus.throwing ||
                gameState.status == GameStatus.selectingMal ||
                gameState.status == GameStatus.moving)
            ? 1.0
            : 0.0;
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
        int stackCount = 1;
        if (mal.currentNodeId != null) {
          // 판 위에 있는 말들의 스택 카운트
          stackCount = team.mals
              .where((m) => m.currentNodeId == mal.currentNodeId)
              .length;
        } else if (!mal.isFinished) {
          // 시작점에 있는 말들의 스택 카운트
          stackCount = team.mals
              .where((m) => m.currentNodeId == null && !m.isFinished)
              .length;
        }

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

          // Pass movement info if this specific mal is moving
          YutResult? moveResult;
          if (state.movingMalId == mal.id && state.currentPath.isNotEmpty) {
            // We don't have the result easily here, but PathFinder uses it.
            // Actually MalComponent.updateFromState calculates its own path if result is provided.
            // Let's change MalComponent to just follow state.currentPath.
          }
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
