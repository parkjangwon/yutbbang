import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/game_rule_config.dart';

/// 글로벌 설정을 기기에 저장·복원한다.
///
/// 팀 수·팀 이름·CPU/플레이어 배정은 판마다 정하는 값이라 저장하지 않는다.
class ConfigRepository {
  static const _useBackDo = 'useBackDo';
  static const _useGaugeControl = 'useGaugeControl';
  static const _backDoFlying = 'backDoFlying';
  static const _autoCarrier = 'autoCarrier';
  static const _totalNak = 'totalNak';
  static const _roastedChestnutMode = 'roastedChestnutMode';
  static const _useItemMode = 'useItemMode';
  static const _aiDifficulty = 'aiDifficulty';
  static const _nakChancePercent = 'nakChancePercent';
  static const _malCount = 'malCount';
  static const _cpuSpeed = 'cpuSpeed';

  const ConfigRepository();

  /// 저장된 값을 [base]가 돌려주는 설정에 덮어써서 돌려준다. 저장된 값이 없으면 기본값.
  /// [base]는 저장소를 읽은 뒤에 호출되므로 그 사이 바뀐 상태를 반영한다.
  Future<GameRuleConfig> load(GameRuleConfig Function() base) async {
    final prefs = await SharedPreferences.getInstance();
    return base().copyWith(
      useBackDo: prefs.getBool(_useBackDo) ?? true,
      useGaugeControl: prefs.getBool(_useGaugeControl) ?? false,
      backDoFlying: prefs.getBool(_backDoFlying) ?? false,
      autoCarrier: prefs.getBool(_autoCarrier) ?? false,
      totalNak: prefs.getBool(_totalNak) ?? false,
      roastedChestnutMode: prefs.getBool(_roastedChestnutMode) ?? false,
      useItemMode: prefs.getBool(_useItemMode) ?? false,
      aiDifficulty: prefs.getInt(_aiDifficulty) ?? 5,
      nakChancePercent: prefs.getInt(_nakChancePercent) ?? 15,
      malCount: prefs.getInt(_malCount) ?? 2,
      cpuSpeed: CpuSpeed.values
          .where((s) => s.name == prefs.getString(_cpuSpeed))
          .firstOrNull,
    );
  }

  Future<void> save(GameRuleConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_useBackDo, config.useBackDo),
      prefs.setBool(_useGaugeControl, config.useGaugeControl),
      prefs.setBool(_backDoFlying, config.backDoFlying),
      prefs.setBool(_autoCarrier, config.autoCarrier),
      prefs.setBool(_totalNak, config.totalNak),
      prefs.setBool(_roastedChestnutMode, config.roastedChestnutMode),
      prefs.setBool(_useItemMode, config.useItemMode),
      prefs.setInt(_aiDifficulty, config.aiDifficulty),
      prefs.setInt(_nakChancePercent, config.nakChancePercent),
      prefs.setInt(_malCount, config.malCount),
      prefs.setString(_cpuSpeed, config.cpuSpeed.name),
    ]);
  }
}
