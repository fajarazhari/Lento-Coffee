import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.coffeeBrown,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.coffeeBrown,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.coffeeLight,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.coffeeMuted,
  );

  static TextStyle get labelBold => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: AppColors.coffeeBrown,
  );

  static TextStyle get kdsTicketNumber => GoogleFonts.inter(
    fontSize: 72,
    fontWeight: FontWeight.w900,
    color: AppColors.coffeeBrown,
    letterSpacing: 2,
  );
}
