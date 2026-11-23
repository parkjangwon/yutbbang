import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/models/game_rule_config.dart';
import '../providers/game_provider.dart';
import '../widgets/setup/rule_options.dart';
import '../widgets/setup/setup_widgets.dart';
import 'game_screen.dart';

/// 이번 판에만 적용할 설정. 글로벌 설정을 기본값으로 시작한다.
class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  late final List<TextEditingController> _nameControllers;
  late GameRuleConfig _config;

  @override
  void initState() {
    super.initState();
    _config = ref.read(gameProvider).config;
    _nameControllers = [
      for (final name in _config.teamNames) TextEditingController(text: name),
    ];
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _update(GameRuleConfig next) => setState(() => _config = next);

  void _renameTeam(int index, String name) {
    _update(
      _config.copyWith(teamNames: List.of(_config.teamNames)..[index] = name),
    );
  }

  void _start() {
    ref.read(gameProvider.notifier).startGameWithConfig(_config);
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Scaffold(
      appBar: AppBar(title: const Text('게임 시작 설정')),
      // 시작 버튼은 스크롤과 관계없이 항상 하단에 보이게 고정한다.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: const Text(
            '배틀 시작!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('팀 설정', large: true),
            SettingsRow(
              label: '참여 팀 수',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final count in [2, 3, 4])
                    ChoiceChip(
                      label: Text('$count팀'),
                      selected: config.teamCount == count,
                      onSelected: (selected) {
                        if (selected) _update(config.withTeamCount(count));
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < config.teamCount; i++)
              TeamSetupRow(
                index: i,
                nameController: _nameControllers[i],
                controllerId: config.teamControllers[i],
                teamCount: config.teamCount,
                onNameChanged: (name) => _renameTeam(i, name),
                onControllerSelected: (id) =>
                    _update(config.withController(i, id)),
              ),
            const Divider(height: 40),
            const SectionHeader('게임당 말'),
            MalCountSlider(config: config, onChanged: _update),
            const Divider(height: 40),
            const SectionHeader('낙 확률'),
            const SizedBox(height: 12),
            NakChanceChips(config: config, onChanged: _update),
            const Divider(height: 40),
            RuleSwitchList(
              options: basicRuleOptions,
              config: config,
              onChanged: _update,
            ),
            const Divider(height: 40),
            const SectionHeader('특수 규칙 (House Rules)', large: true),
            RuleSwitchList(
              options: houseRuleOptions,
              config: config,
              onChanged: _update,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
