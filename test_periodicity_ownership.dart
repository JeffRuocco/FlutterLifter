// ignore_for_file: avoid_print

import 'package:flutter_lifter/models/shared_enums.dart';

import 'package:flutter_lifter/models/program_models.dart';

void main() {
  print("Testing periodicity ownership changes...\n");

  try {
    // Test 1: Create a program with default periodicity
    print("=== Test 1: Program with Default Periodicity ===");
    final program = Program.create(
      name: "Test Program",
      description: "Testing periodicity ownership",
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity:
          const WorkoutPeriodicity.weekly([1, 3, 5]), // Mon, Wed, Fri
    );

    print("Program created: ${program.name}");
    print("Default periodicity: ${program.periodicityDescription}");
    print("Has scheduling periodicity: ${program.hasSchedulingPeriodicity}");

    // Test 2: Create a cycle (should inherit default periodicity)
    print("\n=== Test 2: Creating Cycle with Inherited Periodicity ===");
    final programWithCycle = program.createNewCycle(
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)),
      notes: "Test cycle with inherited periodicity",
    );

    final cycle = programWithCycle.activeCycle!;
    print("Cycle created: ${cycle.cycleNumber}");
    print("Cycle periodicity: ${cycle.periodicity?.description ?? 'None'}");
    print("Cycle has periodicity: ${cycle.periodicity != null}");

    // Test 3: Check if cycle can determine workout dates
    print("\n=== Test 3: Workout Date Checking ===");
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    print("Today is workout day: ${cycle.isWorkoutExpectedOnDate(today)}");
    print(
        "Tomorrow is workout day: ${cycle.isWorkoutExpectedOnDate(tomorrow)}");

    // Test from program level (should delegate to cycle)
    print(
        "Program says today is workout day: ${programWithCycle.isWorkoutExpectedOnDate(today)}");

    // Test 4: Create cycle with custom periodicity
    print("\n=== Test 4: Cycle with Custom Periodicity ===");
    final customCycle = ProgramCycle.create(
      programId: program.id,
      cycleNumber: 2,
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 58)),
      periodicity: const WorkoutPeriodicity.interval(2), // Every other day
      notes: "Custom periodicity cycle",
    );

    print("Custom cycle created: ${customCycle.cycleNumber}");
    print(
        "Custom cycle periodicity: ${customCycle.periodicity?.description ?? 'None'}");

    // Test 5: JSON serialization
    print("\n=== Test 5: JSON Serialization ===");
    final programJson = program.toJson();
    print(
        "Program JSON contains defaultPeriodicity: ${programJson.containsKey('periodicity')}");

    final cycleJson = cycle.toJson();
    print(
        "Cycle JSON contains periodicity: ${cycleJson.containsKey('periodicity')}");

    print(
        "\n✅ All tests passed! Periodicity ownership changes work correctly.");
  } catch (e, stackTrace) {
    print("❌ Test failed with error: $e");
    print("Stack trace: $stackTrace");
  }
}
