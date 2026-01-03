import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/workout_service.dart';
import '../../models/workout_session_models.dart';
import '../../models/exercise/exercise_set_record.dart';
import '../../models/exercise/exercise_session_record.dart';
import 'repository_providers.dart';

// =============================================================================
// WORKOUT PROVIDERS - State Management Layer
// =============================================================================
//
// This file provides the Riverpod state management layer for workout operations.
// For more information on how to use Riverpod for state management, see:
// [docs/riverpod-guide.md]
//
// ## Architecture Overview
//
// ```
// ┌─────────────────────────────────────────────────────────────────┐
// │  UI Layer (Widgets)                                             │
// │  - Watches workoutNotifierProvider for reactive updates         │
// │  - Uses currentWorkoutProvider, hasActiveWorkoutProvider        │
// └────────────────────────────┬────────────────────────────────────┘
//                              │ ref.watch / ref.read
// ┌────────────────────────────▼────────────────────────────────────┐
// │  State Management Layer (this file)                             │
// │  - WorkoutNotifier: Manages UI state (loading, errors)          │
// │  - WorkoutState: Immutable state for UI consumption             │
// │  - Convenience providers for specific state slices              │
// └────────────────────────────┬────────────────────────────────────┘
//                              │ delegates to
// ┌────────────────────────────▼────────────────────────────────────┐
// │  Business Logic Layer (WorkoutService)                          │
// │  - Core workout operations (start, finish, save)                │
// │  - Auto-save timer management                                   │
// │  - Change detection and debouncing                              │
// └────────────────────────────┬────────────────────────────────────┘
//                              │ persists via
// ┌────────────────────────────▼────────────────────────────────────┐
// │  Data Layer (ProgramRepository)                                 │
// │  - Workout session persistence                                  │
// │  - History retrieval                                            │
// └─────────────────────────────────────────────────────────────────┘
// ```
//
// ## When to Use Which
//
// | Use Case                          | Provider/Class to Use           |
// |-----------------------------------|----------------------------------|
// | UI needs reactive workout state   | workoutNotifierProvider          |
// | Check if workout is active        | hasActiveWorkoutProvider         |
// | Get current workout in widget     | currentWorkoutProvider           |
// | Start/finish/save workout from UI | workoutNotifierProvider.notifier |
// | Direct service access (non-UI)    | workoutServiceProvider           |
// | Load workout history              | workoutHistoryProvider           |
//
// =============================================================================

/// Provider for [WorkoutService] - the core business logic layer.
///
/// Use this for direct service access when you don't need reactive UI state.
/// For most UI code, prefer [workoutNotifierProvider] instead.
///
/// See [WorkoutService] for details on the business logic layer.
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  final programRepository = ref.watch(programRepositoryProvider);
  return WorkoutService(programRepository);
});

/// Main provider for workout state management in UI components.
///
/// This is the primary provider to use for workout functionality in widgets.
/// It provides both the current [WorkoutState] and access to the [WorkoutNotifier]
/// for triggering actions.
///
/// ```dart
/// // Watch state for reactive rebuilds
/// final state = ref.watch(workoutNotifierProvider);
///
/// // Read notifier for actions
/// final notifier = ref.read(workoutNotifierProvider.notifier);
/// await notifier.startWorkout(session);
/// ```
final workoutNotifierProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final workoutService = ref.watch(workoutServiceProvider);
  return WorkoutNotifier(workoutService, ref);
});

/// Convenience provider for accessing just the current workout session.
///
/// Use this when you only need the workout data and don't care about
/// loading/error states. Automatically updates when workout changes.
///
/// ```dart
/// final workout = ref.watch(currentWorkoutProvider);
/// if (workout != null) {
///   Text(workout.programName);
/// }
/// ```
final currentWorkoutProvider = Provider<WorkoutSession?>((ref) {
  return ref.watch(workoutNotifierProvider).currentWorkout;
});

/// Convenience provider for checking if a workout is currently active.
///
/// Returns `true` if there's a workout in progress, `false` otherwise.
/// Useful for conditional UI rendering or navigation guards.
///
/// ```dart
/// final isActive = ref.watch(hasActiveWorkoutProvider);
/// if (isActive) {
///   // Show "Resume Workout" button
/// }
/// ```
final hasActiveWorkoutProvider = Provider<bool>((ref) {
  return ref.watch(workoutNotifierProvider).hasActiveWorkout;
});

/// FutureProvider for loading completed workout history.
///
/// Returns a list of past [WorkoutSession]s for display in history views.
/// Automatically handles loading and error states.
///
/// ```dart
/// final historyAsync = ref.watch(workoutHistoryProvider);
/// historyAsync.when(
///   data: (sessions) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
final workoutHistoryProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getWorkoutHistory();
});

/// StateNotifier that wraps [WorkoutService] for reactive UI state management.
///
/// ## Purpose
/// This is the **state management layer** that bridges [WorkoutService] (business
/// logic) with the UI. It adds reactive state updates, loading indicators, and
/// error handling that the UI needs.
///
/// ## What This Adds Over WorkoutService
/// - **Loading States**: `isLoading` flag for showing spinners/disabling buttons
/// - **Error Handling**: Captures errors and exposes them via `error` property
/// - **Reactive Updates**: State changes trigger UI rebuilds automatically
/// - **UI Orchestration**: Methods like [loadNextWorkout] that coordinate
///   multiple operations for specific UI flows
///
/// ## Usage
/// ```dart
/// // In a ConsumerWidget:
/// final workoutState = ref.watch(workoutNotifierProvider);
/// final notifier = ref.read(workoutNotifierProvider.notifier);
///
/// // Show loading indicator
/// if (workoutState.isLoading) return CircularProgressIndicator();
///
/// // Show error
/// if (workoutState.error != null) return ErrorWidget(workoutState.error!);
///
/// // Start a workout
/// await notifier.startWorkout(session);
/// ```
///
/// See also:
/// - [WorkoutService] - The underlying business logic layer
/// - [WorkoutState] - The immutable state class this notifier manages
class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final WorkoutService _workoutService;
  final Ref _ref;

  WorkoutNotifier(this._workoutService, this._ref)
      : super(const WorkoutState());

  /// Load the next available workout session from the active program cycle
  ///
  /// This should be called at app startup or when returning to the home screen
  /// to ensure the current/next workout is available in state.
  Future<void> loadNextWorkout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = _ref.read(programRepositoryProvider);
      final programs = await repository.getPrograms();

      // Find the active program with an active cycle
      final activeProgram = programs
          .where(
            (program) => program.activeCycle != null,
          )
          .firstOrNull;

      if (activeProgram != null) {
        final nextSession = activeProgram.activeCycle?.currentWorkoutSession;
        state = state.copyWith(
          currentWorkout: nextSession,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          currentWorkout: null,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set the current workout session directly (e.g., when passed via route)
  void setCurrentWorkout(WorkoutSession? session) {
    state = state.copyWith(currentWorkout: session);
  }

  /// Start a new workout session
  Future<void> startWorkout(WorkoutSession session) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _workoutService.startWorkout(session);
      state = state.copyWith(
        currentWorkout: _workoutService.currentWorkout,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Save the current workout (debounced)
  Future<void> saveWorkout() async {
    await _workoutService.saveWorkout();
    // Update state with current workout
    state = state.copyWith(currentWorkout: _workoutService.currentWorkout);
  }

  /// Save the current workout immediately
  Future<void> saveWorkoutImmediate() async {
    await _workoutService.saveWorkoutImmediate();
    state = state.copyWith(currentWorkout: _workoutService.currentWorkout);
  }

  /// Finish the current workout
  Future<void> finishWorkout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Record exercise history before finishing
      final workout = _workoutService.currentWorkout;
      if (workout != null) {
        await _recordExerciseHistory(workout);
      }

      await _workoutService.finishWorkout();
      state = state.copyWith(
        currentWorkout: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Records exercise history for all exercises with completed sets
  ///
  /// This creates [ExerciseSessionRecord] entries for each exercise
  /// that has at least one completed set with recorded weight/reps.
  /// Called automatically when a workout is finished.
  Future<void> _recordExerciseHistory(WorkoutSession workout) async {
    final historyRepo = _ref.read(exerciseHistoryRepositoryProvider);

    for (final workoutExercise in workout.exercises) {
      // Get only completed sets with actual recorded values
      final completedSets = workoutExercise.sets
          .where((set) =>
              set.isCompleted &&
              set.actualWeight != null &&
              set.actualReps != null)
          .toList();

      // Skip if no completed sets with data
      if (completedSets.isEmpty) continue;

      // Convert ExerciseSet to ExerciseSetRecord
      final setRecords = <ExerciseSetRecord>[];
      for (var i = 0; i < completedSets.length; i++) {
        final set = completedSets[i];
        setRecords.add(ExerciseSetRecord.create(
          setNumber: i + 1,
          weight: set.actualWeight!,
          reps: set.actualReps!,
          isWarmup: false, // Could be determined by set position/weight
          notes: set.notes,
        ));
      }

      // Create the session record
      final sessionRecord = ExerciseSessionRecord.create(
        exerciseId: workoutExercise.exercise.id,
        workoutSessionId: workout.id,
        sets: setRecords,
        performedAt: DateTime.now(),
        notes: workoutExercise.notes,
      );

      // Save to repository
      await historyRepo.recordSession(sessionRecord);
    }
  }

  /// Cancel the current workout
  Future<void> cancelWorkout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _workoutService.cancelWorkout();
      state = state.copyWith(
        currentWorkout: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Resume an existing workout
  Future<void> resumeWorkout(String workoutId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _workoutService.resumeWorkout(workoutId);
      state = state.copyWith(
        currentWorkout: _workoutService.currentWorkout,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update the workout state (for UI updates after exercise changes)
  void refreshState() {
    state = state.copyWith(currentWorkout: _workoutService.currentWorkout);
  }

  /// Check if there are unfinished exercises
  bool get hasUnfinishedExercises => _workoutService.hasUnfinishedExercises();

  /// Check if there are uncompleted recorded sets
  bool get hasUncompletedRecordedSets =>
      _workoutService.hasUncompletedRecordedSets();

  /// Get count of unfinished sets
  int get unfinishedSetsCount => _workoutService.getUnfinishedSetsCount();
}

/// Immutable state class representing the current workout UI state.
///
/// This class holds all the state that UI components need to render
/// workout-related views. It includes:
/// - [currentWorkout]: The active workout session (null if none)
/// - [isLoading]: Whether an async operation is in progress
/// - [error]: Error message from the last failed operation (null if none)
///
/// Use [copyWith] to create modified copies (immutable update pattern).
class WorkoutState {
  final WorkoutSession? currentWorkout;
  final bool isLoading;
  final String? error;

  const WorkoutState({
    this.currentWorkout,
    this.isLoading = false,
    this.error,
  });

  bool get hasActiveWorkout => currentWorkout?.isInProgress == true;

  WorkoutState copyWith({
    WorkoutSession? currentWorkout,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutState(
      currentWorkout: currentWorkout ?? this.currentWorkout,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
