import 'package:flutter_lifter/models/exercise_models.dart';

import 'exercise_session_record.dart';

/// Represents the complete history of an exercise for a user.
///
/// This aggregates all [ExerciseSessionRecord]s for a specific exercise,
/// providing lifetime statistics, PR tracking, and progression data.
class ExerciseHistory {
  /// The exercise this history is for
  final Exercise exercise;

  /// All session records for this exercise, ordered by date (newest first)
  final List<ExerciseSessionRecord> sessions;

  /// The all-time best Epley score achieved
  final double? allTimePR;

  /// When the all-time PR was set
  final DateTime? prDate;

  ExerciseHistory({
    required this.exercise,
    required this.sessions,
    this.allTimePR,
    this.prDate,
  });

  /// Factory constructor to build history with auto-calculated stats
  factory ExerciseHistory.fromSessions({
    required Exercise exercise,
    required List<ExerciseSessionRecord> sessions,
  }) {
    // Sort sessions by date (newest first)
    final sortedSessions = List<ExerciseSessionRecord>.from(sessions)
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

    // Find all-time PR
    double? bestPR;
    DateTime? bestDate;

    for (final session in sortedSessions) {
      if (session.sessionPR != null) {
        if (bestPR == null || session.sessionPR! > bestPR) {
          bestPR = session.sessionPR;
          bestDate = session.performedAt;
        }
      }
    }

    return ExerciseHistory(
      exercise: exercise,
      sessions: sortedSessions,
      allTimePR: bestPR,
      prDate: bestDate,
    );
  }

  // ============================================
  // Computed Properties
  // ============================================

  /// Whether user has any history for this exercise
  bool get hasHistory => sessions.isNotEmpty;

  /// Total number of sessions performed
  int get totalSessions => sessions.length;

  /// Total number of sets performed (all time)
  int get totalSets => sessions.fold(0, (sum, s) => sum + s.totalSets);

  /// Total number of working sets performed (all time)
  int get totalWorkingSets => sessions.fold(0, (sum, s) => sum + s.workingSets);

  /// Total volume lifted (all time)
  double get totalVolume => sessions.fold(0.0, (sum, s) => sum + s.totalVolume);

  /// Average weight across all working sets (all time)
  double get averageWeight {
    if (sessions.isEmpty) return 0;
    final allWorkingSets =
        sessions.expand((s) => s.sets).where((set) => !set.isWarmup).toList();
    if (allWorkingSets.isEmpty) return 0;
    return allWorkingSets.map((s) => s.weight).reduce((a, b) => a + b) /
        allWorkingSets.length;
  }

  /// Maximum weight ever lifted for this exercise
  double get maxWeight {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.maxWeight).reduce((a, b) => a > b ? a : b);
  }

  /// Maximum reps ever performed in a single set
  int get maxReps {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.maxReps).reduce((a, b) => a > b ? a : b);
  }

  /// Most recent session
  ExerciseSessionRecord? get mostRecentSession =>
      sessions.isNotEmpty ? sessions.first : null;

  /// Date of most recent session
  DateTime? get lastPerformed => mostRecentSession?.performedAt;

  /// Days since last performed
  int? get daysSinceLastPerformed {
    if (lastPerformed == null) return null;
    return DateTime.now().difference(lastPerformed!).inDays;
  }

  /// PR progression over time (session date -> best Epley that session)
  /// Returns list of entries sorted by date (oldest first) for charting
  List<PRProgressionEntry> get prProgression {
    if (sessions.isEmpty) return [];

    final entries = <PRProgressionEntry>[];
    double runningBest = 0;

    // Process in chronological order (oldest first)
    final chronological = sessions.reversed.toList();

    for (final session in chronological) {
      final sessionBest = session.bestEpleyScore;
      if (sessionBest > runningBest) {
        runningBest = sessionBest;
        entries.add(PRProgressionEntry(
          date: session.performedAt,
          epleyScore: runningBest,
          sessionId: session.id,
          isPR: true,
        ));
      } else {
        entries.add(PRProgressionEntry(
          date: session.performedAt,
          epleyScore: sessionBest,
          sessionId: session.id,
          isPR: false,
        ));
      }
    }

    return entries;
  }

  /// Volume progression over time (for charting)
  List<VolumeProgressionEntry> get volumeProgression {
    if (sessions.isEmpty) return [];

    return sessions.reversed.map((s) {
      return VolumeProgressionEntry(
        date: s.performedAt,
        totalVolume: s.totalVolume,
        workingVolume: s.workingVolume,
        sessionId: s.id,
      );
    }).toList();
  }

  /// Get sessions within a date range
  List<ExerciseSessionRecord> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return sessions.where((s) {
      return s.performedAt.isAfter(start) && s.performedAt.isBefore(end);
    }).toList();
  }

  /// Get the last N sessions
  List<ExerciseSessionRecord> getRecentSessions(int count) {
    return sessions.take(count).toList();
  }

  /// Check if a given Epley score would be a new PR
  bool wouldBePR(double epleyScore) {
    if (allTimePR == null) return true;
    return epleyScore > allTimePR!;
  }

  /// Creates a copy with updated values
  ExerciseHistory copyWith({
    Exercise? exercise,
    List<ExerciseSessionRecord>? sessions,
    double? allTimePR,
    DateTime? prDate,
  }) {
    return ExerciseHistory(
      exercise: exercise ?? this.exercise,
      sessions: sessions ?? this.sessions,
      allTimePR: allTimePR ?? this.allTimePR,
      prDate: prDate ?? this.prDate,
    );
  }

  /// Creates ExerciseHistory from JSON
  factory ExerciseHistory.fromJson(
    Map<String, dynamic> json,
    Exercise exercise,
  ) {
    return ExerciseHistory(
      exercise: exercise,
      sessions: (json['sessions'] as List<dynamic>)
          .map((s) => ExerciseSessionRecord.fromJson(s as Map<String, dynamic>))
          .toList(),
      allTimePR: (json['allTimePR'] as num?)?.toDouble(),
      prDate: json['prDate'] != null
          ? DateTime.parse(json['prDate'] as String)
          : null,
    );
  }

  /// Converts ExerciseHistory to JSON (excludes exercise to avoid duplication)
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exercise.id,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'allTimePR': allTimePR,
      'prDate': prDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ExerciseHistory{exercise: ${exercise.name}, '
        'sessions: ${sessions.length}, allTimePR: $allTimePR}';
  }
}

/// Entry for PR progression chart
class PRProgressionEntry {
  final DateTime date;
  final double epleyScore;
  final String sessionId;
  final bool isPR;

  const PRProgressionEntry({
    required this.date,
    required this.epleyScore,
    required this.sessionId,
    required this.isPR,
  });

  @override
  String toString() =>
      'PRProgressionEntry{date: $date, epley: $epleyScore, isPR: $isPR}';
}

/// Entry for volume progression chart
class VolumeProgressionEntry {
  final DateTime date;
  final double totalVolume;
  final double workingVolume;
  final String sessionId;

  const VolumeProgressionEntry({
    required this.date,
    required this.totalVolume,
    required this.workingVolume,
    required this.sessionId,
  });

  @override
  String toString() =>
      'VolumeProgressionEntry{date: $date, total: $totalVolume, working: $workingVolume}';
}
