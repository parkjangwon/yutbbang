import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/team.dart';
import '../../domain/logic/board_graph.dart';
import '../../domain/logic/path_finder.dart';
import '../../presentation/providers/game_provider.dart';
import '../../presentation/providers/game_state.dart';
import 'board_component.dart';
import 'mal_renderer.dart';

class MalComponent extends PositionComponent
    with TapCallbacks, HasGameReference {
  Mal mal;
  final WidgetRef ref;
  int stackCount = 1;

  final List<Vector2> _moveQueue = [];
  bool _isMoving = false;
  bool _initialized = false;

  // Track last handled movement to prevent animation loops
  String? _lastPathKey;

  MalComponent({required this.mal, required this.ref});

  @override
  Future<void> onLoad() async {
    size = Vector2.all(48);
    anchor = Anchor.center;
    priority = 10;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // 화면 크기 변경 시 말 위치 업데이트
    if (_initialized && !_isMoving) {
      _syncPosition();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (parent == null || parent is! BoardComponent) return;
    final board = parent as BoardComponent;

    if (!_initialized && board.size.x > 100) {
      _syncPosition(immediate: true);
      _initialized = true;
    }

    if (_moveQueue.isNotEmpty && !_isMoving) {
      _processNextMove();
    }
  }

  /// Called by YutGame to sync visual state with logical state
  void updateFromState(Mal newMal, int stack, {List<int>? path}) {
    stackCount = stack;

    // Create a unique key for the current logical state + pending path
    final newPathKey =
        "${newMal.currentNodeId}_${newMal.isFinished}_${path?.join(',')}";

    if (newPathKey == _lastPathKey) {
      // Already handling this move/state, skip to prevent animation restart
      mal = newMal;
      return;
    }

    if (path != null && path.isNotEmpty) {
      // NEW movement path detected
      _lastPathKey = newPathKey;

      final board = parent as BoardComponent;
      _moveQueue.clear(); // Clear old queue

      for (final nodeId in path) {
        if (nodeId == PathFinder.finishNodeId) {
          _moveQueue.add(_getHomePosition());
        } else if (nodeId == PathFinder.startNodeId) {
          _moveQueue.add(_getHomePosition());
        } else {
          final node = BoardGraph.nodes[nodeId];
          if (node != null) {
            _moveQueue.add(board.getRelativeNodePos(node.x, node.y));
          }
        }
      }
      mal = newMal;
    } else {
      // Static state update (e.g. stack count changed or turn ended)
      final posChanged =
          mal.currentNodeId != newMal.currentNodeId ||
          mal.isFinished != newMal.isFinished;

      // 잡혔는지 확인: 이전에 판 위에 있었는데 이제 시작점으로
      final wasCaught =
          mal.currentNodeId != null &&
          newMal.currentNodeId == null &&
          !newMal.isFinished;

      mal = newMal;
      _lastPathKey = newPathKey;

      if (wasCaught) {
        // 잡힌 경우 즉시 보드 밖으로 이동
        _moveQueue.clear();
        _isMoving = false;
        children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());
        _syncPosition(immediate: false); // 잡힌 연출을 위해 부드럽게 이동
      } else if (posChanged && !_isMoving) {
        _syncPosition();
      }
    }
  }

  Vector2 _getHomePosition() {
    if (parent == null || parent is! BoardComponent) return Vector2.zero();
    final board = parent as BoardComponent;
    final gameSize = game.size;

    final state = ref.read(gameProvider);
    final teamIndex = state.teams.indexWhere((t) => t.color == mal.color);
    final totalTeams = state.teams.length;

    // 하단 대기 위젯의 위치에 맞게 X 좌표 계산 (Row의 spaceEvenly와 유사하게)
    final sectionWidth = gameSize.x / (totalTeams > 0 ? totalTeams : 4);
    final screenX = sectionWidth * (teamIndex + 0.5);

    // Y 좌표는 보드 아래쪽 (화면 밖에서 날아오는 느낌)
    final screenY = gameSize.y + 300;

    // Board는 (gameSize - board.size) / 2 에 위치함. 이를 상대 좌표로 변환
    final boardOrigin = (gameSize - board.size) / 2;

    return Vector2(screenX - boardOrigin.x, screenY - boardOrigin.y);
  }

  void _syncPosition({bool immediate = false}) {
    if (parent == null || parent is! BoardComponent) return;
    final board = parent as BoardComponent;
    if (board.size.x < 100) return;

    Vector2 targetPos;
    if (mal.isFinished) {
      targetPos = _getHomePosition();
    } else if (mal.currentNodeId == null) {
      // 시작점: 하단 영역에서 온 것으로 처리
      targetPos = _getHomePosition();
    } else {
      final node = BoardGraph.nodes[mal.currentNodeId!];
      if (node != null) {
        targetPos = board.getRelativeNodePos(node.x, node.y);
      } else {
        return;
      }
    }

    if (immediate) {
      position = targetPos;
    } else {
      _isMoving = true;
      children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());

      final isReturning = mal.currentNodeId == null && !mal.isFinished;
      final duration = isReturning ? 0.3 : 0.4;

      add(
        MoveEffect.to(
          targetPos,
          EffectController(duration: duration, curve: Curves.easeOutCubic),
          onComplete: () => _isMoving = false,
        ),
      );

      if (isReturning) {
        add(
          SequenceEffect([
            ScaleEffect.to(
              Vector2.all(0.6),
              EffectController(duration: 0.15, curve: Curves.easeIn),
            ),
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.15, curve: Curves.easeOut),
            ),
          ]),
        );
      }
    }
  }

  void _processNextMove() {
    _isMoving = true;
    final nextPos = _moveQueue.removeAt(0);

    add(
      MoveEffect.to(
        nextPos,
        EffectController(duration: 0.3, curve: Curves.easeOutQuad),
        onComplete: () {
          _isMoving = false;
        },
      ),
    );

    // Simple Jump Effect
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.4),
          EffectController(duration: 0.15, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.15, curve: Curves.easeIn),
        ),
      ]),
    );
  }

  @override
  void render(Canvas canvas) {
    if (!_initialized) return;
    final center = (size / 2).toOffset();
    final radius = size.x / 2;

    MalRenderer.paintCoin(canvas, center, radius, mal.color, stackCount);

    final state = ref.read(gameProvider);
    // Pulse effect if this piece belongs to the current team and we're picking
    if (state.currentTeam.color == mal.color &&
        (state.status == GameStatus.selectingMal ||
            state.status == GameStatus.awaitingShortcutDecision) &&
        state.currentTeam.isHuman) {
      MalRenderer.paintSelectionPulse(canvas, center, radius);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (mal.isFinished || _isMoving) return;
    final state = ref.read(gameProvider);

    // 아이템 대상 선택 중인지 확인
    if (state.status == GameStatus.awaitingBanishTarget ||
        state.status == GameStatus.awaitingSwapSource ||
        state.status == GameStatus.awaitingSwapTarget) {
      ref.read(gameProvider.notifier).handleMalSelectionForItem(mal.id);
      return;
    }

    if ((state.status == GameStatus.selectingMal ||
            state.status == GameStatus.awaitingShortcutDecision) &&
        state.currentTeam.color == mal.color &&
        state.currentTeam.isHuman) {
      ref.read(gameProvider.notifier).selectMal(mal.id);
    }
  }
}
