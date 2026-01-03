import 'package:flutter_lifter/models/exercise/exercise_history.dart';
import 'package:flutter_lifter/models/exercise/exercise_session_record.dart';
import 'package:flutter_lifter/models/exercise/exercise_set_record.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/utils/utils.dart';

/// Repository interface for exercise history data access.
///
/// This handles fetching and storing exercise session records,
/// PR tracking, and history aggregation.
abstract class ExerciseHistoryRepository {
  /// Get complete history for an exercise
  Future<ExerciseHistory> getExerciseHistory(Exercise exercise);

  /// Get recent sessions for an exercise (limited count)
  Future<List<ExerciseSessionRecord>> getRecentSessions(
    String exerciseId, {
    int limit = 10,
  });

  /// Get all sessions within a date range
  Future<List<ExerciseSessionRecord>> getSessionsInRange(
    String exerciseId,
    DateTime start,
    DateTime end,
  );

  /// Get the all-time PR for an exercise (returns Epley score)
  Future<double?> getAllTimePR(String exerciseId);

  /// Check if a given Epley score would be a new PR for an exercise
  Future<bool> wouldBePR(String exerciseId, double epleyScore);

  /// Record a new session (called after workout is saved)
  Future<ExerciseSessionRecord> recordSession(ExerciseSessionRecord session);

  /// Get all exercises with any recorded history
  Future<List<String>> getExerciseIdsWithHistory();

  /// Get exercise leaderboard (exercises sorted by their all-time PR)
  Future<List<ExerciseLeaderboardEntry>> getExerciseLeaderboard();
}

/// Entry for exercise leaderboard display
class ExerciseLeaderboardEntry {
  final String exerciseId;
  final String exerciseName;
  final double allTimePR;
  final DateTime prDate;
  final int totalSessions;

  const ExerciseLeaderboardEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.allTimePR,
    required this.prDate,
    required this.totalSessions,
  });
}

/// Development implementation with mock data for testing
class DevExerciseHistoryRepository implements ExerciseHistoryRepository {
  // In-memory storage for development
  final Map<String, List<ExerciseSessionRecord>> _sessionsByExercise = {};
  final Map<String, double> _prByExercise = {};

  DevExerciseHistoryRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create mock history for bench press
    final benchPressId = 'bench-press';
    final now = DateTime.now();

    // Generate 8 weeks of mock bench press sessions (2x per week)
    final benchSessions = <ExerciseSessionRecord>[];

    for (var week = 7; week >= 0; week--) {
      // Session 1 of the week
      final date1 = now.subtract(Duration(days: week * 7 + 3));
      final baseWeight = 135.0 + (7 - week) * 5; // Progress over time

      benchSessions.add(ExerciseSessionRecord(
        id: Utils.generateId(),
        exerciseId: benchPressId,
        workoutSessionId: 'workout-$week-1',
        performedAt: date1,
        sets: [
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 1,
            weight: baseWeight * 0.6,
            reps: 10,
            isWarmup: true,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 2,
            weight: baseWeight * 0.8,
            reps: 5,
            isWarmup: true,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 3,
            weight: baseWeight,
            reps: 8,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 4,
            weight: baseWeight,
            reps: 7,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 5,
            weight: baseWeight,
            reps: 6,
          ),
        ],
        sessionPR: calculateEpleyScore(baseWeight, 8),
      ));

      // Session 2 of the week
      final date2 = now.subtract(Duration(days: week * 7));

      benchSessions.add(ExerciseSessionRecord(
        id: Utils.generateId(),
        exerciseId: benchPressId,
        workoutSessionId: 'workout-$week-2',
        performedAt: date2,
        sets: [
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 1,
            weight: baseWeight * 0.6,
            reps: 10,
            isWarmup: true,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 2,
            weight: baseWeight + 10,
            reps: 5,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 3,
            weight: baseWeight + 10,
            reps: 4,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 4,
            weight: baseWeight,
            reps: 8,
          ),
        ],
        sessionPR: calculateEpleyScore(baseWeight + 10, 5),
      ));
    }

    _sessionsByExercise[benchPressId] = benchSessions;
    _prByExercise[benchPressId] = benchSessions
        .map((s) => s.sessionPR ?? 0)
        .reduce((a, b) => a > b ? a : b);

    // Create mock history for squat
    final squatId = 'squat';
    final squatSessions = <ExerciseSessionRecord>[];

    for (var week = 5; week >= 0; week--) {
      final date = now.subtract(Duration(days: week * 7 + 1));
      final baseWeight = 185.0 + (5 - week) * 10;

      squatSessions.add(ExerciseSessionRecord(
        id: Utils.generateId(),
        exerciseId: squatId,
        workoutSessionId: 'squat-workout-$week',
        performedAt: date,
        sets: [
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 1,
            weight: baseWeight * 0.5,
            reps: 10,
            isWarmup: true,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 2,
            weight: baseWeight * 0.75,
            reps: 5,
            isWarmup: true,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 3,
            weight: baseWeight,
            reps: 5,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 4,
            weight: baseWeight,
            reps: 5,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 5,
            weight: baseWeight,
            reps: 5,
          ),
        ],
        sessionPR: calculateEpleyScore(baseWeight, 5),
      ));
    }

    _sessionsByExercise[squatId] = squatSessions;
    _prByExercise[squatId] = squatSessions
        .map((s) => s.sessionPR ?? 0)
        .reduce((a, b) => a > b ? a : b);

    // Create mock history for deadlift
    final deadliftId = 'deadlift';
    final deadliftSessions = <ExerciseSessionRecord>[];

    for (var week = 3; week >= 0; week--) {
      final date = now.subtract(Duration(days: week * 7 + 2));
      final baseWeight = 225.0 + (3 - week) * 15;

      deadliftSessions.add(ExerciseSessionRecord(
        id: Utils.generateId(),
        exerciseId: deadliftId,
        workoutSessionId: 'deadlift-workout-$week',
        performedAt: date,
        sets: [
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 1,
            weight: baseWeight * 0.5,
            reps: 8,
            isWarmup: true,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 2,
            weight: baseWeight,
            reps: 3,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 3,
            weight: baseWeight,
            reps: 3,
          ),
          ExerciseSetRecord(
            id: Utils.generateId(),
            setNumber: 4,
            weight: baseWeight - 20,
            reps: 5,
          ),
        ],
        sessionPR: calculateEpleyScore(baseWeight, 3),
      ));
    }

    _sessionsByExercise[deadliftId] = deadliftSessions;
    _prByExercise[deadliftId] = deadliftSessions
        .map((s) => s.sessionPR ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<ExerciseHistory> getExerciseHistory(Exercise exercise) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final sessions = _sessionsByExercise[exercise.id] ?? [];

    return ExerciseHistory.fromSessions(
      exercise: exercise,
      sessions: sessions,
    );
  }

  @override
  Future<List<ExerciseSessionRecord>> getRecentSessions(
    String exerciseId, {
    int limit = 10,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final sessions = _sessionsByExercise[exerciseId] ?? [];
    final sorted = List<ExerciseSessionRecord>.from(sessions)
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

    return sorted.take(limit).toList();
  }

  @override
  Future<List<ExerciseSessionRecord>> getSessionsInRange(
    String exerciseId,
    DateTime start,
    DateTime end,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final sessions = _sessionsByExercise[exerciseId] ?? [];
    return sessions.where((s) {
      return s.performedAt.isAfter(start) && s.performedAt.isBefore(end);
    }).toList();
  }

  @override
  Future<double?> getAllTimePR(String exerciseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _prByExercise[exerciseId];
  }

  @override
  Future<bool> wouldBePR(String exerciseId, double epleyScore) async {
    final currentPR = await getAllTimePR(exerciseId);
    if (currentPR == null) return true;
    return epleyScore > currentPR;
  }

  @override
  Future<ExerciseSessionRecord> recordSession(
    ExerciseSessionRecord session,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Add to storage
    if (!_sessionsByExercise.containsKey(session.exerciseId)) {
      _sessionsByExercise[session.exerciseId] = [];
    }
    _sessionsByExercise[session.exerciseId]!.add(session);

    // Update PR if needed
    final sessionPR = session.sessionPR;
    if (sessionPR != null) {
      final currentPR = _prByExercise[session.exerciseId];
      if (currentPR == null || sessionPR > currentPR) {
        _prByExercise[session.exerciseId] = sessionPR;
      }
    }

    return session;
  }

  @override
  Future<List<String>> getExerciseIdsWithHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _sessionsByExercise.keys.toList();
  }

  @override
  Future<List<ExerciseLeaderboardEntry>> getExerciseLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final entries = <ExerciseLeaderboardEntry>[];

    // Exercise name lookup (in production this would come from Exercise repository)
    final exerciseNames = {
      'bench-press': 'Barbell Bench Press',
      'squat': 'Barbell Back Squat',
      'deadlift': 'Conventional Deadlift',
    };

    for (final exerciseId in _sessionsByExercise.keys) {
      final sessions = _sessionsByExercise[exerciseId]!;
      final pr = _prByExercise[exerciseId];

      if (sessions.isNotEmpty && pr != null) {
        // Find when PR was set
        final prSession = sessions.firstWhere(
          (s) => s.sessionPR == pr,
          orElse: () => sessions.first,
        );

        entries.add(ExerciseLeaderboardEntry(
          exerciseId: exerciseId,
          exerciseName: exerciseNames[exerciseId] ?? exerciseId,
          allTimePR: pr,
          prDate: prSession.performedAt,
          totalSessions: sessions.length,
        ));
      }
    }

    // Sort by PR (highest first)
    entries.sort((a, b) => b.allTimePR.compareTo(a.allTimePR));

    return entries;
  }
}
