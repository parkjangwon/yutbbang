import 'package:material_ui/material_ui.dart';

import '../../providers/game_state.dart';

/// 상단 바 가운데의 결과/안내 텍스트 (두 줄).
class GameStatusText extends StatelessWidget {
  final GameState state;

  const GameStatusText({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final showResult =
        state.lastResult != null && state.status != GameStatus.moving;
    final showGuide =
        state.status == GameStatus.selectingMal ||
        state.status == GameStatus.awaitingShortcutDecision;

    if (!showResult && !showGuide) return const SizedBox.shrink();

    String? resultText;
    String? guideText;

    if (showResult) {
      final resultLabels = state.currentThrows.map((e) => e.label).toList();
      if (state.lastResult != null &&
          !state.currentThrows.contains(state.lastResult)) {
        resultLabels.add(state.lastResult!.label);
      }
      resultText = '결과: ${resultLabels.join(', ')}';
    }

    if (showGuide) {
      guideText = state.status == GameStatus.awaitingShortcutDecision
          ? '지름길을 선택하세요'
          : '움직일 말을 선택하세요';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First line: Result (or empty space)
        SizedBox(
          height: 24, // Increased height
          child: resultText != null
              ? Text(
                  resultText,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.5,
                    height: 1.2, // Improved line height
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
        // Spacing between lines (only if both exist)
        if (resultText != null && guideText != null) const SizedBox(height: 6),
        // Second line: Guide (or empty space)
        SizedBox(
          height: 22, // Increased height
          child: guideText != null
              ? Text(
                  guideText,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.3,
                    height: 1.2, // Improved line height
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
