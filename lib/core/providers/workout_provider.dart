import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/workout_service.dart';
import '../../models/workout_session_models.dart';
import 'repository_providers.dart';

/// Provider for WorkoutService
///
/// Manages the current workout session, auto-save, and workout lifecycle.
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  final programRepository = ref.watch(programRepositoryProvider);
  return WorkoutService(programRepository);
});

/// StateNotifier for managing workout state
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

/// State class for workout management
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

/// StateNotifierProvider for workout management
final workoutNotifierProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final workoutService = ref.watch(workoutServiceProvider);
  return WorkoutNotifier(workoutService, ref);
});

/// Convenience provider for current workout
final currentWorkoutProvider = Provider<WorkoutSession?>((ref) {
  return ref.watch(workoutNotifierProvider).currentWorkout;
});

/// Convenience provider for active workout status
final hasActiveWorkoutProvider = Provider<bool>((ref) {
  return ref.watch(workoutNotifierProvider).hasActiveWorkout;
});

/// FutureProvider for workout history
final workoutHistoryProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getWorkoutHistory();
});
