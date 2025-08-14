// ignore_for_file: avoid_print

import 'package:flutter_lifter/models/models.dart';

/// Examples demonstrating how to use the WorkoutPeriodicity system
class PeriodicityExamples {
  /// Example 1: Weekly schedule - Monday, Wednesday, Friday
  static Program createWeeklyProgram() {
    return Program.create(
      name: 'Monday/Wednesday/Friday Routine',
      description: 'Classic 3-day weekly split',
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity:
          const WorkoutPeriodicity.weekly([1, 3, 5]), // Mon, Wed, Fri
    );
  }

  /// Example 2: Cyclic schedule - 3 days on, 1 day rest
  static Program createCyclicProgram() {
    return Program.create(
      name: 'High Frequency Training',
      description: '3 days training, 1 day rest cycle',
      type: ProgramType.hypertrophy,
      difficulty: ProgramDifficulty.advanced,
      defaultPeriodicity:
          const WorkoutPeriodicity.cyclic(workoutDays: 3, restDays: 1),
    );
  }

  /// Example 3: Interval schedule - Every other day
  static Program createIntervalProgram() {
    return Program.create(
      name: 'Every Other Day Training',
      description: 'Workout every 2 days for optimal recovery',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.interval(2),
    );
  }

  /// Example 4: Generate workout sessions for a program cycle
  static void demonstrateScheduleGeneration() {
    final program = createWeeklyProgram();
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 28)); // 4 weeks

    // Create a program cycle (execution instance)
    final programWithCycle = program.createNewCycle(
      startDate: startDate,
      endDate: endDate,
      notes: "4-week training cycle",
    );

    // Generate scheduled sessions for the cycle
    final cycle = programWithCycle.activeCycle!;
    final cycleWithSessions = cycle.generateScheduledSessions();

    print(
        'Generated ${cycleWithSessions.scheduledSessions.length} workout sessions');
    print('Program frequency: ${program.frequencyDescription}');
    print('Periodicity: ${program.periodicityDescription}');

    // Print first few sessions
    for (int i = 0;
        i < cycleWithSessions.scheduledSessions.length && i < 5;
        i++) {
      final session = cycleWithSessions.scheduledSessions[i];
      print(
          'Session ${i + 1}: ${session.date.toLocal().toString().split(' ')[0]}');
    }
  }

  /// Example 5: Check if workout is expected on specific dates
  static void demonstrateWorkoutChecking() {
    final program = createCyclicProgram();

    // Create a cycle to provide execution context for workout checking
    final programWithCycle = program.createNewCycle(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 14)),
      notes: "Test cycle for workout checking",
    );

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    print('Checking workout expectations for ${programWithCycle.name}:');
    print('Periodicity: ${programWithCycle.periodicityDescription}');
    print(
        'Is workout expected today? ${programWithCycle.isWorkoutExpectedOnDate(today)}');
    print(
        'Is workout expected tomorrow? ${programWithCycle.isWorkoutExpectedOnDate(tomorrow)}');
    print(
        'Is workout expected day after? ${programWithCycle.isWorkoutExpectedOnDate(dayAfter)}');
  }

  /// Example 6: Custom schedule using metadata
  static Program createCustomProgram() {
    return Program.create(
      name: 'Competition Prep',
      description: 'Custom schedule based on competition timeline',
      type: ProgramType.powerlifting,
      difficulty: ProgramDifficulty.expert,
      defaultPeriodicity: const WorkoutPeriodicity.custom({
        'type': 'competition_prep',
        'phases': ['base', 'intensity', 'peak', 'deload'],
        'schedule': 'variable'
      }),
    );
  }

  /// Example 7: Complete workflow - Template to Execution
  static void demonstrateCompleteWorkflow() {
    print('=== Complete Periodicity Workflow ===\n');

    // 1. Create a program template
    final programTemplate = createWeeklyProgram();
    print('Created program template: ${programTemplate.name}');
    print('Template periodicity: ${programTemplate.periodicityDescription}');
    print('Template has cycles: ${programTemplate.allCycles.length}\n');

    // 2. Create an execution cycle
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 21)); // 3 weeks

    final programWithCycle = programTemplate.createNewCycle(
      startDate: startDate,
      endDate: endDate,
      notes: "3-week strength building cycle",
    );

    print(
        'Created execution cycle: ${programWithCycle.activeCycle?.cycleNumber}');
    print(
        'Cycle duration: ${programWithCycle.activeCycle?.durationInWeeks} weeks\n');

    // 3. Generate sessions for the cycle
    final activeCycle = programWithCycle.activeCycle!;
    final cycleWithSessions = activeCycle.generateScheduledSessions();

    print(
        'Generated ${cycleWithSessions.scheduledSessions.length} workout sessions');
    print('Sessions for cycle ${cycleWithSessions.cycleNumber}:');

    for (int i = 0; i < cycleWithSessions.scheduledSessions.length; i++) {
      final session = cycleWithSessions.scheduledSessions[i];
      final dayName = _getDayName(session.date.weekday);
      print(
          '  Session ${i + 1}: $dayName, ${session.date.toLocal().toString().split(' ')[0]}');
    }

    // 4. Show template is still reusable
    print('\nTemplate remains unchanged and reusable:');
    print('- Template cycles: ${programTemplate.allCycles.length}');
    print(
        '- Template can create new cycles: ${programTemplate.nextCycleNumber}');
  }

  /// Helper method to get day name
  static String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Run all periodicity examples
  static void runAllExamples() {
    print('Running all Periodicity examples...\n');

    demonstrateScheduleGeneration();
    print('\n${'=' * 50}\n');

    demonstrateWorkoutChecking();
    print('\n${'=' * 50}\n');

    demonstrateCompleteWorkflow();

    print('\nAll periodicity examples completed!');
  }
}
