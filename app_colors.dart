import 'package:flutter/material.dart';

/// Fixed "brand chrome" colors — stay the same in light and dark mode
/// (header, drawer, primary buttons), mirroring the web prototype.
class AppColors {
  static const ink = Color(0xFF0F3D3E);
  static const gold = Color(0xFFC9A227);
  static const maroon = Color(0xFF7A2E2E);
  static const voiceRed = Color(0xFFC0392B);
}

/// Surface colors that flip between light/dark mode.
class AppSurface {
  final Color bg;
  final Color card;
  final Color cardAlt;
  final Color text;
  final Color muted;

  const AppSurface({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.text,
    required this.muted,
  });

  static const light = AppSurface(
    bg: Color(0xFFF6EFE2),
    card: Color(0xFFFBF7EC),
    cardAlt: Color(0xFFF0E8D5),
    text: Color(0xFF2B2620),
    muted: Color(0xFF8A7F6A),
  );

  static const dark = AppSurface(
    bg: Color(0xFF15211F),
    card: Color(0xFF1E2C29),
    cardAlt: Color(0xFF26362F),
    text: Color(0xFFEFE7D6),
    muted: Color(0xFF9C9486),
  );
}
