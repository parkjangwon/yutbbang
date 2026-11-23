// 컨트롤 모드 게이지.
import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/game_scene.dart';

void main() {
  group('컨트롤 모드 게이지', () {
    testWidgets('누르면 게이지가 움직이고, 떼면 던진다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          team(0, [null]),
          team(1, [null], isHuman: false),
        ],
        rules: const GameRuleConfig(
          useGaugeControl: true,
          nakChancePercent: 15,
        ),
      );
      scene.notifier.startGauge();
      expect(scene.state.isGaugeRunning, isTrue);
      expect(scene.state.nakZones, hasLength(3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scene.state.gaugeValue, greaterThan(0));

      scene.notifier.stopGauge();
      expect(scene.state.isGaugeRunning, isFalse);
      expect(scene.state.lastResult, isNotNull);
      await scene.finish(tester);
    });
  });
}
