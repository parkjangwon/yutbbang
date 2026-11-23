import 'package:material_ui/material_ui.dart';

/// 라벨 + 입력 위젯 한 줄.
class SettingsRow extends StatelessWidget {
  final String label;
  final Widget child;
  const SettingsRow({super.key, required this.label, required this.child});

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

/// 팀 하나의 설정 행: 이름 입력 + 조작자(CPU/플레이어) 선택.
class TeamSetupRow extends StatelessWidget {
  static const _colors = [Colors.orange, Colors.green, Colors.red, Colors.blue];
  static const _colorNames = ['주황', '초록', '빨강', '파랑'];

  final int index;
  final TextEditingController nameController;
  final int controllerId;
  final int teamCount;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onControllerSelected;

  const TeamSetupRow({
    super.key,
    required this.index,
    required this.nameController,
    required this.controllerId,
    required this.teamCount,
    required this.onNameChanged,
    required this.onControllerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      label: '팀 ${String.fromCharCode(65 + index)} (${_colorNames[index]})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.circle, color: _colors[index]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('CPU'),
                selected: controllerId == 0,
                onSelected: (selected) {
                  if (selected) onControllerSelected(0);
                },
              ),
              ...List.generate(teamCount, (pIdx) {
                final id = pIdx + 1;
                return ChoiceChip(
                  label: Text('플레이어 $id'),
                  selected: controllerId == id,
                  onSelected: (selected) {
                    if (selected) onControllerSelected(id);
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// 규칙 on/off 스위치 (갈색 테마).
class RuleSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const RuleSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: Colors.brown,
      onChanged: onChanged,
    );
  }
}
