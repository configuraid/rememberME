import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2C3E50);
  static const Color primaryLight = Color(0xFF34495E);
  static const Color primaryDark = Color(0xFF1A252F);

  // Secondary Colors
  static const Color secondary = Color(0xFFE8B4A7);
  static const Color secondaryLight = Color(0xFFF5D6CE);
  static const Color secondaryDark = Color(0xFFD89A89);

  // Accent Colors
  static const Color accent = Color(0xFFDAA520);
  static const Color accentLight = Color(0xFFFFD700);

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Dark Mode Backgrounds
  static const Color backgroundDark = Color(0xFF000000);
  static const Color backgroundDarkElevated = Color(0xFF1C1C1E);
  static const Color backgroundDarkSecondary = Color(0xFF121212);

  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDarkSecondary = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Interactive Colors (iOS-style blue, can be used cross-platform)
  static const Color interactive = Color(0xFF007AFF);
  static const Color interactiveLight = Color(0xFF5AC8FA);

  // License Colors
  static const Color basicLicense = Color(0xFF6C757D);
  static const Color lifetimeLicense = Color(0xFFDAA520);

  // Divider & Borders
  static const Color divider = Color(0xFFDEE2E6);
  static const Color border = Color(0xFFCED4DA);
  static const Color borderDark = Color(0xFF38383A);
  static const Color borderDarkLight = Color(0xFF48484A);
  static const Color borderDarkSubtle = Color(0xFF404040);

  // Overlay & Toast
  static const Color toastBackgroundDark = Color(0xFF2C2C2E);
  static const Color toastBackgroundLight = Color(0xFFFFFFFF);

  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x80000000);

  // Grey Scale (für UI-Elemente)
  static const Color grey = Color(0xFF808080);
  static const Color greyLight = Color(0xFFC7C7CC);
  static const Color greyLighter = Color(0xFFE5E5EA);
  static const Color greyDark = Color(0xFF636366);

  static const Color errorLight = Color(0xFFFFB4AB);
  static const Color errorDark = Color(0xFF690005);

  static const Color cardBorderDark = Color(0xFF2A2A2A);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF2C3E50),
    Color(0xFF34495E),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFDAA520),
    Color(0xFFFFD700),
  ];
}
