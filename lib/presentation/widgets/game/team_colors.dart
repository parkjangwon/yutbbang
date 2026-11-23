import 'package:material_ui/material_ui.dart';

import '../../../domain/models/team.dart';
import '../../theme/app_palette.dart';

/// 팀 색상 → UI 색상(모던 미니멀 팔레트).
Color teamColorOf(TeamColor color) => switch (color) {
  TeamColor.orange => AppPalette.terracotta,
  TeamColor.green => AppPalette.sage,
  TeamColor.red => AppPalette.berry,
  TeamColor.blue => AppPalette.slate,
};

/// 팀 색상의 어두운 변형(말 그림자 레이어용).
Color darkerTeamColorOf(TeamColor color) =>
    Color.lerp(teamColorOf(color), Colors.black, 0.25)!;

/// 팀 색상의 옅은 변형(카드 바탕용).
Color softTeamColorOf(TeamColor color) =>
    Color.lerp(teamColorOf(color), Colors.white, 0.82)!;

/// 화면에 보이는 팀 색 이름(실제 팔레트 색 기준).
String teamColorNameOf(TeamColor color) => switch (color) {
  TeamColor.orange => '주황',
  TeamColor.green => '초록',
  TeamColor.red => '자주',
  TeamColor.blue => '파랑',
};
