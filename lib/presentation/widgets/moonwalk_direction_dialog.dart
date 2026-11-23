import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../theme/app_palette.dart';

class MoonwalkDirectionDialog extends ConsumerWidget {
  final int malId;

  const MoonwalkDirectionDialog({super.key, required this.malId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('↩️', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                const Text(
                  '뒷걸음질',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 안내 메시지
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.surfaceSunken,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '뒷걸음질 아이템이 있습니다.\n뒤로 가시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.ink,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 방향 선택 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.surface,
                      foregroundColor: AppPalette.ink,
                      side: const BorderSide(color: AppPalette.line),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      _selectDirection(ref, malId, forward: true);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_upward, size: 28),
                    label: const Text(
                      '앞으로(취소)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      _selectDirection(ref, malId, forward: false);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_downward, size: 28),
                    label: const Text(
                      '뒤로(사용)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 뒤로 가기를 고르면 뒷걸음질 아이템을 쓴다.
  void _selectDirection(WidgetRef ref, int malId, {required bool forward}) {
    ref.read(gameProvider.notifier).confirmMoonwalk(!forward);
  }
}
