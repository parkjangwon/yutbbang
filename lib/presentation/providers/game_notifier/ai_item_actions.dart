part of '../game_provider.dart';

/// CPU 턴 시작 시 아이템 사용.
mixin _AiItemActions on _GameNotifierBase {
  @override
  void _aiProcessItems() {
    final teamIndex = _teamIndex;
    final decision = AiItemLogic.decide(
      teams: state.teams,
      teamIndex: teamIndex,
      difficulty: _rules.aiDifficulty,
      random: _random,
    );
    if (decision == null) return;

    final used = switch (decision.item) {
      ItemType.fixedDice => _useFixedDice(teamIndex),
      ItemType.freeze => _useFreeze(teamIndex),
      ItemType.magnet => _useMagnet(teamIndex),
      ItemType.typhoon => _useTyphoon(teamIndex),
      ItemType.banish => _banishMal(teamIndex, decision.targetMalId!),
      ItemType.swap => _swapMals(
        teamIndex,
        decision.sourceMalId!,
        decision.targetMalId!,
      ),
      ItemType.reroll || ItemType.shield || ItemType.moonwalk => false,
    };
    if (used) _consumeItem(teamIndex, decision.item);
  }
}
