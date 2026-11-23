import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../../domain/models/game_rule_config.dart';
import '../widgets/setup/setup_widgets.dart';
import 'game_screen.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  late List<TextEditingController> _nameControllers;
  late GameRuleConfig _localConfig;

  @override
  void initState() {
    super.initState();
    final config = ref.read(gameProvider).config;
    _localConfig = config;
    _nameControllers = List.generate(
      4,
      (i) => TextEditingController(text: config.teamNames[i]),
    );
  }

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _localConfig;
    final gameNotifier = ref.read(gameProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        title: const Text(
          '게임 시작 설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '팀 설정',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            SettingsRow(
              label: '참여 팀 수',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(3, (index) {
                    final count = index + 2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('$count팀'),
                        selected: config.teamCount == count,
                        onSelected: (selected) {
                          if (selected) _updateTeamCount(config, count);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              config.teamCount,
              (i) => TeamSetupRow(
                index: i,
                nameController: _nameControllers[i],
                controllerId: config.teamControllers[i],
                teamCount: config.teamCount,
                onNameChanged: (val) {
                  setState(() {
                    final names = List<String>.from(_localConfig.teamNames);
                    names[i] = val;
                    _localConfig = _localConfig.copyWith(teamNames: names);
                  });
                },
                onControllerSelected: (id) => _updateController(config, i, id),
              ),
            ),
            const Divider(height: 40),
            const Text(
              '게임당 말',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: config.malCount.toDouble(),
              min: 2,
              max: 5,
              divisions: 3,
              label: config.malCount.toString(),
              activeColor: Colors.brown,
              thumbColor: Colors.brown,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(malCount: val.toInt());
              }),
            ),
            const SizedBox(height: 10),
            Text('현재 말 개수: ${config.malCount}', textAlign: TextAlign.center),
            const Divider(height: 40),
            const Text(
              '낙 확률',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, percent) in const [
                  ('쉬움', 10),
                  ('보통', 15),
                  ('어려움', 25),
                ])
                  _buildNakChoice(
                    label: label,
                    percent: percent,
                    selected: config.nakChancePercent == percent,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _localConfig = _localConfig.copyWith(
                            nakChancePercent: percent,
                          );
                        });
                      }
                    },
                  ),
              ],
            ),
            const Divider(height: 40),
            RuleSwitchTile(
              title: '빽도 사용',
              subtitle: '도 하나에 표시된 빽도를 사용합니다.',
              value: config.useBackDo,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(useBackDo: val);
              }),
            ),
            RuleSwitchTile(
              title: '컨트롤 모드',
              subtitle: '버튼을 누르고 있다가 떼서 결과를 결정합니다.',
              value: config.useGaugeControl,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(useGaugeControl: val);
              }),
            ),
            const Divider(height: 40),
            const Text(
              '특수 규칙 (House Rules)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            RuleSwitchTile(
              title: '빽도 날기',
              subtitle: '대기 중인 말이 빽도가 나오면 즉시 골인합니다.',
              value: config.backDoFlying,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(backDoFlying: val);
              }),
            ),
            RuleSwitchTile(
              title: '자동 임신',
              subtitle: '중앙 지점 도착 시 대기 중인 말 하나를 자동으로 업습니다.',
              value: config.autoCarrier,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(autoCarrier: val);
              }),
            ),
            RuleSwitchTile(
              title: '전낙',
              subtitle: '낙 발생 시 해당 턴의 모든 이전 결과가 무효화됩니다.',
              value: config.totalNak,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(totalNak: val);
              }),
            ),
            RuleSwitchTile(
              title: '군밤 모드 🌰',
              subtitle: '지름길 구간에서 항상 최단 거리로 이동합니다.',
              value: config.roastedChestnutMode,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(roastedChestnutMode: val);
              }),
            ),
            RuleSwitchTile(
              title: '아이템 모드',
              subtitle: '게임판에 아이템 타일이 생성되어 다양한 아이템을 사용할 수 있습니다.',
              value: config.useItemMode,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(useItemMode: val);
              }),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  gameNotifier.startGameWithConfig(_localConfig);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const GameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  '배틀 시작!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNakChoice({
    required String label,
    required int percent,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final displayText = _localConfig.useGaugeControl
        ? '낙 : $label'
        : '$label ($percent%)';
    return ChoiceChip(
      label: Text(displayText),
      selected: selected,
      onSelected: onSelected,
    );
  }

  void _updateController(
    GameRuleConfig config,
    int teamIndex,
    int controllerId,
  ) {
    final nextControllers = List<int>.from(config.teamControllers);
    if (controllerId > 0) {
      for (int i = 0; i < nextControllers.length; i++) {
        if (i != teamIndex && nextControllers[i] == controllerId) {
          nextControllers[i] = 0;
        }
      }
    }
    nextControllers[teamIndex] = controllerId;
    setState(() {
      _localConfig = config.copyWith(
        teamControllers: _normalizeControllers(
          nextControllers,
          config.teamCount,
        ),
      );
    });
  }

  void _updateTeamCount(GameRuleConfig config, int teamCount) {
    final nextControllers = List<int>.from(config.teamControllers);
    for (int i = 0; i < nextControllers.length; i++) {
      if (i >= teamCount) nextControllers[i] = 0;
    }
    final normalized = _normalizeControllers(nextControllers, teamCount);
    setState(() {
      _localConfig = config.copyWith(
        teamCount: teamCount,
        teamControllers: normalized,
      );
    });
  }

  List<int> _normalizeControllers(List<int> controllers, int teamCount) {
    final next = List<int>.from(controllers);
    final used = <int>{};
    for (int i = 0; i < next.length; i++) {
      if (i >= teamCount) {
        next[i] = 0;
        continue;
      }
      final id = next[i];
      if (id > 0) {
        if (used.contains(id)) {
          next[i] = 0;
        } else {
          used.add(id);
        }
      }
    }
    return next;
  }
}
