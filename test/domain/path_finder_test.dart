import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/logic/path_finder.dart';
import 'package:yutbbang/domain/models/yut_result.dart';

const start = PathFinder.startNodeId;
const finish = PathFinder.finishNodeId;

List<int> path(
  int from,
  YutResult r, {
  bool shortcut = false,
  List<int>? history,
  bool reverse = false,
}) => PathFinder.calculatePath(
  from,
  r,
  useShortcut: shortcut,
  previousNodeIds: history,
  isReverse: reverse,
);

void main() {
  group('출발', () {
    test('대기 말이 도를 내면 1번 칸', () {
      expect(path(start, YutResult.do_), [1]);
    });

    test('대기 말이 모를 내면 첫 꼭짓점(5)까지', () {
      expect(path(start, YutResult.mo), [1, 2, 3, 4, 5]);
    });

    test('낙은 움직이지 않는다', () {
      expect(path(3, YutResult.nak), isEmpty);
    });

    test('대기 말은 빽도로 움직일 수 없다', () {
      expect(path(start, YutResult.backDo), isEmpty);
    });
  });

  group('지름길', () {
    test('첫 꼭짓점에서 지름길을 타면 대각선으로 들어간다', () {
      expect(path(5, YutResult.gae, shortcut: true), [21, 22]);
    });

    test('첫 꼭짓점에서 지름길을 안 타면 둘레를 따라간다', () {
      expect(path(5, YutResult.gae), [6, 7]);
    });

    test('첫 꼭짓점 대각선은 중앙을 지나 15번 방향으로 직진한다', () {
      expect(path(5, YutResult.mo, shortcut: true), [21, 22, 20, 23, 24]);
    });

    test('둘째 꼭짓점 대각선은 중앙을 지나 골인 방향으로 직진한다', () {
      expect(path(10, YutResult.mo, shortcut: true), [25, 26, 20, 27, 28]);
    });

    test('중앙을 첫 걸음으로 지나칠 때도 들어온 방향을 유지한다', () {
      expect(path(22, YutResult.geol), [20, 23, 24]);
      expect(path(26, YutResult.geol), [20, 27, 28]);
    });

    test('중앙에 멈췄다가 출발하면 항상 골인 방향(27)', () {
      expect(path(20, YutResult.gae), [27, 28]);
    });

    test('세 번째 꼭짓점(15)은 둘레를 따라 직진', () {
      expect(path(15, YutResult.do_), [16]);
    });
  });

  group('골인', () {
    test('19번에서 도가 나오면 0번을 밟고 골인', () {
      expect(path(19, YutResult.do_), [0, finish]);
    });

    test('0번을 지나치는 이동도 골인', () {
      expect(path(18, YutResult.geol), [19, 0, finish]);
    });

    test('대각선 끝(28)에서도 골인', () {
      expect(path(28, YutResult.do_), [0, finish]);
    });
  });

  group('뒤로 가기', () {
    test('빽도는 이동 기록을 따라 한 칸 되돌아간다', () {
      expect(path(3, YutResult.backDo, history: [1, 2]), [2]);
    });

    test('기록이 대각선이면 대각선으로 되돌아간다', () {
      expect(path(22, YutResult.backDo, history: [1, 2, 3, 4, 5, 21]), [21]);
    });

    test('뒷걸음질(isReverse)은 결과 칸 수만큼 기록을 거슬러 간다', () {
      expect(path(5, YutResult.geol, history: [1, 2, 3, 4], reverse: true), [
        4,
        3,
        2,
      ]);
    });

    test('기록이 없으면 이전 칸(prevId)으로 간다', () {
      expect(path(7, YutResult.backDo), [6]);
    });
  });
}
