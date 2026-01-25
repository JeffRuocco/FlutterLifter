import 'package:flutter_lifter/models/exercise/exercise_history.dart';
import 'package:flutter_lifter/models/exercise/exercise_session_record.dart';
import 'package:flutter_lifter/models/exercise/exercise_set_record.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/utils/utils.dart';
import 'package:hive/hive.dart';

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
class ExerciseHistoryRepositoryImpl implements ExerciseHistoryRepository {
  // In-memory storage for development
  final Map<String, List<ExerciseSessionRecord>> _sessionsByExercise = {};
  final Map<String, double> _prByExercise = {};
  static const _boxName = 'exercise_history';
  final Box<dynamic>? _box;

  /// Private constructor
  ///
  /// [useMockData] indicates whether to populate with mock data.
  ExerciseHistoryRepositoryImpl._(bool useMockData)
    : _box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : null {
    // If a Hive box is open, try to load persisted state (JSON maps).
    if (_box != null) {
      try {
        final storedSessions =
            _box.get('sessionsByExercise') as Map<dynamic, dynamic>?;
        if (storedSessions != null) {
          storedSessions.forEach((k, v) {
            final key = k as String;
            final list = (v as List).cast<Map<dynamic, dynamic>>();
            _sessionsByExercise[key] = list
                .map(
                  (e) => ExerciseSessionRecord.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList();
          });
        }

        final storedPRs = _box.get('prByExercise') as Map<dynamic, dynamic>?;
        if (storedPRs != null) {
          storedPRs.forEach((k, v) {
            _prByExercise[k as String] = (v as num).toDouble();
          });
        }
      } catch (_) {
        // If persisted data is malformed, fall back to in-memory/mock initialization below.
      }
    }

    if (_sessionsByExercise.isEmpty && useMockData) {
      _initializeMockData();
      // Persist initial mock data if box is available
      // _persist();
    }
  }

  Future<void> _persist() async {
    if (_box == null) return;

    final sessionsJson = <String, List<Map<String, dynamic>>>{};
    _sessionsByExercise.forEach((k, v) {
      sessionsJson[k] = v.map((s) => s.toJson()).toList();
    });

    final prJson = <String, double>{};
    _prByExercise.forEach((k, v) => prJson[k] = v);

    await _box.put('sessionsByExercise', sessionsJson);
    await _box.put('prByExercise', prJson);
  }

  /// Factory constructor for development instance.
  ///
  /// Populates with mock data.
  factory ExerciseHistoryRepositoryImpl.development() {
    return ExerciseHistoryRepositoryImpl._(true);
  }

  /// Factory constructor for production instance.
  factory ExerciseHistoryRepositoryImpl.production() {
    return ExerciseHistoryRepositoryImpl._(false);
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

      benchSessions.add(
        ExerciseSessionRecord(
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
        ),
      );

      // Session 2 of the week
      final date2 = now.subtract(Duration(days: week * 7));

      benchSessions.add(
        ExerciseSessionRecord(
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
        ),
      );
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

      squatSessions.add(
        ExerciseSessionRecord(
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
        ),
      );
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

      deadliftSessions.add(
        ExerciseSessionRecord(
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
        ),
      );
    }

    _sessionsByExercise[deadliftId] = deadliftSessions;
    _prByExercise[deadliftId] = deadliftSessions
        .map((s) => s.sessionPR ?? 0)
        .reduce((a, b) => a > b ? a : b);

    // Create mock history for overhead press
    _addMockExerciseHistory(
      exerciseId: 'ohp',
      baseWeight: 95.0,
      weeklyProgress: 2.5,
      weeksOfHistory: 6,
      sessionsPerWeek: 2,
      repsPerSet: 6,
      setsPerSession: 4,
    );

    // Create mock history for barbell row
    _addMockExerciseHistory(
      exerciseId: 'row',
      baseWeight: 135.0,
      weeklyProgress: 5.0,
      weeksOfHistory: 5,
      sessionsPerWeek: 2,
      repsPerSet: 8,
      setsPerSession: 4,
    );

    // Create mock history for pull-ups
    _addMockExerciseHistory(
      exerciseId: 'pullup',
      baseWeight: 0.0, // Bodyweight
      weeklyProgress: 0.0,
      weeksOfHistory: 4,
      sessionsPerWeek: 2,
      repsPerSet: 8,
      setsPerSession: 3,
      useBodyweight: true,
    );

    // Create mock history for dips
    _addMockExerciseHistory(
      exerciseId: 'dips',
      baseWeight: 0.0, // Bodyweight
      weeklyProgress: 0.0,
      weeksOfHistory: 4,
      sessionsPerWeek: 2,
      repsPerSet: 10,
      setsPerSession: 3,
      useBodyweight: true,
    );

    // Create mock history for barbell curl
    _addMockExerciseHistory(
      exerciseId: 'barbell_curl',
      baseWeight: 65.0,
      weeklyProgress: 2.5,
      weeksOfHistory: 6,
      sessionsPerWeek: 2,
      repsPerSet: 10,
      setsPerSession: 3,
    );

    // Create mock history for lateral raise
    _addMockExerciseHistory(
      exerciseId: 'lateral_raise',
      baseWeight: 15.0,
      weeklyProgress: 1.0,
      weeksOfHistory: 5,
      sessionsPerWeek: 2,
      repsPerSet: 15,
      setsPerSession: 3,
    );

    // Create mock history for leg press
    _addMockExerciseHistory(
      exerciseId: 'leg_press',
      baseWeight: 270.0,
      weeklyProgress: 10.0,
      weeksOfHistory: 6,
      sessionsPerWeek: 1,
      repsPerSet: 10,
      setsPerSession: 4,
    );

    // Create mock history for Romanian deadlift
    _addMockExerciseHistory(
      exerciseId: 'romanian_deadlift',
      baseWeight: 155.0,
      weeklyProgress: 5.0,
      weeksOfHistory: 5,
      sessionsPerWeek: 1,
      repsPerSet: 8,
      setsPerSession: 3,
    );

    // Create mock history for lat pulldown
    _addMockExerciseHistory(
      exerciseId: 'lat_pulldown',
      baseWeight: 120.0,
      weeklyProgress: 5.0,
      weeksOfHistory: 6,
      sessionsPerWeek: 2,
      repsPerSet: 10,
      setsPerSession: 3,
    );

    // Create mock history for incline bench press
    _addMockExerciseHistory(
      exerciseId: 'incline_bench',
      baseWeight: 115.0,
      weeklyProgress: 5.0,
      weeksOfHistory: 6,
      sessionsPerWeek: 1,
      repsPerSet: 8,
      setsPerSession: 3,
    );
  }

  /// Helper method to add mock exercise history
  void _addMockExerciseHistory({
    required String exerciseId,
    required double baseWeight,
    required double weeklyProgress,
    required int weeksOfHistory,
    required int sessionsPerWeek,
    required int repsPerSet,
    required int setsPerSession,
    bool useBodyweight = false,
  }) {
    final now = DateTime.now();
    final sessions = <ExerciseSessionRecord>[];

    for (var week = weeksOfHistory - 1; week >= 0; week--) {
      for (var session = 0; session < sessionsPerWeek; session++) {
        final date = now.subtract(Duration(days: week * 7 + session * 3));
        final weight = useBodyweight
            ? 180.0 // Assume 180lb bodyweight for Epley calculation
            : baseWeight + (weeksOfHistory - 1 - week) * weeklyProgress;

        final sets = <ExerciseSetRecord>[];

        // Add warmup set if not bodyweight
        if (!useBodyweight && weight > 0) {
          sets.add(
            ExerciseSetRecord(
              id: Utils.generateId(),
              setNumber: 1,
              weight: weight * 0.5,
              reps: 10,
              isWarmup: true,
            ),
          );
        }

        // Add working sets with slight rep variation
        for (var setNum = 0; setNum < setsPerSession; setNum++) {
          final repVariation = setNum == 0 ? 0 : -setNum; // Fatigue simulation
          final actualReps = (repsPerSet + repVariation).clamp(1, 20);

          sets.add(
            ExerciseSetRecord(
              id: Utils.generateId(),
              setNumber: sets.length + 1,
              weight: useBodyweight ? 0 : weight,
              reps: actualReps,
              isWarmup: false,
            ),
          );
        }

        // Calculate session PR (best Epley score from working sets)
        final workingSets = sets.where((s) => !s.isWarmup);
        final sessionPR = workingSets.isEmpty
            ? 0.0
            : workingSets
                  .map(
                    (s) => calculateEpleyScore(
                      useBodyweight ? 180.0 : s.weight,
                      s.reps,
                    ),
                  )
                  .reduce((a, b) => a > b ? a : b);

        sessions.add(
          ExerciseSessionRecord(
            id: Utils.generateId(),
            exerciseId: exerciseId,
            workoutSessionId: '$exerciseId-workout-$week-$session',
            performedAt: date,
            sets: sets,
            sessionPR: sessionPR,
          ),
        );
      }
    }

    _sessionsByExercise[exerciseId] = sessions;
    if (sessions.isNotEmpty) {
      _prByExercise[exerciseId] = sessions
          .map((s) => s.sessionPR ?? 0)
          .reduce((a, b) => a > b ? a : b);
    }
  }

  @override
  Future<ExerciseHistory> getExerciseHistory(Exercise exercise) async {
    // await Future<void>.delayed(const Duration(milliseconds: 100));

    final sessions = _sessionsByExercise[exercise.id] ?? [];

    return ExerciseHistory.fromSessions(exercise: exercise, sessions: sessions);
  }

  @override
  Future<List<ExerciseSessionRecord>> getRecentSessions(
    String exerciseId, {
    int limit = 10,
  }) async {
    // await Future<void>.delayed(const Duration(milliseconds: 50));

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
    // await Future<void>.delayed(const Duration(milliseconds: 50));

    final sessions = _sessionsByExercise[exerciseId] ?? [];
    return sessions.where((s) {
      return s.performedAt.isAfter(start) && s.performedAt.isBefore(end);
    }).toList();
  }

  @override
  Future<double?> getAllTimePR(String exerciseId) async {
    // await Future<void>.delayed(const Duration(milliseconds: 20));
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

    // Persist changes if Hive box is available
    await _persist();

    return session;
  }

  @override
  Future<List<String>> getExerciseIdsWithHistory() async {
    // await Future<void>.delayed(const Duration(milliseconds: 20));
    return _sessionsByExercise.keys.toList();
  }

  @override
  Future<List<ExerciseLeaderboardEntry>> getExerciseLeaderboard() async {
    // await Future<void>.delayed(const Duration(milliseconds: 100));

    final entries = <ExerciseLeaderboardEntry>[];

    // Exercise name lookup (in production this would come from Exercise repository)
    final exerciseNames = {
      'bench-press': 'Barbell Bench Press',
      'bench': 'Bench Press',
      'squat': 'Barbell Back Squat',
      'deadlift': 'Conventional Deadlift',
      'ohp': 'Overhead Press',
      'row': 'Bent-Over Barbell Row',
      'pullup': 'Pull-ups',
      'dips': 'Dips',
      'barbell_curl': 'Barbell Curl',
      'lateral_raise': 'Lateral Raise',
      'leg_press': 'Leg Press',
      'romanian_deadlift': 'Romanian Deadlift',
      'lat_pulldown': 'Lat Pulldown',
      'incline_bench': 'Incline Bench Press',
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

        entries.add(
          ExerciseLeaderboardEntry(
            exerciseId: exerciseId,
            exerciseName: exerciseNames[exerciseId] ?? exerciseId,
            allTimePR: pr,
            prDate: prSession.performedAt,
            totalSessions: sessions.length,
          ),
        );
      }
    }

    // Sort by PR (highest first)
    entries.sort((a, b) => b.allTimePR.compareTo(a.allTimePR));

    return entries;
  }
}
