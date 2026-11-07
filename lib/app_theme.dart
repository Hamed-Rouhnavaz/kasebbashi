import 'package:flutter/material.dart';

/// رنگ‌های تأکیدی که روی همه پالت‌ها و هر دو حالت خوب دیده می‌شوند
class AppColors {
  static const sage = Color(0xFF2F9E7B);
  static const gold = Color(0xFFC9A24D);
  static const emerald = Color(0xFF2E8B67);
  static const wine = Color(0xFFB5485A);

  // (قدیمی؛ کارت داشبورد حالا از AppHero می‌خواند)
  static const heroTop = Color(0xFF1F3B36);
  static const heroBottom = Color(0xFF0E1D1A);
  static const heroGold = Color(0xFFD9B766);
}

/// پالت‌های رنگی اپ
enum AppPalette {
  luxury(
    label: 'طلایی و سبز',
    description: 'سبز تیره با تأکید طلایی؛ لوکس و آرام',
    seed: Color(0xFF1F3B36),
    heroTop: Color(0xFF1F3B36),
    heroBottom: Color(0xFF0E1D1A),
    heroAccent: Color(0xFFD9B766),
  ),
  rosePurple(
    label: 'صورتی و بنفش',
    description: 'بنفش و صورتی؛ شاد و ملایم',
    seed: Color(0xFF7B3FA0),
    heroTop: Color(0xFF5B2A86),
    heroBottom: Color(0xFFB03A8C),
    heroAccent: Color(0xFFFFD6EA),
  );

  final String label;
  final String description;
  final Color seed;
  final Color heroTop;
  final Color heroBottom;
  final Color heroAccent;

  const AppPalette({
    required this.label,
    required this.description,
    required this.seed,
    required this.heroTop,
    required this.heroBottom,
    required this.heroAccent,
  });
}

/// رنگ‌های کارت اصلی داشبورد (بسته به پالت عوض می‌شود)
class AppHero extends ThemeExtension<AppHero> {
  final Color top;
  final Color bottom;
  final Color accent;

  const AppHero({
    required this.top,
    required this.bottom,
    required this.accent,
  });

  @override
  AppHero copyWith({Color? top, Color? bottom, Color? accent}) => AppHero(
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
        accent: accent ?? this.accent,
      );

  @override
  AppHero lerp(ThemeExtension<AppHero>? other, double t) {
    if (other is! AppHero) return this;
    return AppHero(
      top: Color.lerp(top, other.top, t)!,
      bottom: Color.lerp(bottom, other.bottom, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

const _font = 'Vazirmatn';

ColorScheme _scheme(AppPalette palette, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: brightness,
  );

  switch (palette) {
    case AppPalette.luxury:
      return dark
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
    case AppPalette.rosePurple:
      return dark
          ? base.copyWith(
              primary: const Color(0xFFD6A8F0),
              onPrimary: const Color(0xFF2E0A45),
              primaryContainer: const Color(0xFF3E2150),
              onPrimaryContainer: const Color(0xFFF0DDF7),
              secondary: const Color(0xFFFF8FC1),
              onSecondary: const Color(0xFF45102B),
              secondaryContainer: const Color(0xFF55213D),
              onSecondaryContainer: const Color(0xFFFBDDEB),
              tertiary: const Color(0xFFC9A0F0),
              surface: const Color(0xFF150F1A),
              onSurface: const Color(0xFFF1E8F5),
              surfaceContainerHighest: const Color(0xFF2A2031),
              outline: const Color(0xFF9A8AA5),
              outlineVariant: const Color(0xFF3A2D44),
              error: const Color(0xFFFF8A9B),
            )
          : base.copyWith(
              primary: const Color(0xFF7B3FA0),
              onPrimary: Colors.white,
              primaryContainer: const Color(0xFFF0DDF7),
              onPrimaryContainer: const Color(0xFF2E0A45),
              secondary: const Color(0xFFE0559B),
              onSecondary: Colors.white,
              secondaryContainer: const Color(0xFFFBDDEB),
              onSecondaryContainer: const Color(0xFF52123A),
              tertiary: const Color(0xFF9C5BD6),
              surface: const Color(0xFFFFF8FB),
              onSurface: const Color(0xFF2A1830),
              surfaceContainerHighest: const Color(0xFFF5E7F0),
              outline: const Color(0xFF9A8AA5),
              outlineVariant: const Color(0xFFEBD9E6),
              error: const Color(0xFFC2294A),
            );
  }
}

Color _cardColor(AppPalette palette, bool dark) {
  if (!dark) return Colors.white;
  return palette == AppPalette.rosePurple
      ? const Color(0xFF1E1626)
      : const Color(0xFF1A1D1C);
}

ThemeData buildTheme(
  Brightness brightness, [
  AppPalette palette = AppPalette.luxury,
]) {
  final dark = brightness == Brightness.dark;
  final scheme = _scheme(palette, brightness);
  final cardColor = _cardColor(palette, dark);
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
    extensions: [
      AppHero(
        top: palette.heroTop,
        bottom: palette.heroBottom,
        accent: palette.heroAccent,
      ),
    ],
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
