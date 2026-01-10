import 'package:flutter/material.dart';
import 'package:flutter_lifter/models/models.dart';
import 'package:hugeicons/hugeicons.dart';

import 'default_exercises.dart';

/// Mock data for testing and development purposes.
/// Contains programs with active cycles and workout sessions populated.
///
/// For production defaults without mock data, use:
/// - [DefaultExercises] for exercise templates
/// - [DefaultPrograms] for program templates
class MockPrograms {
  /// Retrieves a mock program by its ID.
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

  /// Retrieves a mock program by name.
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

  /// Mock programs with active cycles and workout sessions for testing
  static List<Program> programs = [
    // Upper/Lower with active cycle and mock sessions
    Program(
      id: 'upper_lower',
      name: 'Upper/Lower',
      description:
          'Train upper body and lower body on alternating days. Perfect for intermediate lifters.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        2,
        4,
        5,
      ]), // Mon, Tue, Thu, Fri - 4 days/week
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime.now(),
      isDefault: true,
      lastUsedAt: DateTime.now().subtract(const Duration(days: 2)),
      metadata: {
        'color': Colors.blue,
        'icon': HugeIcons.strokeRoundedDumbbell01,
      },
      cycles: [
        ProgramCycle(
          cycleNumber: 1,
          id: 'cycle_1',
          programId: 'upper_lower',
          isActive: true,
          isCompleted: false,
          periodicity: WorkoutPeriodicity.weekly([1, 2, 4, 5]),
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          createdAt: DateTime.now().subtract(const Duration(days: 31)),
          scheduledSessions: [
            WorkoutSession(
              id: 'session_1',
              date: DateTime.now(),
              exercises: [
                WorkoutExercise.create(
                  exercise: DefaultExercises.getExerciseById('bench')!,
                  sets: [
                    ExerciseSet.create(targetReps: 5, targetWeight: 195),
                    ExerciseSet.create(targetReps: 5, targetWeight: 185),
                  ],
                ),
                WorkoutExercise.create(
                  exercise: DefaultExercises.getExerciseById('ohp')!,
                  sets: [
                    ExerciseSet.create(targetReps: 5, targetWeight: 150),
                    ExerciseSet.create(targetReps: 5, targetWeight: 140),
                  ],
                ),
                WorkoutExercise.create(
                  exercise: DefaultExercises.getExerciseById('row')!,
                  sets: [
                    ExerciseSet.create(targetReps: 5, targetWeight: 215),
                    ExerciseSet.create(targetReps: 5, targetWeight: 205),
                  ],
                ),
              ],
              programId: 'upper_lower',
              programName: 'Upper/Lower',
            ),
          ],
        ),
      ],
    ),

    // Full Body - clean template (no active cycle for testing variety)
    Program(
      id: 'full_body',
      name: 'Full Body',
      description:
          'Train all major muscle groups in a single session. Ideal for beginners and those with limited time.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        3,
        5,
      ]), // Mon, Wed, Fri - 3 days/week
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime.now(),
      isDefault: true,
      metadata: {
        'color': Colors.green,
        'icon': HugeIcons.strokeRoundedBodyPartMuscle,
      },
    ),

    // Push/Pull/Legs - clean template
    Program(
      id: 'push_pull_legs',
      name: 'Push/Pull/Legs',
      description:
          'Split training by movement patterns: push, pull, and legs. Great for advanced lifters.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.advanced,
      defaultPeriodicity: const WorkoutPeriodicity.cyclic(
        workoutDays: 3,
        restDays: 1,
      ), // 3 days on, 1 day rest
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime.now(),
      isDefault: true,
      metadata: {'color': Colors.orange, 'icon': HugeIcons.strokeRoundedFire},
    ),
  ];
}

/// Helper class for creating mock workout data for testing
class MockWorkoutData {
  /// Creates a mock workout session with sample exercises and sets
  static WorkoutSession createMockSession({
    String? id,
    String? programId,
    String? programName,
    DateTime? date,
    List<String>? exerciseIds,
  }) {
    final exercises = (exerciseIds ?? ['bench', 'squat', 'row'])
        .map((id) => DefaultExercises.getExerciseById(id))
        .whereType<Exercise>()
        .map(
          (exercise) => WorkoutExercise.create(
            exercise: exercise,
            sets: List.generate(
              exercise.defaultSets,
              (index) => ExerciseSet.create(
                targetReps: exercise.defaultReps,
                targetWeight: exercise.defaultWeight ?? 100,
              ),
            ),
          ),
        )
        .toList();

    return WorkoutSession(
      id: id ?? 'mock_session_${DateTime.now().millisecondsSinceEpoch}',
      date: date ?? DateTime.now(),
      exercises: exercises,
      programId: programId,
      programName: programName,
    );
  }

  /// Creates a mock program cycle with scheduled sessions
  static ProgramCycle createMockCycle({
    required String programId,
    int cycleNumber = 1,
    bool isActive = true,
    bool isCompleted = false,
    int numberOfSessions = 4,
    WorkoutPeriodicity? periodicity,
  }) {
    final startDate = DateTime.now().subtract(const Duration(days: 7));
    final sessions = List.generate(
      numberOfSessions,
      (index) => createMockSession(
        id: 'mock_session_${cycleNumber}_$index',
        programId: programId,
        date: startDate.add(Duration(days: index * 2)),
      ),
    );

    return ProgramCycle(
      id: 'mock_cycle_$cycleNumber',
      cycleNumber: cycleNumber,
      programId: programId,
      isActive: isActive,
      isCompleted: isCompleted,
      periodicity: periodicity ?? const WorkoutPeriodicity.weekly([1, 3, 5]),
      startDate: startDate,
      createdAt: startDate.subtract(const Duration(days: 1)),
      scheduledSessions: sessions,
    );
  }
}
