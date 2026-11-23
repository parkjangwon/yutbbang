import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_palette.dart';
import '../widgets/app_background.dart';
import 'game_setup_screen.dart';
import 'settings_screen.dart';
import 'yut_guide_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Wordmark(),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => _open(context, const GameSetupScreen()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('게임 시작'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            label: '기본 설정',
                            icon: Icons.tune,
                            onPressed: () =>
                                _open(context, const SettingsScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SecondaryButton(
                            label: '게임 방법',
                            icon: Icons.menu_book_outlined,
                            onPressed: () =>
                                _open(context, const YutGuideScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) => Text(
                        snapshot.hasData ? 'v${snapshot.data!.version}' : '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppPalette.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// '윷빵' 글자 + 양옆 가는 선 + 윷가락 4개 장식.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    Widget rule() =>
        Expanded(child: Container(height: 1.5, color: AppPalette.boardLine));
    return Column(
      children: [
        Row(
          children: [
            rule(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '윷빵',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.ink,
                  letterSpacing: 2,
                ),
              ),
            ),
            rule(),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '전통 윷놀이 한 판',
          style: TextStyle(fontSize: 15, color: AppPalette.inkMuted),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.ink,
        backgroundColor: AppPalette.surface,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppPalette.line),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
