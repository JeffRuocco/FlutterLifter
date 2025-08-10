import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/theme_utils.dart';
import 'package:flutter_lifter/utils/utils.dart';
import 'package:hugeicons/hugeicons.dart';

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
}

/// Enum for program difficulty levels
enum ProgramDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

extension ProgramDifficultyExtension on ProgramDifficulty {
  String get displayName {
    switch (this) {
      case ProgramDifficulty.beginner:
        return 'Beginner';
      case ProgramDifficulty.intermediate:
        return 'Intermediate';
      case ProgramDifficulty.advanced:
        return 'Advanced';
      case ProgramDifficulty.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case ProgramDifficulty.beginner:
        return 'New to fitness or this type of training';
      case ProgramDifficulty.intermediate:
        return '6+ months of consistent training experience';
      case ProgramDifficulty.advanced:
        return '2+ years of training experience';
      case ProgramDifficulty.expert:
        return 'Competitive athlete or 5+ years experience';
    }
  }
}

/// Enum for program types/categories
enum ProgramType {
  strength,
  hypertrophy,
  powerlifting,
  bodybuilding,
  cardio,
  hiit,
  flexibility,
  general,
  sport,
  rehabilitation,
}

extension ProgramTypeExtension on ProgramType {
  String get displayName {
    switch (this) {
      case ProgramType.strength:
        return 'Strength Training';
      case ProgramType.hypertrophy:
        return 'Muscle Building';
      case ProgramType.powerlifting:
        return 'Powerlifting';
      case ProgramType.bodybuilding:
        return 'Bodybuilding';
      case ProgramType.cardio:
        return 'Cardiovascular';
      case ProgramType.hiit:
        return 'HIIT';
      case ProgramType.flexibility:
        return 'Flexibility';
      case ProgramType.general:
        return 'General Fitness';
      case ProgramType.sport:
        return 'Sport Specific';
      case ProgramType.rehabilitation:
        return 'Rehabilitation';
    }
  }
}

/// Enum for workout session scheduling periodicity types
enum PeriodicityType {
  weekly, // Specific days of the week (e.g., Monday, Wednesday, Friday)
  cyclic, // Cycle pattern (e.g., 3 days on, 1 day rest)
  interval, // Every X days (e.g., every 2 days)
  custom, // Custom pattern defined by dates
}

extension PeriodicityTypeExtension on PeriodicityType {
  String get displayName {
    switch (this) {
      case PeriodicityType.weekly:
        return 'Weekly Schedule';
      case PeriodicityType.cyclic:
        return 'Cycle Pattern';
      case PeriodicityType.interval:
        return 'Interval Schedule';
      case PeriodicityType.custom:
        return 'Custom Schedule';
    }
  }

  String get description {
    switch (this) {
      case PeriodicityType.weekly:
        return 'Workouts on specific days of the week';
      case PeriodicityType.cyclic:
        return 'Repeating cycle of workout and rest days';
      case PeriodicityType.interval:
        return 'Workouts every X days';
      case PeriodicityType.custom:
        return 'Custom workout schedule';
    }
  }
}

/// Represents the scheduling periodicity for workout sessions in a program
class WorkoutPeriodicity {
  final PeriodicityType type;

  // For weekly scheduling - list of weekdays (1=Monday, 7=Sunday)
  final List<int>? weeklyDays;

  // For cyclic scheduling - number of workout days followed by rest days
  final int? workoutDays;
  final int? restDays;

  // For interval scheduling - workout every X days
  final int? intervalDays;

  // For custom scheduling - specific dates or patterns
  final Map<String, dynamic>? customPattern;

  const WorkoutPeriodicity({
    required this.type,
    this.weeklyDays,
    this.workoutDays,
    this.restDays,
    this.intervalDays,
    this.customPattern,
  });

  /// Creates a weekly periodicity (e.g., Monday, Wednesday, Friday)
  const WorkoutPeriodicity.weekly(List<int> days)
      : type = PeriodicityType.weekly,
        weeklyDays = days,
        workoutDays = null,
        restDays = null,
        intervalDays = null,
        customPattern = null;

  /// Creates a cyclic periodicity (e.g., 3 days on, 1 day rest)
  const WorkoutPeriodicity.cyclic({
    required int this.workoutDays,
    required int this.restDays,
  })  : type = PeriodicityType.cyclic,
        weeklyDays = null,
        intervalDays = null,
        customPattern = null;

  /// Creates an interval periodicity (e.g., every 2 days)
  const WorkoutPeriodicity.interval(int days)
      : type = PeriodicityType.interval,
        weeklyDays = null,
        workoutDays = null,
        restDays = null,
        intervalDays = days,
        customPattern = null;

  /// Creates a custom periodicity with flexible patterns
  const WorkoutPeriodicity.custom(Map<String, dynamic> pattern)
      : type = PeriodicityType.custom,
        weeklyDays = null,
        workoutDays = null,
        restDays = null,
        intervalDays = null,
        customPattern = pattern;

  /// Returns a human-readable description of the periodicity
  String get description {
    switch (type) {
      case PeriodicityType.weekly:
        if (weeklyDays == null || weeklyDays!.isEmpty) return 'No schedule';
        final dayNames = weeklyDays!.map(_getDayName).join(', ');
        return 'Every $dayNames';

      case PeriodicityType.cyclic:
        if (workoutDays == null || restDays == null) return 'Invalid cycle';
        return '$workoutDays days on, $restDays days rest';

      case PeriodicityType.interval:
        if (intervalDays == null) return 'Invalid interval';
        return 'Every $intervalDays days';

      case PeriodicityType.custom:
        return 'Custom schedule';
    }
  }

  /// Returns the frequency per week for display purposes
  String get frequencyDescription {
    switch (type) {
      case PeriodicityType.weekly:
        final count = weeklyDays?.length ?? 0;
        return '$count days/week';

      case PeriodicityType.cyclic:
        if (workoutDays == null || restDays == null) return 'Variable';
        final cycleLength = workoutDays! + restDays!;
        final weeklyFreq = (workoutDays! / cycleLength * 7).round();
        return '~$weeklyFreq days/week';

      case PeriodicityType.interval:
        if (intervalDays == null) return 'Variable';
        final weeklyFreq = (7 / intervalDays!).round();
        return '~$weeklyFreq days/week';

      case PeriodicityType.custom:
        return 'Variable';
    }
  }

  /// Generates workout dates for a given period based on the periodicity
  List<DateTime> generateWorkoutDates(DateTime startDate, DateTime endDate) {
    final workoutDates = <DateTime>[];

    switch (type) {
      case PeriodicityType.weekly:
        _generateWeeklyDates(startDate, endDate, workoutDates);
        break;

      case PeriodicityType.cyclic:
        _generateCyclicDates(startDate, endDate, workoutDates);
        break;

      case PeriodicityType.interval:
        _generateIntervalDates(startDate, endDate, workoutDates);
        break;

      case PeriodicityType.custom:
        _generateCustomDates(startDate, endDate, workoutDates);
        break;
    }

    return workoutDates;
  }

  void _generateWeeklyDates(
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
    if (weeklyDays == null || weeklyDays!.isEmpty) return;

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (weeklyDays!.contains(currentDate.weekday)) {
        workoutDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  void _generateCyclicDates(
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
    if (workoutDays == null || restDays == null) return;

    var currentDate = startDate;
    var dayInCycle = 0;
    final cycleLength = workoutDays! + restDays!;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (dayInCycle < workoutDays!) {
        workoutDates.add(currentDate);
      }

      currentDate = currentDate.add(const Duration(days: 1));
      dayInCycle = (dayInCycle + 1) % cycleLength;
    }
  }

  void _generateIntervalDates(
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
    if (intervalDays == null) return;

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      workoutDates.add(currentDate);
      currentDate = currentDate.add(Duration(days: intervalDays!));
    }
  }

  void _generateCustomDates(
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
    // Custom implementation would depend on the specific pattern stored in customPattern
    // This is a placeholder for future custom scheduling logic
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Creates a copy of this periodicity with updated values
  WorkoutPeriodicity copyWith({
    PeriodicityType? type,
    List<int>? weeklyDays,
    int? workoutDays,
    int? restDays,
    int? intervalDays,
    Map<String, dynamic>? customPattern,
  }) {
    return WorkoutPeriodicity(
      type: type ?? this.type,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      workoutDays: workoutDays ?? this.workoutDays,
      restDays: restDays ?? this.restDays,
      intervalDays: intervalDays ?? this.intervalDays,
      customPattern: customPattern ?? this.customPattern,
    );
  }

  /// Creates WorkoutPeriodicity from JSON
  factory WorkoutPeriodicity.fromJson(Map<String, dynamic> json) {
    final type = PeriodicityType.values.firstWhere(
      (e) => e.toString() == 'PeriodicityType.${json['type']}',
      orElse: () => PeriodicityType.weekly,
    );

    return WorkoutPeriodicity(
      type: type,
      weeklyDays: json['weeklyDays'] != null
          ? List<int>.from(json['weeklyDays'])
          : null,
      workoutDays: json['workoutDays'],
      restDays: json['restDays'],
      intervalDays: json['intervalDays'],
      customPattern: json['customPattern'],
    );
  }

  /// Converts WorkoutPeriodicity to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'weeklyDays': weeklyDays,
      'workoutDays': workoutDays,
      'restDays': restDays,
      'intervalDays': intervalDays,
      'customPattern': customPattern,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutPeriodicity &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          _listEquals(weeklyDays, other.weeklyDays) &&
          workoutDays == other.workoutDays &&
          restDays == other.restDays &&
          intervalDays == other.intervalDays;

  @override
  int get hashCode => Object.hash(
        type,
        weeklyDays,
        workoutDays,
        restDays,
        intervalDays,
        customPattern,
      );

  @override
  String toString() {
    return 'WorkoutPeriodicity{type: $type, description: $description}';
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Represents a fitness program with scheduled workout sessions
class Program {
  final String id;
  final String name;
  final String? description;
  final ProgramType type;
  final ProgramDifficulty difficulty;
  final WorkoutPeriodicity? periodicity;
  List<WorkoutSession> scheduledSessions;
  final DateTime createdAt;
  DateTime? startDate;
  DateTime? endDate;
  final String? createdBy;
  final bool isActive;
  final bool isPublic;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  Program({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.difficulty,
    this.periodicity,
    this.scheduledSessions = const [],
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.createdBy,
    this.isActive = true,
    this.isPublic = false,
    this.tags = const [],
    this.imageUrl,
    this.metadata,
  });

  /// Named constructor for creating new programs with auto-generated ID
  Program.create({
    required this.name,
    this.description,
    required this.type,
    required this.difficulty,
    required this.periodicity,
    this.scheduledSessions = const [],
    this.startDate,
    this.endDate,
    this.createdBy,
    this.isActive = true,
    this.isPublic = false,
    this.tags = const [],
    this.imageUrl,
    this.metadata,
  })  : id = Utils.generateId(),
        createdAt = DateTime.now();

  /// Returns the duration of the program in days
  int? get durationInDays {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!).inDays + 1;
  }

  /// Returns the duration of the program in weeks
  int? get durationInWeeks {
    final days = durationInDays;
    if (days == null) return null;
    return (days / 7).ceil();
  }

  /// Returns whether the program is currently running
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Returns the total number of scheduled workouts
  int get totalWorkoutsCount => scheduledSessions.length;

  /// Returns the number of completed workouts
  int get completedWorkoutsCount =>
      scheduledSessions.where((session) => session.isCompleted).length;

  /// Returns the program completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (scheduledSessions.isEmpty) return 0.0;
    return completedWorkoutsCount / totalWorkoutsCount;
  }

  /// Returns the next scheduled workout session
  WorkoutSession? get nextWorkout {
    final now = DateTime.now();
    return scheduledSessions
        .where((session) => !session.isCompleted && session.date.isAfter(now))
        .fold<WorkoutSession?>(null, (next, session) {
      if (next == null || session.date.isBefore(next.date)) {
        return session;
      }
      return next;
    });
  }

  /// Returns the most recent completed workout
  WorkoutSession? get lastCompletedWorkout {
    return scheduledSessions
        .where((session) => session.isCompleted)
        .fold<WorkoutSession?>(null, (latest, session) {
      if (latest == null || session.date.isAfter(latest.date)) {
        return session;
      }
      return latest;
    });
  }

  /// Returns workouts scheduled for a specific week
  List<WorkoutSession> getWorkoutsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return scheduledSessions
        .where((session) =>
            session.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            session.date.isBefore(weekEnd))
        .toList();
  }

  /// Returns workouts scheduled for a specific date
  List<WorkoutSession> getWorkoutsForDate(DateTime date) {
    return scheduledSessions
        .where((session) =>
            session.date.year == date.year &&
            session.date.month == date.month &&
            session.date.day == date.day)
        .toList();
  }

  /// Adds a new workout session to the program
  Program addWorkoutSession(WorkoutSession session) {
    return copyWith(
      scheduledSessions: [...scheduledSessions, session],
    );
  }

  /// Removes a workout session from the program
  Program removeWorkoutSession(String sessionId) {
    return copyWith(
      scheduledSessions: scheduledSessions
          .where((session) => session.id != sessionId)
          .toList(),
    );
  }

  /// Updates a workout session in the program
  Program updateWorkoutSession(WorkoutSession updatedSession) {
    final updatedSessions = scheduledSessions
        .map((session) =>
            session.id == updatedSession.id ? updatedSession : session)
        .toList();
    return copyWith(scheduledSessions: updatedSessions);
  }

  /// Generates and schedules workout sessions based on the program's periodicity
  Program generateScheduledSessions({
    DateTime? programStartDate,
    DateTime? programEndDate,
    bool replaceExisting = false,
  }) {
    final start = programStartDate ?? startDate ?? DateTime.now();
    final end = programEndDate ??
        endDate ??
        start.add(const Duration(days: 84)); // Default 12 weeks

    List<WorkoutSession> newSessions = [];
    if (!replaceExisting) {
      newSessions = List.from(scheduledSessions);
    }

    // Generate workout dates based on periodicity
    final workoutDates = periodicity!.generateWorkoutDates(start, end);

    // Create workout sessions for each date
    for (final date in workoutDates) {
      // Skip if session already exists for this date (when not replacing)
      if (!replaceExisting &&
          scheduledSessions.any((session) =>
              session.date.year == date.year &&
              session.date.month == date.month &&
              session.date.day == date.day)) {
        continue;
      }

      final session = WorkoutSession.create(
        programId: id,
        programName: name,
        date: date,
      );
      newSessions.add(session);
    }

    return copyWith(
      scheduledSessions: newSessions,
      startDate: programStartDate ?? startDate,
      endDate: programEndDate ?? endDate,
    );
  }

  /// Returns the expected frequency description from periodicity
  String get frequencyDescription {
    return periodicity?.frequencyDescription ?? 'No schedule';
  }

  /// Returns the periodicity description
  String get periodicityDescription {
    return periodicity?.description ?? 'No periodicity defined';
  }

  /// Returns whether this program has a defined periodicity
  bool get hasSchedulingPeriodicity => periodicity != null;

  /// Returns the next expected workout date based on periodicity
  DateTime? getNextExpectedWorkoutDate({DateTime? fromDate}) {
    if (periodicity == null) return null;

    final from = fromDate ?? DateTime.now();
    final futureEnd = from.add(const Duration(days: 365)); // Look ahead 1 year

    final futureDates = periodicity!.generateWorkoutDates(from, futureEnd);
    return futureDates.isNotEmpty ? futureDates.first : null;
  }

  /// Checks if a workout is expected on a specific date based on periodicity
  bool isWorkoutExpectedOnDate(DateTime date) {
    if (periodicity == null) return false;

    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    final workoutDates = periodicity!.generateWorkoutDates(dateStart, dateEnd);
    return workoutDates.isNotEmpty;
  }

  /// Returns the program color, falling back to the app's primary color
  Color getColor(BuildContext context) {
    if (metadata != null && metadata!.containsKey('color')) {
      return metadata!['color'] as Color;
    }
    // Return theme-aware primary color using your theme extension
    return context.primaryColor;
  }

  /// Returns the program icon, falling back to a default icon
  IconData get icon {
    if (metadata != null && metadata!.containsKey('icon')) {
      return metadata!['icon'] as IconData;
    }
    // Return a default icon
    return HugeIcons.strokeRoundedDumbbell01;
  }

  /// Creates a copy of this program with updated values
  Program copyWith({
    String? id,
    String? name,
    String? description,
    ProgramType? type,
    ProgramDifficulty? difficulty,
    WorkoutPeriodicity? periodicity,
    List<WorkoutSession>? scheduledSessions,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    bool? isActive,
    bool? isPublic,
    List<String>? tags,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      periodicity: periodicity ?? this.periodicity,
      scheduledSessions: scheduledSessions ?? this.scheduledSessions,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a Program from JSON
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: ProgramType.values.firstWhere(
        (e) => e.toString() == 'ProgramType.${json['type']}',
        orElse: () => ProgramType.general,
      ),
      difficulty: ProgramDifficulty.values.firstWhere(
        (e) => e.toString() == 'ProgramDifficulty.${json['difficulty']}',
        orElse: () => ProgramDifficulty.beginner,
      ),
      periodicity: json['periodicity'] != null
          ? WorkoutPeriodicity.fromJson(json['periodicity'])
          : null,
      scheduledSessions: json['scheduledSessions'] != null
          ? (json['scheduledSessions'] as List)
              .map((sessionJson) => WorkoutSession.fromJson(sessionJson))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      createdBy: json['createdBy'],
      isActive: json['isActive'] ?? true,
      isPublic: json['isPublic'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
      metadata: json['metadata'],
    );
  }

  /// Converts Program to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'periodicity': periodicity?.toJson(),
      'scheduledSessions':
          scheduledSessions.map((session) => session.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
      'isPublic': isPublic,
      'tags': tags,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Program && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Program{id: $id, name: $name, type: $type, '
        'difficulty: $difficulty, periodicity: ${periodicity?.description}, '
        'workoutsCount: ${scheduledSessions.length}, isActive: $isActive}';
  }
}
