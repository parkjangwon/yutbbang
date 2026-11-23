import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yutbbang/domain/models/game_item.dart';
import 'package:yutbbang/presentation/guide/guide_content.dart';
import 'package:yutbbang/presentation/screens/yut_guide_screen.dart';

void main() {
  test('윷 결과표 확률의 합은 1 (16/16)', () {
    final total = yutOutcomeRows
        .map((r) => int.parse(r.chance.split('/').first))
        .reduce((a, b) => a + b);
    expect(total, 16);
  });

  test('모든 아이템이 가이드에 설명돼 있다', () {
    final text = guideSections.expand((s) => s.bullets).join('\n');
    for (final item in GameItem.allItems) {
      expect(text, contains('${item.emoji} ${item.name}'), reason: item.name);
    }
  });

  testWidgets('가이드 화면이 렌더링된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: YutGuideScreen()));
    expect(find.text('윷놀이 가이드'), findsOneWidget);
    expect(find.text('빽도'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('전략 팁'), 300);
    expect(find.textContaining('전략 팁'), findsOneWidget);
  });
}
