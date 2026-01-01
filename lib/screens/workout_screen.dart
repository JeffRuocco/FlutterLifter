import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/providers.dart';
import '../core/router/app_router.dart';
import '../models/models.dart';
import '../models/operation_result.dart';
import '../services/logging_service.dart';
import '../utils/operation_ui_handler.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_bottom_sheet.dart';
import '../widgets/debug_action_button.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/animations/animate_on_load.dart';
import '../widgets/animations/success_confetti.dart';

/// The main screen for creating and managing a workout session.
///
/// The workout session is loaded from the [workoutNotifierProvider] state,
/// which should be populated by the HomeScreen or app initialization.
/// An optional [workoutSession] can be passed to override the provider state.
class WorkoutScreen extends ConsumerStatefulWidget {
  /// Optional workout session to use instead of reading from provider state.
  /// If null, the screen will read from [currentWorkoutProvider].
  final WorkoutSession? workoutSession;

  const WorkoutScreen({
    super.key,
    this.workoutSession,
  });

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    // If a session was passed explicitly, set it in the provider
    if (widget.workoutSession != null) {
      Future.microtask(() {
        ref
            .read(workoutNotifierProvider.notifier)
            .setCurrentWorkout(widget.workoutSession);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startWorkout(WorkoutSession workoutSession) async {
    try {
      final workoutService = ref.read(workoutServiceProvider);
      await workoutService.startWorkout(workoutSession);
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

    final workoutService = ref.read(workoutServiceProvider);

    // Check for unfinished sets before finishing
    if (workoutService.hasUnfinishedExercises()) {
      final shouldContinue = await _showUnfinishedSetsDialog();
      if (!shouldContinue || !mounted) return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Finish Workout?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: dialogContext.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to finish this workout? Your progress will be saved.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: dialogContext.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: dialogContext.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              try {
                await workoutService.finishWorkout();
                if (!mounted) return;

                // Trigger confetti celebration
                setState(() => _showConfetti = true);
                HapticFeedback.heavyImpact();

                // Wait for confetti animation then navigate
                await Future.delayed(const Duration(milliseconds: 2000));
                if (!mounted) return;

                showSuccessMessage(context, 'Workout completed! Great job! 🎉');
                context.goToHome(); // Navigate to home screen
              } catch (error) {
                if (!mounted) return;
                showErrorMessage(context, 'Failed to finish workout: $error');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.successColor,
              foregroundColor: dialogContext.onSuccessColor,
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
    final workoutService = ref.read(workoutServiceProvider);
    final unfinishedCount = workoutService.getUnfinishedSetsCount();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Unfinished Sets',
          style: AppTextStyles.headlineSmall.copyWith(
            color: dialogContext.textPrimary,
          ),
        ),
        content: Text(
          'You have $unfinishedCount unfinished sets with recorded data. '
          'Are you sure you want to finish the workout?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: dialogContext.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue Workout'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.warningColor,
              foregroundColor: dialogContext.onWarningColor,
            ),
            child: const Text('Finish Anyway'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _addExercise(WorkoutSession workoutSession) {
    final workoutService = ref.read(workoutServiceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => AddExerciseBottomSheet(
        onExerciseAdded: (exercise) async {
          LoggingService.logUserAction(
              "Add exercise to workout session: ${exercise.name}");
          setState(() {
            workoutSession.exercises.add(exercise);
          });

          // Auto-save the change
          try {
            await workoutService.saveWorkoutImmediate();
            if (!mounted) return;
            showSuccessMessage(context, 'Exercise added!');
          } catch (error) {
            if (!mounted) return;
            showErrorMessage(
                context, 'Exercise added but failed to save: $error');
          }
        },
      ),
    );
  }

  void _removeExercise(int index, WorkoutSession workoutSession) {
    final workoutService = ref.read(workoutServiceProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove Exercise?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: dialogContext.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${workoutSession.exercises[index].name}?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: dialogContext.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: dialogContext.textSecondary,
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
              Navigator.pop(dialogContext);

              // Auto-save the change
              try {
                await workoutService.saveWorkoutImmediate();
                if (!mounted) return;
                showInfoMessage(context, 'Exercise removed');
              } catch (error) {
                if (!mounted) return;
                showErrorMessage(
                    context, 'Exercise removed but failed to save: $error');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.errorColor,
              foregroundColor: dialogContext.onError,
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
    final workoutService = ref.read(workoutServiceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => AddExerciseBottomSheet(
        onExerciseAdded: (exercise) async {
          LoggingService.logUserAction(
              "Swap exercise in workout session: old ${workoutSession.exercises[index].name}, new ${exercise.name}");
          setState(() {
            workoutSession.exercises[index] = exercise;
          });

          // Auto-save the change
          try {
            await workoutService.saveWorkoutImmediate();
            if (!mounted) return;
            showSuccessMessage(context, 'Exercise swapped!');
          } catch (error) {
            if (!mounted) return;
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
      final workoutService = ref.read(workoutServiceProvider);
      await workoutService.saveWorkout();
    } catch (error) {
      // Silent error - don't interrupt workout flow
      if (kDebugMode) {
        print('Failed to save workout: $error');
      }
    }
  }

  /// Calculate workout completion progress (0.0 to 1.0)
  double _calculateProgress(WorkoutSession workoutSession) {
    if (workoutSession.exercises.isEmpty) return 0.0;

    int totalSets = 0;
    int completedSets = 0;

    for (final exercise in workoutSession.exercises) {
      for (final set in exercise.sets) {
        totalSets++;
        if (set.isCompleted) {
          completedSets++;
        }
      }
    }

    if (totalSets == 0) return 0.0;
    return completedSets / totalSets;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the workout state for reactive updates
    final workoutState = ref.watch(workoutNotifierProvider);
    final workoutSession = workoutState.currentWorkout;

    if (workoutState.isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            workoutSession?.programName ?? 'Custom Program',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.onSurface,
            ),
          ),
          backgroundColor: context.surfaceColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Header skeleton
              const SkeletonCard(height: 80),
              const VSpace.md(),
              // Exercise cards skeletons
              SkeletonList(
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: SkeletonExerciseCard(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (workoutState.error != null || workoutSession == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            workoutSession?.programName ?? 'Custom Program',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.onSurface,
            ),
          ),
          backgroundColor: context.surfaceColor,
          elevation: 0,
        ),
        body: workoutState.error != null
            ? EmptyState.error(
                message: workoutState.error!,
                onRetry: () {
                  ref.read(workoutNotifierProvider.notifier).loadNextWorkout();
                },
              )
            : EmptyState.noWorkouts(
                onCreateWorkout: () => context.go(AppRoutes.programs),
              ),
      );
    }

    return _buildWorkoutScreen(workoutSession);
  }

  /// Warn the user if they're leaving the workout screen while having
  /// recorded sets that are not marked complete.
  Future<void> _onWillPop(bool didPop, Object? result) async {
    if (didPop) return; // Already popped, don't process further

    final workoutService = ref.read(workoutServiceProvider);

    // Check if user has uncompleted recorded sets
    if (workoutService.hasUncompletedRecordedSets()) {
      final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(
                'Incomplete Sets',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: dialogContext.textPrimary,
                ),
              ),
              content: Text(
                'You have sets with recorded data that are not marked as complete. '
                'Are you sure you want to leave this screen?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: dialogContext.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogContext.warningColor,
                    foregroundColor: dialogContext.onWarningColor,
                  ),
                  child: const Text('Leave Anyway'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldLeave && mounted) {
        context.goToHome();
      }
    } else {
      // No uncompleted sets, navigate to home immediately
      if (mounted) {
        context.goToHome();
      }
    }
  }

  Widget _buildWorkoutScreen(WorkoutSession workoutSession) {
    final workoutService = ref.read(workoutServiceProvider);
    final progress = _calculateProgress(workoutSession);

    return SuccessConfetti(
      isPlaying: _showConfetti,
      onComplete: () => setState(() => _showConfetti = false),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) => _onWillPop(didPop, result),
        child: Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutSession.programName ?? 'Custom Program',
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
                  if (workoutService.hasActiveWorkout)
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
            bottom: workoutSession.isInProgress
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: _WorkoutProgressBar(progress: progress),
                  )
                : null,
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
                      await workoutService.saveWorkoutImmediate();
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                    ? EmptyState.noExercises(
                        onAddExercise: () => _addExercise(workoutSession),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: workoutSession.exercises.length,
                        itemBuilder: (context, index) {
                          return SlideInWidget(
                            delay: Duration(milliseconds: 100 + (index * 50)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: ExerciseCard(
                                exercise: workoutSession.exercises[index],
                                exerciseIndex: index + 1,
                                isWorkoutStarted: workoutSession.isInProgress,
                                onRemove: () =>
                                    _removeExercise(index, workoutSession),
                                onSwap: () =>
                                    _swapExercise(index, workoutSession),
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
                                    workoutSession
                                        .exercises[index].sets[setIndex]
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress bar widget for workout completion
class _WorkoutProgressBar extends StatelessWidget {
  final double progress;

  const _WorkoutProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceVariant,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.primaryGradient,
            ),
          ),
        ),
      ),
    );
  }
}
