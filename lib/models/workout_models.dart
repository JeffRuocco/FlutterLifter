import 'package:flutter_lifter/utils/utils.dart';

/// Enum for exercise categories
enum ExerciseCategory {
  strength,
  cardio,
  flexibility,
  balance,
  endurance,
  sports,
  other,
}

extension ExerciseCategoryExtension on ExerciseCategory {
  String get displayName {
    switch (this) {
      case ExerciseCategory.strength:
        return 'Strength';
      case ExerciseCategory.cardio:
        return 'Cardio';
      case ExerciseCategory.flexibility:
        return 'Flexibility';
      case ExerciseCategory.balance:
        return 'Balance';
      case ExerciseCategory.endurance:
        return 'Endurance';
      case ExerciseCategory.sports:
        return 'Sports';
      case ExerciseCategory.other:
        return 'Other';
    }
  }
}

/// Represents a single set within an exercise
class ExerciseSet {
  final String id;
  int? targetReps;
  double? targetWeight;
  int? actualReps;
  double? actualWeight;
  String? notes;
  bool isCompleted;
  DateTime? completedAt;

  ExerciseSet({
    required this.id,
    this.targetReps,
    this.targetWeight,
    this.actualReps,
    this.actualWeight,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
  });

  ExerciseSet.create({
    this.targetReps,
    this.targetWeight,
    this.actualReps,
    this.actualWeight,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
  }) : id = Utils.generateId();

  /// Returns whether this set has target values
  bool get hasTargets => targetReps != null || targetWeight != null;

  /// Returns whether this set has been logged with actual values
  bool get isLogged => actualReps != null || actualWeight != null;

  /// Returns the display text for reps (actual if available, otherwise target)
  String get displayReps {
    if (actualReps != null) {
      return actualReps.toString();
    } else if (targetReps != null) {
      return '(target): ${targetReps.toString()}';
    }
    return '--';
  }

  /// Toggles the completion state of this set
  void toggleCompleted() {
    isCompleted ? markIncomplete() : markCompleted();
  }

  /// Marks this set as completed
  void markCompleted() {
    if (isCompleted) return; // Already completed, do nothing

    isCompleted = true;
    completedAt = DateTime.now();

    // If the set hasn't been logged yet (targets were not changed), use target values as actuals
    actualWeight ??= targetWeight;
    actualReps ??= targetReps;
  }

  /// Marks this set as incomplete
  void markIncomplete() {
    if (isCompleted) {
      isCompleted = false;
      completedAt = null;
    }
  }

  /// Updates the set data (weight, reps, notes) and optionally marks as completed
  void updateSetData({
    double? weight,
    int? reps,
    String? notes,
    bool? markAsCompleted,
  }) {
    if (weight != null) actualWeight = weight;
    if (reps != null) actualReps = reps;
    if (notes != null) this.notes = notes;

    if (markAsCompleted == true && !isCompleted) {
      markCompleted();
    }
  }

  /// Returns the display text for weight (actual if available, otherwise target)
  String get displayWeight {
    if (actualWeight != null) {
      return '${actualWeight!.toStringAsFixed(actualWeight! % 1 == 0 ? 0 : 1)} lbs';
    } else if (targetWeight != null) {
      return '${targetWeight!.toStringAsFixed(targetWeight! % 1 == 0 ? 0 : 1)} lbs';
    }
    return '-- lbs';
  }

  /// Creates a copy of this set with updated values
  ExerciseSet copyWith({
    String? id,
    int? targetReps,
    double? targetWeight,
    int? actualReps,
    double? actualWeight,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
    Duration? restTime,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExerciseSet{id: $id, targetReps: $targetReps, targetWeight: $targetWeight, '
        'actualReps: $actualReps, actualWeight: $actualWeight, isCompleted: $isCompleted}';
  }
}

/// Represents an exercise within a workout
class WorkoutExercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final List<String> targetMuscleGroups;
  final List<ExerciseSet> sets;
  final Duration restTime;
  final String? notes;
  final String? instructions;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.category,
    this.targetMuscleGroups = const [],
    this.sets = const [],
    this.restTime = const Duration(minutes: 3),
    this.notes,
    this.instructions,
    this.imageUrl,
    this.metadata,
  });

  WorkoutExercise.create({
    required this.name,
    required this.category,
    this.targetMuscleGroups = const [],
    this.sets = const [],
    this.restTime = const Duration(minutes: 3),
    this.notes,
    this.instructions,
    this.imageUrl,
    this.metadata,
  }) : id = Utils.generateId();

  /// Returns the number of completed sets
  int get completedSetsCount => sets.where((set) => set.isCompleted).length;

  /// Returns the total number of sets
  int get totalSetsCount => sets.length;

  /// Returns whether all sets are completed
  bool get isCompleted =>
      sets.isNotEmpty && sets.every((set) => set.isCompleted);

  /// Returns the progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (sets.isEmpty) return 0.0;
    return completedSetsCount / totalSetsCount;
  }

  /// Returns the formatted rest time
  String get formattedRestTime {
    final minutes = restTime.inMinutes;
    final seconds = restTime.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Returns the primary muscle groups as a comma-separated string
  String get primaryMuscleGroupsText {
    if (targetMuscleGroups.isEmpty) return 'Various muscles';
    if (targetMuscleGroups.length <= 2) {
      return targetMuscleGroups.join(', ');
    } else {
      return '${targetMuscleGroups.take(2).join(', ')}, +${targetMuscleGroups.length - 2} more';
    }
  }

  /// Add a new set to the exercise, copying parameters from the last set if available.
  void addSet() {
    var lastSet = sets.isNotEmpty ? sets.last : null;
    var newSet = ExerciseSet.create(
      targetWeight: lastSet?.actualWeight ?? lastSet?.targetWeight,
      targetReps: lastSet?.actualReps ?? lastSet?.targetReps,
    );
    sets.add(newSet);
  }

  /// Creates a copy of this exercise with updated values
  WorkoutExercise copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    List<String>? targetMuscleGroups,
    List<ExerciseSet>? sets,
    Duration? restTimeSeconds,
    String? notes,
    String? instructions,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      sets: sets ?? this.sets,
      restTime: restTimeSeconds ?? this.restTime,
      notes: notes ?? this.notes,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExercise &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutExercise{id: $id, name: $name, category: $category, '
        'setsCount: ${sets.length}, completedSets: $completedSetsCount}';
  }
}

/// Represents a complete workout session
class WorkoutSession {
  final String id;
  final String? programId;
  final String? programName;
  final DateTime date;
  final List<WorkoutExercise> exercises;
  DateTime? startTime;
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
}
