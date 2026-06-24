import 'package:flutter/material.dart';

class AppColors {
  // Arrière-plans (fond dark navy)
  static const Color backgroundDark = Color(0xFF0D1B3E);
  static const Color cardDark = Color(0xFF132040);
  static const Color surfaceSecondary = Color(0xFF1A2B52);

  // Accents & actions
  static const Color primaryBlue = Color(0xFF4B8EFF);
  static const Color cyanTeal = Color(0xFF00D4C8);
  static const Color ctaGetStarted = Color(0xFF2563EB);

  // États financiers
  static const Color incomeGreen = Color(0xFF22C55E);
  static const Color outcomeRed = Color(0xFFEF4444);

  // Textes
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);

  // Décoratif
  static const Color gradientStart = Color(0xFF6EA8FF);
  static const Color gradientEnd = Color(0xFF1E3A8A);
  static const Color pillBadge = Color(0xFF2A3F7A);
  static const Color navActive = Color(0xFF38BDF8);

  // Arrière-plans (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceSecondaryLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Textes (Light Mode)
  static const Color textTitleLight = Color(0xFF0F172A);
  static const Color textMainLight = Color(0xFF1E293B);
  static const Color textBodyLight = Color(0xFF334155);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color textSmallLight = Color(0xFF475569);

  // Fallbacks for existing variables used elsewhere
  static const Color primary = primaryBlue;
  static const Color secondary = cyanTeal;
  static const Color tertiary = ctaGetStarted;

  static const Color success = incomeGreen;
  static const Color error = outcomeRed;
  static const Color warning = Colors.orange;
  static const Color starRating = Colors.amber;

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  static const MaterialColor grey = Colors.grey;
}
