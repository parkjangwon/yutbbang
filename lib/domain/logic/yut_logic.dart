import 'dart:math';
import '../models/yut_result.dart';

class YutThrowResult {
  final YutResult result;
  final List<bool> sticks; // true = flat, false = round

  YutThrowResult(this.result, this.sticks);
}

class YutLogic {
  static final Random _random = Random();

  /// Simulates throwing 4 yut sticks.
  static YutThrowResult throwYut({
    bool forceNak = false,
    double randomNakChance = 0.15,
    bool useBackDo = true,
  }) {
    // 1. Nak probability
    if (forceNak || _random.nextDouble() < randomNakChance) {
      return YutThrowResult(YutResult.nak, [false, false, false, false]);
    }

    // 2. Realistic Probability Simulation
    List<bool> sticks = List.generate(4, (_) => _random.nextBool());

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
}
