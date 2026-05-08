import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/theme/seasonal_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => forSeason(SeasonalTheme.normal);

  static ThemeData forSeason(SeasonalTheme season) =>
      fromPalette(getPalette(season));

  static ThemeData fromPalette(SeasonalPalette p) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary:            p.primary,
        primaryContainer:   p.primaryLight,
        secondary:          p.secondary,
        secondaryContainer: p.secondaryLight,
        tertiary:           p.accent,
        surface:            p.surface,
        error:              const Color(0xFFB00020),
        onPrimary:          p.textOnPrimary,
        onSecondary:        p.textOnPrimary,
        onSurface:          p.textBase,
        onError:            p.textOnPrimary,
      ),
      scaffoldBackgroundColor: p.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48, fontWeight: FontWeight.w700,
          color: p.textBase, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36, fontWeight: FontWeight.w700, color: p.textBase,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 28, fontWeight: FontWeight.w600, color: p.textBase,
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: p.textBase,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: p.textBase,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: p.textBase,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: p.textBase,
        ),
        bodyLarge:  GoogleFonts.dmSans(fontSize: 16, color: p.textBase),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: p.textSecondary),
        bodySmall:  GoogleFonts.dmSans(fontSize: 12, color: p.textSecondary),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:       p.surface,
        foregroundColor:       p.textBase,
        elevation:             0,
        scrolledUnderElevation: 1,
        surfaceTintColor:      p.primaryLight,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700, color: p.textBase,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.textOnPrimary,
          minimumSize:     const Size(double.infinity, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize:     const Size(double.infinity, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          side: BorderSide(color: p.primary, width: 1.5),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      p.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide:   BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide:   BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide:   BorderSide(color: p.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide:   const BorderSide(color: Color(0xFFB00020)),
        ),
        labelStyle: GoogleFonts.dmSans(color: p.textSecondary),
        hintStyle:  GoogleFonts.dmSans(color: p.textDisabled),
      ),
      cardTheme: CardThemeData(
        color:     p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side:         BorderSide(color: p.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceVariant,
        selectedColor:   p.primaryLight,
        labelStyle:      GoogleFonts.dmSans(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide(color: p.border),
      ),
      dividerTheme: DividerThemeData(
        color: p.divider, thickness: 1, space: AppSizes.lg,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      p.surface,
        selectedItemColor:    p.primary,
        unselectedItemColor:  p.textDisabled,
        selectedLabelStyle:   GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
        type:      BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.textBase,
        contentTextStyle: GoogleFonts.dmSans(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
