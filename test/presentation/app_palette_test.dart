import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yutbbang/domain/models/team.dart';
import 'package:yutbbang/presentation/theme/app_palette.dart';
import 'package:yutbbang/presentation/widgets/game/team_colors.dart';

/// WCAG 2.1 대비율.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

double distance(Color a, Color b) {
  final dr = (a.r - b.r) * 255, dg = (a.g - b.g) * 255, db = (a.b - b.b) * 255;
  return sqrt(dr * dr + dg * dg + db * db);
}

void main() {
  test('본문 글자는 배경·카드 위에서 4.5:1 이상', () {
    expect(
      contrast(AppPalette.ink, AppPalette.background),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppPalette.ink, AppPalette.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppPalette.inkMuted, AppPalette.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('팀 색은 모던 미니멀 팔레트를 쓰고 서로 충분히 다르다', () {
    final colors = TeamColor.values.map(teamColorOf).toList();
    expect(colors.first, AppPalette.terracotta);
    expect(colors[1], AppPalette.sage);
    for (int i = 0; i < colors.length; i++) {
      for (int j = i + 1; j < colors.length; j++) {
        expect(
          distance(colors[i], colors[j]),
          greaterThan(60),
          reason: '$i vs $j',
        );
      }
    }
  });

  test('말 위 흰 팀 글자는 큰 글자 기준 3:1 이상', () {
    for (final c in TeamColor.values) {
      expect(
        contrast(Colors.white, teamColorOf(c)),
        greaterThanOrEqualTo(3),
        reason: '$c',
      );
    }
  });

  test('주요 버튼(던지기·기권) 위 흰 글자도 3:1 이상', () {
    expect(
      contrast(Colors.white, AppPalette.throwButton),
      greaterThanOrEqualTo(3),
    );
    expect(contrast(Colors.white, AppPalette.danger), greaterThanOrEqualTo(3));
  });
}
