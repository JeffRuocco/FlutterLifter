import 'package:flutter/material.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

/// App Colors - Centralized color palette for FlutterLifter
///
/// ## Architecture
/// Colors are organized into semantic groups:
/// - **Semantic colors**: Status indicators (success, error, warning, info)
/// - **Neutral colors**: Surfaces, text, borders for light/dark modes
/// - **Domain colors**: Fitness-specific (muscle groups, workout types)
/// - **Brand colors**: Social login providers
///
/// ## Usage
/// Prefer using `context.primaryColor`, `context.surfaceColor` etc. from
/// theme_utils.dart which automatically adapts to the current theme.
/// Use these constants for static colors that don't change with theme.
class AppColors {
  AppColors._();

  // ============================================
  // SEMANTIC COLORS (same in light and dark mode)
  // ============================================

  /// Success state - confirmations, completed actions
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFF86EFAC);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF064E3B);

  /// Error state - failures, destructive actions
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  /// Warning state - caution, attention needed
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFDE68A);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF78350F);

  /// Info state - informational messages
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFBFDBFE);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF1E3A8A);

  // ============================================
  // NEUTRAL COLORS - LIGHT MODE
  // ============================================

  /// Light mode surfaces (Material 3 surface hierarchy)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Color(0xFFF5F6F8);
  static const Color surfaceContainerHigh = Color(0xFFEEF0F2);
  static const Color surfaceContainerHighest = Color(0xFFE5E8EB);

  /// Light mode text
  static const Color onSurface = Color(0xFF212121);
  static const Color onSurfaceVariant = Color(0xFF616161);
  static const Color textHint = Color(0xFF9E9E9E);

  /// Light mode outlines/borders
  static const Color outline = Color(0xFFADB5BD);
  static const Color outlineVariant = Color(0xFFCED4DA);

  // ============================================
  // NEUTRAL COLORS - DARK MODE
  // ============================================

  /// Dark mode surfaces (Material 3 surface hierarchy)
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceContainerLowestDark = Color(0xFF0E0E0E);
  static const Color surfaceContainerLowDark = Color(0xFF1A1A1A);
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);
  static const Color surfaceContainerHighDark = Color(0xFF282828);
  static const Color surfaceContainerHighestDark = Color(0xFF323232);

  /// Dark mode text
  static const Color onSurfaceDark = Color(0xFFE0E0E0);
  static const Color onSurfaceVariantDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF757575);

  /// Dark mode outlines/borders
  static const Color outlineDark = Color(0xFF5C5C5C);
  static const Color outlineVariantDark = Color(0xFF404040);

  // ============================================
  // BRAND / SOCIAL COLORS
  // ============================================

  static const Color google = Color(0xFFEA4335);
  static const Color facebook = Color(0xFF1877F2);
  static const Color apple = Color(0xFF000000);

  // ============================================
  // FITNESS DOMAIN COLORS
  // ============================================

  /// Workout type colors
  static const Color cardio = Color(0xFFFF6B6B);
  static const Color strength = Color(0xFF4ECDC4);
  static const Color flexibility = Color(0xFFFFE66D);
  static const Color rest = Color(0xFF95E1D3);

  /// Muscle group colors
  static const Color muscleChest = Color(0xFFFF6B4A);
  static const Color muscleBack = Color(0xFF26A69A);
  static const Color muscleLegs = Color(0xFF7C3AED);
  static const Color muscleShoulders = Color(0xFFF59E0B);
  static const Color muscleArms = Color(0xFF3B82F6);
  static const Color muscleCore = Color(0xFF10B981);
  static const Color muscleFullBody = Color(0xFFEC4899);

  /// Get muscle group color by name
  static Color getMuscleGroupColor(MuscleGroup muscleGroup) {
    switch (muscleGroup) {
      case MuscleGroup.chest:
        return muscleChest;
      case MuscleGroup.back:
        return muscleBack;
      case MuscleGroup.legs:
        return muscleLegs;
      case MuscleGroup.shoulders:
        return muscleShoulders;
      case MuscleGroup.arms:
        return muscleArms;
      case MuscleGroup.core:
        return muscleCore;
      case MuscleGroup.fullBody:
        return muscleFullBody;
      default:
        return muscleFullBody;
    }
  }

  // ============================================
  // GLASSMORPHISM COLORS
  // ============================================

  /// Glass effect colors for light mode
  static Color glassLight = Colors.white.withValues(alpha: 0.7);
  static Color glassLightStrong = Colors.white.withValues(alpha: 0.85);
  static Color glassBorderLight = const Color(
    0xFF000000,
  ).withValues(alpha: 0.08);

  /// Glass effect colors for dark mode
  static Color glassDark = Colors.white.withValues(alpha: 0.08);
  static Color glassDarkStrong = Colors.white.withValues(alpha: 0.15);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.15);

  /// Glass shadows
  static Color glassShadowLight = Colors.black.withValues(alpha: 0.1);
  static Color glassShadowDark = Colors.black.withValues(alpha: 0.3);
}
