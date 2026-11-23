import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/yut_logic.dart';
import 'package:yutbbang/domain/models/yut_result.dart';

import '../helpers/fixtures.dart';

void main() {
  group('YutLogic.throwYut', () {
    test('forceNak이면 무조건 낙', () {
      final r = YutLogic.throwYut(forceNak: true, randomNakChance: 0);
      expect(r.result, YutResult.nak);
    });

    test('난수가 낙 확률보다 작으면 낙', () {
      final r = YutLogic.throwYut(
        randomNakChance: 0.15,
        random: FakeRandom(doubles: [0.1]),
      );
      expect(r.result, YutResult.nak);
    });

    final cases = <List<bool>, YutResult>{
      [false, false, false, false]: YutResult.mo,
      [false, true, false, false]: YutResult.do_,
      [true, false, false, false]: YutResult.backDo,
      [true, true, false, false]: YutResult.gae,
      [true, true, true, false]: YutResult.geol,
      [true, true, true, true]: YutResult.yut,
    };
    cases.forEach((sticks, expected) {
      test('막대 $sticks → ${expected.label}', () {
        final r = YutLogic.throwYut(
          randomNakChance: 0,
          random: FakeRandom(doubles: [0.99], bools: sticks),
        );
        expect(r.result, expected);
        expect(r.sticks, sticks);
      });
    });

    test('빽도를 끄면 표시 막대가 첫 번째여도 도', () {
      final r = YutLogic.throwYut(
        randomNakChance: 0,
        useBackDo: false,
        random: FakeRandom(doubles: [0.99], bools: [true, false, false, false]),
      );
      expect(r.result, YutResult.do_);
    });

    test('결과는 항상 막대 모양과 일치한다 (무작위 1000회)', () {
      final rng = Random(42);
      for (int i = 0; i < 1000; i++) {
        final r = YutLogic.throwYut(randomNakChance: 0.1, random: rng);
        if (r.result == YutResult.nak) continue;
        final flats = r.sticks.where((s) => s).length;
        final expected = switch (flats) {
          0 => YutResult.mo,
          1 => r.sticks[0] ? YutResult.backDo : YutResult.do_,
          2 => YutResult.gae,
          3 => YutResult.geol,
          _ => YutResult.yut,
        };
        expect(r.result, expected);
      }
    });
  });

  test('황금 윷은 윷 또는 모만 나온다', () {
    final rng = Random(1);
    final results = {
      for (int i = 0; i < 100; i++) YutLogic.throwGolden(random: rng).result,
    };
    expect(results, {YutResult.yut, YutResult.mo});
  });

  group('YutResult', () {
    test('윷·모만 보너스 턴', () {
      expect(
        YutResult.values.where((r) => r.isBonusTurn),
        [YutResult.yut, YutResult.mo],
      );
    });

    test('이동 칸 수', () {
      expect(YutResult.values.map((r) => r.moveCount), [1, 2, 3, 4, 5, -1, 0]);
    });
  });
}
