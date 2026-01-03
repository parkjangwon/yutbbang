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

            // Handle intersection at node 20 (Center)
            if (currentId == 20) {
              if (i == 0) {
                // Starting move from Center:
                // Only allow turning (27) if coming from Node 5 path (22) AND user explicitly picks shortcut.
                final entryId =
                    (previousNodeIds != null && previousNodeIds.isNotEmpty)
                    ? previousNodeIds.last
                    : null;

                if (entryId == 22) {
                  // Came from Top-Right corner path
                  nextId = useShortcut ? 27 : 23;
                } else if (entryId == 26) {
                  // Came from Top-Left corner path: already on shortcut, keep going straight to 27
                  nextId = 27;
                } else {
                  // Default/Fallthrough
                  nextId = 27;
                }
              } else {
                // Passing through Center: MUST go straight according to entry vector.
                final prevId = i >= 2 ? path[i - 2] : startId;
                if (prevId == 26) {
                  // 10 -> 25 -> 26 -> 20 -> 27 (Straight)
                  nextId = 27;
                } else if (prevId == 22) {
                  // 5 -> 21 -> 22 -> 20 -> 23 (Straight)
                  nextId = 23;
                }
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
