import 'package:material_ui/material_ui.dart';

import '../../../domain/models/team.dart';
import '../../theme/app_palette.dart';
import '../game/team_colors.dart';

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
                color: AppPalette.ink,
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
      label:
          '팀 ${TeamColor.values[index].letter} (${teamColorNameOf(TeamColor.values[index])})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.circle,
                color: teamColorOf(TeamColor.values[index]),
              ),
              filled: true,
              fillColor: AppPalette.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppPalette.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppPalette.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppPalette.terracotta),
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

/// 규칙 on/off 스위치 (전역 스위치 테마 사용).
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
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppPalette.inkMuted),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
