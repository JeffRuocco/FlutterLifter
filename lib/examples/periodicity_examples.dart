// ignore_for_file: avoid_print

import 'package:flutter_lifter/models/workout_models.dart';

/// Examples demonstrating how to use the WorkoutPeriodicity system
class PeriodicityExamples {
  /// Example 1: Weekly schedule - Monday, Wednesday, Friday
  static Program createWeeklyProgram() {
    return Program.create(
      name: 'Monday/Wednesday/Friday Routine',
      description: 'Classic 3-day weekly split',
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.intermediate,
      periodicity: const WorkoutPeriodicity.weekly([1, 3, 5]), // Mon, Wed, Fri
    );
  }

  /// Example 2: Cyclic schedule - 3 days on, 1 day rest
  static Program createCyclicProgram() {
    return Program.create(
      name: 'High Frequency Training',
      description: '3 days training, 1 day rest cycle',
      type: ProgramType.hypertrophy,
      difficulty: ProgramDifficulty.advanced,
      periodicity: const WorkoutPeriodicity.cyclic(workoutDays: 3, restDays: 1),
    );
  }

  /// Example 3: Interval schedule - Every other day
  static Program createIntervalProgram() {
    return Program.create(
      name: 'Every Other Day Training',
      description: 'Workout every 2 days for optimal recovery',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      periodicity: const WorkoutPeriodicity.interval(2),
    );
  }

  /// Example 4: Generate workout sessions for a program
  static void demonstrateScheduleGeneration() {
    final program = createWeeklyProgram();
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 28)); // 4 weeks

    // Generate scheduled sessions
    final programWithSessions = program.generateScheduledSessions(
      programStartDate: startDate,
      programEndDate: endDate,
    );

    print(
        'Generated ${programWithSessions.scheduledSessions.length} workout sessions');
    print('Program frequency: ${program.frequencyDescription}');
    print('Periodicity: ${program.periodicityDescription}');

    // Print first few sessions
    for (int i = 0;
        i < programWithSessions.scheduledSessions.length && i < 5;
        i++) {
      final session = programWithSessions.scheduledSessions[i];
      print(
          'Session ${i + 1}: ${session.date.toLocal().toString().split(' ')[0]}');
    }
  }

  /// Example 5: Check if workout is expected on specific dates
  static void demonstrateWorkoutChecking() {
    final program = createCyclicProgram();

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    print(
        'Is workout expected today? ${program.isWorkoutExpectedOnDate(today)}');
    print(
        'Is workout expected tomorrow? ${program.isWorkoutExpectedOnDate(tomorrow)}');
    print(
        'Is workout expected day after? ${program.isWorkoutExpectedOnDate(dayAfter)}');
  }

  /// Example 6: Custom schedule using metadata
  static Program createCustomProgram() {
    return Program.create(
      name: 'Competition Prep',
      description: 'Custom schedule based on competition timeline',
      type: ProgramType.powerlifting,
      difficulty: ProgramDifficulty.expert,
      periodicity: const WorkoutPeriodicity.custom({
        'type': 'competition_prep',
        'phases': ['base', 'intensity', 'peak', 'deload'],
        'schedule': 'variable'
      }),
    );
  }
}
