import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextStyle heading(AppSurface s, {double size = 20, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.amiri(fontSize: size, fontWeight: weight, color: s.text);

  static TextStyle body(AppSurface s, {double size = 15}) =>
      GoogleFonts.tajawal(fontSize: size, color: s.text);

  static ThemeData build(AppSurface s, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: s.bg,
      fontFamily: GoogleFonts.tajawal().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        brightness: brightness,
        background: s.bg,
        surface: s.card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: Color(0xFFF6EFE2),
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }
}
