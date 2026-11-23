import 'dart:math';

import '../models/yut_result.dart';

class YutThrowResult {
  final YutResult result;
  final List<bool> sticks; // true = flat, false = round

  YutThrowResult(this.result, this.sticks);
}

/// 윷가락 4개를 던지는 확률 로직.
///
/// 막대 값 true = 평평한 면(배)이 위. 평평한 면 개수로 결과가 정해진다:
/// 1개=도(첫 번째 막대면 빽도), 2개=개, 3개=걸, 4개=윷, 0개=모.
class YutLogic {
  static final Random _random = Random();

  /// Simulates throwing 4 yut sticks.
  static YutThrowResult throwYut({
    bool forceNak = false,
    double randomNakChance = 0.15,
    bool useBackDo = true,
    Random? random,
  }) {
    final rng = random ?? _random;
    // 1. Nak probability
    if (forceNak || rng.nextDouble() < randomNakChance) {
      return YutThrowResult(YutResult.nak, [false, false, false, false]);
    }

    // 2. Realistic Probability Simulation
    final sticks = List.generate(4, (_) => rng.nextBool());

    int flatCount = sticks.where((s) => s).length;
    YutResult result;

    if (flatCount == 1) {
      if (useBackDo && sticks[0]) {
        result = YutResult.backDo;
      } else {
        result = YutResult.do_;
      }
    } else if (flatCount == 2) {
      result = YutResult.gae;
    } else if (flatCount == 3) {
      result = YutResult.geol;
    } else if (flatCount == 4) {
      result = YutResult.yut;
    } else {
      // flatCount == 0
      result = YutResult.mo;
    }

    return YutThrowResult(result, sticks);
  }

  /// 황금 윷: 윷 또는 모가 50:50으로 나온다.
  static YutThrowResult throwGolden({Random? random}) {
    final isYut = (random ?? _random).nextBool();
    return isYut
        ? YutThrowResult(YutResult.yut, const [true, true, true, true])
        : YutThrowResult(YutResult.mo, const [false, false, false, false]);
  }
}
