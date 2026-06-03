import 'package:flutter/material.dart';

class KutralKoColors {
  const KutralKoColors._();

  static const carbon = Color(0xFF141210);
  static const ink = Color(0xFF24201C);
  static const smoke = Color(0xFFEEE8DF);
  static const ivory = Color(0xFFFFFAF2);
  static const panel = Color(0xFFFFFFFF);
  static const gold = Color(0xFFC99A3A);
  static const amber = Color(0xFFE1A12F);
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
        backgroundColor: KutralKoColors.ivory,
        foregroundColor: KutralKoColors.carbon,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KutralKoColors.panel,
        indicatorColor: KutralKoColors.smoke,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
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
