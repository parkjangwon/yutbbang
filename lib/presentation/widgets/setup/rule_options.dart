import 'package:material_ui/material_ui.dart';

import '../../../domain/models/game_rule_config.dart';
import 'setup_widgets.dart';

/// 켜고 끄는 규칙 하나: 화면 문구와 설정 값 읽기/쓰기.
class RuleOption {
  final String title;
  final String subtitle;
  final bool Function(GameRuleConfig) read;
  final GameRuleConfig Function(GameRuleConfig, bool) write;

  const RuleOption(this.title, this.subtitle, this.read, this.write);
}

/// 기본 규칙(빽도·컨트롤 모드).
final basicRuleOptions = [
  RuleOption(
    '빽도 사용',
    '도 하나에 표시된 빽도를 사용합니다.',
    (c) => c.useBackDo,
    (c, v) => c.copyWith(useBackDo: v),
  ),
  RuleOption(
    '컨트롤 모드',
    '버튼을 누르고 있다가 떼서 결과를 결정합니다.',
    (c) => c.useGaugeControl,
    (c, v) => c.copyWith(useGaugeControl: v),
  ),
];

/// 특수 규칙(하우스 룰)과 아이템 모드.
final houseRuleOptions = [
  RuleOption(
    '빽도 날기',
    '대기 중인 말이 빽도가 나오면 즉시 골인합니다.',
    (c) => c.backDoFlying,
    (c, v) => c.copyWith(backDoFlying: v),
  ),
  RuleOption(
    '자동 임신',
    '중앙 지점 도착 시 대기 중인 말 하나를 자동으로 업습니다.',
    (c) => c.autoCarrier,
    (c, v) => c.copyWith(autoCarrier: v),
  ),
  RuleOption(
    '전낙',
    '낙 발생 시 해당 턴의 모든 이전 결과가 무효화됩니다.',
    (c) => c.totalNak,
    (c, v) => c.copyWith(totalNak: v),
  ),
  RuleOption(
    '군밤 모드 🌰',
    '지름길 구간에서 항상 최단 거리로 이동합니다.',
    (c) => c.roastedChestnutMode,
    (c, v) => c.copyWith(roastedChestnutMode: v),
  ),
  RuleOption(
    '아이템 모드',
    '게임판에 아이템 타일이 생성되어 다양한 아이템을 사용할 수 있습니다.',
    (c) => c.useItemMode,
    (c, v) => c.copyWith(useItemMode: v),
  ),
];

/// [options] 규칙들의 스위치 목록.
class RuleSwitchList extends StatelessWidget {
  final List<RuleOption> options;
  final GameRuleConfig config;
  final ValueChanged<GameRuleConfig> onChanged;

  const RuleSwitchList({
    super.key,
    required this.options,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options)
          RuleSwitchTile(
            title: option.title,
            subtitle: option.subtitle,
            value: option.read(config),
            onChanged: (v) => onChanged(option.write(config, v)),
          ),
      ],
    );
  }
}

/// 낙 확률 선택 칩(쉬움·보통·어려움). 컨트롤 모드에서는 퍼센트 대신 '낙 : 난이도'로 표기.
class NakChanceChips extends StatelessWidget {
  static const levels = [('쉬움', 10), ('보통', 15), ('어려움', 25)];

  final GameRuleConfig config;
  final ValueChanged<GameRuleConfig> onChanged;

  const NakChanceChips({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, percent) in levels)
          ChoiceChip(
            label: Text(
              config.useGaugeControl ? '낙 : $label' : '$label ($percent%)',
            ),
            selected: config.nakChancePercent == percent,
            onSelected: (selected) {
              if (selected) {
                onChanged(config.copyWith(nakChancePercent: percent));
              }
            },
          ),
      ],
    );
  }
}

/// 게임당 말 수(2~5) 슬라이더.
class MalCountSlider extends StatelessWidget {
  final GameRuleConfig config;
  final ValueChanged<GameRuleConfig> onChanged;

  const MalCountSlider({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: config.malCount.toDouble(),
          min: 2,
          max: 5,
          divisions: 3,
          label: config.malCount.toString(),
          activeColor: Colors.brown,
          thumbColor: Colors.brown,
          onChanged: (v) => onChanged(config.copyWith(malCount: v.toInt())),
        ),
        const SizedBox(height: 10),
        Text('현재 말 개수: ${config.malCount}', textAlign: TextAlign.center),
      ],
    );
  }
}

/// 설정 화면 섹션 제목.
class SectionHeader extends StatelessWidget {
  final String text;
  final bool large;

  const SectionHeader(this.text, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: large ? 22 : 18,
        fontWeight: FontWeight.bold,
        color: large ? Colors.brown : null,
      ),
    );
  }
}
