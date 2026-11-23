import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game_item.dart';
import '../providers/game_provider.dart';
import '../theme/app_palette.dart';

class ItemInventory extends ConsumerWidget {
  const ItemInventory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final team = state.currentTeam;

    // 아이템 모드가 비활성화되어 있으면 표시하지 않음
    if (!state.activeConfig.useItemMode) {
      return const SizedBox.shrink();
    }

    // 가로 화면: 오른쪽 위(던지기 버튼은 오른쪽 아래), 세로 화면: 판 위 가운데.
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${team.name}의 가방',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppPalette.inkMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildItemSlots(context, ref, team.items),
        ),
      ],
    );

    return landscape
        ? Positioned(top: 12, right: 16, child: content)
        : Positioned(top: 80, left: 0, right: 0, child: Center(child: content));
  }

  List<Widget> _buildItemSlots(
    BuildContext context,
    WidgetRef ref,
    List<ItemType> items,
  ) {
    return [
      _buildItemSlot(context, ref, items.isNotEmpty ? items[0] : null, 0),
      const SizedBox(width: 8, height: 8),
      _buildItemSlot(context, ref, items.length > 1 ? items[1] : null, 1),
    ];
  }

  Widget _buildItemSlot(
    BuildContext context,
    WidgetRef ref,
    ItemType? item,
    int slotIndex,
  ) {
    final state = ref.watch(gameProvider);
    final isMyTurn = state.currentTeam.isHuman;

    final name = item == null ? null : GameItem.fromType(item).name;
    return Semantics(
      button: item != null,
      label: name == null ? '빈 칸' : '가방: $name',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: item != null && isMyTurn
            ? () => _useItem(context, ref, item)
            : null,
        onLongPress: item != null
            ? () => _showItemDescription(context, item)
            : null,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: item != null
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppPalette.surface, AppPalette.terracottaSoft],
                  )
                : null,
            color: item == null
                ? AppPalette.surface.withValues(alpha: 0.55)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMyTurn && item != null
                  ? AppPalette.terracotta.withValues(alpha: 0.6)
                  : AppPalette.line,
              width: 2,
            ),
            boxShadow: item != null
                ? [
                    BoxShadow(
                      blurRadius: 8,
                      color: AppPalette.terracotta.withValues(alpha: 0.18),
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: item == null
                ? null
                : Text(
                    GameItem.fromType(item).emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
          ),
        ),
      ),
    );
  }

  /// 안내가 있으면 먼저 보여주고, 수동 아이템이면 사용한다.
  void _useItem(BuildContext context, WidgetRef ref, ItemType type) {
    final item = GameItem.fromType(type);
    final hint = item.tapHint;
    if (hint != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hint), duration: const Duration(seconds: 2)),
      );
    }
    if (!item.isAutoTriggered) {
      ref.read(gameProvider.notifier).useItem(type);
    }
  }

  void _showItemDescription(BuildContext context, ItemType item) {
    final gameItem = GameItem.fromType(item);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(gameItem.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text(gameItem.name),
          ],
        ),
        content: Text(gameItem.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
