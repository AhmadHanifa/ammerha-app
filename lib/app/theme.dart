import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors from docs/design-identity.md («زيتوني هادي»).
abstract final class AppColors {
  static const primary = Color(0xFF3D6B5C);
  static const primaryDark = Color(0xFF2F5A4B);
  static const primaryTint = Color(0xFFE3EEE8);
  static const primarySoft = Color(0xFFF0F5F2);

  static const ink = Color(0xFF24302B);
  static const inkSoft = Color(0xFF5F6B65);
  static const line = Color(0xFFE3E9E5);
  static const lineSoft = Color(0xFFEEF2EF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F7F5);

  static const priceUp = Color(0xFFB54A3F);
  static const priceDown = Color(0xFF2F6B4F);

  static const importedBg = Color(0xFFE6EEF6);
  static const importedFg = Color(0xFF2C5584);
  static const freshBg = Color(0xFFF3E9D2);
  static const freshFg = Color(0xFF6B5320);
}

abstract final class AppRadius {
  static const card = 14.0;
  static const cardLarge = 20.0;
}

/// [useGoogleFonts] is off in widget tests, which have no network.
ThemeData buildAppTheme({bool useGoogleFonts = true}) {
  TextStyle font({double? fontSize, FontWeight? fontWeight, Color? color}) => useGoogleFonts
      ? GoogleFonts.ibmPlexSansArabic(fontSize: fontSize, fontWeight: fontWeight, color: color)
      : TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  final text = (useGoogleFonts ? GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme) : base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontSize: 24, height: 1.5, fontWeight: FontWeight.w600),
      titleMedium: text.titleMedium?.copyWith(fontSize: 17, height: 1.6, fontWeight: FontWeight.w600),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
      bodySmall: text.bodySmall?.copyWith(fontSize: 14, height: 1.6, color: AppColors.inkSoft),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        textStyle: font(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        textStyle: font(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryTint,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => font(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.inkSoft,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.inkSoft),
      ),
    ),
    dividerColor: AppColors.lineSoft,
  );
}
