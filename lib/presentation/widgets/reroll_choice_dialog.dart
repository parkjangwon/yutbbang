import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../theme/app_palette.dart';

class RerollChoiceDialog extends ConsumerWidget {
  const RerollChoiceDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final result = state.lastResult;
    final resultLabel = result?.label ?? '?';

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
                const Text('🔄', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                const Text(
                  '다시 던지기',
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
              child: Column(
                children: [
                  const Text(
                    '현재 결과',
                    style: TextStyle(fontSize: 14, color: AppPalette.inkMuted),
                  ),
                  Text(
                    resultLabel,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.terracotta,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '다시 던지기 아이템을 사용하시겠습니까?\n현재 결과는 무시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppPalette.inkMuted,
              ),
            ),
            const SizedBox(height: 24),

            // 선택 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppPalette.ink,
                      side: const BorderSide(color: AppPalette.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref.read(gameProvider.notifier).confirmReroll(false);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '그냥 진행',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      ref.read(gameProvider.notifier).confirmReroll(true);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '다시 던지기',
                      style: TextStyle(
                        fontSize: 16,
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
}
