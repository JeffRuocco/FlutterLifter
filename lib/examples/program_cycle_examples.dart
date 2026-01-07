// ignore_for_file: avoid_print

import 'package:flutter_lifter/models/models.dart';

/// Examples demonstrating how to use ProgramCycle with Program
class ProgramCycleExamples {
  /// Run all examples
  static void runAllExamples() {
    print("Running all ProgramCycle examples...\n");

    exampleProgramWithMultipleCycles();
    print("\n${"=" * 50}\n");

    exampleWorkingWithCycles();
    print("\n${"=" * 50}\n");

    exampleQueryingCycles();
    print("\n${"=" * 50}\n");

    exampleTemplateVsExecution();
    print("\n${"=" * 50}\n");

    exampleDateBasedActivation();
    print("\n${"=" * 50}\n");

    exampleOverlapValidation();
    print("\n${"=" * 50}\n");

    exampleSingleActiveCycleConstraint();
    print("\nAll examples completed!");
  }

  /// Example: Creating a program template and running multiple cycles
  static void exampleProgramWithMultipleCycles() {
    // Create a program template (no start/end dates, no scheduled sessions)
    final program = Program.create(
      name: "5/3/1 Program",
      description: "Jim Wendler's 5/3/1 strength training program",
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        3,
        5,
      ]), // Mon, Wed, Fri
    );

    print("Created program template: ${program.name}");
    print("Next cycle number: ${program.nextCycleNumber}"); // Should be 1

    // Start the first cycle using the new API
    final programWithCycle1 = program.createCycle(
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)), // 4 weeks
      notes: "First cycle - establishing baseline",
    );

    print("Started cycle 1: ${programWithCycle1.activeCycle?.cycleNumber}");
    print(
      "Current cycle is active: ${programWithCycle1.activeCycle?.isCurrentlyActive}",
    );

    // Generate sessions for the current cycle
    final activeCycle = programWithCycle1.activeCycle!;
    final cycleWithSessions = activeCycle.generateScheduledSessions();
    final programWithSessions = programWithCycle1.updateCycle(
      cycleWithSessions,
    );
    print(
      "Generated ${programWithSessions.activeCycle?.totalWorkoutsCount} sessions for cycle 1",
    );

    // Complete the first cycle
    final programAfterCycle1 = programWithSessions.completeCurrentCycle();
    print(
      "Cycle 1 completed: ${programAfterCycle1.lastCompletedCycle?.isCompleted}",
    );

    // Start the second cycle using the new API
    final programWithCycle2 = programAfterCycle1.createCycle(
      startDate: DateTime.now().add(const Duration(days: 35)),
      endDate: DateTime.now().add(const Duration(days: 63)), // 4 weeks
      notes: "Second cycle - progressive overload",
    );

    print("Started cycle 2: ${programWithCycle2.activeCycle?.cycleNumber}");
    print("Total cycles: ${programWithCycle2.cycles.length}");
    print("Completed cycles: ${programWithCycle2.completedCycles.length}");
    print(
      "Active cycle: ${programWithCycle2.activeCycle?.cycleNumber ?? 'None'}",
    );
  }

  /// Example: Working with individual cycles
  static void exampleWorkingWithCycles() {
    final periodicity = const WorkoutPeriodicity.cyclic(
      workoutDays: 2,
      restDays: 1,
    );

    // Create a cycle manually
    final cycle = ProgramCycle.create(
      programId: "program-123",
      cycleNumber: 1,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 21)), // 3 weeks
      notes: "Introduction cycle",
      periodicity: periodicity,
    );

    print("Created cycle: ${cycle.cycleNumber}");
    print("Duration in weeks: ${cycle.durationInWeeks}");
    print("Duration in days: ${cycle.durationInDays}");

    // Generate sessions for the cycle
    final cycleWithSessions = cycle.generateScheduledSessions();

    print("Generated ${cycleWithSessions.totalWorkoutsCount} sessions");
    print(
      "Completion percentage: ${(cycleWithSessions.completionPercentage * 100).toStringAsFixed(1)}%",
    );

    // Mark cycle as completed
    final completedCycle = cycleWithSessions.complete();
    print("Cycle completed: ${completedCycle.isCompleted}");
    print("Cycle active: ${completedCycle.isActive}");
  }

  /// Example: Querying program cycles
  static void exampleQueryingCycles() {
    // Create a program template with multiple cycles
    var program = Program.create(
      name: "Push/Pull/Legs",
      type: ProgramType.hypertrophy,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        2,
        3,
        5,
        6,
        7,
      ]), // 6 days
    );

    // Add multiple cycles using the new API
    program = program.createCycle(
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 28),
      notes: "Cycle 1 - Foundation phase",
    );

    program = program.createCycle(
      startDate: DateTime(2024, 2, 1),
      endDate: DateTime(2024, 2, 28),
      notes: "Cycle 2 - Intensity phase",
    );

    program = program.createCycle(
      startDate: DateTime(2024, 3, 1),
      endDate: DateTime(2024, 3, 28),
      notes: "Cycle 3 - Peak phase",
    );

    // Complete the first two cycles
    var cycle1 = program.cycles[0].complete();
    var cycle2 = program.cycles[1].complete();
    program = program.updateCycle(cycle1);
    program = program.updateCycle(cycle2);

    // Query cycle information
    print("Total cycles: ${program.allCycles.length}");
    print("Active cycle: ${program.activeCycle?.cycleNumber ?? 'None'}");
    print("Completed cycles: ${program.completedCycles.length}");
    print("Current cycle: ${program.activeCycle?.cycleNumber ?? 'None'}");
    print(
      "Last completed cycle: ${program.lastCompletedCycle?.cycleNumber ?? 'None'}",
    );
    print("Next cycle number: ${program.nextCycleNumber}");

    // Query cycles for specific dates
    final cycle = program.cycles.first;
    final weekStart = DateTime(2024, 1, 1);
    final workoutsThisWeek = cycle.getWorkoutsForWeek(weekStart);
    print("Workouts in first week of cycle 1: ${workoutsThisWeek.length}");
  }

  /// Example: Program as template vs ProgramCycle as execution
  static void exampleTemplateVsExecution() {
    // Create a program template - this is reusable
    final strengthProgram = Program.create(
      name: "Starting Strength",
      description: "Linear progression strength program",
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        3,
        5,
      ]), // Mon, Wed, Fri
      tags: ["strength", "beginner", "linear progression"],
    );

    print("Program template created: ${strengthProgram.name}");
    print(
      "Template has scheduling periodicity: ${strengthProgram.hasSchedulingPeriodicity}",
    );
    print("Template frequency: ${strengthProgram.frequencyDescription}");

    // Now create multiple cycles of this program
    print("\n--- Running multiple cycles ---");

    // Cycle 1: Introduction phase
    var programWithCycles = strengthProgram.createCycle(
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 28),
      notes: "Cycle 1: Learning proper form with light weights",
    );

    // Cycle 2: Progressive loading
    programWithCycles = programWithCycles.createCycle(
      startDate: DateTime(2024, 2, 1),
      endDate: DateTime(2024, 2, 28),
      notes: "Cycle 2: Increasing weights, building strength base",
    );

    // Cycle 3: Intermediate progression
    programWithCycles = programWithCycles.createCycle(
      startDate: DateTime(2024, 3, 1),
      endDate: DateTime(2024, 3, 28),
      notes: "Cycle 3: Higher weights, focus on consistency",
    );

    print(
      "Created ${programWithCycles.cycles.length} cycles for ${programWithCycles.name}",
    );

    // Generate sessions for each cycle
    for (int i = 0; i < programWithCycles.cycles.length; i++) {
      final cycle = programWithCycles.cycles[i];
      final cycleWithSessions = cycle.generateScheduledSessions();
      programWithCycles = programWithCycles.updateCycle(cycleWithSessions);

      print(
        "Cycle ${cycle.cycleNumber}: ${cycleWithSessions.totalWorkoutsCount} sessions generated",
      );
      print("  Duration: ${cycleWithSessions.durationInWeeks} weeks");
      print("  Notes: ${cycleWithSessions.notes}");
    }

    // The program template remains unchanged and can be used to create more cycles
    print("\nProgram template is still clean and reusable:");
    print("- Template name: ${strengthProgram.name}");
    print(
      "- Template has ${strengthProgram.cycles.length} cycles (should be 0)",
    );
    print("- Template can be used to create new program instances");
  }

  /// Example: Single active cycle constraint
  static void exampleSingleActiveCycleConstraint() {
    print("=== Single Active Cycle Constraint Example ===\n");

    // Create a program
    final program = Program.create(
      name: "Hypertrophy Program",
      description: "Muscle building program with planned cycles",
      type: ProgramType.hypertrophy,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        2,
        4,
        5,
      ]), // 4x per week
      tags: ["hypertrophy", "muscle building"],
    );

    print("Created program: ${program.name}");

    final now = DateTime.now();

    // Create first cycle (automatically active based on dates)
    var programWithCycles = program.createCycle(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now.add(const Duration(days: 21)),
      notes: "Cycle 1: Foundation building",
    );

    print("Has active cycle: ${programWithCycles.activeCycle != null}");
    print(
      "Current active cycle: ${programWithCycles.activeCycle?.cycleNumber}",
    );

    // Create second cycle with future dates - this should not automatically activate
    programWithCycles = programWithCycles.createCycle(
      startDate: now.add(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 58)),
      notes: "Cycle 2: Progressive overload",
    );

    print("\nAfter creating second cycle:");
    print("Total cycles: ${programWithCycles.allCycles.length}");
    print("Has active cycle: ${programWithCycles.activeCycle != null}");
    print(
      "Current active cycle: ${programWithCycles.activeCycle?.cycleNumber}",
    );

    // Complete the current active cycle
    final activeCycle = programWithCycles.activeCycle!;
    final completedCycle = activeCycle.copyWith(
      isActive: false,
      isCompleted: true,
    );
    programWithCycles = programWithCycles.updateCycle(completedCycle);

    print("\nAfter completing cycle 2:");
    print("Has active cycle: ${programWithCycles.activeCycle != null}");
    print("Completed cycles: ${programWithCycles.completedCycles.length}");
    print(
      "Current active cycle: ${programWithCycles.activeCycle?.cycleNumber ?? 'None'}",
    );

    // Create and activate a third cycle with future dates (after second cycle)
    programWithCycles = programWithCycles.createCycle(
      startDate: now.add(const Duration(days: 60)),
      endDate: now.add(const Duration(days: 88)),
      notes: "Cycle 3: Intensification phase",
    );

    print("\nAfter creating third cycle:");
    print("Has active cycle: ${programWithCycles.activeCycle != null}");
    print(
      "Current active cycle: ${programWithCycles.activeCycle?.cycleNumber}",
    );

    // Demonstrate trying to activate a specific cycle
    final firstCycle = programWithCycles.allCycles.first;
    try {
      // This should fail if the cycle is not within valid date range
      programWithCycles = programWithCycles.activateCycle(firstCycle.id);
      print("\nSuccessfully activated cycle ${firstCycle.cycleNumber}");
      print(
        "Current active cycle: ${programWithCycles.activeCycle?.cycleNumber}",
      );
    } catch (e) {
      print("\nError activating cycle: $e");
      print("This is expected if the cycle is outside the valid date range");
    }

    // Show validation methods
    print("\nValidation checks:");
    print("Has valid cycle state: ${programWithCycles.hasValidCycleState}");
    print("Active cycles count: ${programWithCycles.activeCyclesCount}");
  }

  /// Example: Date-based activation demonstration
  static void exampleDateBasedActivation() {
    print("=== Date-Based Activation Example ===\n");

    final program = Program.create(
      name: "Smart Activation Program",
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([1, 3, 5]),
    );

    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    final nextMonth = now.add(const Duration(days: 30));

    // Create cycles with different date ranges
    var programWithCycles = program.createCycle(
      startDate: lastMonth,
      endDate: now.add(const Duration(days: 7)), // Active now
      notes: "Current cycle",
    );

    programWithCycles = programWithCycles.createCycle(
      startDate: nextMonth,
      endDate: nextMonth.add(const Duration(days: 28)), // Future cycle
      notes: "Future cycle",
    );

    print("Cycles created with different date ranges:");
    print("Total cycles: ${programWithCycles.cycles.length}");
    print("Active cycles: ${programWithCycles.activeCyclesCount}");

    // Show which cycles can be activated
    final activatableCycles = programWithCycles.getActivatableCycles();
    print("Cycles that can be activated now: ${activatableCycles.length}");

    for (final cycle in activatableCycles) {
      print(
        "- ${cycle.notes}: ${cycle.startDate} to ${cycle.effectiveEndDate}",
      );
    }

    // Try to activate future cycle (should fail)
    final futureCycle = programWithCycles.cycles.last;
    try {
      programWithCycles = programWithCycles.activateCycle(futureCycle.id);
    } catch (e) {
      print("\nExpected error activating future cycle: $e");
    }

    // Refresh activation based on current date
    programWithCycles = programWithCycles.refreshCycleActivation();
    print(
      "\nAfter refresh - Active cycles: ${programWithCycles.activeCyclesCount}",
    );

    // Check overlap before creating
    final wouldOverlap = programWithCycles.wouldCycleOverlap(
      now.subtract(const Duration(days: 5)),
      now.add(const Duration(days: 5)),
    );
    print("Would new cycle overlap? $wouldOverlap");
  }

  /// Example: Date range overlap validation
  static void exampleOverlapValidation() {
    print("=== Date Range Overlap Validation Example ===\n");

    var program = Program.create(
      name: "Validation Test Program",
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: null,
    );

    final baseDate = DateTime.now();

    // Add first cycle
    program = program.createCycle(
      startDate: baseDate,
      endDate: baseDate.add(const Duration(days: 30)),
      notes: "Base cycle",
    );

    print(
      "Added base cycle: $baseDate to ${baseDate.add(const Duration(days: 30))}",
    );

    // Test various overlap scenarios
    final testCases = [
      {
        'name': 'Valid adjacent cycle',
        'start': baseDate.add(const Duration(days: 31)),
        'end': baseDate.add(const Duration(days: 60)),
        'shouldSucceed': true,
      },
      {
        'name': 'Overlapping start',
        'start': baseDate.add(const Duration(days: 15)),
        'end': baseDate.add(const Duration(days: 45)),
        'shouldSucceed': false,
      },
      {
        'name': 'Overlapping end',
        'start': baseDate.subtract(const Duration(days: 15)),
        'end': baseDate.add(const Duration(days: 15)),
        'shouldSucceed': false,
      },
      {
        'name': 'Contained within',
        'start': baseDate.add(const Duration(days: 5)),
        'end': baseDate.add(const Duration(days: 25)),
        'shouldSucceed': false,
      },
    ];

    for (final testCase in testCases) {
      final name = testCase['name'] as String;
      final start = testCase['start'] as DateTime;
      final end = testCase['end'] as DateTime;
      final shouldSucceed = testCase['shouldSucceed'] as bool;

      // First check with wouldCycleOverlap
      final wouldOverlap = program.wouldCycleOverlap(start, end);
      print(
        '$name - Would overlap: $wouldOverlap (expected: ${!shouldSucceed})',
      );

      // Then try to create the cycle
      try {
        program = program.createCycle(
          startDate: start,
          endDate: end,
          notes: name,
        );
        print('  ✓ Successfully created cycle');

        if (!shouldSucceed) {
          print('  ⚠️  Expected this to fail!');
        }
      } catch (e) {
        print('  ✗ Failed to create cycle: ${e.toString().split(': ').last}');

        if (shouldSucceed) {
          print('  ⚠️  Expected this to succeed!');
        }
      }
      print('');
    }

    print('Final cycles count: ${program.cycles.length}');
  }
}
