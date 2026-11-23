import 'package:material_ui/material_ui.dart';

import '../guide/guide_content.dart';
import '../theme/app_palette.dart';

/// 윷놀이 규칙·조작·아이템 설명 화면. 내용은 [guideSections]에 있다.
class YutGuideScreen extends StatelessWidget {
  const YutGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('윷놀이 가이드')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section(guideIntro),
          const _SectionTitle('🥢', '윷 결과'),
          const _SectionBody(
            '윷가락의 평평한 면이 "배", 둥근 면이 "등"입니다. '
            '확률은 낙이 아닐 때 기준입니다.',
          ),
          const SizedBox(height: 8),
          const _YutOutcomeTable(),
          for (final section in guideSections) _Section(section),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final GuideSection section;
  const _Section(this.section);

  @override
  Widget build(BuildContext context) {
    final body = section.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(section.emoji, section.title),
        if (body != null) _SectionBody(body),
        if (section.bullets.isNotEmpty) _BulletList(items: section.bullets),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String text;
  const _SectionTitle(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Text(
        '$emoji  $text',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppPalette.ink,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _YutOutcomeTable extends StatelessWidget {
  const _YutOutcomeTable();

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(
      fontWeight: FontWeight.w800,
      color: AppPalette.terracotta,
    );
    const cell = TextStyle(fontSize: 14);

    TableRow row(List<String> values, {TextStyle style = cell, Color? color}) {
      return TableRow(
        decoration: BoxDecoration(color: color),
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Text(v, style: style, textAlign: TextAlign.center),
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: const TableBorder.symmetric(
          inside: BorderSide(color: AppPalette.line),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1),
        },
        children: [
          row(
            const ['결과', '윷가락', '이동', '확률'],
            style: header,
            color: AppPalette.terracottaSoft,
          ),
          for (final (i, r) in yutOutcomeRows.indexed)
            row([
              r.name,
              r.sticks,
              r.move,
              r.chance,
            ], color: i.isEven ? AppPalette.surface : AppPalette.surfaceSunken),
        ],
      ),
    );
  }
}
