import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/theme_extensions.dart';
import '../models/shared_enums.dart';

/// Extension on [ProgramType] to provide consistent color mapping across the app.
extension ProgramTypeColorExtension on ProgramType {
  /// Returns the color associated with this program type.
  ///
  /// Some types use static colors (strength, hypertrophy, etc.),
  /// while others use theme-aware colors (flexibility, general, etc.).
  Color getColor(BuildContext context) {
    switch (this) {
      case ProgramType.strength:
        return AppColors.muscleChest;
      case ProgramType.hypertrophy:
        return AppColors.muscleBack;
      case ProgramType.powerlifting:
        return AppColors.muscleCore;
      case ProgramType.bodybuilding:
        return AppColors.muscleLegs;
      case ProgramType.cardio:
      case ProgramType.hiit:
        return AppColors.cardio;
      case ProgramType.flexibility:
      case ProgramType.rehabilitation:
        return context.warningColor;
      case ProgramType.general:
      case ProgramType.sport:
        return context.primaryColor;
    }
  }
}

/// Extension on [ProgramDifficulty] to provide consistent color mapping across the app.
extension ProgramDifficultyColorExtension on ProgramDifficulty {
  /// Returns the color associated with this difficulty level.
  ///
  /// - Beginner: Success/green color
  /// - Intermediate: Warning/yellow color
  /// - Advanced/Expert: Error/red color
  Color getColor(BuildContext context) {
    switch (this) {
      case ProgramDifficulty.beginner:
        return context.successColor;
      case ProgramDifficulty.intermediate:
        return context.warningColor;
      case ProgramDifficulty.advanced:
      case ProgramDifficulty.expert:
        return context.errorColor;
    }
  }

  /// Returns the color for a difficulty string (case-insensitive).
  ///
  /// Useful when difficulty is provided as a display string rather than enum.
  /// Falls back to primary color for unknown values.
  static Color getColorFromString(BuildContext context, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return context.successColor;
      case 'intermediate':
        return context.warningColor;
      case 'advanced':
      case 'expert':
        return context.errorColor;
      default:
        return context.primaryColor;
    }
  }
}
