import 'package:material_ui/material_ui.dart';

import '../providers/game_state.dart';
import '../theme/app_palette.dart';

class YutGaugeWidget extends StatelessWidget {
  final double value;
  final List<NakZone> nakZones;
  final bool isVisible;

  const YutGaugeWidget({
    super.key,
    required this.value,
    this.nakZones = const [],
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      width: 280,
      height: 40,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
        boxShadow: AppPalette.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Background Track
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppPalette.surfaceSunken,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),

          // Nak Zones (Red) scattered
          ...nakZones.map(
            (zone) => Positioned(
              left: 280 * zone.start,
              width: 280 * (zone.end - zone.start),
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppPalette.danger.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Progress Pin (The needle/pointer)
          Positioned(
            left: (280 * value).clamp(0.0, 276.0),
            child: Container(
              width: 6,
              height: 32,
              decoration: BoxDecoration(
                color: AppPalette.ink,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.highlight.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // Gauge Labels
          const Positioned(
            top: 2,
            left: 10,
            child: Text(
              'CONTROL GAUGE',
              style: TextStyle(
                color: AppPalette.inkMuted,
                fontSize: 7,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
