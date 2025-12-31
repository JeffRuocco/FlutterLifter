import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/utils/utils.dart';

/// Stores user-specific preferences/overrides for an exercise.
/// Used to customize default exercises without modifying the immutable originals.
class UserExercisePreferences {
  final String id;

  /// The ID of the exercise these preferences apply to
  final String exerciseId;

  /// User's preferred number of sets (overrides exercise.defaultSets)
  final int? preferredSets;

  /// User's preferred number of reps (overrides exercise.defaultReps)
  final int? preferredReps;

  /// User's preferred weight (overrides exercise.defaultWeight)
  final double? preferredWeight;

  /// User's preferred rest time in seconds (overrides exercise.defaultRestTimeSeconds)
  final int? preferredRestTimeSeconds;

  /// User's personal notes for this exercise
  final String? notes;

  /// When these preferences were created
  final DateTime createdAt;

  /// When these preferences were last updated
  final DateTime updatedAt;

  UserExercisePreferences({
    required this.id,
    required this.exerciseId,
    this.preferredSets,
    this.preferredReps,
    this.preferredWeight,
    this.preferredRestTimeSeconds,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new preference with auto-generated ID and timestamps
  factory UserExercisePreferences.create({
    required String exerciseId,
    int? preferredSets,
    int? preferredReps,
    double? preferredWeight,
    int? preferredRestTimeSeconds,
    String? notes,
  }) {
    final now = DateTime.now();
    return UserExercisePreferences(
      id: Utils.generateId(),
      exerciseId: exerciseId,
      preferredSets: preferredSets,
      preferredReps: preferredReps,
      preferredWeight: preferredWeight,
      preferredRestTimeSeconds: preferredRestTimeSeconds,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns whether any preferences are set
  bool get hasPreferences =>
      preferredSets != null ||
      preferredReps != null ||
      preferredWeight != null ||
      preferredRestTimeSeconds != null ||
      notes != null;

  /// Applies these preferences to an exercise, returning a new Exercise with overridden defaults
  Exercise applyToExercise(Exercise exercise) {
    if (exercise.id != exerciseId) {
      throw ArgumentError(
        'Preferences exerciseId ($exerciseId) does not match exercise.id (${exercise.id})',
      );
    }

    return exercise.copyWith(
      defaultSets: preferredSets ?? exercise.defaultSets,
      defaultReps: preferredReps ?? exercise.defaultReps,
      defaultWeight: preferredWeight ?? exercise.defaultWeight,
      defaultRestTimeSeconds:
          preferredRestTimeSeconds ?? exercise.defaultRestTimeSeconds,
      notes: notes ?? exercise.notes,
    );
  }

  /// Creates a copy with updated values
  UserExercisePreferences copyWith({
    String? id,
    String? exerciseId,
    int? preferredSets,
    int? preferredReps,
    double? preferredWeight,
    int? preferredRestTimeSeconds,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserExercisePreferences(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      preferredSets: preferredSets ?? this.preferredSets,
      preferredReps: preferredReps ?? this.preferredReps,
      preferredWeight: preferredWeight ?? this.preferredWeight,
      preferredRestTimeSeconds:
          preferredRestTimeSeconds ?? this.preferredRestTimeSeconds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Creates UserExercisePreferences from JSON
  factory UserExercisePreferences.fromJson(Map<String, dynamic> json) {
    return UserExercisePreferences(
      id: json['id'],
      exerciseId: json['exerciseId'],
      preferredSets: json['preferredSets'],
      preferredReps: json['preferredReps'],
      preferredWeight: json['preferredWeight']?.toDouble(),
      preferredRestTimeSeconds: json['preferredRestTimeSeconds'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Converts UserExercisePreferences to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'preferredSets': preferredSets,
      'preferredReps': preferredReps,
      'preferredWeight': preferredWeight,
      'preferredRestTimeSeconds': preferredRestTimeSeconds,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserExercisePreferences &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserExercisePreferences{id: $id, exerciseId: $exerciseId, '
        'preferredSets: $preferredSets, preferredReps: $preferredReps, '
        'preferredWeight: $preferredWeight}';
  }
}
