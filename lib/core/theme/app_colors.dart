import 'package:flutter/material.dart';

/// App Colors - Centralized color palette for FlutterLifter
/// Updated with warmer coral/orange primary and teal secondary
class AppColors {
  // Primary Colors - Warm Coral/Orange
  static const Color primary = Color(0xFFFF6B4A);
  static const Color primaryLight = Color(0xFFFF9A7A);
  static const Color primaryDark = Color(0xFFE54525);

  // Secondary Colors - Teal
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF64D8CB);
  static const Color secondaryDark = Color(0xFF00796B);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFFF2F4F8);
  static const Color surfaceVariantLight = Color(0xFF1E1E1E);

  // Surface Tints for M3 depth perception
  static const Color surfaceTint = primary;
  static const Color surfaceContainer = Color(0xFFF5F6F8);
  static const Color surfaceContainerLow = Color(0xFFF8F9FA);
  static const Color surfaceContainerHigh = Color(0xFFEEF0F2);
  static const Color surfaceContainerHighest = Color(0xFFE5E8EB);
  // Dark mode surface containers - improved contrast for visibility
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);
  static const Color surfaceContainerLowDark = Color(0xFF1A1A1A);
  static const Color surfaceContainerHighDark = Color(0xFF282828);
  static const Color surfaceContainerHighestDark = Color(0xFF323232);

  // Outline Colors - Light mode improved for visibility
  static const Color outline = Color(0xFFADB5BD);
  static const Color outlineVariant = Color(0xFFCED4DA);
  // Dark mode outlines - improved visibility against dark surfaces
  static const Color outlineDark = Color(0xFF5C5C5C);
  static const Color outlineVariantDark = Color(0xFF404040);

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF212121);
  static const Color onSurfaceLight = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textHint = Color(0xFF9E9E9E);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessLight = Color(0xFF064E3B);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorLight = Color(0xFF7F1D1D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFDE68A);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningLight = Color(0xFF78350F);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFBFDBFE);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoLight = Color(0xFF1E3A8A);

  // Border Colors - improved for light mode visibility
  static const Color border = Color(0xFFCED4DA);
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color borderDark = Color(0xFFADB5BD);

  // Social Colors
  // static const Color google = Color(0xFF4285F4);
  static const Color google = Color(0xFFEA4335);
  static const Color facebook = Color(0xFF1877F2);
  static const Color apple = Color(0xFF000000);

  // Fitness-specific Colors
  static const Color cardio = Color(0xFFFF6B6B);
  static const Color strength = Color(0xFF4ECDC4);
  static const Color flexibility = Color(0xFFFFE66D);
  static const Color rest = Color(0xFF95E1D3);

  // Muscle Group Colors for exercise indicators
  static const Color muscleChest = Color(0xFFFF6B4A);
  static const Color muscleBack = Color(0xFF26A69A);
  static const Color muscleLegs = Color(0xFF7C3AED);
  static const Color muscleShoulders = Color(0xFFF59E0B);
  static const Color muscleArms = Color(0xFF3B82F6);
  static const Color muscleCore = Color(0xFF10B981);
  static const Color muscleFullBody = Color(0xFFEC4899);

  // Gradient Definitions
  static const List<Color> primaryGradient = [primary, primaryLight];
  static const List<Color> secondaryGradient = [secondary, secondaryLight];
  static const List<Color> successGradient = [success, Color(0xFF34D399)];
  static const List<Color> warmGradient = [
    Color(0xFFFF6B4A),
    Color(0xFFFFA07A)
  ];
  static const List<Color> coolGradient = [
    Color(0xFF26A69A),
    Color(0xFF4DD0E1)
  ];
  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B4A),
    Color(0xFFFF9A7A),
    Color(0xFFFFC371)
  ];
  static const List<Color> oceanGradient = [
    Color(0xFF26A69A),
    Color(0xFF64D8CB),
    Color(0xFF80DEEA)
  ];

  // Glassmorphism Colors
  // Light mode: Use subtle dark tint for glass effect on light backgrounds
  static Color glassWhite = Colors.white.withValues(alpha: 0.7);
  static Color glassWhiteStrong = Colors.white.withValues(alpha: 0.85);
  static Color glassBorder = Color(0xFF000000).withValues(alpha: 0.08);
  // Dark mode: Use light tint for glass effect on dark backgrounds
  static Color glassBlack = Colors.white.withValues(alpha: 0.08);
  static Color glassBlackStrong = Colors.white.withValues(alpha: 0.15);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.15);
  // Glass shadow for depth
  static Color glassShadow = Colors.black.withValues(alpha: 0.1);
  static Color glassShadowDark = Colors.black.withValues(alpha: 0.3);

  /// Get muscle group color by name
  static Color getMuscleGroupColor(String muscleGroup) {
    final normalized = muscleGroup.toLowerCase();
    if (normalized.contains('chest') || normalized.contains('pec')) {
      return muscleChest;
    } else if (normalized.contains('back') || normalized.contains('lat')) {
      return muscleBack;
    } else if (normalized.contains('leg') ||
        normalized.contains('quad') ||
        normalized.contains('hamstring') ||
        normalized.contains('glute') ||
        normalized.contains('calf')) {
      return muscleLegs;
    } else if (normalized.contains('shoulder') || normalized.contains('delt')) {
      return muscleShoulders;
    } else if (normalized.contains('arm') ||
        normalized.contains('bicep') ||
        normalized.contains('tricep')) {
      return muscleArms;
    } else if (normalized.contains('core') || normalized.contains('ab')) {
      return muscleCore;
    } else {
      return muscleFullBody;
    }
  }
}
