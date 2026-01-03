import 'package:flutter_lifter/utils/utils.dart';

/// Calculates the Epley score (estimated 1RM) for a given weight and reps.
///
/// The Epley formula is: weight × (1 + reps/30)
/// This provides a standardized way to compare sets with different rep ranges.
double calculateEpleyScore(double weight, int reps) {
  if (reps <= 0) return 0;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30.0);
}

/// Represents a single set within an exercise session.
///
/// This is used to record individual sets performed during a workout,
/// including the weight, reps, and calculated Epley score for PR tracking.
class ExerciseSetRecord {
  /// Unique identifier for this set record
  final String id;

  /// Set number within the exercise (1-indexed)
  final int setNumber;

  /// Weight used for this set (in lbs)
  final double weight;

  /// Number of repetitions completed
  final int reps;

  /// Whether this was a warmup set (not counted in working sets)
  final bool isWarmup;

  /// Rate of Perceived Exertion (1-10 scale, optional)
  final double? rpe;

  /// Optional notes for this specific set
  final String? notes;

  /// Calculated Epley score: weight × (1 + reps/30)
  /// This allows comparison of sets with different rep ranges.
  final double epleyScore;

  ExerciseSetRecord({
    required this.id,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isWarmup = false,
    this.rpe,
    this.notes,
    double? epleyScore,
  }) : epleyScore = epleyScore ?? calculateEpleyScore(weight, reps);

  /// Factory constructor for creating a new set record with auto-generated ID
  factory ExerciseSetRecord.create({
    required int setNumber,
    required double weight,
    required int reps,
    bool isWarmup = false,
    double? rpe,
    String? notes,
  }) {
    return ExerciseSetRecord(
      id: Utils.generateId(),
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      isWarmup: isWarmup,
      rpe: rpe,
      notes: notes,
    );
  }

  /// Creates a copy with updated values
  ExerciseSetRecord copyWith({
    String? id,
    int? setNumber,
    double? weight,
    int? reps,
    bool? isWarmup,
    double? rpe,
    String? notes,
  }) {
    return ExerciseSetRecord(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isWarmup: isWarmup ?? this.isWarmup,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  /// Creates ExerciseSetRecord from JSON
  factory ExerciseSetRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseSetRecord(
      id: json['id'] as String,
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      isWarmup: json['isWarmup'] as bool? ?? false,
      rpe: (json['rpe'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      epleyScore: (json['epleyScore'] as num?)?.toDouble(),
    );
  }

  /// Converts ExerciseSetRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'isWarmup': isWarmup,
      'rpe': rpe,
      'notes': notes,
      'epleyScore': epleyScore,
    };
  }

  /// Display string for weight × reps format
  String get displayString {
    final weightStr =
        weight % 1 == 0 ? weight.toInt().toString() : weight.toStringAsFixed(1);
    return '$weightStr lbs × $reps';
  }

  /// Display string for Epley score
  String get epleyDisplayString {
    return 'Est. 1RM: ${epleyScore.toStringAsFixed(1)} lbs';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSetRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExerciseSetRecord{id: $id, set: $setNumber, weight: $weight, reps: $reps, '
        'isWarmup: $isWarmup, epleyScore: ${epleyScore.toStringAsFixed(1)}}';
  }
}
