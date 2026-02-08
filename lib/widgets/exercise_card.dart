import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lifter/models/exercise/exercise_set_record.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/exercise/exercise_session_record.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/providers/repository_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import 'common/app_widgets.dart';
import 'exercise_detail_bottom_sheet.dart';

import 'set_input_widget.dart';

/// A card widget that displays a workout exercise and its sets.
class ExerciseCard extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final bool isWorkoutStarted;
  final VoidCallback onRemove;
  final VoidCallback onSwap;
  final Function(int setIndex) onToggleSetCompleted;
  final Function(
    int setIndex,
    double? weight,
    int? reps,
    String? notes,
    bool? markAsCompleted,
  )
  onSetUpdated;
  final VoidCallback onAddSet;
  final Function(int setIndex)? onRemoveSet;
  // Optional wrapper to modify the header (e.g., make it the drag start area)
  final Widget Function(Widget header)? headerWrapper;

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
    this.onRemoveSet,
    this.headerWrapper,
  });

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  ExerciseSessionRecord? _lastSession;
  double? _allTimePR;
  String? _userNotes;

  @override
  void initState() {
    super.initState();
    // Start collapsed if completed OR if parent forces collapse (e.g., during drag)
    _isExpanded = !widget.exercise.isCompleted;
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _expandController.value = _isExpanded ? 1.0 : 0.0;

    _loadExerciseHistory();
    _loadUserNotes();
  }

  // Return whether the card is currently expanded.
  bool isExpandedState() => _isExpanded;

  // Force set expanded state (used by parent to restore pre-drag state).
  void setExpanded() {
    setState(() {
      _isExpanded = true;
      _expandController.forward();
    });
  }

  /// Force the collapsed state due to a drag starting/ending. Public so
  /// external callers (screen) can immediately collapse/restore without
  /// waiting for a rebuild.
  void setCollapse() {
    setState(() {
      _isExpanded = false;
      _expandController.reverse();
    });
  }

  /// Load user notes from preferences
  Future<void> _loadUserNotes() async {
    final repo = ref.read(exerciseRepositoryProvider);
    try {
      final preference = await repo.getPreferenceForExercise(
        widget.exercise.exercise.id,
      );
      if (!mounted) return;
      setState(() {
        _userNotes = preference?.userNotes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userNotes = null;
      });
    }
  }

  /// Load exercise history data (last session and PR)
  void _loadExerciseHistory() {
    final exerciseId = widget.exercise.exercise.id;

    // Load last session
    ref.read(lastExerciseSessionProvider(exerciseId).future).then((session) {
      if (mounted) {
        setState(() => _lastSession = session);
      }
    });

    // Load all-time PR
    ref.read(exercisePRProvider(exerciseId).future).then((pr) {
      if (mounted) {
        setState(() => _allTimePR = pr);
      }
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  /// Toggle the expanded/collapsed state of the exercise card
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
        ? widget.exercise.targetMuscleGroups.first
        : MuscleGroup.fullBody;
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
                colors: [muscleColor, muscleColor.withValues(alpha: 0.5)],
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
              children: [const Divider(height: 1), _buildExerciseBody(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(BuildContext context, Color muscleColor) {
    final headerWidget = InkWell(
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
                      ...widget.exercise.targetMuscleGroups.take(2).map((
                        muscle,
                      ) {
                        final chipColor = AppColors.getMuscleGroupColor(muscle);
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
                              muscle.displayName,
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
                  // Last Performance Indicator
                  if (_lastSession != null) ...[
                    const VSpace.xs(),
                    _buildLastPerformanceIndicator(context),
                  ],
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

    if (widget.headerWrapper != null) {
      return widget.headerWrapper!(headerWidget);
    }

    return headerWidget;
  }

  /// Build the last performance indicator showing the best set from the last session
  Widget _buildLastPerformanceIndicator(BuildContext context) {
    if (_lastSession == null) return const SizedBox.shrink();

    final prSet = _lastSession!.prSet;
    if (prSet == null) return const SizedBox.shrink();

    // Check if current session has beaten the PR
    final currentBestEpley = _calculateCurrentBestEpley();
    final isPRBeaten =
        currentBestEpley != null &&
        _allTimePR != null &&
        currentBestEpley > _allTimePR!;

    return Row(
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedTime04,
          color: context.textSecondary,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          'Last: ${prSet.weight.toStringAsFixed(prSet.weight % 1 == 0 ? 0 : 1)} lbs × ${prSet.reps}',
          style: AppTextStyles.labelSmall.copyWith(
            color: context.textSecondary,
            fontSize: 10,
          ),
        ),
        // Show PR indicator if current session beats the all-time PR
        if (isPRBeaten) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.warningColor,
                  context.warningColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMedal01,
                  color: context.onWarningColor,
                  size: 10,
                ),
                const SizedBox(width: 2),
                Text(
                  'NEW PR!',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.onWarningColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Calculate the best Epley score from current workout's completed sets
  double? _calculateCurrentBestEpley() {
    final completedSets = widget.exercise.sets
        .where(
          (set) =>
              set.isCompleted &&
              set.actualWeight != null &&
              set.actualReps != null &&
              set.actualWeight! > 0 &&
              set.actualReps! > 0,
        )
        .toList();

    if (completedSets.isEmpty) return null;

    double bestEpley = 0;
    for (final set in completedSets) {
      final epley = calculateEpleyScore(set.actualWeight!, set.actualReps!);
      if (epley > bestEpley) bestEpley = epley;
    }

    return bestEpley;
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
          // Exercise Notes — prefer user notes, fall back to exercise notes
          if ((_userNotes?.isNotEmpty ?? false) ||
              (widget.exercise.notes?.isNotEmpty == true)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.surfaceVariant,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall,
                ),
              ),
              child: MarkdownBody(
                data: _userNotes?.isNotEmpty == true
                    ? _userNotes!
                    : widget.exercise.notes!,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
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
              child: _buildDismissibleSet(context, index, set),
            );
          }),

          // Add Set Button - allow in planning mode as well as active workouts
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
      ),
    );
  }

  void _addSet(BuildContext context) {
    // In a real app, this would add a new set to the exercise
    // For now, we'll just show a message
    widget.onAddSet.call();
    showSuccessMessage(context, 'Set added!');
  }

  /// Build a dismissible set row that can be swiped to delete
  Widget _buildDismissibleSet(
    BuildContext context,
    int index,
    ExerciseSet set,
  ) {
    // Allow dismissing/removing sets in planning mode as well as when workout
    // is started, as long as there's more than one set and a handler exists.
    final canDismiss =
        widget.exercise.sets.length > 1 && widget.onRemoveSet != null;

    if (!canDismiss) {
      return SetInputWidget(
        setNumber: index + 1,
        exerciseSet: set,
        isWorkoutStarted: widget.isWorkoutStarted,
        onCompletedToggle: () => widget.onToggleSetCompleted.call(index),
        onUpdated: (weight, reps, notes, markAsCompleted) => widget.onSetUpdated
            .call(index, weight, reps, notes, markAsCompleted),
      );
    }

    return Dismissible(
      key: ValueKey('set_${set.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Always show confirmation before removing a set
        return await _showRemoveSetConfirmation(context, index + 1);
      },
      onDismissed: (direction) {
        widget.onRemoveSet?.call(index);
        HapticFeedback.mediumImpact();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.errorColor,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: context.onError,
          size: AppDimensions.iconMedium,
        ),
      ),
      child: SetInputWidget(
        setNumber: index + 1,
        exerciseSet: set,
        isWorkoutStarted: widget.isWorkoutStarted,
        onCompletedToggle: () => widget.onToggleSetCompleted.call(index),
        onUpdated: (weight, reps, notes, markAsCompleted) => widget.onSetUpdated
            .call(index, weight, reps, notes, markAsCompleted),
      ),
    );
  }

  /// Show confirmation dialog before removing a set
  Future<bool> _showRemoveSetConfirmation(
    BuildContext context,
    int setNumber,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove Set $setNumber?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: dialogContext.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this set?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: dialogContext.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: dialogContext.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.errorColor,
              foregroundColor: dialogContext.onError,
            ),
            child: const Text('Remove', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows a modal bottom sheet with detailed information about the exercise.
  Future<void> _showExerciseDetails(BuildContext context) async {
    await ExerciseDetailBottomSheet.show(context, widget.exercise.exercise);
    _loadUserNotes();
  }
}
