import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app_palette.dart';

/// 앱 전체 Material 테마(모던 미니멀).
ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.terracotta,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppPalette.terracotta,
        onPrimary: Colors.white,
        secondary: AppPalette.sage,
        surface: AppPalette.surface,
        onSurface: AppPalette.ink,
        error: AppPalette.danger,
      );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppPalette.background,
    textTheme: GoogleFonts.nanumGothicTextTheme().apply(
      bodyColor: AppPalette.ink,
      displayColor: AppPalette.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.background,
      foregroundColor: AppPalette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppPalette.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.terracotta,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: rounded,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppPalette.ink),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppPalette.surface,
      selectedColor: AppPalette.terracottaSoft,
      side: const BorderSide(color: AppPalette.line),
      labelStyle: const TextStyle(color: AppPalette.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.white
            : AppPalette.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppPalette.sage
            : AppPalette.surfaceSunken,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppPalette.line),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppPalette.terracotta,
      thumbColor: AppPalette.terracotta,
      inactiveTrackColor: AppPalette.line,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerTheme: const DividerThemeData(color: AppPalette.line),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppPalette.ink,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
