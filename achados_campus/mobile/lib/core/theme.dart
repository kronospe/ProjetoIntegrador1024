import 'package:material_ui/material_ui.dart';

/// Paleta do site original (base.css), em tema escuro.
class AppColors {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141C);
  static const surface2 = Color(0xFF1B1B26);
  static const border = Color(0x1FFFFFFF);
  static const text = Color(0xFFF0F0F5);
  static const text2 = Color(0x8CFFFFFF);
  static const text3 = Color(0x52FFFFFF);

  static const purple = Color(0xFF7C5CFC);
  static const purpleBg = Color(0x267C5CFC);
  static const green = Color(0xFF00C48C);
  static const greenBg = Color(0x2600C48C);
  static const red = Color(0xFFFF6B6B);
  static const redBg = Color(0x26FF6B6B);
  static const yellow = Color(0xFFFBBF24);
  static const yellowBg = Color(0x26FBBF24);
  static const gray = Color(0xFF94A3B8);
  static const grayBg = Color(0x2664748B);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.purple,
    onPrimary: Colors.white,
    secondary: AppColors.green,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.red,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
  );
}
