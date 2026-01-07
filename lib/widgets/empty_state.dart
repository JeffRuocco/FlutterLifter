import 'package:flutter/material.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

/// A beautiful empty state widget with optional Lottie animation
class EmptyState extends StatelessWidget {
  final String? lottieAsset;
  final HugeIconData? icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;
  final Color? iconColor;

  const EmptyState({
    super.key,
    this.lottieAsset,
    this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 80,
    this.iconColor,
  });

  /// Factory for no workouts state
  factory EmptyState.noWorkouts({VoidCallback? onCreateWorkout}) {
    return EmptyState(
      lottieAsset: 'assets/lottie/empty_workout.json',
      icon: HugeIcons.strokeRoundedDumbbell01,
      title: 'No Workouts Yet',
      description: 'Start your fitness journey by creating your first workout.',
      actionLabel: 'Create Workout',
      onAction: onCreateWorkout,
    );
  }

  /// Factory for no programs state
  factory EmptyState.noPrograms({VoidCallback? onBrowsePrograms}) {
    return EmptyState(
      lottieAsset: 'assets/lottie/empty_program.json',
      icon: HugeIcons.strokeRoundedTask01,
      title: 'No Active Program',
      description:
          'Choose a training program to get started with structured workouts.',
      actionLabel: 'Browse Programs',
      onAction: onBrowsePrograms,
    );
  }

  /// Factory for no exercises state
  factory EmptyState.noExercises({VoidCallback? onAddExercise}) {
    return EmptyState(
      icon: HugeIcons.strokeRoundedGymnasticRings,
      title: 'No Exercises',
      description: 'Add exercises to build your workout routine.',
      actionLabel: 'Add Exercise',
      onAction: onAddExercise,
    );
  }

  /// Factory for error state
  factory EmptyState.error({String? message, VoidCallback? onRetry}) {
    return EmptyState(
      icon: HugeIcons.strokeRoundedAlert02,
      iconColor: AppColors.error,
      title: 'Oops! Something went wrong',
      description: message ?? 'We encountered an error. Please try again.',
      actionLabel: 'Try Again',
      onAction: onRetry,
    );
  }

  /// Factory for no search results
  factory EmptyState.noResults({
    String? searchTerm,
    VoidCallback? onClearSearch,
  }) {
    return EmptyState(
      icon: HugeIcons.strokeRoundedSearch01,
      title: 'No Results Found',
      description: searchTerm != null
          ? 'No matches for "$searchTerm". Try a different search term.'
          : 'No matches found. Try adjusting your search.',
      actionLabel: onClearSearch != null ? 'Clear Search' : null,
      onAction: onClearSearch,
    );
  }

  /// Factory for offline state
  factory EmptyState.offline({VoidCallback? onRetry}) {
    return EmptyState(
      icon: HugeIcons.strokeRoundedWifiDisconnected01,
      title: 'You\'re Offline',
      description: 'Check your internet connection and try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animation or icon
            if (lottieAsset != null)
              _buildLottieAnimation()
            else if (icon != null)
              _buildIcon(effectiveIconColor),

            SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onAction,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    // Try to load Lottie, fall back to icon if asset doesn't exist
    return LottieBuilder.asset(
      lottieAsset!,
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if Lottie fails to load
        if (icon != null) {
          return _buildIcon(
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildIcon(Color color) {
    return Container(
      width: iconSize + 40,
      height: iconSize + 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? HugeIcon(icon: icon!, size: iconSize, color: color)
          : SizedBox.shrink(),
    );
  }
}
