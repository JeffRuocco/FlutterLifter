import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/app_colors.dart';
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

// TODO: support session scheduling periodicity

/// Represents a fitness program with scheduled workout sessions
class Program {
  final String id;
  final String name;
  final String? description;
  final ProgramType type;
  final ProgramDifficulty difficulty;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Program && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Program{id: $id, name: $name, type: $type, '
        'difficulty: $difficulty, workoutsCount: ${scheduledSessions.length}, '
        'isActive: $isActive}';
  }
}
