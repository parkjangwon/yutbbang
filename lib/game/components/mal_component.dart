import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/team.dart';
import '../../domain/logic/path_finder.dart';
import '../../presentation/providers/game_provider.dart';
import '../../presentation/providers/game_view.dart';
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
          final pos = board.layout.nodeOffsetById(nodeId);
          if (pos != null) _moveQueue.add(pos.toVector2());
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

  /// 대기·완주 말의 판 밖 위치(하단 대기 패널 쪽).
  Vector2 _getHomePosition() {
    if (parent is! BoardComponent) return Vector2.zero();
    final board = parent as BoardComponent;
    final teams = ref.read(gameProvider).teams;
    return board.layout
        .homeOffset(
          teamIndex: teams.indexWhere((t) => t.color == mal.color),
          teamCount: teams.length,
        )
        .toVector2();
  }

  void _syncPosition({bool immediate = false}) {
    if (parent == null || parent is! BoardComponent) return;
    final board = parent as BoardComponent;
    if (board.size.x < 100) return;

    final nodeId = mal.currentNodeId;
    final Vector2 targetPos;
    if (nodeId == null) {
      // 대기·완주: 하단 대기 영역
      targetPos = _getHomePosition();
    } else {
      final pos = board.layout.nodeOffsetById(nodeId);
      if (pos == null) return;
      targetPos = pos.toVector2();
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

    if (ref.read(gameProvider).isMalHighlighted(mal)) {
      MalRenderer.paintSelectionPulse(canvas, center, radius);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isMoving) return;
    final notifier = ref.read(gameProvider.notifier);
    switch (ref.read(gameProvider).malTapAction(mal)) {
      case MalTapAction.itemTarget:
        notifier.handleMalSelectionForItem(mal.id);
      case MalTapAction.select:
        notifier.selectMal(mal.id);
      case MalTapAction.none:
        break;
    }
  }
}
