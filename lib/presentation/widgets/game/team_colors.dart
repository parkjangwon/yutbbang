import 'package:material_ui/material_ui.dart';

import '../../../domain/models/team.dart';

/// 팀 색상 → UI 색상.
Color teamColorOf(TeamColor color) {
  switch (color) {
    case TeamColor.orange:
      return Colors.orange;
    case TeamColor.green:
      return Colors.green;
    case TeamColor.red:
      return Colors.red;
    case TeamColor.blue:
      return Colors.blue;
  }
}

/// 팀 색상의 어두운 변형(말 그림자 레이어용).
Color darkerTeamColorOf(TeamColor color) {
  switch (color) {
    case TeamColor.orange:
      return Colors.orange.shade800;
    case TeamColor.green:
      return Colors.green.shade800;
    case TeamColor.red:
      return Colors.red.shade800;
    case TeamColor.blue:
      return Colors.blue.shade800;
  }
}
