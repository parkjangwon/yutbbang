import '../models/team.dart';

/// 불변 팀 리스트를 다루는 헬퍼.
extension TeamListOps on List<Team> {
  /// [index] 번째 팀만 [transform] 결과로 바꾼 새 리스트.
  List<Team> updatedAt(int index, Team Function(Team team) transform) {
    final next = List<Team>.from(this);
    next[index] = transform(next[index]);
    return next;
  }

  /// 말 id로 소속 팀 인덱스를 찾는다. 없으면 -1.
  int teamIndexOfMal(int malId) =>
      indexWhere((t) => t.mals.any((m) => m.id == malId));

  /// [teamIndex] 팀이 아닌 팀들 중 판 위에 말이 있는 팀이 있는지.
  bool hasOpponentOnBoard(int teamIndex) {
    for (int i = 0; i < length; i++) {
      if (i != teamIndex && this[i].hasMalOnBoard) return true;
    }
    return false;
  }
}
