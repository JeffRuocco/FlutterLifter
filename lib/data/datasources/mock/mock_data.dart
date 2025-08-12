import 'package:flutter/material.dart';
import 'package:flutter_lifter/models/workout_models.dart';
import 'package:hugeicons/hugeicons.dart';

class MockPrograms {
  /// Retrieves a program by its ID.
  /// Returns null if the program is not found.
  static Program? getProgramById(String id) {
    try {
      return programs.firstWhere(
        (program) => program.id.toLowerCase() == id.toLowerCase(),
        orElse: () => throw Exception('Program not found: $id'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Retrieves a program by name.
  /// Returns null if the program is not found.
  static Program? getProgramByName(String name) {
    try {
      return programs.firstWhere(
        (program) => program.name.toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Program not found: $name'),
      );
    } catch (e) {
      return null;
    }
  }

  static List<Program> programs = [
    Program(
      id: 'upper_lower',
      name: 'Upper/Lower',
      description:
          'Train upper body and lower body on alternating days. Perfect for intermediate lifters.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly(
          [1, 2, 4, 5]), // Mon, Tue, Thu, Fri - 4 days/week
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime.now(),
      metadata: {
        'color': Colors.blue,
        'icon': HugeIcons.strokeRoundedDumbbell01,
      },
    ),
    Program(
      id: 'full_body',
      name: 'Full Body',
      description:
          'Train all major muscle groups in a single session. Ideal for beginners and those with limited time.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.weekly(
          [1, 3, 5]), // Mon, Wed, Fri - 3 days/week
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime.now(),
      metadata: {
        'color': Colors.green,
        'icon': HugeIcons.strokeRoundedBodyPartMuscle,
      },
    ),
    Program(
      id: 'push_pull_legs',
      name: 'Push/Pull/Legs',
      description:
          'Split training by movement patterns: push, pull, and legs. Great for advanced lifters.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.advanced,
      defaultPeriodicity: const WorkoutPeriodicity.cyclic(
          workoutDays: 3, restDays: 1), // 3 days on, 1 day rest
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime.now(),
      metadata: {
        'color': Colors.orange,
        'icon': HugeIcons.strokeRoundedFire,
      },
    ),
  ];
}

class MockExercises {
  /// Retrieves an exercise by its name.
  /// Returns null if the exercise is not found.
  static Exercise? getExerciseByName(String name) {
    try {
      return exercises.firstWhere(
        (exercise) => exercise.name.toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Exercise not found: $name'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Retrieves an exercise by its ID.
  /// Returns null if the exercise is not found.
  static Exercise? getExerciseById(String id) {
    try {
      return exercises.firstWhere(
        (exercise) => exercise.id.toLowerCase() == id.toLowerCase(),
        orElse: () => throw Exception('Exercise not found: $id'),
      );
    } catch (e) {
      return null;
    }
  }

  /// List of predefined exercises
  static List<Exercise> exercises = [
    Exercise(
      id: 'squat',
      name: 'Barbell Back Squat',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Quadriceps', 'Glutes', 'Hamstrings'],
      defaultSets: 4,
      defaultReps: 8,
      defaultRestTimeSeconds: 180,
    ),
    Exercise(
      id: 'bench',
      name: 'Bench Press',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Chest', 'Triceps', 'Shoulders'],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 120,
    ),
    Exercise(
      id: 'deadlift',
      name: 'Deadlift',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Hamstrings', 'Glutes', 'Back'],
      defaultSets: 3,
      defaultReps: 5,
      defaultRestTimeSeconds: 180,
    ),
    Exercise(
      id: 'ohp',
      name: 'Overhead Press',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Shoulders', 'Triceps', 'Core'],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 120,
    ),
    Exercise(
      id: 'row',
      name: 'Bent-Over Barbell Row',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Lats', 'Rhomboids', 'Rear Delts'],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 90,
    ),
    Exercise(
      id: 'pullup',
      name: 'Pull-ups',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Lats', 'Biceps', 'Rhomboids'],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 90,
    ),
    Exercise(
      id: 'dips',
      name: 'Dips',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Triceps', 'Chest', 'Shoulders'],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 90,
    ),
    Exercise(
      id: 'lunges',
      name: 'Lunges',
      category: ExerciseCategory.strength,
      targetMuscleGroups: ['Quadriceps', 'Glutes', 'Hamstrings'],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
    ),
    Exercise(
      id: 'plank',
      name: 'Plank',
      category: ExerciseCategory.flexibility,
      targetMuscleGroups: ['Core', 'Shoulders'],
      defaultSets: 3,
      defaultReps: 30,
      defaultRestTimeSeconds: 60,
    ),
    Exercise(
      id: 'running',
      name: 'Running',
      category: ExerciseCategory.cardio,
      targetMuscleGroups: ['Legs', 'Cardiovascular'],
      defaultSets: 1,
      defaultReps: 30,
      defaultRestTimeSeconds: 0,
    ),
  ];
}
