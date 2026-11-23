import 'dart:math';
import 'dart:ui';

import '../domain/logic/board_graph.dart';

/// 화면 크기에 따른 윷판 배치 계산. 모든 좌표는 판의 왼쪽 위 기준.
class BoardLayout {
  static const double boardRatio = 0.85;
  static const double paddingRatio = 0.1;
  static const double majorNodeRatio = 0.05;
  static const double minorNodeRatio = 0.035;

  /// 판 밖 대기 위치를 화면 아래로 얼마나 내릴지(말이 아래에서 날아오는 연출).
  static const double homeDropOffset = 300;

  /// 판이 이 크기보다 작으면 아직 레이아웃 전으로 본다.
  static const double minReadySide = 100;

  static const Set<int> _majorNodes = {0, 5, 10, 15, 20};

  final Size screen;

  const BoardLayout(this.screen);

  double get boardSide => min(screen.width, screen.height) * boardRatio;

  Offset get boardOrigin =>
      Offset((screen.width - boardSide) / 2, (screen.height - boardSide) / 2);

  bool get isReady => boardSide > minReadySide;

  /// 꼭짓점과 중앙(큰 원).
  static bool isMajorNode(int nodeId) => _majorNodes.contains(nodeId);

  Offset nodeOffset(double nx, double ny) {
    final padding = boardSide * paddingRatio;
    final available = boardSide - 2 * padding;
    return Offset(padding + nx * available, padding + ny * available);
  }

  Offset? nodeOffsetById(int nodeId) {
    final node = BoardGraph.nodes[nodeId];
    return node == null ? null : nodeOffset(node.x, node.y);
  }

  double nodeRadius(int nodeId) =>
      boardSide * (isMajorNode(nodeId) ? majorNodeRatio : minorNodeRatio);

  /// 대기·완주 말이 머무는 판 밖 위치. 하단 대기 패널처럼 팀 수로 화면을 나눈다.
  Offset homeOffset({required int teamIndex, required int teamCount}) {
    final sectionWidth = screen.width / (teamCount > 0 ? teamCount : 4);
    final screenPoint = Offset(
      sectionWidth * (teamIndex + 0.5),
      screen.height + homeDropOffset,
    );
    return screenPoint - boardOrigin;
  }
}
