import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/screens/lobby_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.nanumGothicTextTheme(),
      ),
      home: const LobbyScreen(),
    );
  }
}
