import '../models/yut_result.dart';
import 'board_graph.dart';

class PathFinder {
  static const int startNodeId = -1;
  static const int finishNodeId = -99;

  /// Determines the path for a move.
  /// [useShortcut] if true, the first step will take the shortcut if available.
  static List<int> calculatePath(
    int startId,
    YutResult result, {
    bool useShortcut = false,
    List<int>? previousNodeIds,
    bool isReverse = false,
  }) {
    if (result == YutResult.nak) return [];
    if ((result == YutResult.backDo || isReverse) && startId == startNodeId)
      return [];

    List<int> path = [];
    int currentId = startId;
    int moves = result.moveCount.abs();

    for (int i = 0; i < moves; i++) {
      int? nextId;

      if (result == YutResult.backDo || isReverse) {
        // Use historical nodes for backward movement if available
        if (previousNodeIds != null && previousNodeIds.length > i) {
          nextId = previousNodeIds[previousNodeIds.length - 1 - i];
        } else {
          nextId = BoardGraph.nodes[currentId]?.prevId ?? startNodeId;
        }
      } else {
        if (currentId == startNodeId) {
          nextId = 1;
        } else {
          final node = BoardGraph.nodes[currentId];
          if (node == null) break;

          // Shortcut Choice: only on the very first step of the move
          if (i == 0 && useShortcut && node.shortcutNextId != null) {
            nextId = node.shortcutNextId;
          } else {
            nextId = node.nextId;

            // 추가: 가운데(20번) 노드를 '통과'할 때의 방향 유지 로직
            if (currentId == 20) {
              if (i > 0) {
                // 통과 중인 경우: 들어온 방향에 따라 직진
                final prevId = (i == 1) ? startId : path[i - 2];
                if (prevId == 22) {
                  // 1꼭짓점에서 온 대각선 -> 15번 방향(23)으로 직진
                  nextId = node.shortcutNextId ?? 23;
                } else if (prevId == 26) {
                  // 2꼭짓점에서 온 대각선 -> 완료 방향(27)으로 직진
                  nextId = 27;
                }
              } else {
                // 가운데에서 '출발'하는 경우: 사용자의 규칙에 따라 무조건 완주 방향(27)
                nextId = 27;
              }
            }
          }
        }
      }

      if (nextId == null) {
        path.add(finishNodeId);
        break;
      }

      // Finish Logic:
      // Traditional Yutnori:
      // - To finish from the main path, you must land on or pass node 0 (Home) FROM node 19.
      // - To finish from the diagonal path, you must land on or pass node 0 FROM node 28.
      if (nextId == 0) {
        if (currentId == 19 || currentId == 28) {
          // You reached the Home circle.
          // In some rules, just landing on Home (0) is finishing.
          // In others, you need to move one more step.
          // Let's implement: landing on or passing Home = Finish.
          path.add(0);
          path.add(finishNodeId);
          break;
        } else {
          // This is node 0 as a normal node (e.g. from 19 back-do? No)
          path.add(0);
          currentId = 0;
        }
      } else {
        path.add(nextId);
        currentId = nextId;
      }
    }

    return path;
  }
}
