import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/utils/utils.dart';

/// Represents a complete workout session
class WorkoutSession {
  final String id;
  final String? programId;
  final String? programName; // TODO: is this needed?
  /// Date of the session.
  final DateTime date;
  final List<WorkoutExercise> exercises;

  /// Time session was started.
  DateTime? startTime;

  /// Time session was ended.
  DateTime? endTime;
  String? notes;
  Map<String, dynamic>? metadata;

  WorkoutSession({
    required this.id,
    this.programId,
    this.programName,
    required this.date,
    this.exercises = const [],
    this.startTime,
    this.endTime,
    this.notes,
    this.metadata,
  });

  WorkoutSession.create({
    this.programId,
    this.programName,
    required this.date,
    this.exercises = const [],
    this.startTime,
    this.endTime,
    this.notes,
    this.metadata,
  }) : id = Utils.generateId();

  /// Returns the duration of the workout
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Returns whether the workout is in progress
  bool get isInProgress => startTime != null && endTime == null;

  /// Returns whether the workout is completed
  bool get isCompleted => startTime != null && endTime != null;

  /// Returns the total number of exercises
  int get totalExercisesCount => exercises.length;

  /// Returns the number of completed exercises
  int get completedExercisesCount =>
      exercises.where((ex) => ex.isCompleted).length;

  /// Returns the workout progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (exercises.isEmpty) return 0.0;
    return completedExercisesCount / totalExercisesCount;
  }

  /// Returns the total number of sets across all exercises
  int get totalSetsCount =>
      exercises.fold(0, (sum, ex) => sum + ex.totalSetsCount);

  /// Returns the total number of completed sets across all exercises
  int get completedSetsCount =>
      exercises.fold(0, (sum, ex) => sum + ex.completedSetsCount);

  /// Returns whether the workout has uncompleted exercises
  bool get hasUncompletedExercises => exercises.any((ex) => !ex.isCompleted);

  void start() {
    startTime ??= DateTime.now();
  }

  /// Creates a copy of this workout session with updated values
  WorkoutSession copyWith({
    String? id,
    String? programId,
    String? programName,
    DateTime? date,
    List<WorkoutExercise>? exercises,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates WorkoutSession from JSON
  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      programId: json['programId'],
      programName: json['programName'],
      date: DateTime.parse(json['date']),
      exercises: json['exercises'] != null
          ? (json['exercises'] as List)
              .map((exerciseJson) => WorkoutExercise.fromJson(exerciseJson))
              .toList()
          : [],
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      notes: json['notes'],
      metadata: json['metadata'],
    );
  }

  /// Converts WorkoutSession to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programId': programId,
      'programName': programName,
      'date': date.toIso8601String(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutSession{id: $id, programName: $programName, date: $date, '
        'exercisesCount: ${exercises.length}, isCompleted: $isCompleted}';
  }

  /// Generate a simple hash of the workout data to detect changes
  String get hash {
    final buffer = StringBuffer();

    // Include basic workout info
    buffer.write(id);
    buffer.write(programId ?? '');
    buffer.write(programName ?? '');
    buffer.write(date.millisecondsSinceEpoch);
    buffer.write(startTime?.millisecondsSinceEpoch ?? 0);
    buffer.write(endTime?.millisecondsSinceEpoch ?? 0);
    buffer.write(notes ?? '');
    buffer.write(metadata?.toString() ?? '');
    buffer.write(exercises.length);

    // Include exercise data using their hash getters
    for (final exercise in exercises) {
      buffer.write(exercise.hash);
    }

    // Return a simple hash code
    return buffer.toString().hashCode.toString();
  }
}
