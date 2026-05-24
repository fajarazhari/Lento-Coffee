import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.coffeeBrown,
      brightness: Brightness.light,
      primary: AppColors.coffeeBrown,
      secondary: AppColors.goldBrown,
      surface: AppColors.warmCream,
      onPrimary: AppColors.pureWhite,
      onSecondary: AppColors.pureWhite,
      onSurface: AppColors.textDark,
    ),
    scaffoldBackgroundColor: AppColors.warmCream,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.pureWhite,
      foregroundColor: AppColors.coffeeBrown,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.coffeeBrown,
        letterSpacing: 1,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.coffeeBrown,
        foregroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.pureWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.coffeeBrown, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.coffeeMuted,
        fontSize: 12,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.pureWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.pureWhite,
      selectedColor: AppColors.coffeeBrown,
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderColor,
      thickness: 1,
    ),
  );
}
