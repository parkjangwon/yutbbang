class BoardNode {
  final int id;
  final double x; // 0.0 to 1.0
  final double y; // 0.0 to 1.0
  final int? nextId;
  final int? shortcutNextId;
  final int? prevId;

  const BoardNode({
    required this.id,
    required this.x,
    required this.y,
    this.nextId,
    this.shortcutNextId,
    this.prevId,
  });

  BoardNode copyWithShortcut(int shortcutId) {
    return BoardNode(
      id: id,
      x: x,
      y: y,
      nextId: nextId,
      shortcutNextId: shortcutId,
      prevId: prevId,
    );
  }
}

class BoardGraph {
  static final Map<int, BoardNode> nodes = _buildNodes();

  static Map<int, BoardNode> _buildNodes() {
    final map = <int, BoardNode>{};

    // --- Counter-Clockwise Path ---
    // 0: Bottom-Right (Start/Finish)
    // 1-4: Right edge (Upward)
    // 5: Top-Right (Corner)
    // 6-9: Top edge (Leftward)
    // 10: Top-Left (Corner)
    // 11-14: Left edge (Downward)
    // 15: Bottom-Left (Corner)
    // 16-19: Bottom edge (Rightward back to 0)

    // Right Edge: 0(1,1) -> 5(1,0)
    for (int i = 0; i < 5; i++) {
      map[i] = BoardNode(
        id: i,
        x: 1.0,
        y: 1.0 - (i * 0.2),
        nextId: i + 1,
        prevId: i == 0 ? 19 : i - 1,
      );
    }
    map[5] = const BoardNode(id: 5, x: 1.0, y: 0.0, nextId: 6, prevId: 4);

    // Top Edge: 5(1,0) -> 10(0,0)
    for (int i = 6; i < 10; i++) {
      map[i] = BoardNode(
        id: i,
        x: 1.0 - ((i - 5) * 0.2),
        y: 0.0,
        nextId: i + 1,
        prevId: i - 1,
      );
    }
    map[10] = const BoardNode(id: 10, x: 0.0, y: 0.0, nextId: 11, prevId: 9);

    // Left Edge: 10(0,0) -> 15(0,1)
    for (int i = 11; i < 15; i++) {
      map[i] = BoardNode(
        id: i,
        x: 0.0,
        y: (i - 10) * 0.2,
        nextId: i + 1,
        prevId: i - 1,
      );
    }
    map[15] = const BoardNode(id: 15, x: 0.0, y: 1.0, nextId: 16, prevId: 14);

    // Bottom Edge: 15(0,1) -> 19(0.8, 1)
    for (int i = 16; i < 20; i++) {
      map[i] = BoardNode(
        id: i,
        x: (i - 15) * 0.2,
        y: 1.0,
        nextId: i == 19 ? 0 : i + 1,
        prevId: i - 1,
      );
    }

    // Fix Node 0 prev
    map[0] = const BoardNode(id: 0, x: 1.0, y: 1.0, nextId: 1, prevId: 19);

    // --- Diagonals (Shortcuts) ---
    // Shortcut 5 (Top-Right) to 15 (Bottom-Left)
    // 5 -> 21 -> 22 -> 20 (Center) -> 23 -> 24 -> 15
    map[21] = const BoardNode(id: 21, x: 0.8, y: 0.2, nextId: 22, prevId: 5);
    map[22] = const BoardNode(id: 22, x: 0.65, y: 0.35, nextId: 20, prevId: 21);
    map[20] = const BoardNode(
      id: 20,
      x: 0.5,
      y: 0.5,
      nextId: 27, // 기본 경로를 완주 방향(27번)으로 설정
      prevId: 22,
    ); // Center
    map[23] = const BoardNode(id: 23, x: 0.35, y: 0.65, nextId: 24, prevId: 20);
    map[24] = const BoardNode(id: 24, x: 0.2, y: 0.8, nextId: 15, prevId: 23);

    // Shortcut 10 (Top-Left) to 0 (Bottom-Right)
    // 10 -> 25 -> 26 -> 20 (Center) -> 27 -> 28 -> 0
    map[25] = const BoardNode(id: 25, x: 0.2, y: 0.2, nextId: 26, prevId: 10);
    map[26] = const BoardNode(id: 26, x: 0.35, y: 0.35, nextId: 20, prevId: 25);
    // Note: Node 20 is already defined, but it needs logic to pick 27 or 23 depending on where it came from
    // We update its shortcut id later.

    map[27] = const BoardNode(id: 27, x: 0.65, y: 0.65, nextId: 28, prevId: 20);
    map[28] = const BoardNode(id: 28, x: 0.8, y: 0.8, nextId: 0, prevId: 27);

    // Apply Shortcuts
    map[5] = map[5]!.copyWithShortcut(21);
    map[10] = map[10]!.copyWithShortcut(25);
    // 규칙: 중앙(20번)에 멈추면 다음 이동은 선택 없이 무조건 완주 방향(27번)으로 고정함.
    // 기존 shortcutNextId였던 23번(좌하단 방향)은 이제 선택지로 제공되지 않음.
    map[20] = map[20]!.copyWithShortcut(23);

    return map;
  }
}
