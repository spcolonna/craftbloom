import 'package:flutter/material.dart';
import 'package:craftbloom/core/config/color_config.dart';

abstract final class AppColors {
  // ── Primario — derivado de ColorConfig.primary ────────────────────────
  static const primary      = ColorConfig.primary;
  static final primaryDark  = _darken(ColorConfig.primary, 0.14);
  static final primaryLight = _lighten(ColorConfig.primary, 0.13);

  // ── Secundario — derivado de ColorConfig.secondary ────────────────────
  static const secondary      = ColorConfig.secondary;
  static final secondaryDark  = _darken(ColorConfig.secondary, 0.14);
  static final secondaryLight = _lighten(ColorConfig.secondary, 0.14);

  // ── Acento — derivado de ColorConfig.accent ───────────────────────────
  static const accent      = ColorConfig.accent;
  static final accentLight = _lighten(ColorConfig.accent, 0.15);

  // ── Fondos ────────────────────────────────────────────────────────────
  static const background     = ColorConfig.background;
  static const surface        = Color(0xFFFFFFFF);
  static final surfaceVariant = _darken(ColorConfig.background, 0.02);

  // ── Texto — derivado de ColorConfig.textBase ──────────────────────────
  static const textPrimary   = ColorConfig.textBase;
  static final textSecondary = _lighten(ColorConfig.textBase, 0.25);
  static final textDisabled  = _lighten(ColorConfig.textBase, 0.45);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ── Bordes y separadores — derivados del color primario ───────────────
  static final divider = _lighten(ColorConfig.primary, 0.18);
  static final border  = _lighten(ColorConfig.primary, 0.12);

  // ── Estados de pedido (semánticos — no cambian con la marca) ──────────
  static const statusPending         = Color(0xFF9E9E9E);
  static const statusReceived        = Color(0xFF2196F3);
  static const statusAccepted        = Color(0xFF00BCD4);
  static const statusRejected        = Color(0xFFF44336);
  static const statusAwaitingPayment = Color(0xFFFF9800);
  static const statusProcessing      = Color(0xFF9C27B0);
  static const statusPaused          = Color(0xFF795548);
  static const statusReady           = Color(0xFF4CAF50);
  static const statusShipped         = Color(0xFF03A9F4);
  static const statusCompleted       = Color(0xFF388E3C);
  static const statusCancelled       = Color(0xFFB71C1C);

  // ── Semánticos (fijos) ────────────────────────────────────────────────
  static const error   = Color(0xFFB00020);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const info    = Color(0xFF2196F3);

  // ── Helpers ───────────────────────────────────────────────────────────
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
