import 'package:flutter/material.dart';
import '../providers/game_state.dart';

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
        color: Colors.grey.shade900.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                color: Colors.white10,
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
                  color: Colors.redAccent.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.8),
                    blurRadius: 12,
                    spreadRadius: 2,
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
                color: Colors.white54,
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
