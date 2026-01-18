import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/router/app_router.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../models/models.dart';
import 'common/app_widgets.dart';
import 'exercise_detail_content.dart';

/// A bottom sheet that displays detailed information about an exercise.
///
/// This is a thin wrapper around [ExerciseDetailContent] that provides
/// the bottom sheet chrome (header, handle, close button).
///
/// Use [ExerciseDetailBottomSheet.show] to display as a modal.
class ExerciseDetailBottomSheet extends StatelessWidget {
  /// The exercise to display details for
  final Exercise exercise;

  const ExerciseDetailBottomSheet({super.key, required this.exercise});

  /// Shows the exercise detail bottom sheet as a modal.
  static Future<void> show(BuildContext context, Exercise exercise) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailBottomSheet(exercise: exercise),
    );
  }

  Color _getMuscleGroupColor() {
    final primaryMuscle = exercise.targetMuscleGroups.isNotEmpty
        ? exercise.targetMuscleGroups.first
        : MuscleGroup.fullBody;
    return AppColors.getMuscleGroupColor(primaryMuscle);
  }

  HugeIconData _getCategoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return HugeIcons.strokeRoundedDumbbell01;
      case ExerciseCategory.cardio:
        return HugeIcons.strokeRoundedRunningShoes;
      case ExerciseCategory.flexibility:
        return HugeIcons.strokeRoundedYoga01;
      case ExerciseCategory.balance:
        return HugeIcons.strokeRoundedBodyPartMuscle;
      case ExerciseCategory.endurance:
        return HugeIcons.strokeRoundedTimer01;
      case ExerciseCategory.sports:
        return HugeIcons.strokeRoundedBasketball01;
      case ExerciseCategory.other:
        return HugeIcons.strokeRoundedWorkoutGymnastics;
    }
  }

  @override
  Widget build(BuildContext context) {
    final muscleColor = _getMuscleGroupColor();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.borderRadiusXLarge),
            topRight: Radius.circular(AppDimensions.borderRadiusXLarge),
          ),
        ),
        child: Column(
          children: [
            // Header with gradient
            _buildHeader(context, muscleColor),

            // Scrollable content using shared ExerciseDetailContent
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ExerciseDetailContent(exercise: exercise),

                  const VSpace.xl(),

                  // Link to main exercise details page
                  AppButton.text(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      context.pushExerciseDetail(exercise.id);
                    },
                    text: 'View exercise',
                  ),

                  const VSpace.sm(),

                  // Close button
                  AppButton.elevated(
                    text: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),

                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () => Navigator.pop(context),
                  //     child: const Text('Close'),
                  //   ),
                  // ),
                  const VSpace.md(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color muscleColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            muscleColor.withValues(alpha: 0.2),
            muscleColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.borderRadiusXLarge),
          topRight: Radius.circular(AppDimensions.borderRadiusXLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const VSpace.md(),

          // Icon and title row
          Row(
            children: [
              // Category icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: muscleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: _getCategoryIcon(exercise.category),
                    color: muscleColor,
                    size: 28,
                  ),
                ),
              ),
              const HSpace.md(),

              // Title and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
