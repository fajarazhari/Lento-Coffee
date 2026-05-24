import 'package:flutter/material.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────
// Mirrors the Kotlin/Compose UI theme exactly
abstract class AppColors {
  // Primary brand colors
  static const Color coffeeBrown = Color(0xFF5D4037);
  static const Color coffeeDark  = Color(0xFF3E2723);
  static const Color coffeeLight = Color(0xFF8D6E63);
  static const Color coffeeMuted = Color(0xFFBCAAA4);
  static const Color goldBrown   = Color(0xFFA1887F);

  // Background
  static const Color warmCream   = Color(0xFFFAF6F1);
  static const Color pureWhite   = Color(0xFFFFFFFF);

  // UI
  static const Color borderColor = Color(0xFFE0D5CB);
  static const Color searchBarBg = Color(0xFFF5F0EB);
  static const Color selectedBg  = Color(0xFFF0E8E0);
  static const Color textDark    = Color(0xFF2D1C0E);

  // Status
  static const Color statusGreen  = Color(0xFF2E7D32);
  static const Color statusOrange = Color(0xFFEF6C00);
  static const Color statusRed    = Color(0xFFC62828);
  static const Color statusBlue   = Color(0xFF1565C0);

  // KDS column badge colors
  static const Color kdsNewBadge    = Color(0xFFEF9A9A);
  static const Color kdsBrewBadge   = Color(0xFFFFCC80);
  static const Color kdsReadyBadge  = Color(0xFFA5D6A7);

  // Notification
  static const Color notificationBadge = Color(0xFFE53935);
}
