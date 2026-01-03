import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_item.dart';
import '../providers/game_provider.dart';

class ItemChoiceDialog extends ConsumerWidget {
  final int nodeId;

  const ItemChoiceDialog({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final teamIdx =
        state.pendingItemTeamIndex ?? (state.turnIndex % state.teams.length);
    final team = state.teams[teamIdx];
    final pendingItem = state.pendingItem;

    if (pendingItem == null) {
      return const SizedBox.shrink();
    }

    final newItem = GameItem.fromType(pendingItem);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade50, Colors.amber.shade100],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(newItem.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 12),
                const Text(
                  '아이템 획득!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 새 아이템 정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    newItem.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    newItem.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '인벤토리가 꽉 찼습니다!\n기존 아이템을 교체하거나 새 아이템을 포기하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 기존 아이템 선택
            const Text(
              '교체할 아이템 선택:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: team.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final type = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildExistingItemSlot(
                    context,
                    ref,
                    type,
                    idx,
                    teamIdx,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 포기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.read(gameProvider.notifier).discardPendingItem();
                  Navigator.pop(context);
                },
                child: const Text(
                  '새 아이템 포기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingItemSlot(
    BuildContext context,
    WidgetRef ref,
    ItemType itemType,
    int slotIndex,
    int teamIndex,
  ) {
    final item = GameItem.fromType(itemType);

    return GestureDetector(
      onTap: () {
        ref
            .read(gameProvider.notifier)
            .replaceItem(slotIndex, nodeId, teamIndex: teamIndex);
        Navigator.pop(context);
      },
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown, width: 2),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
