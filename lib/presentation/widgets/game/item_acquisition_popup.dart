import 'package:material_ui/material_ui.dart';

import '../../../domain/models/game_item.dart';
import '../../theme/app_palette.dart';

/// 아이템 획득 팝업 (토스트 스타일). Stack 안에서 Positioned로 배치된다.
class ItemAcquisitionPopup extends StatelessWidget {
  final ItemType type;
  final String? teamName;

  const ItemAcquisitionPopup({super.key, required this.type, this.teamName});

  @override
  Widget build(BuildContext context) {
    final item = GameItem.fromType(type);
    final name = teamName ?? '누군가';

    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppPalette.cardShadow,
            border: Border.all(color: AppPalette.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[$name] ${item.name} 획득!',
                      style: const TextStyle(
                        color: AppPalette.terracotta,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: AppPalette.inkMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
