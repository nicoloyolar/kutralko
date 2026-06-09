import 'package:flutter/material.dart';

class KutralKoColors {
  const KutralKoColors._();

  static const carbon = Color(0xFF080706);
  static const obsidian = Color(0xFF0D0B08);
  static const ink = Color(0xFF18130E);
  static const graphite = Color(0xFF211B14);
  static const charcoal = Color(0xFF2C241A);
  static const smoke = Color(0xFFE9DDC7);
  static const ivory = Color(0xFFFFF8EA);
  static const champagne = Color(0xFFF6E6C3);
  static const panel = Color(0xFFFFFFFF);
  static const gold = Color(0xFFD6A947);
  static const amber = Color(0xFFF0B646);
  static const orange = Color(0xFFE56625);
  static const ember = Color(0xFFB83A1E);
  static const teal = Color(0xFF1A8B91);
  static const muted = Color(0xFF776B5F);
  static const success = Color(0xFF247A52);
}

class KutralKoTheme {
  const KutralKoTheme._();

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KutralKoColors.gold,
        brightness: Brightness.dark,
        primary: KutralKoColors.gold,
        secondary: KutralKoColors.gold,
        surface: KutralKoColors.graphite,
        onSurface: KutralKoColors.ivory,
        error: KutralKoColors.ember,
      ),
      scaffoldBackgroundColor: KutralKoColors.obsidian,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: KutralKoColors.carbon,
        surfaceTintColor: KutralKoColors.carbon,
        foregroundColor: KutralKoColors.ivory,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KutralKoColors.carbon,
        indicatorColor: KutralKoColors.gold.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? KutralKoColors.gold : KutralKoColors.smoke,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? KutralKoColors.gold : KutralKoColors.smoke,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: KutralKoColors.graphite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: KutralKoColors.gold.withValues(alpha: 0.12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KutralKoColors.gold,
          foregroundColor: KutralKoColors.carbon,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KutralKoColors.gold,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: KutralKoColors.gold.withValues(alpha: 0.42)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: KutralKoColors.gold),
      ),
      iconTheme: const IconThemeData(color: KutralKoColors.champagne),
      dividerTheme: DividerThemeData(
        color: KutralKoColors.gold.withValues(alpha: 0.14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KutralKoColors.ink,
        labelStyle: const TextStyle(color: KutralKoColors.champagne),
        hintStyle: TextStyle(
          color: KutralKoColors.smoke.withValues(alpha: 0.62),
        ),
        prefixIconColor: KutralKoColors.gold,
        suffixIconColor: KutralKoColors.smoke,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: KutralKoColors.gold.withValues(alpha: 0.24),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: KutralKoColors.gold.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KutralKoColors.gold, width: 1.5),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return KutralKoColors.gold.withValues(alpha: 0.95);
            }
            return KutralKoColors.ink;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return KutralKoColors.carbon;
            }
            return KutralKoColors.smoke;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: KutralKoColors.gold.withValues(alpha: 0.42)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
