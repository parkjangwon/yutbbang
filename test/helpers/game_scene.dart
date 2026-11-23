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

/// 실제 GameNotifier에 원하는 장면을 바로 심을 수 있게 한 테스트용 하위 클래스.
class SeedableGameNotifier extends GameNotifier {
  void seed(GameState s) => state = s;
}

/// 실제 GameNotifier로 특정 장면에서 시작하는 흐름 테스트 하네스.
///
/// `testWidgets` 안에서 쓰고, 타이머는 `tester.pump(Duration)`으로 진행한다.
/// 끝나면 반드시 [finish]를 호출한다.
class GameScene {
  GameScene._(this.container, this.notifier);

  final ProviderContainer container;
  final SeedableGameNotifier notifier;

  GameState get state => container.read(gameProvider);

  static Future<GameScene> start(
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
    final container = ProviderContainer(
      overrides: [
        gameProvider.overrideWith(SeedableGameNotifier.new),
        if (random != null) gameRandomProvider.overrideWithValue(random),
      ],
    );
    container.listen(gameProvider, (_, _) {});
    final notifier =
        container.read(gameProvider.notifier) as SeedableGameNotifier;
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
    return GameScene._(container, notifier);
  }

  /// CPU 차례가 계속 이어질 수 있으므로 먼저 정리하고,
  /// 남은 타이머는 ref.mounted 검사로 무시된다.
  Future<void> finish(WidgetTester tester) async {
    container.dispose();
    await tester.pump(const Duration(seconds: 10));
  }
}

Team withItems(Team t, List<ItemType> items) => t.copyWith(items: items);
