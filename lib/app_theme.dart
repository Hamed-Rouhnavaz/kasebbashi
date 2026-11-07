import 'package:flutter/material.dart';

/// رنگ‌های تأکیدی که هم روی حالت روشن و هم تیره خوب دیده می‌شوند
class AppColors {
  static const sage = Color(0xFF2F9E7B);
  static const gold = Color(0xFFC9A24D);
  static const emerald = Color(0xFF2E8B67);
  static const wine = Color(0xFFB5485A);

  // کارت اصلی داشبورد
  static const heroTop = Color(0xFF1F3B36);
  static const heroBottom = Color(0xFF0E1D1A);
  static const heroGold = Color(0xFFD9B766);
}

const _font = 'Vazirmatn';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1F3B36),
    brightness: brightness,
  );

  final scheme = dark
      ? base.copyWith(
          primary: const Color(0xFFEDE6D6),
          onPrimary: const Color(0xFF1B1D1C),
          primaryContainer: const Color(0xFF2B3230),
          onPrimaryContainer: const Color(0xFFDCE8E3),
          secondary: const Color(0xFFD2AE62),
          onSecondary: const Color(0xFF1A1405),
          secondaryContainer: const Color(0xFF3A3020),
          onSecondaryContainer: const Color(0xFFF1E6CC),
          tertiary: const Color(0xFFD08B7B),
          surface: const Color(0xFF121413),
          onSurface: const Color(0xFFECE9E2),
          surfaceContainerHighest: const Color(0xFF262A29),
          outline: const Color(0xFF8C928F),
          outlineVariant: const Color(0xFF2E3331),
          error: const Color(0xFFE57368),
        )
      : base.copyWith(
          primary: const Color(0xFF1F3B36),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDCE8E3),
          onPrimaryContainer: const Color(0xFF10231F),
          secondary: const Color(0xFFB8924A),
          onSecondary: const Color(0xFF1A1405),
          secondaryContainer: const Color(0xFFF1E6CC),
          onSecondaryContainer: const Color(0xFF3B2D0B),
          tertiary: const Color(0xFF8A4B3F),
          surface: const Color(0xFFFAF8F4),
          onSurface: const Color(0xFF1B1D1C),
          surfaceContainerHighest: const Color(0xFFEDE9E1),
          outline: const Color(0xFF8C928F),
          outlineVariant: const Color(0xFFE3DED3),
          error: const Color(0xFFB3392F),
        );

  final cardColor = dark ? const Color(0xFF1A1D1C) : Colors.white;
  final radius14 = BorderRadius.circular(14);

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius14,
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _font,
    scaffoldBackgroundColor: scheme.surface,
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: _font,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.secondary, 1.6),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: radius14),
        textStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: radius14),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        textStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
      elevation: 2,
      extendedTextStyle: const TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.secondary),
  );
}
