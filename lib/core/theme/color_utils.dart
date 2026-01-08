import 'package:flutter/material.dart';

/// Utility functions for color manipulation.
///
/// ## Usage
/// ```dart
/// // Lighten/darken colors
/// ColorUtils.lighten(color, 0.2);
/// ColorUtils.darken(color, 0.1);
///
/// // Get contrasting text color
/// ColorUtils.getContrastingTextColor(backgroundColor);
/// ```
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

  /// Determines if a color is considered "light" based on luminance
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// Gets the best contrasting text color (black or white) for a background
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Gets an "on" color for a given background that meets WCAG AA contrast.
  ///
  /// Unlike [getContrastingTextColor] which only returns black/white,
  /// this method tries to find a tinted version of the background color
  /// that still provides sufficient contrast, giving a more cohesive look.
  ///
  /// Falls back to black or white if no tinted option works.
  static Color getOnColor(
    Color backgroundColor, {
    double minContrastRatio = 4.5,
  }) {
    final bgLuminance = backgroundColor.computeLuminance();
    final isLightBg = bgLuminance > 0.5;

    // First, check if pure black or white is needed
    final pureContrast = isLightBg ? Colors.black : Colors.white;

    // For very light or very dark backgrounds, just use black/white
    if (bgLuminance > 0.85 || bgLuminance < 0.15) {
      return pureContrast;
    }

    // Try to find a tinted version that works
    final hsl = HSLColor.fromColor(backgroundColor);

    // Target lightness: very dark for light backgrounds, very light for dark
    final targetLightness = isLightBg ? 0.15 : 0.95;

    // Create a tinted version
    var tinted = hsl.withLightness(targetLightness).toColor();

    // Check if it meets contrast requirements
    final contrastRatio = ContrastUtils.getContrastRatio(
      tinted,
      backgroundColor,
    );

    if (contrastRatio >= minContrastRatio) {
      return tinted;
    }

    // If tinted doesn't work, try adjusting further
    final adjustStep = isLightBg ? -0.05 : 0.05;
    var currentLightness = targetLightness;

    for (var i = 0; i < 10; i++) {
      currentLightness = (currentLightness + adjustStep).clamp(0.0, 1.0);
      tinted = hsl.withLightness(currentLightness).toColor();

      if (ContrastUtils.getContrastRatio(tinted, backgroundColor) >=
          minContrastRatio) {
        return tinted;
      }
    }

    // Fallback to pure black or white
    return pureContrast;
  }

  /// Generates a container color from a primary/secondary color.
  ///
  /// Container colors are muted versions used for backgrounds (like chips,
  /// cards, etc.) that still relate to the source color.
  ///
  /// [forDarkTheme] - Whether this is for dark mode
  /// [opacity] - How much of the color to preserve (0.0-1.0)
  static Color getContainerColor(
    Color sourceColor, {
    required bool forDarkTheme,
    double opacity = 0.2,
  }) {
    final hsl = HSLColor.fromColor(sourceColor);

    if (forDarkTheme) {
      // For dark theme: darker, less saturated version
      return hsl
          .withLightness((hsl.lightness * 0.4).clamp(0.1, 0.3))
          .withSaturation((hsl.saturation * 0.7).clamp(0.0, 0.8))
          .toColor();
    } else {
      // For light theme: lighter, less saturated version
      return hsl
          .withLightness(
            (hsl.lightness + (1 - hsl.lightness) * 0.7).clamp(0.85, 0.95),
          )
          .withSaturation((hsl.saturation * 0.5).clamp(0.0, 0.6))
          .toColor();
    }
  }

  /// Generates a complete "on" color set for a given source color.
  ///
  /// Returns a [ColorSet] with:
  /// - `onColor`: For use on the source color directly
  /// - `container`: A muted container version of the source
  /// - `onContainer`: For use on the container color
  static ColorSet getColorSet(Color sourceColor, {required bool forDarkTheme}) {
    final container = getContainerColor(
      sourceColor,
      forDarkTheme: forDarkTheme,
    );

    return ColorSet(
      onColor: getOnColor(sourceColor),
      container: container,
      onContainer: getOnColor(container),
    );
  }
}

/// A set of related colors for a primary/secondary color.
class ColorSet {
  final Color onColor;
  final Color container;
  final Color onContainer;

  const ColorSet({
    required this.onColor,
    required this.container,
    required this.onContainer,
  });
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
  static bool meetsWCAGAA(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    final ratio = getContrastRatio(foreground, background);
    return largeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// WCAG AAA requires 7:1 for normal text, 4.5:1 for large text
  static bool meetsWCAGAAA(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
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
