import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/move_resolver.dart';
import 'package:yutbbang/domain/logic/path_finder.dart';
import 'package:yutbbang/domain/models/yut_result.dart';

import '../helpers/fixtures.dart';

const finish = PathFinder.finishNodeId;

void main() {
  group('movableMals', () {
    test('일반 결과는 완주하지 않은 모든 말', () {
      final t = team(0, [null, 3, null], finished: {2});
      final ids = MoveResolver.movableMals(
        t,
        YutResult.gae,
        backDoFlying: false,
      ).map((m) => m.id);
      expect(ids, [0, 1]);
    });

    test('빽도는 판 위의 말만', () {
      final t = team(0, [null, 3]);
      final ids = MoveResolver.movableMals(
        t,
        YutResult.backDo,
        backDoFlying: true,
      ).map((m) => m.id);
      expect(ids, [1]);
    });

    test('판 위에 말이 없으면 빽도 날기일 때만 대기 말', () {
      final t = team(0, [null, null]);
      expect(
        MoveResolver.movableMals(t, YutResult.backDo, backDoFlying: false),
        isEmpty,
      );
      expect(
        MoveResolver.movableMals(t, YutResult.backDo, backDoFlying: true),
        hasLength(2),
      );
    });
  });

  group('isShortcutDecisionPoint', () {
    test('5·10번에서 앞으로 갈 때만 지름길을 묻는다', () {
      final t = team(0, [5, 10, 15, 20]);
      bool ask(int i, YutResult r) =>
          MoveResolver.isShortcutDecisionPoint(t.mals[i], r);
      expect(ask(0, YutResult.do_), isTrue);
      expect(ask(1, YutResult.mo), isTrue);
      expect(ask(0, YutResult.backDo), isFalse);
      expect(ask(2, YutResult.do_), isFalse);
      expect(ask(3, YutResult.do_), isFalse);
    });
  });

  group('planPath', () {
    test('빽도 날기: 대기 말이 빽도로 바로 골인', () {
      final teams = [team(0, [null]), team(1, [null])];
      final p = MoveResolver.planPath(
        teams: teams,
        team: teams[0],
        mal: teams[0].mals[0],
        result: YutResult.backDo,
        backDoFlying: true,
      );
      expect(p, [finish]);
    });

    test('골인 직전 칸(0번)에 상대가 있으면 그 칸에 멈춘다', () {
      final teams = [team(0, [19]), team(1, [0])];
      final p = MoveResolver.planPath(
        teams: teams,
        team: teams[0],
        mal: teams[0].mals[0],
        result: YutResult.do_,
        backDoFlying: false,
      );
      expect(p, [0]);
    });

    test('골인 직전 칸이 비어 있으면 골인', () {
      final teams = [team(0, [19]), team(1, [3])];
      final p = MoveResolver.planPath(
        teams: teams,
        team: teams[0],
        mal: teams[0].mals[0],
        result: YutResult.do_,
        backDoFlying: false,
      );
      expect(p, [0, finish]);
    });
  });

  group('apply', () {
    MoveOutcome move(
      List teams0,
      int malId,
      List<int> path,
      YutResult r, {
      bool autoCarrier = false,
      bool reverse = false,
    }) => MoveResolver.apply(
      teams: teams0.cast(),
      teamIndex: 0,
      malId: malId,
      path: path,
      result: r,
      autoCarrier: autoCarrier,
      isReverse: reverse,
    );

    test('출발 말이 이동하면 위치와 기록이 갱신된다', () {
      final out = move([team(0, [null]), team(1, [null])], 0, [1, 2, 3], YutResult.geol);
      final mal = malOf(out.teams, 0);
      expect(mal.currentNodeId, 3);
      expect(mal.historyNodeIds, [1, 2]);
      expect(out.caughtOpponent, isFalse);
    });

    test('같은 칸의 우리 말은 업혀서 함께 이동한다', () {
      final out = move([team(0, [3, 3, null]), team(1, [null])], 0, [4, 5], YutResult.gae);
      expect(malOf(out.teams, 0).currentNodeId, 5);
      expect(malOf(out.teams, 1).currentNodeId, 5);
      expect(malOf(out.teams, 2).currentNodeId, isNull);
    });

    test('상대 말이 있는 칸에 멈추면 잡는다', () {
      final out = move([team(0, [2]), team(1, [4, 4])], 0, [3, 4], YutResult.gae);
      expect(out.caughtOpponent, isTrue);
      expect(out.caughtHuman, isTrue);
      expect(malOf(out.teams, 10).currentNodeId, isNull);
      expect(malOf(out.teams, 11).currentNodeId, isNull);
      expect(malOf(out.teams, 10).isFinished, isFalse);
    });

    test('지나치기만 한 칸의 상대 말은 잡지 않는다', () {
      final out = move([team(0, [2]), team(1, [3])], 0, [3, 4], YutResult.gae);
      expect(out.caughtOpponent, isFalse);
      expect(malOf(out.teams, 10).currentNodeId, 3);
    });

    test('골인하면 완주 처리된다', () {
      final out = move([team(0, [19]), team(1, [null])], 0, [0, finish], YutResult.do_);
      final mal = malOf(out.teams, 0);
      expect(mal.isFinished, isTrue);
      expect(mal.currentNodeId, isNull);
      expect(out.landingNodeId, 0);
    });

    test('빽도 날기 골인은 상대의 대기·완주 말을 건드리지 않는다 (회귀)', () {
      final teams = [
        team(0, [null]),
        team(1, [null, 7, null], finished: {2}),
      ];
      final out = move(teams, 0, [finish], YutResult.backDo);
      expect(out.caughtOpponent, isFalse);
      expect(malOf(out.teams, 0).isFinished, isTrue);
      expect(malOf(out.teams, 12).isFinished, isTrue);
      expect(malOf(out.teams, 11).currentNodeId, 7);
    });

    test('빽도는 이동 기록을 한 칸 지운다', () {
      final teams = [
        team(0, [3], history: [[1, 2]]),
        team(1, [null]),
      ];
      final out = move(teams, 0, [2], YutResult.backDo);
      final mal = malOf(out.teams, 0);
      expect(mal.currentNodeId, 2);
      expect(mal.historyNodeIds, [1]);
    });

    test('자동 임신: 중앙에 도착하면 대기 말 하나가 합류', () {
      final teams = [team(0, [22, null, null]), team(1, [null])];
      final out = move(teams, 0, [20], YutResult.do_, autoCarrier: true);
      expect(malOf(out.teams, 0).currentNodeId, 20);
      expect(malOf(out.teams, 1).currentNodeId, 20);
      expect(malOf(out.teams, 2).currentNodeId, isNull);
    });

    test('자동 임신 규칙이 꺼져 있으면 합류하지 않는다', () {
      final teams = [team(0, [22, null]), team(1, [null])];
      final out = move(teams, 0, [20], YutResult.do_);
      expect(malOf(out.teams, 1).currentNodeId, isNull);
    });
  });
}
