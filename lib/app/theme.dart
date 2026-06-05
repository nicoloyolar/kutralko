import 'package:flutter/material.dart';

class KutralKoColors {
  const KutralKoColors._();

  static const carbon = Color(0xFF080706);
  static const ink = Color(0xFF18130E);
  static const smoke = Color(0xFFE9DDC7);
  static const ivory = Color(0xFFFFF8EA);
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
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KutralKoColors.gold,
        brightness: Brightness.light,
        primary: KutralKoColors.carbon,
        secondary: KutralKoColors.gold,
        surface: KutralKoColors.ivory,
      ),
      scaffoldBackgroundColor: KutralKoColors.ivory,
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
        indicatorColor: KutralKoColors.gold.withValues(alpha: 0.2),
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
      cardTheme: const CardThemeData(
        color: KutralKoColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KutralKoColors.carbon,
          foregroundColor: KutralKoColors.ivory,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KutralKoColors.carbon,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: KutralKoColors.smoke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KutralKoColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KutralKoColors.smoke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KutralKoColors.smoke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KutralKoColors.gold, width: 1.5),
        ),
      ),
    );
  }
}
