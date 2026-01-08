import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_utils.dart';

/// BuildContext extensions for easy theme access throughout the app.
///
/// ## Usage
/// ```dart
/// // Access colors
/// context.primaryColor
/// context.surfaceColor
/// context.textPrimary
///
/// // Check mode
/// context.isDarkMode
///
/// // Access gradients
/// context.primaryGradient
/// ```
extension AppThemeExtension on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);

  /// Get the current color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get the current text theme
  TextTheme get textTheme => theme.textTheme;

  /// Check if current theme is dark
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // ============================================
  // PRIMARY COLORS
  // ============================================

  /// Primary color (adapts to current theme)
  Color get primaryColor => colorScheme.primary;

  /// Primary container color
  Color get primaryContainer => colorScheme.primaryContainer;

  /// Text/icon color on primary
  Color get onPrimary => colorScheme.onPrimary;

  /// Text/icon color on primary container
  Color get onPrimaryContainer => colorScheme.onPrimaryContainer;

  // ============================================
  // SECONDARY COLORS
  // ============================================

  /// Secondary color (adapts to current theme)
  Color get secondaryColor => colorScheme.secondary;

  /// Secondary container color
  Color get secondaryContainer => colorScheme.secondaryContainer;

  /// Text/icon color on secondary
  Color get onSecondary => colorScheme.onSecondary;

  /// Text/icon color on secondary container
  Color get onSecondaryContainer => colorScheme.onSecondaryContainer;

  // ============================================
  // SURFACE COLORS
  // ============================================

  /// Main surface/background color
  Color get surfaceColor => colorScheme.surface;

  /// Surface variant (for cards, containers)
  Color get surfaceVariant => colorScheme.surfaceContainerHighest;

  /// Text/icon color on surface
  Color get onSurface => colorScheme.onSurface;

  /// Secondary text/icon color on surface
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;

  /// Background color (alias for surface in M3)
  Color get backgroundColor => colorScheme.surface;

  /// Text/icon color on background
  Color get onBackground => colorScheme.onSurface;

  // ============================================
  // OUTLINE COLORS
  // ============================================

  /// Outline/border color
  Color get outlineColor => colorScheme.outline;

  /// Subtle outline/border color
  Color get outlineVariant => colorScheme.outlineVariant;

  // ============================================
  // ERROR COLORS
  // ============================================

  /// Error color
  Color get errorColor => colorScheme.error;

  /// Text/icon color on error
  Color get onError => colorScheme.onError;

  /// Error container color
  Color get errorContainer => colorScheme.errorContainer;

  /// Text/icon color on error container
  Color get onErrorContainer => colorScheme.onErrorContainer;

  // ============================================
  // STATUS COLORS (from AppColors)
  // ============================================

  /// Success color (adapts to light/dark mode for contrast)
  Color get successColor =>
      isDarkMode ? AppColors.successContainer : AppColors.success;

  /// Text/icon color on success
  Color get onSuccessColor =>
      isDarkMode ? AppColors.onSuccessContainer : AppColors.onSuccess;

  /// Warning color (adapts to light/dark mode for contrast)
  Color get warningColor =>
      isDarkMode ? AppColors.warningContainer : AppColors.warning;

  /// Text/icon color on warning
  Color get onWarningColor =>
      isDarkMode ? AppColors.onWarningContainer : AppColors.onWarning;

  /// Info color (adapts to light/dark mode for contrast)
  Color get infoColor => isDarkMode ? AppColors.infoContainer : AppColors.info;

  /// Text/icon color on info
  Color get onInfoColor =>
      isDarkMode ? AppColors.onInfoContainer : AppColors.onInfo;

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Primary text color
  Color get textPrimary => onSurface;

  /// Secondary text color
  Color get textSecondary => onSurfaceVariant;

  /// Disabled text color
  Color get textDisabled => onSurface.withValues(alpha: 0.38);

  // ============================================
  // GRADIENTS
  // ============================================

  /// Primary gradient using theme colors
  List<Color> get primaryGradient => [
    primaryColor,
    ColorUtils.lighten(primaryColor, 0.1),
  ];

  /// Secondary gradient using theme colors
  List<Color> get secondaryGradient => [
    secondaryColor,
    ColorUtils.lighten(secondaryColor, 0.1),
  ];

  /// Success gradient
  List<Color> get successGradient => [
    successColor,
    ColorUtils.lighten(successColor, 0.15),
  ];

  /// Warm gradient - shifts primary toward orange/red tones
  List<Color> get warmGradient {
    final hsl = HSLColor.fromColor(primaryColor);
    // Shift hue toward warm (30° is orange, 0° is red)
    final warmHue = (hsl.hue - 20).clamp(0.0, 360.0);
    final warmColor = hsl
        .withHue(warmHue)
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor();
    return [primaryColor, warmColor];
  }

  /// Cool gradient - shifts secondary toward blue/cyan tones
  List<Color> get coolGradient {
    final hsl = HSLColor.fromColor(secondaryColor);
    // Shift hue toward cool (200° is cyan, 240° is blue)
    final coolHue = (hsl.hue + 20) % 360;
    final coolColor = hsl
        .withHue(coolHue)
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor();
    return [secondaryColor, coolColor];
  }
}
