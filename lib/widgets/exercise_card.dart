import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import '../models/workout_models.dart';
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

class _ExerciseCardState extends State<ExerciseCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          _buildExerciseHeader(context),

          // Exercise Body (collapsible)
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildExerciseBody(context),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
        topRight: Radius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Exercise Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.exercise.isCompleted
                    ? context.successColor
                    : context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: widget.exercise.isCompleted
                    ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: context.onSuccessColor,
                        size: 16,
                      )
                    : Text(
                        '${widget.exerciseIndex}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.primaryColor,
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
                  ),
                  const VSpace.xs(),
                  Row(
                    children: [
                      Text(
                        widget.exercise.primaryMuscleGroupsText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      ...[
                        Text(
                          ' • ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          color: context.textSecondary,
                          size: 12,
                        ),
                        const HSpace.xs(),
                        Text(
                          widget.exercise.formattedRestTime,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: widget.exercise.isCompleted
                          ? context.successColor.withValues(alpha: 0.1)
                          : context.outlineVariant,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusSmall),
                    ),
                    child: Text(
                      '${widget.exercise.completedSetsCount}/${widget.exercise.totalSetsCount}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.exercise.isCompleted
                            ? context.successColor
                            : context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

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

            // Expand/Collapse Icon
            HugeIcon(
              icon: _isExpanded
                  ? HugeIcons.strokeRoundedArrowUp01
                  : HugeIcons.strokeRoundedArrowDown01,
              color: context.textSecondary,
              size: AppDimensions.iconMedium,
            ),
          ],
        ),
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
