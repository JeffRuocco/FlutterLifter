import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Utility functions for color manipulation and theme generation
class ColorUtils {
  ColorUtils._();

  /// Lightens a color by the given amount (0.0 to 1.0)
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darkens a color by the given amount (0.0 to 1.0)
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Adjusts saturation of a color by the given amount
  static Color saturate(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Desaturates a color by the given amount
  static Color desaturate(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Creates a light variant of a color suitable for light theme containers
  static Color createLightVariant(Color color) {
    return lighten(color, 0.25);
  }

  /// Creates a dark variant of a color suitable for dark theme containers
  static Color createDarkVariant(Color color) {
    return darken(color, 0.15);
  }

  /// Creates a container color (lighter, less saturated version)
  static Color createContainerColor(Color color, {required bool isDark}) {
    if (isDark) {
      return darken(desaturate(color, 0.2), 0.3);
    } else {
      return lighten(desaturate(color, 0.3), 0.35);
    }
  }

  /// Determines if a color is considered "light" based on luminance
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// Gets the best contrasting text color (black or white) for a background
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Generates a full ColorScheme from primary and secondary colors
  static ColorScheme generateColorScheme({
    required Color primary,
    required Color secondary,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    // Generate primary variants
    final primaryLight = lighten(primary, 0.2);
    final primaryDark = darken(primary, 0.15);
    final primaryContainer =
        isDark ? darken(primary, 0.25) : lighten(primary, 0.35);
    final onPrimary = getContrastingTextColor(primary);
    final onPrimaryContainer = isDark ? primaryLight : primaryDark;

    // Generate secondary variants
    final secondaryLight = lighten(secondary, 0.2);
    final secondaryDark = darken(secondary, 0.15);
    final secondaryContainer =
        isDark ? darken(secondary, 0.25) : lighten(secondary, 0.35);
    final onSecondary = getContrastingTextColor(secondary);
    final onSecondaryContainer = isDark ? secondaryLight : secondaryDark;

    // Surface colors
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final onSurface = isDark ? AppColors.onSurfaceLight : AppColors.onSurface;
    final surfaceVariant = isDark
        ? AppColors.surfaceContainerHighestDark
        : AppColors.surfaceVariant;
    final onSurfaceVariant = isDark ? Colors.white70 : AppColors.textSecondary;

    // Outline colors
    final outline = isDark ? AppColors.outlineDark : AppColors.outline;
    final outlineVariant =
        isDark ? AppColors.outlineVariantDark : AppColors.outlineVariant;

    // Error colors remain constant
    const error = AppColors.error;
    final errorContainer = isDark ? darken(error, 0.3) : lighten(error, 0.35);

    return ColorScheme(
      brightness: brightness,
      primary: isDark ? primaryLight : primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: isDark ? secondaryLight : secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: isDark ? lighten(error, 0.3) : darken(error, 0.3),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.surface : AppColors.surfaceDark,
      onInverseSurface: isDark ? AppColors.onSurface : AppColors.onSurfaceLight,
      inversePrimary: isDark ? primary : primaryLight,
      surfaceTint: isDark ? primaryLight : primary,
    );
  }
}

/// Utilities for WCAG contrast ratio validation
class ContrastUtils {
  ContrastUtils._();

  /// Calculates the relative luminance of a color (WCAG 2.1)
  /// Returns a value between 0 (black) and 1 (white)
  static double getLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Calculates the contrast ratio between two colors
  /// Returns a value between 1 (no contrast) and 21 (max contrast)
  static double getContrastRatio(Color foreground, Color background) {
    final fgLuminance = getLuminance(foreground) + 0.05;
    final bgLuminance = getLuminance(background) + 0.05;
    return fgLuminance > bgLuminance
        ? fgLuminance / bgLuminance
        : bgLuminance / fgLuminance;
  }

  /// WCAG AA requires 4.5:1 for normal text, 3:1 for large text
  /// Large text is 18pt+ regular or 14pt+ bold
  static bool meetsWCAGAA(Color foreground, Color background,
      {bool largeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return largeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// WCAG AAA requires 7:1 for normal text, 4.5:1 for large text
  static bool meetsWCAGAAA(Color foreground, Color background,
      {bool largeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return largeText ? ratio >= 4.5 : ratio >= 7.0;
  }

  /// Returns a human-readable contrast level
  static ContrastLevel getContrastLevel(Color foreground, Color background) {
    final ratio = getContrastRatio(foreground, background);
    if (ratio >= 7.0) return ContrastLevel.aaa;
    if (ratio >= 4.5) return ContrastLevel.aa;
    if (ratio >= 3.0) return ContrastLevel.aaLarge;
    return ContrastLevel.fail;
  }

  /// Returns the contrast ratio formatted as a string (e.g., "4.5:1")
  static String formatContrastRatio(Color foreground, Color background) {
    final ratio = getContrastRatio(foreground, background);
    return '${ratio.toStringAsFixed(1)}:1';
  }

  /// Suggests a better color if contrast is insufficient
  /// Returns null if the current color already meets requirements
  static Color? suggestBetterContrast(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    if (meetsWCAGAA(foreground, background, largeText: largeText)) {
      return null; // Already good
    }

    final bgLuminance = getLuminance(background);
    final isLightBg = bgLuminance > 0.5;

    // Try to adjust the foreground color
    var adjusted = foreground;
    for (var i = 0; i < 20; i++) {
      adjusted = isLightBg
          ? ColorUtils.darken(adjusted, 0.05)
          : ColorUtils.lighten(adjusted, 0.05);

      if (meetsWCAGAA(adjusted, background, largeText: largeText)) {
        return adjusted;
      }
    }

    // Fallback to black or white
    return isLightBg ? Colors.black : Colors.white;
  }
}

/// Contrast level based on WCAG guidelines
enum ContrastLevel {
  /// Fails WCAG requirements (< 3:1)
  fail,

  /// Passes for large text only (>= 3:1)
  aaLarge,

  /// Passes WCAG AA (>= 4.5:1)
  aa,

  /// Passes WCAG AAA (>= 7:1)
  aaa,
}

extension ContrastLevelExtension on ContrastLevel {
  /// Human-readable label
  String get label {
    switch (this) {
      case ContrastLevel.fail:
        return 'Low Contrast';
      case ContrastLevel.aaLarge:
        return 'OK for Large Text';
      case ContrastLevel.aa:
        return 'Good (AA)';
      case ContrastLevel.aaa:
        return 'Excellent (AAA)';
    }
  }

  /// Color to represent this level
  Color get indicatorColor {
    switch (this) {
      case ContrastLevel.fail:
        return const Color(0xFFEF4444); // Red
      case ContrastLevel.aaLarge:
        return const Color(0xFFF59E0B); // Amber
      case ContrastLevel.aa:
        return const Color(0xFF10B981); // Green
      case ContrastLevel.aaa:
        return const Color(0xFF059669); // Darker Green
    }
  }

  /// Whether this level passes minimum accessibility
  bool get passesMinimum => this != ContrastLevel.fail;
}
