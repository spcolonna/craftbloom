import 'package:flutter/material.dart';

/// ┌─────────────────────────────────────────────────────────────────────┐
/// │   PALETA DEL NEGOCIO — editá estos 5 valores para cambiar          │
/// │   la paleta completa de la app. El resto se deriva automáticamente. │
/// └─────────────────────────────────────────────────────────────────────┘
abstract final class ColorConfig {
  /// Color principal — botones, highlights, íconos activos.
  /// Tonos dark/light se generan solos a partir de este valor.
  static const Color primary = Color(0xFF317B74); // Teal profundo

  /// Color secundario — chips, badges, secciones de apoyo.
  static const Color secondary = Color(0xFFBF6B3D); // Terracota cálida

  /// Acento — estrellas de rating, badges especiales, detalles.
  static const Color accent = Color(0xFFF2C84B); // Amarillo solar

  /// Fondo general de la app (pantallas, Scaffold).
  static const Color background = Color(0xFFF4F2EE); // Lino cálido

  /// Color base para texto y elementos oscuros.
  /// textSecondary y textDisabled se aclaran automáticamente desde aquí.
  static const Color textBase = Color(0xFF1C2420); // Verde gris oscuro
}
