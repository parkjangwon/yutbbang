import 'dart:math';

import '../models/game_item.dart';
import '../models/team.dart';
import 'item_effects.dart';

/// CPU가 턴 시작 시 쓸 아이템과 대상.
class AiItemDecision {
  final ItemType item;
  final int? sourceMalId;
  final int? targetMalId;

  const AiItemDecision(this.item, {this.sourceMalId, this.targetMalId});
}

/// CPU 아이템 사용 판단. 한 턴에 최대 하나만 쓴다.
class AiItemLogic {
  /// 난이도에 비례한 확률(난이도/12)로 아이템 사용을 검토하고,
  /// 보유 순서대로 조건이 맞는 첫 아이템을 고른다.
  static AiItemDecision? decide({
    required List<Team> teams,
    required int teamIndex,
    required int difficulty,
    required Random random,
  }) {
    final team = teams[teamIndex];
    if (team.isHuman || team.items.isEmpty) return null;
    if (random.nextDouble() > difficulty / 12.0) return null;

    for (final item in team.items) {
      final decision = _consider(item, teams, teamIndex);
      if (decision != null) return decision;
    }
    return null;
  }

  static AiItemDecision? _consider(
    ItemType item,
    List<Team> teams,
    int teamIndex,
  ) {
    final team = teams[teamIndex];
    final opponents = [
      for (final t in teams)
        if (t.color != team.color) t,
    ];

    switch (item) {
      case ItemType.fixedDice:
        // 판 위에 내 말이 하나도 없을 때.
        return team.mals.every((m) => m.currentNodeId == null)
            ? const AiItemDecision(ItemType.fixedDice)
            : null;
      case ItemType.freeze:
        // 다음 팀 말이 16번 칸 이후(마지막 변 또는 대각선)에 있을 때.
        final nextTeam = teams[(teamIndex + 1) % teams.length];
        return nextTeam.mals.any((m) => (m.currentNodeId ?? -1) > 15)
            ? const AiItemDecision(ItemType.freeze)
            : null;
      case ItemType.banish:
        // 가장 번호가 큰 칸의 상대 말이 10번 칸 이후일 때 그 말을 귀가.
        final (targetId, pos) = _furthestMal(opponents);
        return targetId != null && pos > 10
            ? AiItemDecision(ItemType.banish, targetMalId: targetId)
            : null;
      case ItemType.magnet:
        // 상대 말 2개 이상을 잡을 수 있을 때.
        return ItemEffects.magnetCatchCount(teams, teamIndex) >= 2
            ? const AiItemDecision(ItemType.magnet)
            : null;
      case ItemType.swap:
        // 출발 직후(1~4번) 내 말과 대각선(21번 이후) 상대 말을 맞바꾼다.
        final source = team.mals
            .where((m) => m.isOnBoard && m.currentNodeId! < 5)
            .firstOrNull;
        final (targetId, pos) = _furthestMal(opponents);
        return source != null && targetId != null && pos > 20
            ? AiItemDecision(
                ItemType.swap,
                sourceMalId: source.id,
                targetMalId: targetId,
              )
            : null;
      case ItemType.typhoon:
        // 완주 수에서 밀리거나 상대 말이 대각선(21번 이후)에 있을 때.
        final losing = opponents.any(
          (t) =>
              t.finishedCount > team.finishedCount ||
              t.mals.any((m) => (m.currentNodeId ?? -1) > 20),
        );
        return losing ? const AiItemDecision(ItemType.typhoon) : null;
      case ItemType.reroll:
      case ItemType.shield:
      case ItemType.moonwalk:
        // 자동 발동 아이템은 여기서 쓰지 않는다.
        return null;
    }
  }

  /// 상대 말 중 칸 번호가 가장 큰 말 (id, 칸 번호). 없으면 (null, -1).
  static (int?, int) _furthestMal(List<Team> opponents) {
    int? id;
    var maxPos = -1;
    for (final t in opponents) {
      for (final m in t.mals) {
        final pos = m.currentNodeId;
        if (pos != null && pos > maxPos) {
          maxPos = pos;
          id = m.id;
        }
      }
    }
    return (id, maxPos);
  }
}
