import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/domain/models/team.dart';
import 'package:yutbbang/presentation/widgets/game/team_colors.dart';

void main() {
  test('팀 색 이름은 실제 팔레트 색과 맞는다', () {
    expect(TeamColor.values.map(teamColorNameOf), ['주황', '초록', '자주', '파랑']);
  });
}
