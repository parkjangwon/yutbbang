Vector2 _getStartOffset(TeamColor color) {
  // 보드 크기에 비례하는 간격 사용
  if (parent == null || parent is! BoardComponent) {
    return Vector2.zero();
  }
  final board = parent as BoardComponent;
  final gap = board.size.x * 0.08; // 보드 너비의 8%

  switch (color) {
    case TeamColor.orange:
      return Vector2(-gap, 0);
    case TeamColor.green:
      return Vector2(gap, 0);
    case TeamColor.red:
      return Vector2(-gap, gap * 1.5);
    case TeamColor.blue:
      return Vector2(gap, gap * 1.5);
  }
}

Vector2 _getStartOffsetVertical(TeamColor color) {
  // 화면 우측에 팀별로 세로 정렬
  final gameHeight = gameRef.size.y;
  final topMargin = gameHeight * 0.15; // 상단 여백 (X 버튼 아래)
  final spacing = size.y * 1.3; // 말 사이 간격

  double yPos;
  switch (color) {
    case TeamColor.orange:
      yPos = topMargin;
      break;
    case TeamColor.green:
      yPos = topMargin + spacing;
      break;
    case TeamColor.red:
      yPos = topMargin + spacing * 2;
      break;
    case TeamColor.blue:
      yPos = topMargin + spacing * 3;
      break;
  }

  return Vector2(0, yPos);
}
