import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';

import 'set_input_widget.dart';

class ExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isWorkoutStarted;
  final VoidCallback onRemove;
  final VoidCallback onSwap;
  final Function(int setIndex) onToggleSetCompleted;
  final Function(int setIndex, double? weight, int? reps, String? notes,
      bool? markAsCompleted) onSetUpdated;
  final VoidCallback onAddSet;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.isWorkoutStarted,
    required this.onRemove,
    required this.onSwap,
    required this.onToggleSetCompleted,
    required this.onSetUpdated,
    required this.onAddSet,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
    HapticFeedback.selectionClick();
  }

  /// Get the primary muscle group color for this exercise
  Color _getMuscleGroupColor() {
    final primaryMuscle = widget.exercise.targetMuscleGroups.isNotEmpty
        ? widget.exercise.targetMuscleGroups.first.toLowerCase()
        : '';
    return AppColors.getMuscleGroupColor(primaryMuscle);
  }

  @override
  Widget build(BuildContext context) {
    final muscleColor = _getMuscleGroupColor();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muscle group color indicator stripe
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  muscleColor,
                  muscleColor.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
                topRight: Radius.circular(AppDimensions.borderRadiusLarge),
              ),
            ),
          ),

          // Exercise Header
          _buildExerciseHeader(context, muscleColor),

          // Exercise Body (collapsible with animation)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(height: 1),
                _buildExerciseBody(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(BuildContext context, Color muscleColor) {
    return InkWell(
      onTap: _toggleExpanded,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Exercise Number with muscle color accent
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.exercise.isCompleted
                    ? context.successColor
                    : muscleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.exercise.isCompleted
                      ? context.successColor
                      : muscleColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: widget.exercise.isCompleted
                    ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: context.onSuccessColor,
                        size: 18,
                      )
                    : Text(
                        '${widget.exerciseIndex}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: muscleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const HSpace.md(),

            // Exercise Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exercise.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const VSpace.xs(),
                  Row(
                    children: [
                      // Muscle group chips with colors
                      ...widget.exercise.targetMuscleGroups
                          .take(2)
                          .map((muscle) {
                        final chipColor =
                            AppColors.getMuscleGroupColor(muscle.toLowerCase());
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: chipColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              muscle,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: chipColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                      const HSpace.xs(),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        color: context.textSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.exercise.formattedRestTime,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress and Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.exercise.sets.isNotEmpty)
                  _buildProgressIndicator(context),

                const VSpace.xs(),

                // Actions Menu
                PopupMenuButton<String>(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMoreVertical,
                    color: context.textSecondary,
                    size: AppDimensions.iconMedium,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'details':
                        _showExerciseDetails(context);
                        break;
                      case 'swap':
                        widget.onSwap.call();
                        break;
                      case 'remove':
                        widget.onRemove.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedInformationCircle,
                            color: context.textSecondary,
                            size: AppDimensions.iconMedium,
                          ),
                          const HSpace.sm(),
                          Text(
                            'View Details',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'swap',
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedRepeat,
                            color: context.textSecondary,
                            size: AppDimensions.iconMedium,
                          ),
                          const HSpace.sm(),
                          Text(
                            'Swap Exercise',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            color: context.errorColor,
                            size: AppDimensions.iconMedium,
                          ),
                          const HSpace.sm(),
                          Text(
                            'Remove',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Expand/Collapse Icon with rotation animation
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                color: context.textSecondary,
                size: AppDimensions.iconMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a mini progress ring for the exercise
  Widget _buildProgressIndicator(BuildContext context) {
    final progress = widget.exercise.totalSetsCount > 0
        ? widget.exercise.completedSetsCount / widget.exercise.totalSetsCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: widget.exercise.isCompleted
            ? context.successColor.withValues(alpha: 0.1)
            : context.outlineVariant,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: context.outlineVariant,
              valueColor: AlwaysStoppedAnimation(
                widget.exercise.isCompleted
                    ? context.successColor
                    : context.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.exercise.completedSetsCount}/${widget.exercise.totalSetsCount}',
            style: AppTextStyles.labelSmall.copyWith(
              color: widget.exercise.isCompleted
                  ? context.successColor
                  : context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Notes (if any)
          if (widget.exercise.notes?.isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.surfaceVariant,
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
              child: Text(
                widget.exercise.notes!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const VSpace.md(),
          ],

          // Sets Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'SET',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'WEIGHT',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'REPS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxl), // Space for check button
              ],
            ),
          ),

          // Sets List
          ...widget.exercise.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: SetInputWidget(
                setNumber: index + 1,
                exerciseSet: set,
                isWorkoutStarted: widget.isWorkoutStarted,
                onCompletedToggle: () =>
                    widget.onToggleSetCompleted.call(index),
                onUpdated: (weight, reps, notes, markAsCompleted) => widget
                    .onSetUpdated
                    .call(index, weight, reps, notes, markAsCompleted),
              ),
            );
          }),

          // Add Set Button
          if (widget.isWorkoutStarted) ...[
            const VSpace.sm(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addSet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  side: BorderSide(color: context.primaryColor),
                ),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  color: context.primaryColor,
                  size: AppDimensions.iconMedium,
                ),
                label: Text(
                  'Add Set',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addSet(BuildContext context) {
    // In a real app, this would add a new set to the exercise
    // For now, we'll just show a message
    widget.onAddSet.call();
    showSuccessMessage(context, 'Set added!');
  }

  void _showExerciseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const VSpace.lg(),

              // Exercise Name
              Text(
                widget.exercise.name,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const VSpace.xs(),

              // Category and Muscle Groups
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _buildInfoChip(context, widget.exercise.category.displayName),
                  ...widget.exercise.targetMuscleGroups.map(
                    (muscle) => _buildInfoChip(context, muscle),
                  ),
                ],
              ),
              const VSpace.lg(),

              // Instructions (placeholder)
              Text(
                'Instructions',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const VSpace.sm(),
              Text(
                widget.exercise.instructions ??
                    'Exercise instructions will be available soon. For now, please refer to proper form guides or consult with a fitness professional.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),

              const VSpace.xl(),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: context.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
