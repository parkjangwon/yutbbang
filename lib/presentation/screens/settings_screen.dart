import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import 'yut_guide_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.watch(gameProvider.notifier);
    final config = ref.watch(gameProvider).config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('시스템 설정'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'CPU 난이도',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: config.aiDifficulty.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: config.aiDifficulty.toString(),
            activeColor: Colors.brown,
            thumbColor: Colors.brown,
            onChanged: (val) {
              gameNotifier.updateConfig(
                config.copyWith(aiDifficulty: val.toInt()),
              );
            },
          ),
          const SizedBox(height: 10),
          Text('현재 난이도: ${config.aiDifficulty}', textAlign: TextAlign.center),
          const Divider(height: 40),
          const Text(
            '낙 확률',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNakChoice(
                label: '쉬움',
                percent: 10,
                selected: config.nakChancePercent == 10,
                onSelected: (selected) {
                  if (selected)
                    gameNotifier.updateConfig(
                      config.copyWith(nakChancePercent: 10),
                    );
                },
                isControlMode: config.useGaugeControl,
              ),
              const SizedBox(width: 8),
              _buildNakChoice(
                label: '보통',
                percent: 15,
                selected: config.nakChancePercent == 15,
                onSelected: (selected) {
                  if (selected)
                    gameNotifier.updateConfig(
                      config.copyWith(nakChancePercent: 15),
                    );
                },
                isControlMode: config.useGaugeControl,
              ),
              const SizedBox(width: 8),
              _buildNakChoice(
                label: '어려움',
                percent: 25,
                selected: config.nakChancePercent == 25,
                onSelected: (selected) {
                  if (selected)
                    gameNotifier.updateConfig(
                      config.copyWith(nakChancePercent: 25),
                    );
                },
                isControlMode: config.useGaugeControl,
              ),
            ],
          ),
          const Divider(height: 40),
          const Text(
            '규칙 기본 설정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('빽도 사용'),
            subtitle: const Text('도 하나에 표시된 빽도를 사용합니다.'),
            value: config.useBackDo,
            activeColor: Colors.brown,
            onChanged: (val) {
              gameNotifier.updateConfig(config.copyWith(useBackDo: val));
            },
          ),
          SwitchListTile(
            title: const Text('컨트롤 모드'),
            subtitle: const Text('게이지 타이밍으로 결정하는 컨트롤 모드를 기본으로 사용합니다.'),
            value: config.useGaugeControl,
            activeColor: Colors.brown,
            onChanged: (val) {
              gameNotifier.updateConfig(config.copyWith(useGaugeControl: val));
            },
          ),
          const Divider(height: 40),
          ListTile(
            title: const Text('윷놀이 가이드'),
            subtitle: const Text('규칙과 게임 설명 보기'),
            trailing: const Icon(Icons.menu_book),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const YutGuideScreen()),
              );
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildNakChoice({
    required String label,
    required int percent,
    required bool selected,
    required ValueChanged<bool> onSelected,
    bool isControlMode = false,
  }) {
    final displayText = isControlMode ? '낙 : $label' : '$label ($percent%)';
    return ChoiceChip(
      label: Text(displayText),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
