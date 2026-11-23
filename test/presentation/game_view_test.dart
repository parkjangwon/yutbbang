import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/game_rule_config.dart';
import 'package:yutbbang/domain/models/team.dart';
import 'package:yutbbang/domain/models/yut_result.dart';
import 'package:yutbbang/presentation/providers/game_state.dart';
import 'package:yutbbang/presentation/providers/game_view.dart';

import '../helpers/fixtures.dart';

GameState stateOf(
  GameStatus status, {
  bool humanTurn = true,
  List<Team>? teams,
  List<YutResult> throws = const [],
  YutResult? lastResult,
}) {
  return GameState(
    config: const GameRuleConfig(),
    activeConfig: const GameRuleConfig(),
    teams:
        teams ??
        [
          team(0, [3, null], isHuman: humanTurn),
          team(1, [7]),
        ],
    status: status,
    currentThrows: throws,
    lastResult: lastResult,
  );
}

void main() {
  group('버튼·패널 표시', () {
    test('던지기 버튼은 사람 차례의 던지기 단계에서만', () {
      expect(stateOf(GameStatus.throwing).canHumanThrow, isTrue);
      expect(
        stateOf(GameStatus.throwing, humanTurn: false).canHumanThrow,
        isFalse,
      );
      expect(stateOf(GameStatus.selectingMal).canHumanThrow, isFalse);
    });

    test('지름길 선택 패널은 사람 차례의 지름길 결정 단계에서만', () {
      expect(
        stateOf(GameStatus.awaitingShortcutDecision).showShortcutChoice,
        isTrue,
      );
      expect(
        stateOf(
          GameStatus.awaitingShortcutDecision,
          humanTurn: false,
        ).showShortcutChoice,
        isFalse,
      );
    });

    test('기권 버튼은 사람 차례이고 게임이 끝나지 않았을 때', () {
      expect(stateOf(GameStatus.moving).showForfeitButton, isTrue);
      expect(stateOf(GameStatus.finished).showForfeitButton, isFalse);
      expect(
        stateOf(GameStatus.moving, humanTurn: false).showForfeitButton,
        isFalse,
      );
    });

    test('윷 표시는 던지기·말 선택·이동 중에만 보인다', () {
      for (final s in GameStatus.values) {
        final visible = {
          GameStatus.throwing,
          GameStatus.selectingMal,
          GameStatus.moving,
        }.contains(s);
        expect(stateOf(s).isYutDisplayVisible, visible, reason: '$s');
      }
    });
  });

  group('말 탭', () {
    test('사람 차례 말 선택 단계에서 내 말을 누르면 선택', () {
      final s = stateOf(GameStatus.selectingMal);
      expect(s.malTapAction(s.teams[0].mals[0]), MalTapAction.select);
    });

    test('상대 말이나 CPU 차례에는 아무 일도 없다', () {
      final s = stateOf(GameStatus.selectingMal);
      expect(s.malTapAction(s.teams[1].mals[0]), MalTapAction.none);
      final cpu = stateOf(GameStatus.selectingMal, humanTurn: false);
      expect(cpu.malTapAction(cpu.teams[0].mals[0]), MalTapAction.none);
    });

    test('아이템 대상 선택 중에는 어느 팀 말이든 아이템 대상으로 넘긴다', () {
      for (final status in [
        GameStatus.awaitingBanishTarget,
        GameStatus.awaitingSwapSource,
        GameStatus.awaitingSwapTarget,
      ]) {
        final s = stateOf(status);
        expect(s.malTapAction(s.teams[1].mals[0]), MalTapAction.itemTarget);
      }
    });

    test('완주한 말은 누를 수 없다', () {
      final s = stateOf(
        GameStatus.selectingMal,
        teams: [
          team(0, [null], finished: {0}),
          team(1, [7]),
        ],
      );
      expect(s.malTapAction(s.teams[0].mals[0]), MalTapAction.none);
    });

    test('선택 가능한 내 말만 강조 표시', () {
      final s = stateOf(GameStatus.selectingMal);
      expect(s.isMalHighlighted(s.teams[0].mals[0]), isTrue);
      expect(s.isMalHighlighted(s.teams[1].mals[0]), isFalse);
      expect(
        stateOf(GameStatus.throwing).isMalHighlighted(s.teams[0].mals[0]),
        isFalse,
      );
    });
  });

  group('대기 말 패널', () {
    test('사람 차례 말 선택 단계의 현재 팀만 누를 수 있다', () {
      final s = stateOf(GameStatus.selectingMal);
      expect(s.canSelectWaitingMals(s.teams[0]), isTrue);
      expect(s.canSelectWaitingMals(s.teams[1]), isFalse);
    });

    test('CPU가 말을 고르는 중에는 누를 수 없다 (회귀)', () {
      final s = stateOf(GameStatus.selectingMal, humanTurn: false);
      expect(s.canSelectWaitingMals(s.teams[0]), isFalse);
    });
  });

  group('업힌 말 수', () {
    test('판 위에서는 같은 칸의 우리 팀 말 수', () {
      final s = stateOf(
        GameStatus.throwing,
        teams: [
          team(0, [4, 4, 9]),
          team(1, [4]),
        ],
      );
      expect(s.stackCountOf(s.teams[0].mals[0]), 2);
      expect(s.stackCountOf(s.teams[0].mals[2]), 1);
    });

    test('대기 말은 대기 중인 우리 팀 말 수, 완주 말은 1', () {
      final s = stateOf(
        GameStatus.throwing,
        teams: [
          team(0, [null, null, null], finished: {2}),
          team(1, [4]),
        ],
      );
      expect(s.stackCountOf(s.teams[0].mals[0]), 2);
      expect(s.stackCountOf(s.teams[0].mals[2]), 1);
    });
  });

  group('상단 안내 문구', () {
    test('아무 결과도 없고 선택 단계도 아니면 둘 다 없음', () {
      final lines = stateOf(GameStatus.throwing).statusLines;
      expect(lines.result, isNull);
      expect(lines.guide, isNull);
    });

    test('쌓인 결과를 순서대로 보여주고 말 선택을 안내', () {
      final lines = stateOf(
        GameStatus.selectingMal,
        throws: [YutResult.yut, YutResult.gae],
        lastResult: YutResult.gae,
      ).statusLines;
      expect(lines.result, '결과: 윷, 개');
      expect(lines.guide, '움직일 말을 선택하세요');
    });

    test('방금 나온 결과가 아직 쌓이지 않았으면 뒤에 붙인다', () {
      final lines = stateOf(
        GameStatus.throwing,
        throws: [YutResult.mo],
        lastResult: YutResult.nak,
      ).statusLines;
      expect(lines.result, '결과: 모, 낙');
    });

    test('이동 중에는 결과를 숨긴다', () {
      final lines = stateOf(
        GameStatus.moving,
        lastResult: YutResult.do_,
      ).statusLines;
      expect(lines.result, isNull);
    });

    test('지름길 결정 단계 안내', () {
      final lines = stateOf(GameStatus.awaitingShortcutDecision).statusLines;
      expect(lines.guide, '지름길을 선택하세요');
    });
  });
}
