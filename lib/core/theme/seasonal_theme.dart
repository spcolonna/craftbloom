import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum
// ─────────────────────────────────────────────────────────────────────────────

enum SeasonalTheme {
  normal,
  christmas,
  halloween,
  valentines;

  String get label => switch (this) {
    normal     => 'Normal',
    christmas  => 'Navidad',
    halloween  => 'Halloween',
    valentines => 'San Valentín',
  };

  String get emoji => switch (this) {
    normal     => '🌸',
    christmas  => '🎄',
    halloween  => '🎃',
    valentines => '💕',
  };

  static SeasonalTheme fromString(String? value) =>
      SeasonalTheme.values.firstWhere(
        (t) => t.name == value,
        orElse: () => SeasonalTheme.normal,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Paleta de colores por tema (con derivados automáticos, igual que AppColors)
// ─────────────────────────────────────────────────────────────────────────────

class SeasonalPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textBase;
  final Color? particleColor1;
  final Color? particleColor2;

  const SeasonalPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textBase,
    this.particleColor1,
    this.particleColor2,
  });

  Color get primaryLight    => _lighten(primary, 0.13);
  Color get primaryDark     => _darken(primary, 0.14);
  Color get secondaryLight  => _lighten(secondary, 0.14);
  Color get accentLight     => _lighten(accent, 0.15);
  Color get surfaceVariant  => _darken(background, 0.02);
  Color get textSecondary   => _lighten(textBase, 0.25);
  Color get textDisabled    => _lighten(textBase, 0.45);
  Color get divider         => _lighten(primary, 0.18);
  Color get border          => _lighten(primary, 0.12);
  Color get surface         => const Color(0xFFFFFFFF);
  Color get textOnPrimary   => const Color(0xFFFFFFFF);

  static Color _darken(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, double a) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + a).clamp(0.0, 1.0)).toColor();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paletas
// ─────────────────────────────────────────────────────────────────────────────

const _palettes = <SeasonalTheme, SeasonalPalette>{
  SeasonalTheme.normal: SeasonalPalette(
    primary:    Color(0xFFE8A0BF),
    secondary:  Color(0xFFBA90C6),
    accent:     Color(0xFFCFA05A),
    background: Color(0xFFFFF5F0),
    textBase:   Color(0xFF2D1B33),
  ),
  SeasonalTheme.christmas: SeasonalPalette(
    primary:         Color(0xFFCC2936),
    secondary:       Color(0xFF2D6A2D),
    accent:          Color(0xFFFFD700),
    background:      Color(0xFFFFF8F0),
    textBase:        Color(0xFF1A2E1A),
    particleColor1:  Color(0xFFFFFFFF),
    particleColor2:  Color(0xFFB8D4F5),
  ),
  SeasonalTheme.halloween: SeasonalPalette(
    primary:         Color(0xFFFF6B00),
    secondary:       Color(0xFF7B2FBE),
    accent:          Color(0xFF84CC16),
    background:      Color(0xFF1A0A2E),
    textBase:        Color(0xFFF5E6FF),
    particleColor1:  Color(0xFFFF6B00),
    particleColor2:  Color(0xFF7B2FBE),
  ),
  SeasonalTheme.valentines: SeasonalPalette(
    primary:         Color(0xFFE91E63),
    secondary:       Color(0xFFFF6090),
    accent:          Color(0xFFFFD700),
    background:      Color(0xFFFFF0F3),
    textBase:        Color(0xFF4A0030),
    particleColor1:  Color(0xFFE91E63),
    particleColor2:  Color(0xFFFF6090),
  ),
};

SeasonalPalette getPalette(SeasonalTheme theme) =>
    _palettes[theme] ?? _palettes[SeasonalTheme.normal]!;
