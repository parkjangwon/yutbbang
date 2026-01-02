import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../../domain/models/game_rule_config.dart';
import 'game_screen.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingsRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.brown,
              ),
            ),
          ),
          Expanded(flex: 3, child: child),
        ],
      ),
    );
  }
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
            _SettingsRow(
              label: '참여 팀 수',
              child: Row(
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
            ...List.generate(config.teamCount, (i) {
              final colors = [
                Colors.orange,
                Colors.green,
                Colors.red,
                Colors.blue,
              ];
              final controllerId = config.teamControllers[i];
              return _SettingsRow(
                label:
                    '팀 ${String.fromCharCode(65 + i)} (${['주황', '초록', '빨강', '파랑'][i]})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameControllers[i],
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.circle, color: colors[i]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          final names = List<String>.from(
                            _localConfig.teamNames,
                          );
                          names[i] = val;
                          _localConfig = _localConfig.copyWith(
                            teamNames: names,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildControllerChoice(
                          label: 'CPU',
                          id: 0,
                          selected: controllerId == 0,
                          onSelected: (selected) {
                            if (selected) _updateController(config, i, 0);
                          },
                        ),
                        ...List.generate(config.teamCount, (pIdx) {
                          final id = pIdx + 1;
                          return _buildControllerChoice(
                            label: '플레이어 $id',
                            id: id,
                            selected: controllerId == id,
                            onSelected: (selected) {
                              if (selected) _updateController(config, i, id);
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 40),
            const Text(
              '게임 말 수 설정',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            _SettingsRow(
              label: '팀당 말 수',
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: config.malCount.toDouble(),
                      min: 2,
                      max: 5,
                      divisions: 3,
                      activeColor: Colors.brown,
                      onChanged: (val) => setState(() {
                        _localConfig = _localConfig.copyWith(
                          malCount: val.toInt(),
                        );
                      }),
                    ),
                  ),
                  Text(
                    '${config.malCount}개',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            SwitchListTile(
              title: const Text(
                '빽도 사용',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('도 하나에 표시된 빽도를 사용합니다.'),
              value: config.useBackDo,
              activeColor: Colors.brown,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(useBackDo: val);
              }),
            ),
            SwitchListTile(
              title: const Text(
                '컨트롤 모드',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('버튼을 누르고 있다가 떼서 결과를 결정합니다.'),
              value: config.useGaugeControl,
              activeColor: Colors.brown,
              onChanged: (val) => setState(() {
                _localConfig = _localConfig.copyWith(useGaugeControl: val);
              }),
            ),
            const Divider(height: 40),
            const Text(
              '낙 확률 설정',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            _SettingsRow(
              label: '낙 확률',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildNakChoice(
                    label: '쉬움',
                    percent: 10,
                    selected: config.nakChancePercent == 10,
                    onSelected: (selected) {
                      if (selected)
                        setState(() {
                          _localConfig = _localConfig.copyWith(
                            nakChancePercent: 10,
                          );
                        });
                    },
                  ),
                  _buildNakChoice(
                    label: '보통',
                    percent: 15,
                    selected: config.nakChancePercent == 15,
                    onSelected: (selected) {
                      if (selected)
                        setState(() {
                          _localConfig = _localConfig.copyWith(
                            nakChancePercent: 15,
                          );
                        });
                    },
                  ),
                  _buildNakChoice(
                    label: '어려움',
                    percent: 25,
                    selected: config.nakChancePercent == 25,
                    onSelected: (selected) {
                      if (selected)
                        setState(() {
                          _localConfig = _localConfig.copyWith(
                            nakChancePercent: 25,
                          );
                        });
                    },
                  ),
                ],
              ),
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

  Widget _buildControllerChoice({
    required String label,
    required int id,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
