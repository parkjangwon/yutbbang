import 'dart:math';

import '../models/team.dart';
import '../models/yut_result.dart';
import 'path_finder.dart';

class AILogic {
  static final Random _random = Random();

  /// Decides which mal to move for a given result.
  /// [difficulty] 1 to 10.
  static int? decideMove({
    required int difficulty,
    required List<Team> teams,
    required int turnIndex,
    required YutResult result,
    Random? random,
  }) {
    final rng = random ?? _random;
    final currentTeam = teams[turnIndex % teams.length];
    final opponentTeams = teams
        .where((t) => t.color != currentTeam.color)
        .toList();

    // 1. Get all movable mals (not finished)
    final movableMals = currentTeam.mals.where((m) => !m.isFinished).toList();
    if (movableMals.isEmpty) return null;

    // 2. Score each move
    final scores = <MapEntry<int, int>>[];

    for (var mal in movableMals) {
      int score = 0;
      final path = PathFinder.calculatePath(
        mal.currentNodeId ?? -1,
        result,
        previousNodeIds: mal.historyNodeIds,
      ); // Use -1 for start

      if (path.isEmpty) continue;

      final destinationId = path.last;

      if (destinationId == PathFinder.finishNodeId) {
        // Goal move
        score += 100;
      } else {
        // Catch opponent?
        bool canCatch = false;
        for (var ot in opponentTeams) {
          if (ot.mals.any((om) => om.currentNodeId == destinationId)) {
            canCatch = true;
            break;
          }
        }
        if (canCatch) score += 150;

        // Carry teammate?
        bool canCarry = currentTeam.mals.any(
          (m) => m.id != mal.id && m.currentNodeId == destinationId,
        );
        if (canCarry) score += 40;

        // Distance progress
        score += path.length * 5;
      }

      scores.add(MapEntry(mal.id, score));
    }

    if (scores.isEmpty) return movableMals.first.id;

    // 3. Difficulty based selection
    // Level 10: Always pick highest score
    // Level 1: Random pick
    // Intermediate: Probability weighting

    scores.sort((a, b) => b.value.compareTo(a.value));

    // Simple difficulty heuristic:
    // With probability (difficulty/10), pick best. Else pick random.
    final threshold = difficulty / 10.0;
    if (rng.nextDouble() < threshold) {
      return scores.first.key;
    }
    return scores[rng.nextInt(scores.length)].key;
  }
}
