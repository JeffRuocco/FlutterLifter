import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/utils/utils.dart';

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

  /// Creates ExerciseSet from JSON
  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      id: json['id'],
      targetReps: json['targetReps'],
      targetWeight: json['targetWeight']?.toDouble(),
      actualReps: json['actualReps'],
      actualWeight: json['actualWeight']?.toDouble(),
      notes: json['notes'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  /// Converts ExerciseSet to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'actualReps': actualReps,
      'actualWeight': actualWeight,
      'notes': notes,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
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

/// Represents a defined exercise that can be added to a [WorkoutSession].
class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final List<String> targetMuscleGroups;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeight;
  final int defaultRestTimeSeconds;
  final String? notes;
  final String? instructions;
  final String? imageUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.targetMuscleGroups,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultWeight,
    this.defaultRestTimeSeconds = (60 * 3),
    this.notes,
    this.instructions,
    this.imageUrl,
  });

  /// Creates Exercise from JSON
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      category: ExerciseCategory.values.firstWhere(
        (e) => e.toString() == 'ExerciseCategory.${json['category']}',
        orElse: () => ExerciseCategory.other,
      ),
      targetMuscleGroups: List<String>.from(json['targetMuscleGroups'] ?? []),
      defaultSets: json['defaultSets'] ?? 3,
      defaultReps: json['defaultReps'] ?? 10,
      defaultWeight: json['defaultWeight']?.toDouble(),
      defaultRestTimeSeconds: json['defaultRestTimeSeconds'] ?? 180,
      notes: json['notes'],
      instructions: json['instructions'],
      imageUrl: json['imageUrl'],
    );
  }

  /// Converts Exercise to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.toString().split('.').last,
      'targetMuscleGroups': targetMuscleGroups,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultWeight': defaultWeight,
      'defaultRestTimeSeconds': defaultRestTimeSeconds,
      'notes': notes,
      'instructions': instructions,
      'imageUrl': imageUrl,
    };
  }
}

/// Represents an instance of an [Exercise] within a workout.
class WorkoutExercise {
  final String id;

  /// Base [Exercise]
  final Exercise exercise;
  final List<ExerciseSet> sets;
  final Duration restTime;
  final String? notes;

  WorkoutExercise({
    required this.id,
    required this.exercise,
    this.sets = const [],
    this.restTime = const Duration(minutes: 3),
    this.notes,
  });

  WorkoutExercise.create({
    required this.exercise,
    this.sets = const [],
    this.restTime = const Duration(minutes: 3),
    this.notes,
  }) : id = Utils.generateId();

  /// Returns the name of the exercise
  String get name => exercise.name;

  /// Returns the category of the exercise
  ExerciseCategory get category => exercise.category;

  /// Returns the instructions for the exercise
  String? get instructions => exercise.instructions;

  /// Returns the target muscle groups for the exercise
  List<String> get targetMuscleGroups => exercise.targetMuscleGroups;

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
    final targetMuscleGroups = exercise.targetMuscleGroups;
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
    Exercise? exercise,
    List<ExerciseSet>? sets,
    Duration? restTime,
    String? notes,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
    );
  }

  /// Creates WorkoutExercise from JSON
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'],
      exercise: Exercise.fromJson(json['exercise']),
      sets: json['sets'] != null
          ? (json['sets'] as List)
              .map((setJson) => ExerciseSet.fromJson(setJson))
              .toList()
          : [],
      restTime: Duration(seconds: json['restTimeSeconds'] ?? 180),
      notes: json['notes'],
    );
  }

  /// Converts WorkoutExercise to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise': exercise.toJson(),
      'sets': sets.map((set) => set.toJson()).toList(),
      'restTimeSeconds': restTime.inSeconds,
      'notes': notes,
    };
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
    return 'WorkoutExercise{id: $id, name: $exercise.name, category: $exercise.category, '
        'setsCount: ${sets.length}, completedSets: $completedSetsCount}';
  }
}
