import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game_item.dart';
import '../providers/game_provider.dart';

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

    // 화면 크기에 따라 레이아웃 변경
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      // 태블릿: 우측 세로 정렬
      return Positioned(
        right: 20,
        top: 100,
        child: Column(
          children: [
            Text(
              '${team.name} 가방',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 4),
            ..._buildItemSlots(context, ref, team.items),
          ],
        ),
      );
    } else {
      // 모바일: 상단 가로 정렬
      return Positioned(
        top: 80,
        left: 0,
        right: 0,
        child: Column(
          children: [
            Text(
              '${team.name}의 가방',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildItemSlots(context, ref, team.items),
            ),
          ],
        ),
      );
    }
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

    return GestureDetector(
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
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.amber.shade300, Colors.amber.shade700],
                )
              : null,
          color: item == null ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMyTurn && item != null
                ? Colors.white
                : Colors.grey.shade400,
            width: 2,
          ),
          boxShadow: item != null
              ? [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.amber.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            item != null ? GameItem.fromType(item).emoji : '?',
            style: const TextStyle(fontSize: 32),
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
