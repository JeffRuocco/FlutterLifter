import 'dart:math';

import 'package:flutter_lifter/utils/utils.dart';

import 'exercise_set_record.dart';

/// Represents all sets from a single workout session for a specific exercise.
///
/// This aggregates all [ExerciseSetRecord]s performed during a workout,
/// providing computed statistics like total volume, max weight, and session PR.
class ExerciseSessionRecord {
  /// Unique identifier for this session record
  final String id;

  /// ID of the exercise this session is for
  final String exerciseId;

  /// ID of the workout session this was performed in (links to WorkoutSession)
  final String workoutSessionId;

  /// When this exercise was performed
  final DateTime performedAt;

  /// All sets performed during this session
  final List<ExerciseSetRecord> sets;

  /// Best Epley score achieved this session (cached for performance)
  final double? sessionPR;

  /// Optional notes for this exercise session
  final String? notes;

  ExerciseSessionRecord({
    required this.id,
    required this.exerciseId,
    required this.workoutSessionId,
    required this.performedAt,
    required this.sets,
    this.sessionPR,
    this.notes,
  });

  /// Factory constructor for creating a new session record with auto-generated ID
  factory ExerciseSessionRecord.create({
    required String exerciseId,
    required String workoutSessionId,
    required List<ExerciseSetRecord> sets,
    DateTime? performedAt,
    String? notes,
  }) {
    final now = performedAt ?? DateTime.now();
    final bestEpley = sets.isEmpty
        ? null
        : sets
            .where((s) => !s.isWarmup)
            .map((s) => s.epleyScore)
            .fold<double>(0, (a, b) => a > b ? a : b);

    return ExerciseSessionRecord(
      id: Utils.generateId(),
      exerciseId: exerciseId,
      workoutSessionId: workoutSessionId,
      performedAt: now,
      sets: sets,
      sessionPR: bestEpley,
      notes: notes,
    );
  }

  // ============================================
  // Computed Properties
  // ============================================

  /// Total number of sets performed
  int get totalSets => sets.length;

  /// Number of working (non-warmup) sets
  int get workingSets => sets.where((s) => !s.isWarmup).length;

  /// Total volume (weight × reps) across all sets
  double get totalVolume {
    return sets.fold(0.0, (sum, s) => sum + (s.weight * s.reps));
  }

  /// Total volume for working sets only (excludes warmup)
  double get workingVolume {
    return sets
        .where((s) => !s.isWarmup)
        .fold(0.0, (sum, s) => sum + (s.weight * s.reps));
  }

  /// Maximum weight lifted this session
  double get maxWeight {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.weight).reduce(max);
  }

  /// Maximum reps performed in a single set this session
  int get maxReps {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.reps).reduce(max);
  }

  /// Best Epley score this session (calculated if not cached)
  double get bestEpleyScore {
    if (sessionPR != null) return sessionPR!;
    if (sets.isEmpty) return 0;
    return sets
        .where((s) => !s.isWarmup)
        .map((s) => s.epleyScore)
        .fold<double>(0, (a, b) => a > b ? a : b);
  }

  /// The set with the best Epley score this session
  ExerciseSetRecord? get prSet {
    if (sets.isEmpty) return null;
    final workingSets = sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) return null;
    return workingSets.reduce((a, b) => a.epleyScore > b.epleyScore ? a : b);
  }

  /// Average weight across working sets
  double get averageWeight {
    final workingSets = sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) return 0;
    return workingSets.map((s) => s.weight).reduce((a, b) => a + b) /
        workingSets.length;
  }

  /// Average reps across working sets
  double get averageReps {
    final workingSets = sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) return 0;
    return workingSets.map((s) => s.reps).reduce((a, b) => a + b) /
        workingSets.length;
  }

  /// Creates a copy with updated values
  ExerciseSessionRecord copyWith({
    String? id,
    String? exerciseId,
    String? workoutSessionId,
    DateTime? performedAt,
    List<ExerciseSetRecord>? sets,
    double? sessionPR,
    String? notes,
  }) {
    return ExerciseSessionRecord(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      performedAt: performedAt ?? this.performedAt,
      sets: sets ?? this.sets,
      sessionPR: sessionPR ?? this.sessionPR,
      notes: notes ?? this.notes,
    );
  }

  /// Creates ExerciseSessionRecord from JSON
  factory ExerciseSessionRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseSessionRecord(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      workoutSessionId: json['workoutSessionId'] as String,
      performedAt: DateTime.parse(json['performedAt'] as String),
      sets: (json['sets'] as List<dynamic>)
          .map((s) => ExerciseSetRecord.fromJson(s as Map<String, dynamic>))
          .toList(),
      sessionPR: (json['sessionPR'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  /// Converts ExerciseSessionRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'workoutSessionId': workoutSessionId,
      'performedAt': performedAt.toIso8601String(),
      'sets': sets.map((s) => s.toJson()).toList(),
      'sessionPR': sessionPR,
      'notes': notes,
    };
  }

  /// Summary string for display
  String get summaryString {
    return '$workingSets sets • ${totalVolume.toStringAsFixed(0)} lbs total';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSessionRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExerciseSessionRecord{id: $id, exerciseId: $exerciseId, '
        'performedAt: $performedAt, sets: ${sets.length}, sessionPR: $sessionPR}';
  }
}
