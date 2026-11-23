import 'package:material_ui/material_ui.dart';

/// 모던 미니멀 테마 색. 따뜻한 아이보리 바탕에 테라코타·세이지 파스텔.
abstract final class AppPalette {
  // 바탕
  static const background = Color(0xFFF7F1EA);
  static const surface = Color(0xFFFFFDFA);
  static const surfaceSunken = Color(0xFFF1E8DD);
  static const line = Color(0xFFE6DACB);

  // 글자
  static const ink = Color(0xFF4A3B30);
  static const inkMuted = Color(0xFF7A6858);

  // 팀 (흰 글자 3:1 이상, 서로 구분되게)
  static const terracotta = Color(0xFFC0603C);
  static const sage = Color(0xFF5E8A5A);
  static const berry = Color(0xFF9E4F78);
  static const slate = Color(0xFF5A7BA0);

  // 행동
  static const throwButton = Color(0xFFC9693A);
  static const danger = Color(0xFFB84A48);
  static const highlight = Color(0xFFE59A4F);

  // 윷판
  static const boardSurface = Color(0xFFFBF6EF);
  static const boardLine = Color(0xFFC9B4A1);
  static const nodeFill = Color(0xFFFFFFFF);
  static const nodeBorder = Color(0xFFB7A08C);
  static const majorNodeFill = Color(0xFFF6DFC2);
  static const majorNodeBorder = Color(0xFFD4B08B);

  // 배지
  static const sageSoft = Color(0xFFDCE6D6);
  static const terracottaSoft = Color(0xFFF5DDCF);

  static const cardShadow = [
    BoxShadow(color: Color(0x1A4A3B30), blurRadius: 18, offset: Offset(0, 6)),
  ];
}
