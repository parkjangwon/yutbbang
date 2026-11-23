import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yutbbang/data/config_repository.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';

void main() {
  const repo = ConfigRepository();

  test('저장된 값이 없으면 기본값', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await repo.load(() => const GameRuleConfig());
    expect(c.aiDifficulty, 5);
    expect(c.nakChancePercent, 15);
    expect(c.useBackDo, isTrue);
    expect(c.useItemMode, isFalse);
  });

  test('저장한 글로벌 설정을 그대로 복원한다', () async {
    SharedPreferences.setMockInitialValues({});
    const saved = GameRuleConfig(
      aiDifficulty: 9,
      nakChancePercent: 25,
      useBackDo: false,
      useGaugeControl: true,
      backDoFlying: true,
      autoCarrier: true,
      totalNak: true,
      roastedChestnutMode: true,
      useItemMode: true,
    );
    await repo.save(saved);
    final c = await repo.load(() => const GameRuleConfig());
    expect(
      [
        c.aiDifficulty,
        c.nakChancePercent,
        c.useBackDo,
        c.useGaugeControl,
        c.backDoFlying,
        c.autoCarrier,
        c.totalNak,
        c.roastedChestnutMode,
        c.useItemMode,
      ],
      [9, 25, false, true, true, true, true, true, true],
    );
  });

  test('판마다 정하는 값(팀 수)은 저장하지 않는다', () async {
    SharedPreferences.setMockInitialValues({});
    await repo.save(const GameRuleConfig(teamCount: 4));
    final c = await repo.load(() => const GameRuleConfig(teamCount: 3));
    expect(c.teamCount, 3);
  });

  test('설정 화면의 "게임당 말" 기본값은 저장된다 (회귀)', () async {
    SharedPreferences.setMockInitialValues({});
    await repo.save(const GameRuleConfig(malCount: 4));
    final c = await repo.load(() => const GameRuleConfig());
    expect(c.malCount, 4);
  });
}
