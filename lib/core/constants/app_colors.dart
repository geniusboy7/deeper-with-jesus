import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color primaryLight = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color ctaGoldLight = Color(0xFFCA8A04);
  static const Color backgroundLight = Color(0xFFFAF5FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF4C1D95);
  static const Color textSecondaryLight = Color(0xFF6D28D9);
  static const Color errorLight = Color(0xFFDC2626);
  static const Color dividerLight = Color(0xFFE9D5FF);

  // Dark Mode
  static const Color primaryDark = Color(0xFFA78BFA);
  static const Color secondaryDark = Color(0xFFC4B5FD);
  static const Color ctaGoldDark = Color(0xFFEAB308);
  static const Color backgroundDark = Color(0xFF1C1023);
  static const Color surfaceDark = Color(0xFF2D1F3D);
  static const Color textPrimaryDark = Color(0xFFF3E8FF);
  static const Color textSecondaryDark = Color(0xFFC4B5FD);
  static const Color errorDark = Color(0xFFF87171);
  static const Color dividerDark = Color(0xFF3D2A54);

  // Shared
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color overlay = Color(0x80000000);
  static const Color likeRed = Color(0xFFEF4444);
  static const Color gold = Color(0xFFCA8A04);

  // Get theme-aware color
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryDark : primaryLight;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dividerDark : dividerLight;
}
