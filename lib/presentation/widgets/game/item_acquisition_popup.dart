import 'package:material_ui/material_ui.dart';

import '../../../domain/models/game_item.dart';

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
            color: Colors.brown.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.amber, width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[$name] ${item.name} 획득!',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
