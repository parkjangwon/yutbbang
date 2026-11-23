import 'dart:math';

import '../models/nak_zone.dart';

/// 컨트롤 모드 게이지 난이도. 낙 확률이 높을수록 낙 구간이 많고 좁으며 게이지가 빠르다.
class GaugeSettings {
  final int zoneCount;
  final double zoneWidth;
  final double speedStep;

  const GaugeSettings(this.zoneCount, this.zoneWidth, this.speedStep);

  factory GaugeSettings.forNakChance(int nakChancePercent) {
    if (nakChancePercent >= 25) return const GaugeSettings(4, 0.08, 0.055);
    if (nakChancePercent >= 15) return const GaugeSettings(3, 0.1, 0.045);
    return const GaugeSettings(1, 0.15, 0.035);
  }
}

class GaugeLogic {
  /// 낙 구간을 무작위로 만든다. 구간 시작점은 0.1 ~ (0.9 - 폭) 사이.
  /// 낙 확률 25% 이상(어려움)일 때만 구간끼리 겹치지 않도록 재시도한다.
  static List<NakZone> generateNakZones(int nakChancePercent, Random random) {
    final settings = GaugeSettings.forNakChance(nakChancePercent);
    final avoidOverlap = nakChancePercent >= 25;
    final zones = <NakZone>[];

    for (int i = 0; i < settings.zoneCount; i++) {
      double start = 0;
      for (int attempt = 0; attempt < 50; attempt++) {
        start = 0.1 + random.nextDouble() * (0.8 - settings.zoneWidth);
        if (!avoidOverlap) break;
        final end = start + settings.zoneWidth;
        final overlaps = zones.any((z) => !(end < z.start || start > z.end));
        if (!overlaps) break;
      }
      zones.add(NakZone(start, start + settings.zoneWidth));
    }
    return zones;
  }

  /// 게이지 한 틱 진행. 0과 1 사이를 왕복한다. (새 값, 새 방향)을 돌려준다.
  static (double, double) step(double value, double direction, double speed) {
    final next = value + speed * direction;
    if (next >= 1.0) return (1.0, -1.0);
    if (next <= 0.0) return (0.0, 1.0);
    return (next, direction);
  }

  static bool isInNakZone(double value, List<NakZone> zones) =>
      zones.any((z) => z.contains(value));
}
