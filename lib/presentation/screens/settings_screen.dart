import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/game_provider.dart';
import '../widgets/setup/rule_options.dart';
import 'yut_guide_screen.dart';

/// 기본(글로벌) 설정. 바꾸는 즉시 기기에 저장된다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(gameProvider.select((s) => s.config));
    final update = ref.read(gameProvider.notifier).updateConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기본 설정'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader('CPU 난이도'),
          Slider(
            value: config.aiDifficulty.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: config.aiDifficulty.toString(),
            activeColor: Colors.brown,
            thumbColor: Colors.brown,
            onChanged: (v) => update(config.copyWith(aiDifficulty: v.toInt())),
          ),
          const SizedBox(height: 10),
          Text('현재 난이도: ${config.aiDifficulty}', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const SectionHeader('CPU 속도'),
          const SizedBox(height: 8),
          CpuSpeedChips(config: config, onChanged: update),
          const Divider(height: 40),
          const SectionHeader('게임당 말'),
          MalCountSlider(config: config, onChanged: update),
          const Divider(height: 40),
          const SectionHeader('낙 확률'),
          const SizedBox(height: 12),
          NakChanceChips(config: config, onChanged: update),
          const Divider(height: 40),
          const SectionHeader('규칙 기본 설정'),
          RuleSwitchList(
            options: basicRuleOptions,
            config: config,
            onChanged: update,
          ),
          const Divider(height: 40),
          const SectionHeader('특수 규칙 (House Rules)'),
          RuleSwitchList(
            options: houseRuleOptions,
            config: config,
            onChanged: update,
          ),
          const Divider(height: 40),
          ListTile(
            title: const Text('윷놀이 가이드'),
            subtitle: const Text('규칙과 게임 설명 보기'),
            trailing: const Icon(Icons.menu_book),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const YutGuideScreen())),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
