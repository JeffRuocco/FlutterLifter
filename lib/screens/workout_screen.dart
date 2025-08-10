import 'package:flutter/material.dart';
import 'package:flutter_lifter/utils/mock_data.dart';
import 'package:flutter_lifter/utils/utils.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import '../models/workout_models.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_bottom_sheet.dart';

class WorkoutScreen extends StatefulWidget {
  // TODO: create and pass in program model
  final String programId;
  final String programName;
  final DateTime workoutDate;

  WorkoutScreen({
    super.key,
    String? programId,
    String? programName,
    DateTime? workoutDate,
  })  : programId = programId ?? Utils.generateId(),
        programName = programName ?? 'Custom Workout',
        workoutDate = workoutDate ?? DateTime.now();

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late WorkoutSession _workoutSession;
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

  void _initializeWorkout() {
    // Initialize with sample exercises based on program
    // In a real app, this would come from the selected program
    // TODO: Fetch exercises from program
    _workoutSession = WorkoutSession.create(
      programId: widget.programId,
      programName: widget.programName,
      exercises: _getSampleExercises(),
      date: widget.workoutDate,
    );
  }

  List<WorkoutExercise> _getSampleExercises() {
    return [
      WorkoutExercise.create(
        exercise: MockExercises.getExerciseByName('Barbell Back Squat') ??
            MockExercises.exercises[0],
        sets: [
          ExerciseSet.create(targetReps: 8, targetWeight: 135),
          ExerciseSet.create(targetReps: 8, targetWeight: 155),
          ExerciseSet.create(targetReps: 6, targetWeight: 175),
          ExerciseSet.create(targetReps: 6, targetWeight: 175),
        ],
        notes: 'Focus on depth and form',
      ),
      WorkoutExercise.create(
        exercise: MockExercises.getExerciseByName('Bench Press') ??
            MockExercises.exercises[1],
        sets: [
          ExerciseSet.create(targetReps: 10, targetWeight: 135),
          ExerciseSet.create(targetReps: 8, targetWeight: 155),
          ExerciseSet.create(targetReps: 6, targetWeight: 175),
        ],
        notes: 'Pause at chest, control the negative',
      ),
      WorkoutExercise.create(
        exercise: MockExercises.getExerciseByName('Bent-Over Barbell Row') ??
            MockExercises.exercises[4],
        sets: [
          ExerciseSet.create(targetReps: 10, targetWeight: 115),
          ExerciseSet.create(targetReps: 8, targetWeight: 135),
          ExerciseSet.create(targetReps: 8, targetWeight: 135),
        ],
      ),
    ];
  }

  void _startWorkout() {
    setState(() {
      _workoutSession.start();
    });
    showSuccessMessage(context, 'Workout started! Let\'s go! 💪');
  }

  void _finishWorkout() {
    // TODO: Warn if sets are unfinished, especially if actual reps were record, but set was never marked completed
    if (!_workoutSession.isInProgress) return;
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

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddExerciseBottomSheet(
        onExerciseAdded: (exercise) {
          setState(() {
            _workoutSession.exercises.add(exercise);
          });
          showSuccessMessage(context, 'Exercise added!');
        },
      ),
    );
  }

  void _removeExercise(int index) {
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
          'Are you sure you want to remove ${_workoutSession.exercises[index].name}?',
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
                _workoutSession.exercises.removeAt(index);
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

  void _swapExercise(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddExerciseBottomSheet(
        onExerciseAdded: (exercise) {
          setState(() {
            _workoutSession.exercises[index] = exercise;
          });
          showSuccessMessage(context, 'Exercise swapped!');
        },
        isSwapping: true,
        currentExercise: _workoutSession.exercises[index],
      ),
    );
  }

  String _formatWorkoutDuration() {
    if (_workoutSession.startTime == null) return '';
    final duration = DateTime.now().difference(_workoutSession.startTime!);
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
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.programName,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.onSurface,
              ),
            ),
            if (_workoutSession.isInProgress)
              Text(
                _formatWorkoutDuration(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.successColor,
                ),
              ),
          ],
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        actions: [
          if (_workoutSession.isInProgress)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: context.successColor,
              ),
              onPressed: _finishWorkout,
              tooltip: 'Finish Workout',
            ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: context.onSurface,
            ),
            onPressed: _addExercise,
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
                        color: _workoutSession.isInProgress
                            ? context.successColor.withValues(alpha: 0.1)
                            : context.outlineVariant,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusSmall),
                      ),
                      child: Text(
                        _workoutSession.isInProgress
                            ? 'In Progress'
                            : 'Not Started',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _workoutSession.isInProgress
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
                  '${_workoutSession.totalExercisesCount} exercises',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Start Workout Button (if not started)
          if (!_workoutSession.isInProgress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLarge,
                child: ElevatedButton.icon(
                  onPressed: _startWorkout,
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
            child: _workoutSession.exercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _workoutSession.exercises.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ExerciseCard(
                          exercise: _workoutSession.exercises[index],
                          exerciseIndex: index + 1,
                          isWorkoutStarted: _workoutSession.isInProgress,
                          onRemove: () => _removeExercise(index),
                          onSwap: () => _swapExercise(index),
                          onToggleSetCompleted: (setIndex) {
                            // TODO: start rest timer based on set.restTime
                            setState(() {
                              _workoutSession.exercises[index].sets[setIndex]
                                  .toggleCompleted();
                            });
                          },
                          onSetUpdated:
                              (setIndex, weight, reps, notes, markAsCompleted) {
                            setState(() {
                              _workoutSession.exercises[index].sets[setIndex]
                                  .updateSetData(
                                      weight: weight,
                                      reps: reps,
                                      notes: notes,
                                      markAsCompleted: markAsCompleted);
                            });
                          },
                          onAddSet: () => setState(() {
                            _workoutSession.exercises[index].addSet();
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

  Widget _buildEmptyState() {
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
              onPressed: _addExercise,
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
