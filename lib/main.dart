import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/lobby_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: YutApp()));
}

class YutApp extends StatelessWidget {
  const YutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '윷빵 (yutbbang)',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const LobbyScreen(),
    );
  }
}
