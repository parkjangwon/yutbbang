// 게임 나가기, 행동 기록, CPU 속도, 다시 던지기 질문 조건.
import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/game_scene.dart';

const cpuVsCpu = GameRuleConfig(teamControllers: [0, 0], nakChancePercent: 0);

void main() {
  group('게임 나가기', () {
    testWidgets('나가면 로비 상태로 돌아간다', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [3]),
        team(1, [null]),
      ]);
      scene.notifier.exitGame();
      expect(scene.state.status, GameStatus.lobby);
      expect(
        scene.state.teams.every((t) => t.mals.every((m) => m.isWaiting)),
        isTrue,
      );
      await scene.finish(tester);
    });

    testWidgets('나간 뒤에는 예약돼 있던 CPU 행동이 실행되지 않는다 (회귀)', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [null]),
        team(1, [null]),
      ]);
      scene.notifier.startGameWithConfig(cpuVsCpu);
      await tester.pump(const Duration(milliseconds: 2500)); // CPU가 던지기 시작
      scene.notifier.exitGame();
      await tester.pump(const Duration(seconds: 20));
      expect(scene.state.status, GameStatus.lobby);
      expect(scene.state.lastResult, isNull);
      await scene.finish(tester);
    });

    testWidgets('새 게임을 시작하면 이전 판의 예약 행동은 무시된다', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [null]),
        team(1, [null]),
      ]);
      scene.notifier.startGameWithConfig(cpuVsCpu);
      await tester.pump(const Duration(milliseconds: 1500));
      scene.notifier.startGameWithConfig(
        const GameRuleConfig(teamControllers: [1, 0], nakChancePercent: 0),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(scene.state.status, GameStatus.throwing);
      expect(scene.state.turnIndex, 0, reason: '사람 차례에서 멈춰 있어야 한다');
      expect(scene.state.lastResult, isNull);
      await scene.finish(tester);
    });
  });

  group('행동 기록', () {
    testWidgets('던진 결과를 팀 이름과 함께 기록한다', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [null]),
        team(1, [null]),
      ]);
      scene.notifier.throwYut(forceNak: true);
      expect(scene.state.actionLog.last, 'A팀: 낙');
      await scene.finish(tester);
    });

    testWidgets('잡기와 골인을 기록한다', (tester) async {
      final scene = await GameScene.start(
        tester,
        [
          team(0, [2, 19]),
          team(1, [3], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.do_, YutResult.do_],
      );
      scene.notifier.selectMal(0);
      await tester.pump(const Duration(milliseconds: 700));
      expect(scene.state.actionLog.last, 'A팀이 B팀 말을 잡았습니다');

      scene.notifier.seed(
        scene.state.copyWith(
          status: GameStatus.selectingMal,
          currentThrows: [YutResult.do_],
        ),
      );
      scene.notifier.selectMal(1);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(scene.state.actionLog, contains('A팀 말 골인!'));
      await scene.finish(tester);
    });

    testWidgets('아이템 사용을 기록한다', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [null]), [ItemType.freeze]),
        team(1, [null], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.freeze);
      expect(scene.state.actionLog.last, 'A팀: ❄️ 얼음탄 사용');
      await scene.finish(tester);
    });

    testWidgets('얼음탄으로 차례를 건너뛰면 기록한다', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [null]),
        team(1, [null], isHuman: false, skipNextTurn: true),
      ]);
      scene.notifier.nextTurn();
      expect(scene.state.actionLog.last, 'B팀: ❄️ 얼어서 차례를 건너뜁니다');
      await scene.finish(tester);
    });

    testWidgets('최근 5개까지만 남긴다', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [null]),
        team(1, [null]),
      ]);
      for (int i = 0; i < 7; i++) {
        scene.notifier.seed(scene.state.copyWith(status: GameStatus.throwing));
        scene.notifier.throwYut(forceNak: true);
      }
      expect(scene.state.actionLog, hasLength(5));
      await scene.finish(tester);
    });
  });

  group('CPU 속도', () {
    testWidgets('빠름이면 CPU 첫 던지기가 절반 시간에 시작된다', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [null]),
        team(1, [null]),
      ]);
      scene.notifier.startGameWithConfig(
        cpuVsCpu.copyWith(cpuSpeed: CpuSpeed.fast),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      expect(scene.state.lastResult, isNotNull);
      await scene.finish(tester);
    });

    testWidgets('보통이면 2초 전에는 던지지 않는다', (tester) async {
      final scene = await GameScene.start(tester, [
        team(0, [null]),
        team(1, [null]),
      ]);
      scene.notifier.startGameWithConfig(cpuVsCpu);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(scene.state.lastResult, isNull);
      await scene.finish(tester);
    });
  });

  group('다시 던지기 질문', () {
    testWidgets('윷·모가 나오면 묻지 않고 그대로 진행한다', (tester) async {
      final scene = await GameScene.start(tester, [
        withItems(team(0, [null]), [ItemType.reroll, ItemType.fixedDice]),
        team(1, [null], isHuman: false),
      ]);
      scene.notifier.useItem(ItemType.fixedDice); // 윷 또는 모 확정
      scene.notifier.throwYut();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(scene.state.showRerollChoice, isFalse);
      expect(scene.state.currentThrows, hasLength(1));
      expect(scene.state.teams[0].items, [ItemType.reroll]);
      await scene.finish(tester);
    });
  });
}
