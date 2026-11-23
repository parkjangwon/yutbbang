import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_provider.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';

import '../../helpers/fixtures.dart';

/// 사람 2팀, 말 2개, 랜덤 낙 없음.
const twoHumans = GameRuleConfig(teamControllers: [1, 2], nakChancePercent: 0);

/// 항상 '모'(평평한 면 0개)가 나오고 낙은 안 나오는 난수.
Random alwaysMo() => FakeRandom(doubles: [0.99], bools: [false]);

void main() {
  late ProviderContainer container;
  GameState state() => container.read(gameProvider);
  GameNotifier notifier() => container.read(gameProvider.notifier);

  Future<void> setUp0(WidgetTester tester, {Random? random}) async {
    SharedPreferences.setMockInitialValues({'aiDifficulty': 8});
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    container = ProviderContainer(
      overrides: [
        if (random != null) gameRandomProvider.overrideWithValue(random),
      ],
    );
    container.listen(gameProvider, (_, _) {});
    state();
    await tester.pump();
  }

  /// 남은 타이머를 모두 흘려보내고 컨테이너를 정리한다.
  Future<void> tearDown0(WidgetTester tester) async {
    // CPU 차례가 계속 이어질 수 있으므로 먼저 정리하고, 남은 타이머는 ref.mounted 검사로 무시된다.
    container.dispose();
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('처음에는 로비 상태이고 저장된 설정을 불러온다', (tester) async {
    await setUp0(tester);
    expect(state().status, GameStatus.lobby);
    expect(state().config.aiDifficulty, 8);
    await tearDown0(tester);
  });

  testWidgets('게임 시작: 팀·말 생성, 아이템 모드면 아이템 타일 8개', (tester) async {
    await setUp0(tester);
    notifier().startGameWithConfig(
      twoHumans.copyWith(
        teamCount: 3,
        malCount: 4,
        teamControllers: [1, 2, 3],
        useItemMode: true,
      ),
    );
    expect(state().status, GameStatus.throwing);
    expect(state().teams, hasLength(3));
    expect(state().teams.every((t) => t.mals.length == 4), isTrue);
    expect(state().itemTiles, hasLength(8));
    await tearDown0(tester);
  });

  testWidgets('첫 던지기에서 낙이 나오면 바로 상대 차례', (tester) async {
    await setUp0(tester);
    notifier().startGameWithConfig(twoHumans);
    notifier().throwYut(forceNak: true);
    expect(state().lastResult, YutResult.nak);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(state().turnIndex, 1);
    expect(state().status, GameStatus.throwing);
    await tearDown0(tester);
  });

  testWidgets('모 → 한 번 더 → 낙: 모는 그대로 써서 말이 5번 칸으로 간다', (tester) async {
    await setUp0(tester, random: alwaysMo());
    notifier().startGameWithConfig(twoHumans);

    notifier().throwYut();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(state().currentThrows, [YutResult.mo]);
    expect(state().status, GameStatus.throwing, reason: '모는 보너스 턴');

    notifier().throwYut(forceNak: true);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(state().status, GameStatus.selectingMal);

    // 말을 고르면 5칸 이동 애니메이션(300ms × 5 + 300ms) 뒤 적용.
    notifier().selectMal(0);
    await tester.pump(const Duration(milliseconds: 1800));
    expect(state().teams[0].mals[0].currentNodeId, 5);
    expect(state().turnIndex, 1);
    await tearDown0(tester);
  });

  testWidgets('전낙 규칙: 모 다음 낙이면 모까지 버리고 턴 종료', (tester) async {
    await setUp0(tester, random: alwaysMo());
    notifier().startGameWithConfig(twoHumans.copyWith(totalNak: true));

    notifier().throwYut();
    await tester.pump(const Duration(milliseconds: 1000));
    notifier().throwYut(forceNak: true);
    await tester.pump(const Duration(milliseconds: 1000));

    expect(state().turnIndex, 1);
    expect(state().currentThrows, isEmpty);
    expect(state().teams[0].mals.every((m) => m.currentNodeId == null), isTrue);
    await tearDown0(tester);
  });

  testWidgets('던지는 중이 아니면 throwYut은 무시된다', (tester) async {
    await setUp0(tester);
    notifier().throwYut();
    expect(state().status, GameStatus.lobby);
    await tearDown0(tester);
  });

  testWidgets('2팀 중 한 팀이 기권하면 남은 팀이 승리', (tester) async {
    await setUp0(tester);
    notifier().startGameWithConfig(twoHumans);
    notifier().forfeit(1);
    expect(state().status, GameStatus.finished);
    expect(state().teams[0].isWinner, isTrue);
    expect(state().teams[1].hasForfeit, isTrue);
    await tearDown0(tester);
  });

  testWidgets('3팀 중 한 팀 기권이면 게임은 계속된다', (tester) async {
    await setUp0(tester);
    notifier().startGameWithConfig(
      twoHumans.copyWith(teamCount: 3, teamControllers: [1, 2, 3]),
    );
    notifier().forfeit(1);
    expect(state().status, GameStatus.throwing);
    expect(state().turnIndex, 2);
    await tearDown0(tester);
  });

  testWidgets('설정 변경은 로비에서 다음 판 설정에도 반영되고 저장된다', (tester) async {
    await setUp0(tester);
    notifier().updateConfig(state().config.copyWith(nakChancePercent: 25));
    expect(state().activeConfig.nakChancePercent, 25);
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('nakChancePercent'), 25);
    await tearDown0(tester);
  });

  testWidgets('CPU끼리 대결하면 사람 입력 없이 끝까지 진행된다', (tester) async {
    await setUp0(tester, random: Random(2026));
    notifier().startGameWithConfig(
      const GameRuleConfig(
        teamControllers: [0, 0],
        malCount: 2,
        useItemMode: true,
      ),
    );
    for (int i = 0; i < 2000 && state().status != GameStatus.finished; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(state().status, GameStatus.finished);
    expect(state().teams.where((t) => t.isWinner), hasLength(1));
    await tearDown0(tester);
  });
}
