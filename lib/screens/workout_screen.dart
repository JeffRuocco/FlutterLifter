import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

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

  const WorkoutScreen({super.key, this.workoutSession});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showConfetti = false;

  /// Per-card keys to allow forcing collapse on drag start. Mapped to exercise IDs.
  ///
  /// Can be used to access the state and call functions of individual ExerciseCard widgets.
  ///
  /// **Example:** To collapse a specific card by its exercise ID:
  /// ```
  /// (_cardKeys[exercise.id]?.currentState as dynamic)?.setCollapse();
  /// ```
  final Map<String, GlobalKey> _cardKeys = {};

  /// Temporarily store expanded state for each card during a reorder Mapped to exercise IDs.
  final Map<String, bool> _wasExpandedMap = {};

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
      final workoutNotifier = ref.read(workoutNotifierProvider.notifier);
      await workoutNotifier.startWorkout(workoutSession);
      if (!mounted) return;
      showSuccessMessage(context, 'Workout started! Auto-save enabled 💪');
    } catch (error) {
      LoggingService.logAuthError('start workout', error);

      if (!mounted) return;
      showErrorMessage(context, 'Failed to start workout: $error');
    }
  }

  /// Finish the current workout session with confirmation and checks.
  Future<void> _finishWorkout(WorkoutSession workoutSession) async {
    if (!workoutSession.isInProgress) return;

    final workoutNotifier = ref.read(workoutNotifierProvider.notifier);

    // Check for unfinished sets before finishing
    if (workoutNotifier.hasUnfinishedExercises) {
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
                await workoutNotifier.finishWorkout();
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
            child: const Text('Finish', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }

  /// Show dialog for unfinished sets warning
  Future<bool> _showUnfinishedSetsDialog() async {
    final workoutNotifier = ref.read(workoutNotifierProvider.notifier);
    final unfinishedCount = workoutNotifier.unfinishedSetsCount;

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
    final notifier = ref.read(workoutNotifierProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => AddExerciseBottomSheet(
        onExerciseAdded: (exercise) async {
          LoggingService.logUserAction(
            "Add exercise to workout session: ${exercise.name}",
          );

          // Use the notifier to add exercise (updates state + handles immutable list)
          notifier.addExercise(exercise);

          // Auto-save the change
          try {
            await notifier.saveWorkoutImmediate();
            if (!mounted) return;
            showSuccessMessage(context, 'Exercise added!');
          } catch (error) {
            if (!mounted) return;
            showErrorMessage(
              context,
              'Exercise added but failed to save: $error',
            );
          }
        },
      ),
    );
  }

  void _removeExercise(int index, WorkoutSession workoutSession) {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    final exerciseName = workoutSession.exercises[index].exercise.name;

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
          'Are you sure you want to remove $exerciseName?',
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
                "Remove exercise from workout session: $exerciseName",
              );

              // Use the notifier to remove exercise (updates state + handles immutable list)
              notifier.removeExerciseAt(index);
              Navigator.pop(dialogContext);

              // Auto-save the change
              try {
                await notifier.saveWorkoutImmediate();
                if (!mounted) return;
                showInfoMessage(context, 'Exercise removed');
              } catch (error) {
                if (!mounted) return;
                showErrorMessage(
                  context,
                  'Exercise removed but failed to save: $error',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.errorColor,
              foregroundColor: dialogContext.onError,
            ),
            child: const Text('Remove', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }

  /// Shows a modal bottom sheet to swap the current exercise with a new one.
  void _swapExercise(int index, WorkoutSession workoutSession) {
    final notifier = ref.read(workoutNotifierProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => AddExerciseBottomSheet(
        onExerciseAdded: (exercise) async {
          LoggingService.logUserAction(
            "Swap exercise in workout session: old ${workoutSession.exercises[index].name}, new ${exercise.name}",
          );

          // Use the notifier to swap exercise (updates state + handles immutable list)
          notifier.swapExercise(index, exercise);

          // Auto-save the change
          try {
            await notifier.saveWorkoutImmediate();
            if (!mounted) return;
            showSuccessMessage(context, 'Exercise swapped!');
          } catch (error) {
            if (!mounted) return;
            showErrorMessage(
              context,
              'Exercise swapped but failed to save: $error',
            );
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
      final workoutNotifier = ref.read(workoutNotifierProvider.notifier);
      await workoutNotifier.saveWorkout();
    } catch (error) {
      // Silent error - don't interrupt workout flow
      LoggingService.error('Failed to save workout: $error');
    }
  }

  /// Allow changing the planned date for the given session.
  /// Shows a date picker, warns on conflicts, and persists the change.
  Future<void> _changePlannedDate(WorkoutSession workoutSession) async {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    final repo = ref.read(programRepositoryProvider);

    final currentDate = workoutSession.date;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      ),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked == null) return;

    // If same day (no-op) - compare y/m/d
    if (workoutSession.date.year == picked.year &&
        workoutSession.date.month == picked.month &&
        workoutSession.date.day == picked.day) {
      if (!mounted) return;
      showInfoMessage(context, 'Date unchanged.');
      return;
    }

    final start = DateTime(picked.year, picked.month, picked.day);

    List<WorkoutSession> existing = [];
    try {
      // Check ALL sessions on the target date (not just completed) to detect conflicts
      final allSessions = await repo.getWorkoutHistory();
      existing = allSessions.where((s) {
        final sd = s.date;
        return sd.year == start.year &&
            sd.month == start.month &&
            sd.day == start.day &&
            s.id != workoutSession.id; // Exclude current session from conflicts
      }).toList();
    } catch (_) {
      // ignore failures - continue as if no conflicts
      existing = [];
    }

    if (!mounted) return;

    var shouldProceed = true;

    if (existing.isNotEmpty) {
      // Show picker to let user open or overwrite existing sessions
      final overwrite = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return Container(
            decoration: BoxDecoration(
              color: sheetContext.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessions on ${start.toLocal().toString().split(' ')[0]}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: sheetContext.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...existing.map((s) {
                    return Card(
                      child: ListTile(
                        title: Text(s.programName ?? 'Custom Program'),
                        subtitle: Text(
                          s.date.toLocal().toString().split(' ')[0],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Open that session instead
                                ref
                                    .read(workoutNotifierProvider.notifier)
                                    .setCurrentWorkout(s);
                                Navigator.of(sheetContext).pop(false);
                                // navigate in case caller expects a route change
                                if (mounted) context.go(AppRoutes.workout);
                              },
                              child: const Text('Open'),
                            ),
                            TextButton(
                              onPressed: () async {
                                // Overwrite: delete existing then continue
                                Navigator.of(sheetContext).pop(true);
                                try {
                                  await repo.deleteWorkoutSession(s.id);
                                } catch (e) {
                                  // ignore deletion error - continue
                                }
                              },
                              child: const Text('Overwrite'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      shouldProceed = overwrite ?? false;
      if (!shouldProceed) return; // user opened existing or cancelled
    }

    // Confirm change (extra confirmation if in-progress)
    if (!mounted) return;
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              workoutSession.isInProgress
                  ? 'Change Date (In Progress)'
                  : 'Change Planned Date',
              style: AppTextStyles.headlineSmall.copyWith(
                color: dialogContext.textPrimary,
              ),
            ),
            content: Text(
              workoutSession.isInProgress
                  ? 'This workout is in progress. Changing the date will reset start/end times and may affect auto-save. Are you sure you want to continue?'
                  : 'Change this workout to ${picked.toLocal().toString().split(' ')[0]}? This will reset start/end times.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: dialogContext.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogContext.successColor,
                  foregroundColor: dialogContext.onSuccessColor,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // Apply the change: reset start/end times
    final oldDate = workoutSession.date;
    final updated = workoutSession.copyWith(
      date: DateTime(picked.year, picked.month, picked.day),
      startTime: null,
      endTime: null,
    );

    try {
      // Update state with markDirty to ensure next save persists changes
      notifier.setCurrentWorkout(updated, markDirty: true);

      // Persist via notifier (proper architecture pattern)
      await notifier.saveWorkoutImmediate();

      // For program cycle sessions, also reschedule future sessions
      if (updated.metadata?['cycleId'] != null) {
        await repo.rescheduleFutureSessions(
          session: updated,
          originalDate: oldDate,
        );
      }

      LoggingService.logUserAction(
        'Changed workout date to ${updated.date} for session ${updated.id}',
      );

      if (!mounted) return;
      showSuccessMessage(context, 'Workout date updated');
      setState(() {});
    } catch (error) {
      LoggingService.error('Failed to change planned date: $error');
      if (!mounted) return;
      showErrorMessage(context, 'Failed to update date: $error');
    }
  }

  /// Allow selecting which date to view on this screen.
  /// Loads an existing session for the date if available, otherwise creates
  /// a new planned session for that date and persists it so it can be edited.
  Future<void> _selectViewDate(WorkoutSession currentSession) async {
    // If in-progress, require confirmation before switching
    if (currentSession.isInProgress) {
      final leave = await _confirmLeaveInProgressWorkout();
      if (!leave) return;
    }

    // Show date picker
    final picked = await _pickViewDate(currentSession.date);
    if (picked == null) return;

    // If same date selected, do nothing
    if (_isSameDate(currentSession.date, picked)) return;

    // Gather sessions for the selected date
    final sessions = await _gatherSessionsForDate(picked);
    if (!mounted) return;

    // Handle based on number of sessions found
    await _handleDateSelection(picked, sessions);
  }

  /// Shows confirmation dialog when leaving an in-progress workout.
  Future<bool> _confirmLeaveInProgressWorkout() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Leave In-Progress Workout?',
              style: AppTextStyles.headlineSmall.copyWith(
                color: dialogContext.textPrimary,
              ),
            ),
            content: Text(
              'You have an in-progress workout. Selecting a different date will switch views. Are you sure you want to continue?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: dialogContext.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogContext.warningColor,
                  foregroundColor: dialogContext.onWarningColor,
                ),
                child: const Text('Switch'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Shows date picker for selecting a view date.
  Future<DateTime?> _pickViewDate(DateTime initialDate) async {
    if (!mounted) return null;
    return showDatePicker(
      context: context,
      initialDate: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
  }

  /// Checks if two dates are the same (year, month, day).
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Gathers all workout sessions scheduled for a given date.
  Future<List<WorkoutSession>> _gatherSessionsForDate(DateTime date) async {
    final repo = ref.read(programRepositoryProvider);
    final sessions = <WorkoutSession>[];

    try {
      // Check program cycle sessions
      final programs = await repo.getPrograms();
      for (final program in programs) {
        final cycle = program.activeCycle;
        if (cycle == null) continue;
        for (final s in cycle.scheduledSessions) {
          if (_isSameDate(s.date, date)) {
            sessions.add(s);
          }
        }
      }

      // Check standalone sessions stored locally
      final all = await repo.getWorkoutHistory();
      for (final s in all) {
        if (_isSameDate(s.date, date) && !sessions.any((e) => e.id == s.id)) {
          sessions.add(s);
        }
      }
    } catch (e) {
      // If repository queries fail, proceed with empty list
    }

    return sessions;
  }

  /// Handles the date selection based on available sessions.
  Future<void> _handleDateSelection(
    DateTime picked,
    List<WorkoutSession> sessions,
  ) async {
    if (sessions.isEmpty) {
      await _handleNoSessionsForDate(picked);
    } else if (sessions.length == 1) {
      await _handleSingleSessionForDate(picked, sessions.first);
    } else {
      await _handleMultipleSessionsForDate(picked, sessions);
    }
  }

  /// Handles case when no sessions exist for the selected date.
  Future<void> _handleNoSessionsForDate(DateTime picked) async {
    final create = await _showCreatePlannedWorkoutDialog(picked);
    if (!create) return;

    final notifier = ref.read(workoutNotifierProvider.notifier);
    final newSession = WorkoutSession.create(
      programName: 'Planned Workout',
      date: DateTime(picked.year, picked.month, picked.day),
    );

    notifier.setCurrentWorkout(newSession, markDirty: true);
    try {
      await notifier.saveWorkoutImmediate();
      if (!mounted) return;
      showSuccessMessage(
        context,
        'Planned workout created for ${DateFormat.yMMMMd().format(picked)}',
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      showErrorMessage(context, 'Failed to create planned workout: $error');
    }
  }

  /// Shows dialog to confirm creating a new planned workout.
  Future<bool> _showCreatePlannedWorkoutDialog(DateTime date) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Create Planned Workout?',
              style: AppTextStyles.headlineSmall.copyWith(
                color: dialogContext.textPrimary,
              ),
            ),
            content: Text(
              'No sessions are scheduled for ${DateFormat.yMMMMd().format(date)}.\n\nWould you like to create a planned workout for that date?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: dialogContext.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogContext.successColor,
                  foregroundColor: dialogContext.onSuccessColor,
                ),
                child: const Text('Create'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Handles case when a single session exists for the selected date.
  Future<void> _handleSingleSessionForDate(
    DateTime picked,
    WorkoutSession session,
  ) async {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    notifier.setCurrentWorkout(session);
    setState(() {});
  }

  /// Handles case when multiple sessions exist for the selected date.
  Future<void> _handleMultipleSessionsForDate(
    DateTime picked,
    List<WorkoutSession> sessions,
  ) async {
    final selected = await _showSessionPickerSheet(picked, sessions);
    if (selected != null) {
      final notifier = ref.read(workoutNotifierProvider.notifier);
      notifier.setCurrentWorkout(selected);
      setState(() {});
    }
  }

  /// Shows bottom sheet to pick from multiple sessions.
  Future<WorkoutSession?> _showSessionPickerSheet(
    DateTime date,
    List<WorkoutSession> sessions,
  ) async {
    return showModalBottomSheet<WorkoutSession?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: sheetContext.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sessions on ${DateFormat.yMMMMd().format(date)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: sheetContext.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...sessions.map(
                  (s) => Card(
                    child: ListTile(
                      title: Text(s.programName ?? 'Custom Workout'),
                      subtitle: Text(s.notes ?? ''),
                      onTap: () => Navigator.of(sheetContext).pop(s),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(null),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            style: AppTextStyles.titleMedium.copyWith(color: context.onSurface),
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
            style: AppTextStyles.titleMedium.copyWith(color: context.onSurface),
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

    final workoutNotifier = ref.read(workoutNotifierProvider.notifier);

    // Check if user has uncompleted recorded sets
    if (workoutNotifier.hasUncompletedRecordedSets) {
      final shouldLeave =
          await showDialog<bool>(
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
    final workoutNotifier = ref.read(workoutNotifierProvider.notifier);
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
                  if (workoutNotifier.hasActiveWorkout)
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
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFloppyDisk,
                    color: context.onSurface,
                  ),
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await workoutNotifier.saveWorkoutImmediate();
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
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  color: context.onSurface,
                ),
                onPressed: () => _changePlannedDate(workoutSession),
                tooltip: 'Change Date',
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
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _selectViewDate(workoutSession),
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  final sessionDate = workoutSession.date;
                                  final now = DateTime.now();
                                  final isToday =
                                      sessionDate.year == now.year &&
                                      sessionDate.month == now.month &&
                                      sessionDate.day == now.day;
                                  final label = isToday
                                      ? 'Today\'s Workout'
                                      : DateFormat.yMMMMd().format(sessionDate);

                                  return Row(
                                    children: [
                                      Text(
                                        label,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              color: context.textPrimary,
                                            ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedCalendar01,
                                        color: context.textSecondary,
                                        size: AppDimensions.iconSmall,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
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
                              AppDimensions.borderRadiusSmall,
                            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
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
                            AppDimensions.borderRadiusLarge,
                          ),
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
                    : ReorderableListView.builder(
                        key: const ValueKey('reorderable_exercises'),
                        buildDefaultDragHandles: false,
                        scrollController: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: workoutSession.exercises.length,
                        onReorderStart: (index) {
                          LoggingService.logUserAction(
                            'Started reordering exercises in workout session ${workoutSession.id}',
                          );
                          // Capture and collapse each card immediately; store previous state
                          _wasExpandedMap.clear();
                          _cardKeys.forEach((id, k) {
                            try {
                              final expanded =
                                  (k.currentState as dynamic)?.isExpandedState()
                                      as bool? ??
                                  false;
                              _wasExpandedMap[id] = expanded;
                              (k.currentState as dynamic)?.setCollapse();
                            } catch (_) {}
                          });
                        },
                        onReorder: (oldIndex, newIndex) async {
                          final notifier = ref.read(
                            workoutNotifierProvider.notifier,
                          );

                          // Adjust newIndex when moving down the list
                          if (newIndex > oldIndex) newIndex -= 1;

                          final updatedExercises = List<WorkoutExercise>.from(
                            workoutSession.exercises,
                          );

                          final item = updatedExercises.removeAt(oldIndex);
                          updatedExercises.insert(newIndex, item);

                          final updated = workoutSession.copyWith(
                            exercises: updatedExercises,
                          );

                          // Update state and persist immediately
                          notifier.setCurrentWorkout(updated, markDirty: true);
                          await notifier.saveWorkoutImmediate();
                          if (mounted) setState(() {});
                        },
                        onReorderEnd: (index) {
                          setState(() {
                            LoggingService.logUserAction(
                              'Finished reordering exercises in workout session ${workoutSession.id}',
                            );
                          });
                          // Restore each card and re-apply previous expanded state
                          _cardKeys.forEach((id, k) {
                            try {
                              final wasExpanded = _wasExpandedMap[id] ?? false;
                              if (wasExpanded) {
                                (k.currentState as dynamic)?.setExpanded();
                              } else {
                                (k.currentState as dynamic)?.setCollapse();
                              }
                            } catch (_) {}
                          });
                          _wasExpandedMap.clear();
                        },
                        itemBuilder: (context, index) {
                          final ex = workoutSession.exercises[index];
                          return SlideInWidget(
                            key: ValueKey(ex.id),
                            delay: Duration(milliseconds: 100 + (index * 50)),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: ExerciseCard(
                                exercise: ex,
                                exerciseIndex: index + 1,
                                isWorkoutStarted: workoutSession.isInProgress,
                                onRemove: () =>
                                    _removeExercise(index, workoutSession),
                                onSwap: () =>
                                    _swapExercise(index, workoutSession),
                                headerWrapper: (header) => GestureDetector(
                                  onLongPressStart: (_) {
                                    HapticFeedback.mediumImpact();
                                  },
                                  child: ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: header,
                                  ),
                                ),
                                key: _cardKeys.putIfAbsent(
                                  ex.id,
                                  () => GlobalKey(),
                                ),
                                onToggleSetCompleted: (setIndex) async {
                                  // TODO: start rest timer based on set.restTime
                                  setState(() {
                                    final exercise =
                                        workoutSession.exercises[index];
                                    final result = exercise.sets[setIndex]
                                        .toggleCompleted();
                                    OperationUIHandler.handleResult(
                                      context,
                                      result,
                                    );

                                    if (result is OperationSuccess) {
                                      LoggingService.logSetComplete(
                                        exercise.name,
                                        setIndex + 1,
                                        exercise.sets[setIndex].actualWeight,
                                        exercise.sets[setIndex].actualReps,
                                      );
                                    }

                                    // Collapse the card after marking set complete
                                    if (exercise.isCompleted) {
                                      (_cardKeys[exercise.id]?.currentState
                                              as dynamic)
                                          ?.setCollapse();
                                    }
                                  });

                                  // Auto-save the change
                                  await _saveWorkout();
                                },
                                onSetUpdated:
                                    (
                                      setIndex,
                                      weight,
                                      reps,
                                      notes,
                                      markAsCompleted,
                                    ) async {
                                      setState(() {
                                        final set = workoutSession
                                            .exercises[index]
                                            .sets[setIndex];

                                        if (workoutSession.isInProgress) {
                                          // Workout started -> update actuals
                                          set.updateSetData(
                                            weight: weight,
                                            reps: reps,
                                            notes: notes,
                                            markAsCompleted: markAsCompleted,
                                          );
                                        } else {
                                          // Planning mode -> update targets
                                          if (weight != null) {
                                            set.targetWeight = weight;
                                          }
                                          if (reps != null) {
                                            set.targetReps = reps;
                                          }
                                          if (notes != null) set.notes = notes;

                                          // If user explicitly marked as completed while planning,
                                          // convert targets to actuals and mark completed.
                                          if (markAsCompleted == true) {
                                            set.actualWeight ??=
                                                set.targetWeight;
                                            set.actualReps ??= set.targetReps;
                                            set.markCompleted();
                                          }
                                        }
                                      });

                                      await _saveWorkout();
                                    },
                                onAddSet: () async {
                                  setState(() {
                                    workoutSession.exercises[index].addSet();
                                  });

                                  await _saveWorkout();
                                },
                                onRemoveSet: (setIndex) async {
                                  var removed = false;
                                  setState(() {
                                    removed = workoutSession.exercises[index]
                                        .removeSet(setIndex);
                                  });

                                  if (!removed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unable to remove set. Please try again.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  // Auto-save the change
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
      decoration: BoxDecoration(color: context.surfaceVariant),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: context.primaryGradient),
          ),
        ),
      ),
    );
  }
}
