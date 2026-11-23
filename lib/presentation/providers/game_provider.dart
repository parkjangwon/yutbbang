import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config_repository.dart';
import '../../domain/logic/ai_item_logic.dart';
import '../../domain/logic/ai_logic.dart';
import '../../domain/logic/board_graph.dart';
import '../../domain/logic/gauge_logic.dart';
import '../../domain/logic/item_effects.dart';
import '../../domain/logic/item_tile_generator.dart';
import '../../domain/logic/move_resolver.dart';
import '../../domain/logic/team_list_ops.dart';
import '../../domain/logic/turn_resolver.dart';
import '../../domain/logic/yut_logic.dart';
import '../../domain/models/game_item.dart';
import '../../domain/models/game_rule_config.dart';
import '../../domain/models/team.dart';
import '../../domain/models/yut_result.dart';
import 'game_state.dart';

part 'game_notifier/game_notifier_base.dart';
part 'game_notifier/setup_actions.dart';
part 'game_notifier/throw_actions.dart';
part 'game_notifier/move_actions.dart';
part 'game_notifier/turn_actions.dart';
part 'game_notifier/item_actions.dart';
part 'game_notifier/ai_item_actions.dart';

/// 게임 전반에서 쓰는 난수 생성기. 테스트에서 시드 고정용으로 override 한다.
final gameRandomProvider = Provider<Random>((ref) => Random());

/// 글로벌 설정 저장소. 테스트에서 override 할 수 있다.
final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => const ConfigRepository(),
);

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);

/// 윷놀이 게임 상태 머신.
///
/// 기능별로 part 파일에 나뉘어 있다.
/// - [_SetupActions] 설정 저장·게임 시작
/// - [_ThrowActions] 윷 던지기·게이지·다시 던지기
/// - [_MoveActions] 말 선택·지름길·뒷걸음질·이동
/// - [_TurnActions] 턴 넘기기·기권
/// - [_ItemActions] 아이템 획득·사용
/// - [_AiItemActions] CPU 아이템 사용
class GameNotifier extends _GameNotifierBase
    with
        _SetupActions,
        _ThrowActions,
        _MoveActions,
        _TurnActions,
        _ItemActions,
        _AiItemActions {
  @override
  GameState build() {
    ref.onDispose(_cancelGauge);
    _loadConfig();
    const config = GameRuleConfig();
    return _SetupActions._buildInitialState(config, config);
  }
}
