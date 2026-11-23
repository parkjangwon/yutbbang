import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/team.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_provider.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';

import '../helpers/fixtures.dart';

/// 실제 GameNotifier에 원하는 장면을 바로 심을 수 있게 한 테스트용 하위 클래스.
class SeedableGameNotifier extends GameNotifier {
  void seed(GameState s) => state = s;
}

void main() {
  late ProviderContainer container;
  late SeedableGameNotifier notifier;
  GameState state() => container.read(gameProvider);

  Future<void> setUpScene(
    WidgetTester tester,
    List<Team> teams, {
    GameStatus status = GameStatus.throwing,
    List<YutResult> throws = const [],
    GameRuleConfig rules = const GameRuleConfig(nakChancePercent: 0),
    Set<int> itemTiles = const {},
    Random? random,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    container = ProviderContainer(
      overrides: [
        gameProvider.overrideWith(SeedableGameNotifier.new),
        if (random != null) gameRandomProvider.overrideWithValue(random),
      ],
    );
    container.listen(gameProvider, (_, _) {});
    notifier = container.read(gameProvider.notifier) as SeedableGameNotifier;
    await tester.pump();
    notifier.seed(
      GameState(
        config: rules,
        activeConfig: rules,
        teams: teams,
        status: status,
        currentThrows: throws,
        itemTiles: itemTiles,
      ),
    );
  }

  Future<void> finish(WidgetTester tester) async {
    // CPU 차례가 계속 이어질 수 있으므로 먼저 정리하고, 남은 타이머는 ref.mounted 검사로 무시된다.
    container.dispose();
    await tester.pump(const Duration(seconds: 10));
  }

  Team withItems(Team t, List<ItemType> items) => t.copyWith(items: items);

  group('지름길', () {
    testWidgets('첫 꼭짓점의 말을 고르면 지름길을 묻고, 고르면 대각선으로 간다', (tester) async {
      await setUpScene(
        tester,
        [
          team(0, [5]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.geol],
      );
      notifier.selectMal(0);
      expect(state().status, GameStatus.awaitingShortcutDecision);

      notifier.chooseShortcut(true);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(state().teams[0].mals[0].currentNodeId, 20);
      await finish(tester);
    });

    testWidgets('지름길을 거절하면 둘레를 따라간다', (tester) async {
      await setUpScene(
        tester,
        [
          team(0, [5]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.geol],
      );
      notifier.selectMal(0);
      notifier.chooseShortcut(false);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(state().teams[0].mals[0].currentNodeId, 8);
      await finish(tester);
    });

    testWidgets('군밤 모드면 묻지 않고 지름길', (tester) async {
      await setUpScene(
        tester,
        [
          team(0, [10]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.gae],
        rules: const GameRuleConfig(roastedChestnutMode: true),
      );
      notifier.selectMal(0);
      expect(state().status, GameStatus.moving);
      await tester.pump(const Duration(milliseconds: 900));
      expect(state().teams[0].mals[0].currentNodeId, 26);
      await finish(tester);
    });
  });

  group('뒷걸음질', () {
    testWidgets('도·개·걸로 판 위 말을 고르면 방향을 묻고, 쓰면 뒤로 간다', (tester) async {
      await setUpScene(
        tester,
        [
          withItems(
            team(
              0,
              [4],
              history: [
                [1, 2, 3],
              ],
            ),
            [ItemType.moonwalk],
          ),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.gae],
      );
      notifier.selectMal(0);
      expect(state().showMoonwalkChoice, isTrue);

      notifier.confirmMoonwalk(true);
      await tester.pump(const Duration(milliseconds: 900));
      expect(state().teams[0].mals[0].currentNodeId, 2);
      expect(state().teams[0].items, isEmpty);
      await finish(tester);
    });

    testWidgets('쓰지 않으면 아이템은 남고 앞으로 간다', (tester) async {
      await setUpScene(
        tester,
        [
          withItems(
            team(
              0,
              [4],
              history: [
                [1, 2, 3],
              ],
            ),
            [ItemType.moonwalk],
          ),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.gae],
      );
      notifier.selectMal(0);
      notifier.confirmMoonwalk(false);
      await tester.pump(const Duration(milliseconds: 900));
      expect(state().teams[0].mals[0].currentNodeId, 6);
      expect(state().teams[0].items, [ItemType.moonwalk]);
      await finish(tester);
    });
  });

  group('아이템 사용', () {
    testWidgets('얼음탄: 다음 팀을 얼리고 아이템을 소모', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [null]), [ItemType.freeze]),
        team(1, [null], isHuman: false),
      ]);
      notifier.useItem(ItemType.freeze);
      expect(state().teams[1].skipNextTurn, isTrue);
      expect(state().teams[0].items, isEmpty);
      await finish(tester);
    });

    testWidgets('자석: 잡을 말이 없으면 안내만 하고 아이템은 남는다', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [2]), [ItemType.magnet]),
        team(1, [15], isHuman: false),
      ]);
      notifier.useItem(ItemType.magnet);
      expect(state().itemMessage, '주변에 잡을 상대 말이 없습니다.');
      expect(state().teams[0].items, [ItemType.magnet]);
      await finish(tester);
    });

    testWidgets('강제 귀가권: 대상 선택 → 상대 말이 출발점으로', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [2]), [ItemType.banish]),
        team(1, [12], isHuman: false),
      ]);
      notifier.useItem(ItemType.banish);
      expect(state().status, GameStatus.awaitingBanishTarget);

      notifier.handleMalSelectionForItem(0); // 내 말은 대상이 아니다
      expect(state().status, GameStatus.awaitingBanishTarget);

      notifier.handleMalSelectionForItem(10);
      expect(state().teams[1].mals[0].currentNodeId, isNull);
      expect(state().status, GameStatus.throwing);
      await finish(tester);
    });

    testWidgets('위치 교환: 내 말 → 상대 말 순서로 골라 자리를 바꾼다', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [2]), [ItemType.swap]),
        team(1, [24], isHuman: false),
      ]);
      notifier.useItem(ItemType.swap);
      notifier.handleMalSelectionForItem(0);
      expect(state().status, GameStatus.awaitingSwapTarget);
      notifier.handleMalSelectionForItem(10);
      expect(state().teams[0].mals[0].currentNodeId, 24);
      expect(state().teams[1].mals[0].currentNodeId, 2);
      expect(state().status, GameStatus.throwing);
      await finish(tester);
    });

    testWidgets('황금 윷: 다음 던지기는 윷 또는 모', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [null]), [ItemType.fixedDice]),
        team(1, [null], isHuman: false),
      ]);
      notifier.useItem(ItemType.fixedDice);
      expect(state().isFixedDiceActive, isTrue);
      notifier.throwYut();
      expect(state().lastResult, anyOf(YutResult.yut, YutResult.mo));
      expect(state().isFixedDiceActive, isFalse);
      await finish(tester);
    });

    testWidgets('자동 발동 아이템은 가방에서 직접 쓸 수 없다', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [3]), [ItemType.shield, ItemType.moonwalk]),
        team(1, [null], isHuman: false),
      ]);
      notifier.useItem(ItemType.shield);
      notifier.useItem(ItemType.moonwalk);
      expect(state().teams[0].items, [ItemType.shield, ItemType.moonwalk]);
      await finish(tester);
    });

    testWidgets('낙 방지권: 낙이 나오면 자동으로 도가 된다', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [null]), [ItemType.shield]),
        team(1, [null], isHuman: false),
      ]);
      notifier.throwYut(forceNak: true);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(state().currentThrows, [YutResult.do_]);
      expect(state().teams[0].items, isEmpty);
      await finish(tester);
    });

    testWidgets('다시 던지기: 사람에게 묻고, 쓰면 다시 던지기 단계로', (tester) async {
      await setUpScene(tester, [
        withItems(team(0, [null]), [ItemType.reroll]),
        team(1, [null], isHuman: false),
      ]);
      notifier.throwYut(forceNak: true);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(state().showRerollChoice, isTrue);
      notifier.confirmReroll(true);
      expect(state().status, GameStatus.throwing);
      expect(state().teams[0].items, isEmpty);
      await finish(tester);
    });
  });

  group('아이템 획득', () {
    testWidgets('선물 상자 칸에 멈추면 아이템을 얻고 상자가 사라진다', (tester) async {
      await setUpScene(
        tester,
        [
          team(0, [1]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.do_],
        rules: const GameRuleConfig(useItemMode: true),
        itemTiles: {2, 9},
        random: FakeRandom(ints: [6]), // allItems[6] = 얼음탄
      );
      notifier.selectMal(0);
      await tester.pump(const Duration(milliseconds: 700));
      expect(state().teams[0].items, [ItemType.freeze]);
      expect(state().itemTiles, {9});
      expect(state().justAcquiredItem, ItemType.freeze);
      await finish(tester);
    });

    testWidgets('가방이 꽉 차면 교체 여부를 묻고, 교체하면 상자가 사라진다', (tester) async {
      await setUpScene(
        tester,
        [
          withItems(team(0, [1]), [ItemType.magnet, ItemType.swap]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.do_],
        rules: const GameRuleConfig(useItemMode: true),
        itemTiles: {2},
        random: FakeRandom(ints: [6]),
      );
      notifier.selectMal(0);
      await tester.pump(const Duration(milliseconds: 700));
      expect(state().showItemChoice, isTrue);

      notifier.replaceItem(1, 2, teamIndex: 0);
      expect(state().teams[0].items, [ItemType.magnet, ItemType.freeze]);
      expect(state().itemTiles, isEmpty);
      expect(state().showItemChoice, isFalse);
      await finish(tester);
    });

    testWidgets('새 아이템을 포기하면 상자는 칸에 남는다', (tester) async {
      await setUpScene(
        tester,
        [
          withItems(team(0, [1]), [ItemType.magnet, ItemType.swap]),
          team(1, [null], isHuman: false),
        ],
        status: GameStatus.selectingMal,
        throws: [YutResult.do_],
        rules: const GameRuleConfig(useItemMode: true),
        itemTiles: {2},
      );
      notifier.selectMal(0);
      await tester.pump(const Duration(milliseconds: 700));
      notifier.discardPendingItem();
      expect(state().teams[0].items, [ItemType.magnet, ItemType.swap]);
      expect(state().itemTiles, {2});
      await finish(tester);
    });
  });

  group('컨트롤 모드 게이지', () {
    testWidgets('누르면 게이지가 움직이고, 떼면 던진다', (tester) async {
      await setUpScene(
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
      notifier.startGauge();
      expect(state().isGaugeRunning, isTrue);
      expect(state().nakZones, hasLength(3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(state().gaugeValue, greaterThan(0));

      notifier.stopGauge();
      expect(state().isGaugeRunning, isFalse);
      expect(state().lastResult, isNotNull);
      await finish(tester);
    });
  });
}
