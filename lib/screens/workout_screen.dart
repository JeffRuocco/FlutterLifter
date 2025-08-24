import 'package:flutter/material.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/models.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_bottom_sheet.dart';

/// The main screen for creating and managing a workout session.
class WorkoutScreen extends StatefulWidget {
  // TODO: Test passing in existing WorkoutSession instance
  final ProgramRepository programRepository;
  final WorkoutSession workoutSession;

  const WorkoutScreen({
    super.key,
    required this.programRepository,
    required this.workoutSession,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String programId = 'Custom Program';
  String programName = 'Custom Program';
  DateTime? workoutDate;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeWorkout() async {
    try {
      setState(() {
        programId = widget.workoutSession.programId ?? programId;
        programName = widget.workoutSession.programName ?? programName;
        workoutDate = widget.workoutSession.date;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _startWorkout(WorkoutSession workoutSession) {
    setState(() {
      workoutSession.start();
    });
    showSuccessMessage(context, 'Workout started! Let\'s go! 💪');
  }

  void _finishWorkout(WorkoutSession workoutSession) {
    // TODO: Warn if sets are unfinished, especially if actual reps were record, but set was never marked completed
    if (!workoutSession.isInProgress) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Finish Workout?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to finish this workout? Your progress will be saved.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
              showSuccessMessage(context, 'Workout completed! Great job! 🎉');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.successColor,
              foregroundColor: context.onSuccessColor,
            ),
            child: const Text(
              'Finish',
              style: AppTextStyles.labelMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _addExercise(WorkoutSession workoutSession) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddExerciseBottomSheet(
        programRepository: widget.programRepository,
        onExerciseAdded: (exercise) {
          setState(() {
            workoutSession.exercises.add(exercise);
          });
          showSuccessMessage(context, 'Exercise added!');
        },
      ),
    );
  }

  void _removeExercise(int index, WorkoutSession workoutSession) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Exercise?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${workoutSession.exercises[index].name}?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                workoutSession.exercises.removeAt(index);
              });
              Navigator.pop(context);
              showInfoMessage(context, 'Exercise removed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.errorColor,
              foregroundColor: context.onError,
            ),
            child: const Text(
              'Remove',
              style: AppTextStyles.labelMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _swapExercise(int index, WorkoutSession workoutSession) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddExerciseBottomSheet(
        programRepository: widget.programRepository,
        onExerciseAdded: (exercise) {
          setState(() {
            workoutSession.exercises[index] = exercise;
          });
          showSuccessMessage(context, 'Exercise swapped!');
        },
        isSwapping: true,
        currentExercise: workoutSession.exercises[index],
      ),
    );
  }

  String _formatWorkoutDuration(WorkoutSession workoutSession) {
    if (workoutSession.startTime == null) return '';
    final duration = DateTime.now().difference(workoutSession.startTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            programName,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.onSurface,
            ),
          ),
          backgroundColor: context.surfaceColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: context.primaryColor,
              ),
              const VSpace.md(),
              Text(
                'Loading workout...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            programName,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.onSurface,
            ),
          ),
          backgroundColor: context.surfaceColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: context.errorColor,
                size: AppDimensions.iconXLarge,
              ),
              const VSpace.md(),
              Text(
                'Error loading workout',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const VSpace.sm(),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildWorkoutScreen(widget.workoutSession);
  }

  Widget _buildWorkoutScreen(WorkoutSession workoutSession) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              programName,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.onSurface,
              ),
            ),
            if (workoutSession.isInProgress)
              Text(
                _formatWorkoutDuration(workoutSession),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.successColor,
                ),
              ),
          ],
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        actions: [
          if (workoutSession.isInProgress)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: context.successColor,
              ),
              onPressed: () => _finishWorkout(workoutSession),
              tooltip: 'Finish Workout',
            ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: context.onSurface,
            ),
            onPressed: () => _addExercise(workoutSession),
            tooltip: 'Add Exercise',
          ),
        ],
      ),
      body: Column(
        children: [
          // Workout Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.surfaceVariant,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Workout',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: workoutSession.isInProgress
                            ? context.successColor.withValues(alpha: 0.1)
                            : context.outlineVariant,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusSmall),
                      ),
                      child: Text(
                        workoutSession.isInProgress
                            ? 'In Progress'
                            : 'Not Started',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: workoutSession.isInProgress
                              ? context.successColor
                              : context.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const VSpace.xs(),
                Text(
                  '${workoutSession.totalExercisesCount} exercises',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Start Workout Button (if not started)
          if (!workoutSession.isInProgress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLarge,
                child: ElevatedButton.icon(
                  onPressed: () => _startWorkout(workoutSession),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusLarge),
                    ),
                  ),
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    color: context.onPrimary,
                    size: AppDimensions.iconMedium,
                  ),
                  label: const Text(
                    'Start Workout',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),
            ),

          const VSpace.md(),

          // Exercises List
          Expanded(
            child: workoutSession.exercises.isEmpty
                ? _buildEmptyState(workoutSession)
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: workoutSession.exercises.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ExerciseCard(
                          exercise: workoutSession.exercises[index],
                          exerciseIndex: index + 1,
                          isWorkoutStarted: workoutSession.isInProgress,
                          onRemove: () =>
                              _removeExercise(index, workoutSession),
                          onSwap: () => _swapExercise(index, workoutSession),
                          onToggleSetCompleted: (setIndex) {
                            // TODO: start rest timer based on set.restTime
                            setState(() {
                              workoutSession.exercises[index].sets[setIndex]
                                  .toggleCompleted();
                            });
                          },
                          onSetUpdated:
                              (setIndex, weight, reps, notes, markAsCompleted) {
                            setState(() {
                              workoutSession.exercises[index].sets[setIndex]
                                  .updateSetData(
                                      weight: weight,
                                      reps: reps,
                                      notes: notes,
                                      markAsCompleted: markAsCompleted);
                            });
                          },
                          onAddSet: () => setState(() {
                            workoutSession.exercises[index].addSet();
                          }),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WorkoutSession workoutSession) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedDumbbell01,
                color: context.textSecondary,
                size: AppDimensions.iconXLarge,
              ),
            ),
            const VSpace.lg(),
            Text(
              'No Exercises Added',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
              ),
            ),
            const VSpace.sm(),
            Text(
              'Tap the + button to add exercises to your workout',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const VSpace.xl(),
            ElevatedButton.icon(
              onPressed: () => _addExercise(workoutSession),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.onPrimary,
              ),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: context.onPrimary,
                size: AppDimensions.iconMedium,
              ),
              label: const Text(
                'Add First Exercise',
                style: AppTextStyles.buttonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
