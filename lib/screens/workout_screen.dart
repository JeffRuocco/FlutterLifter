import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/data/repositories/exercise_repository.dart';
import 'package:flutter_lifter/models/models.dart';
import 'package:flutter_lifter/models/operation_result.dart';
import 'package:flutter_lifter/services/service_locator.dart';
import 'package:flutter_lifter/services/workout_service.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/utils/operation_ui_handler.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_bottom_sheet.dart';
import '../widgets/debug_action_button.dart';

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
  late WorkoutService _workoutService;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _workoutService = serviceLocator.get<WorkoutService>();
    _initializeWorkout();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeWorkout() {
    try {
      LoggingService.logAppEvent(
          'Workout screen initialized: ${widget.workoutSession.programName}');

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      LoggingService.error('Failed to initialize workout screen', error);

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startWorkout(WorkoutSession workoutSession) async {
    try {
      await _workoutService.startWorkout(workoutSession);
      if (!mounted) return;
      setState(() {}); // Refresh UI
      showSuccessMessage(context, 'Workout started! Auto-save enabled 💪');
    } catch (error) {
      LoggingService.logAuthError('start workout', error);

      if (!mounted) return;
      showErrorMessage(context, 'Failed to start workout: $error');
    }
  }

  Future<void> _finishWorkout(WorkoutSession workoutSession) async {
    if (!workoutSession.isInProgress) return;

    // Check for unfinished sets before finishing
    if (_workoutService.hasUnfinishedExercises()) {
      final shouldContinue = await _showUnfinishedSetsDialog();
      if (!shouldContinue || !mounted) return;
    }

    if (!mounted) return;
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop(); // Close dialog

              try {
                await _workoutService.finishWorkout();
                if (!context.mounted) return;
                showSuccessMessage(context, 'Workout completed! Great job! 🎉');
                Navigator.pop(context); // Return to previous screen
              } catch (error) {
                showErrorMessage(context, 'Failed to finish workout: $error');
              }
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

  /// Show dialog for unfinished sets warning
  Future<bool> _showUnfinishedSetsDialog() async {
    final unfinishedCount = _workoutService.getUnfinishedSetsCount();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unfinished Sets',
          style: AppTextStyles.headlineSmall.copyWith(
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'You have $unfinishedCount unfinished sets with recorded data. '
          'Are you sure you want to finish the workout?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Workout'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.warningColor,
              foregroundColor: context.onWarningColor,
            ),
            child: const Text('Finish Anyway'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _addExercise(WorkoutSession workoutSession) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddExerciseBottomSheet(
        exerciseRepository: serviceLocator.get<ExerciseRepository>(),
        onExerciseAdded: (exercise) async {
          LoggingService.logUserAction(
              "Add exercise to workout session: ${exercise.name}");
          setState(() {
            workoutSession.exercises.add(exercise);
          });

          // Auto-save the change
          try {
            await _workoutService.saveWorkoutImmediate();
            if (!context.mounted) return;
            showSuccessMessage(context, 'Exercise added!');
          } catch (error) {
            showErrorMessage(
                context, 'Exercise added but failed to save: $error');
          }
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
            onPressed: () async {
              LoggingService.logUserAction(
                  "Remove exercise from workout session: ${workoutSession.exercises[index].name}");
              setState(() {
                workoutSession.exercises.removeAt(index);
              });
              Navigator.pop(context);

              // Auto-save the change
              try {
                await _workoutService.saveWorkoutImmediate();
                if (!context.mounted) return;
                showInfoMessage(context, 'Exercise removed');
              } catch (error) {
                showErrorMessage(
                    context, 'Exercise removed but failed to save: $error');
              }
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
        exerciseRepository: serviceLocator.get<ExerciseRepository>(),
        onExerciseAdded: (exercise) async {
          LoggingService.logUserAction(
              "Swap exercise in workout session: old ${workoutSession.exercises[index].name}, new ${exercise.name}");
          setState(() {
            workoutSession.exercises[index] = exercise;
          });

          // Auto-save the change
          try {
            await _workoutService.saveWorkoutImmediate();
            if (!context.mounted) return;
            showSuccessMessage(context, 'Exercise swapped!');
          } catch (error) {
            showErrorMessage(
                context, 'Exercise swapped but failed to save: $error');
          }
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

  /// Save current workout session state to storage
  Future<void> _saveWorkout() async {
    try {
      await _workoutService.saveWorkout();
    } catch (error) {
      // Silent error - don't interrupt workout flow
      if (kDebugMode) {
        print('Failed to save workout: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            widget.workoutSession.programName ?? 'Custom Program',
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
            widget.workoutSession.programName ?? 'Custom Program',
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

  /// Warn the user if they're leaving the workout screen while having
  /// recorded sets that are not marked complete.
  Future<void> _onWillPop(bool didPop, Object? result) async {
    if (didPop) return; // Already popped, don't process further

    // Check if user has uncompleted recorded sets
    if (_workoutService.hasUncompletedRecordedSets()) {
      final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Incomplete Sets',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: context.textPrimary,
                ),
              ),
              content: Text(
                'You have sets with recorded data that are not marked as complete. '
                'Are you sure you want to leave this screen?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.warningColor,
                    foregroundColor: context.onWarningColor,
                  ),
                  child: const Text('Leave Anyway'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldLeave && mounted) {
        Navigator.of(context).pop(); // Now allow pop
      }
    } else {
      // No uncompleted sets, allow pop immediately
      Navigator.of(context).pop();
    }
  }

  Widget _buildWorkoutScreen(WorkoutSession workoutSession) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onWillPop(didPop, result),
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.workoutSession.programName ?? 'Custom Program',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.onSurface,
                ),
              ),
              if (workoutSession.isInProgress) ...[
                Text(
                  _formatWorkoutDuration(workoutSession),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.successColor,
                  ),
                ),
                if (_workoutService.hasActiveWorkout)
                  Text(
                    'Auto-saving every 30s',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.textSecondary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ],
          ),
          backgroundColor: context.surfaceColor,
          elevation: 0,
          actions: [
            // Debug button (only shows when debug mode is enabled)
            const DebugIconButton(),
            if (workoutSession.isInProgress) ...[
              IconButton(
                icon: Icon(
                  HugeIcons.strokeRoundedFloppyDisk,
                  color: context.onSurface,
                ),
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    await _workoutService.saveWorkoutImmediate();
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Progress saved!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to save: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                tooltip: 'Save Progress',
              ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: context.successColor,
                ),
                onPressed: () => _finishWorkout(workoutSession),
                tooltip: 'Finish Workout',
              ),
            ],
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
                            onToggleSetCompleted: (setIndex) async {
                              // TODO: start rest timer based on set.restTime
                              setState(() {
                                final result = workoutSession
                                    .exercises[index].sets[setIndex]
                                    .toggleCompleted();
                                OperationUIHandler.handleResult(
                                    context, result);

                                if (result is OperationSuccess) {
                                  LoggingService.logSetComplete(
                                      workoutSession.exercises[index].name,
                                      setIndex + 1,
                                      workoutSession.exercises[index]
                                          .sets[setIndex].actualWeight,
                                      workoutSession.exercises[index]
                                          .sets[setIndex].actualReps);
                                }
                              });

                              // Auto-save the change
                              await _saveWorkout();
                            },
                            onSetUpdated: (setIndex, weight, reps, notes,
                                markAsCompleted) async {
                              setState(() {
                                workoutSession.exercises[index].sets[setIndex]
                                    .updateSetData(
                                        weight: weight,
                                        reps: reps,
                                        notes: notes,
                                        markAsCompleted: markAsCompleted);
                              });

                              await _saveWorkout();
                            },
                            onAddSet: () async {
                              setState(() {
                                workoutSession.exercises[index].addSet();
                              });

                              await _saveWorkout();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
