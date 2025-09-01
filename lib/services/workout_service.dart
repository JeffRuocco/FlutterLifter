import 'dart:async';

import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/models.dart';
import 'logging_service.dart';

/// Service for managing workout sessions with automatic persistence
///
/// This service handles:
/// - Current workout session state management
/// - Automatic saving during workouts
/// - Workout lifecycle (start, update, finish)
/// - Data persistence through the repository layer
class WorkoutService {
  final ProgramRepository _programRepository;
  WorkoutSession? _currentWorkout;
  Timer? _autoSaveTimer;
  Timer? _debounceTimer;
  String? _lastSavedHash; // Track the hash of the last saved state

  // Auto-save interval (default: 30 seconds)
  static const Duration _autoSaveInterval = Duration(seconds: 30);
  // Debounce interval to prevent duplicate saves
  static const Duration _debounceInterval = Duration(milliseconds: 500);
  WorkoutService(this._programRepository);

  /// Get the current active workout session
  WorkoutSession? get currentWorkout => _currentWorkout;

  /// Whether there is an active workout in progress
  bool get hasActiveWorkout => _currentWorkout?.isInProgress == true;

  /// Start a new workout session
  ///
  /// This will:
  /// - Set the workout as the current active session
  /// - Start the workout timer
  /// - Begin auto-save functionality
  /// - Perform initial save
  Future<void> startWorkout(WorkoutSession session) async {
    LoggingService.logWorkoutStart(session.programName ?? 'Unknown Program');

    // End any existing workout first
    if (_currentWorkout?.isInProgress == true) {
      LoggingService.warning('Ending previous workout to start new one');
      await finishWorkout();
    }

    _currentWorkout = session;
    _lastSavedHash = null; // Reset hash for new workout
    session.start();
    _startAutoSave();
    await _saveWorkout();

    LoggingService.info('Workout started successfully with auto-save enabled');
  }

  /// Trigger a debounced save operation for the current workout session
  ///
  /// Call this method after making any changes to the workout
  /// (e.g., completing sets, adding exercises, updating weights).
  /// This method schedules a save using debouncing to prevent duplicate saves within 500ms,
  /// rather than saving the workout immediately.
  Future<void> saveWorkout() async {
    if (_currentWorkout != null) {
      // Cancel any pending debounced save
      _debounceTimer?.cancel();

      // Schedule a new debounced save
      LoggingService.debug('Scheduling workout save: ${_currentWorkout!.id}');
      _debounceTimer = Timer(_debounceInterval, () async {
        await _saveWorkout();
      });
    }
  }

  /// Save workout immediately without debouncing
  /// Use for critical operations like starting/finishing workouts
  Future<void> saveWorkoutImmediate() async {
    if (_currentWorkout != null) {
      LoggingService.debug(
          'Immediate workout save: ${_currentWorkout!.id} at ${DateTime.now()}');
      // Cancel any pending debounced save since we're saving now
      _debounceTimer?.cancel();
      await _saveWorkout();
    }
  }

  /// Finish the current workout session
  ///
  /// This will:
  /// - Mark the workout as completed
  /// - Perform final save
  /// - Stop auto-save timer
  /// - Clear current workout reference
  Future<void> finishWorkout() async {
    if (_currentWorkout != null) {
      _currentWorkout!.endTime = DateTime.now();
      LoggingService.logWorkoutComplete(
          _currentWorkout!.programName ?? 'Unknown Program',
          _currentWorkout!.duration ?? Duration.zero);
      await _saveWorkout();
      _stopAutoSave();
      _currentWorkout = null;
    }
  }

  /// Cancel the current workout without saving final state
  ///
  /// Use this if the user wants to discard the workout
  Future<void> cancelWorkout() async {
    if (_currentWorkout != null) {
      final startTime = _currentWorkout!.startTime;
      final duration = _currentWorkout!.duration ??
          (startTime != null
              ? DateTime.now().difference(startTime)
              : Duration.zero);

      LoggingService.logWorkoutCanceled(
          _currentWorkout!.programName ?? 'Unknown Program', duration);
      _stopAutoSave();
      await _deleteWorkout(_currentWorkout!.id);
      _currentWorkout = null;
    }
  }

  /// Resume an existing workout session
  ///
  /// Use this to continue a workout that was previously saved
  Future<void> resumeWorkout(String workoutId) async {
    final workout = await _loadWorkout(workoutId);
    if (workout != null && !workout.isCompleted) {
      _currentWorkout = workout;
      _lastSavedHash = workout.hash; // Set hash to current state
      LoggingService.logWorkoutResumed(
          workout.programName ?? 'Unknown Program');
      _startAutoSave();
    }
  }

  /// Get workout session history
  Future<List<WorkoutSession>> getWorkoutHistory() async {
    return await _programRepository.getWorkoutHistory();
  }

  /// Get a specific workout session by ID
  Future<WorkoutSession?> getWorkoutById(String workoutId) async {
    return await _loadWorkout(workoutId);
  }

  /// Check if there are any unfinished sets in the current workout
  bool hasUnfinishedSets() {
    return getUnfinishedSetsCount() > 0;
  }

  /// Get count of unfinished sets
  int getUnfinishedSetsCount() {
    if (_currentWorkout == null) return 0;

    int count = 0;
    for (final exercise in _currentWorkout!.exercises) {
      for (final set in exercise.sets) {
        if ((set.actualReps != null || set.actualWeight != null) &&
            !set.isCompleted) {
          count++;
        }
      }
    }
    return count;
  }

  /// Start automatic saving every 30 seconds
  void _startAutoSave() {
    LoggingService.debug('Starting auto-save timer');
    _stopAutoSave(); // Ensure no duplicate timers
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      if (_currentWorkout?.isInProgress == true) {
        _saveWorkout();
      }
    });
  }

  /// Stop automatic saving
  void _stopAutoSave() {
    LoggingService.debug('Stopping auto-save timer');
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Save the current workout to the repository
  Future<void> _saveWorkout() async {
    if (_currentWorkout != null) {
      // Generate hash of current workout state
      final currentHash = _currentWorkout!.hash;

      // Only save if the workout has actually changed
      if (_lastSavedHash != null && _lastSavedHash == currentHash) {
        LoggingService.debug(
            'Workout unchanged, skipping save: ${_currentWorkout!.id}');
        return;
      }

      try {
        await _programRepository.saveWorkoutSession(_currentWorkout!);
        _lastSavedHash = currentHash; // Update the saved hash
        LoggingService.debug(
            'Saving workout: ${_currentWorkout!.id} at ${DateTime.now()}');
      } catch (e) {
        // Log error but don't throw - we don't want to interrupt the workout
        // In a real app, you might want to show a non-intrusive error message
        LoggingService.error('Failed to save workout: $e');
      }
    }
  }

  /// Load a workout session from the repository
  Future<WorkoutSession?> _loadWorkout(String workoutId) async {
    try {
      LoggingService.debug('Loading workout: $workoutId');
      return await _programRepository.getWorkoutSessionById(workoutId);
    } catch (e) {
      LoggingService.error('Failed to load workout: $e');
      return null;
    }
  }

  /// Delete a workout session from the repository
  Future<void> _deleteWorkout(String workoutId) async {
    try {
      LoggingService.debug('Deleting workout: $workoutId');
      await _programRepository.deleteWorkoutSession(workoutId);
    } catch (e) {
      LoggingService.error('Failed to delete workout: $e');
    }
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    _stopAutoSave();
    _debounceTimer?.cancel();
  }
}
