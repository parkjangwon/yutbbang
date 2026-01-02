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
  /// [isSafe] can be used later for a timing mini-game.
  static YutThrowResult throwYut({
    required bool isSafe,
    bool useBackDo = true,
    double nakChance = 0.15,
  }) {
    // 1. Nak probability
    if (_random.nextDouble() < nakChance) {
      return YutThrowResult(YutResult.nak, [false, false, false, false]);
    }

    // 2. Realistic Probability Simulation
    // In digital Yut, simply generating 4 random bits is okay,
    // but we can bias it slightly to feel more 'natural'.
    // Here we'll use a 50/50 chance for each stick side.
    List<bool> sticks = List.generate(4, (_) => _random.nextBool());

    int flatCount = sticks.where((s) => s).length;
    YutResult result;

    if (flatCount == 1) {
      // Back-Do check: traditionally the stick with a mark.
      // We'll use the first stick for this.
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
