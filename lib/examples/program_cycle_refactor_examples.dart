// ignore_for_file: avoid_print

import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

/// Example demonstrating the refactored Program and ProgramCycle API
/// This shows how the new date-based cycle management works
class ProgramCycleManagementExample {
  static void demonstrateRefactoredAPI() {
    // Create a program
    var program = Program.create(
      name: "Push/Pull/Legs",
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity:
          const WorkoutPeriodicity.weekly([1, 3, 5]), // Mon, Wed, Fri
    );

    print('Created program: ${program.name}');
    print('Initial cycles count: ${program.cycles.length}');

    try {
      // Add a cycle for this month
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthEnd = DateTime(now.year, now.month + 1, 0);

      program = program.createCycle(
        startDate: thisMonthStart,
        endDate: thisMonthEnd,
        notes: "January cycle",
      );

      print('\nAdded January cycle');
      print('Cycles count: ${program.cycles.length}');
      print('Active cycles: ${program.activeCyclesCount}');

      // Add a cycle for next month (future planning)
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);
      final nextMonthEnd = DateTime(now.year, now.month + 2, 0);

      program = program.createCycle(
        startDate: nextMonthStart,
        endDate: nextMonthEnd,
        notes: "February cycle",
      );

      print('\nAdded February cycle (future)');
      print('Cycles count: ${program.cycles.length}');
      print('Active cycles: ${program.activeCyclesCount}');

      // Check which cycles can be activated
      final activatableCycles = program.getActivatableCycles();
      print('\nCycles that can be activated now: ${activatableCycles.length}');
      for (final cycle in activatableCycles) {
        print(
            '- Cycle ${cycle.cycleNumber}: ${cycle.startDate} to ${cycle.effectiveEndDate}');
      }

      // Try to add an overlapping cycle (should fail)
      try {
        program = program.createCycle(
          startDate: thisMonthStart.add(const Duration(days: 15)),
          endDate: thisMonthEnd.add(const Duration(days: 15)),
          notes: "Overlapping cycle",
        );
      } catch (e) {
        print('\nExpected error for overlapping cycle: $e');
      }

      // Check cycle overlap before creating
      final wouldOverlap = program.wouldCycleOverlap(
        thisMonthStart.add(const Duration(days: 10)),
        thisMonthEnd.add(const Duration(days: 10)),
      );
      print('Would new cycle overlap? $wouldOverlap');

      // Refresh cycle activation (updates based on current date)
      program = program.refreshCycleActivation();
      print('\nAfter refresh - Active cycles: ${program.activeCyclesCount}');

      // Demonstrate individual cycle methods
      if (program.cycles.isNotEmpty) {
        final firstCycle = program.cycles.first;
        print('\nFirst cycle details:');
        print('- Can be activated now? ${firstCycle.canBeActivatedOn(now)}');
        print('- Is within date range? ${firstCycle.isWithinDateRange(now)}');
        print('- Effective end date: ${firstCycle.effectiveEndDate}');
        print('- Duration in days: ${firstCycle.durationInDays}');
        print('- Duration in weeks: ${firstCycle.durationInWeeks}');
      }

      // Complete the current cycle
      if (program.activeCycle != null) {
        program = program.completeCurrentCycle();
        print('\nCompleted current cycle');
        print('Active cycles after completion: ${program.activeCyclesCount}');
      }

      // Start an immediate cycle (convenience method)
      program = program.startImmediateCycle(
        endDate: DateTime.now().add(const Duration(days: 30)),
        notes: "Quick 30-day cycle",
      );

      print('\nStarted immediate cycle');
      print('Total cycles: ${program.cycles.length}');
      print('Active cycles: ${program.activeCyclesCount}');
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Demonstrates the improved date validation
  static void demonstrateDateValidation() {
    var program = Program.create(
      name: "Test Program",
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: null,
    );

    final baseDate = DateTime.now();

    print('\n=== Date Validation Demo ===');

    // Add first cycle
    program = program.createCycle(
      startDate: baseDate,
      endDate: baseDate.add(const Duration(days: 30)),
      notes: "Cycle 1",
    );
    print(
        'Added Cycle 1: $baseDate to ${baseDate.add(const Duration(days: 30))}');

    // Try overlapping cycles (should fail)
    final testCases = [
      {
        'name': 'Overlapping start',
        'start': baseDate.add(const Duration(days: 15)),
        'end': baseDate.add(const Duration(days: 45)),
      },
      {
        'name': 'Overlapping end',
        'start': baseDate.subtract(const Duration(days: 15)),
        'end': baseDate.add(const Duration(days: 15)),
      },
      {
        'name': 'Contained within',
        'start': baseDate.add(const Duration(days: 5)),
        'end': baseDate.add(const Duration(days: 25)),
      },
      {
        'name': 'Contains existing',
        'start': baseDate.subtract(const Duration(days: 5)),
        'end': baseDate.add(const Duration(days: 35)),
      },
      {
        'name': 'Valid adjacent',
        'start': baseDate.add(const Duration(days: 31)),
        'end': baseDate.add(const Duration(days: 60)),
      },
    ];

    for (final testCase in testCases) {
      try {
        program = program.createCycle(
          startDate: testCase['start'] as DateTime,
          endDate: testCase['end'] as DateTime,
          notes: testCase['name'] as String,
        );
        print('✓ ${testCase['name']}: Successfully added');
      } catch (e) {
        print('✗ ${testCase['name']}: $e');
      }
    }

    print('\nFinal cycles count: ${program.cycles.length}');
  }
}

/// Extension methods for easier testing and debugging
extension ProgramDebugExtensions on Program {
  /// Prints detailed information about all cycles
  void printCycleDetails() {
    print('\n=== Program Cycle Details ===');
    print('Program: $name');
    print('Total cycles: ${cycles.length}');
    print('Active cycles: $activeCyclesCount');

    for (int i = 0; i < cycles.length; i++) {
      final cycle = cycles[i];
      print('\nCycle ${i + 1}:');
      print('  ID: ${cycle.id}');
      print('  Number: ${cycle.cycleNumber}');
      print('  Start: ${cycle.startDate}');
      print(
          '  End: ${cycle.endDate ?? 'None (defaults to ${cycle.effectiveEndDate})'}');
      print('  Active: ${cycle.isActive}');
      print('  Completed: ${cycle.isCompleted}');
      print('  Currently Active: ${cycle.isCurrentlyActive}');
      print('  Can Activate Now: ${cycle.canBeActivatedOn(DateTime.now())}');
      print('  Notes: ${cycle.notes ?? 'None'}');
    }
    print('========================\n');
  }
}
