import 'package:flutter/material.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/utils/utils.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import '../models/workout_models.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_bottom_sheet.dart';

// TODO: screen refreshing when marking sets completed

class WorkoutScreen extends StatefulWidget {
  // TODO: create and pass in program model
  final ProgramRepository programRepository;
  final String programId;
  final String programName;
  final DateTime workoutDate;

  WorkoutScreen({
    super.key,
    required this.programRepository,
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
  late Future<WorkoutSession> _workoutSessionFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _workoutSessionFuture = _initializeWorkout();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<WorkoutSession> _initializeWorkout() async {
    // Initialize with sample exercises based on program
    // In a real app, this would come from the selected program
    // TODO: Fetch exercises from program
    return WorkoutSession.create(
      programId: widget.programId,
      programName: widget.programName,
      exercises: await _getSampleExercises(),
      date: widget.workoutDate,
    );
  }

  Future<List<WorkoutExercise>> _getSampleExercises() async {
    final barbellBackSquat =
        await widget.programRepository.getExerciseByName('Barbell Back Squat');
    final benchPress =
        await widget.programRepository.getExerciseByName('Bench Press');
    final bentOverBarbellRow = await widget.programRepository
        .getExerciseByName('Bent-Over Barbell Row');

    return [
      if (barbellBackSquat != null)
        WorkoutExercise.create(
          exercise: barbellBackSquat,
          sets: [
            ExerciseSet.create(targetReps: 8, targetWeight: 135),
            ExerciseSet.create(targetReps: 8, targetWeight: 155),
            ExerciseSet.create(targetReps: 6, targetWeight: 175),
            ExerciseSet.create(targetReps: 6, targetWeight: 175),
          ],
          notes: 'Focus on depth and form',
        ),
      if (benchPress != null)
        WorkoutExercise.create(
          exercise: benchPress,
          sets: [
            ExerciseSet.create(targetReps: 10, targetWeight: 135),
            ExerciseSet.create(targetReps: 8, targetWeight: 155),
            ExerciseSet.create(targetReps: 6, targetWeight: 175),
          ],
          notes: 'Pause at chest, control the negative',
        ),
      if (bentOverBarbellRow != null)
        WorkoutExercise.create(
          exercise: bentOverBarbellRow,
          sets: [
            ExerciseSet.create(targetReps: 10, targetWeight: 115),
            ExerciseSet.create(targetReps: 8, targetWeight: 135),
            ExerciseSet.create(targetReps: 8, targetWeight: 135),
          ],
        ),
    ];
  }

  void _startWorkout(WorkoutSession workoutSession) {
    setState(() {
      workoutSession.start();
      // Update the future to reflect the change
      _workoutSessionFuture = Future.value(workoutSession);
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
            // Update the future to reflect the change
            _workoutSessionFuture = Future.value(workoutSession);
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
                // Update the future to reflect the change
                _workoutSessionFuture = Future.value(workoutSession);
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
            // Update the future to reflect the change
            _workoutSessionFuture = Future.value(workoutSession);
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
    return FutureBuilder<WorkoutSession>(
      future: _workoutSessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.backgroundColor,
            appBar: AppBar(
              title: Text(
                widget.programName,
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

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: context.backgroundColor,
            appBar: AppBar(
              title: Text(
                widget.programName,
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
                    snapshot.error.toString(),
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

        final workoutSession = snapshot.data!;
        return _buildWorkoutScreen(workoutSession);
      },
    );
  }

  Widget _buildWorkoutScreen(WorkoutSession workoutSession) {
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
                              // Update the future to reflect the change
                              _workoutSessionFuture =
                                  Future.value(workoutSession);
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
                              // Update the future to reflect the change
                              _workoutSessionFuture =
                                  Future.value(workoutSession);
                            });
                          },
                          onAddSet: () => setState(() {
                            workoutSession.exercises[index].addSet();
                            // Update the future to reflect the change
                            _workoutSessionFuture =
                                Future.value(workoutSession);
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
