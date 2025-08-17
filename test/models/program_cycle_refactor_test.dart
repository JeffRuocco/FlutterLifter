import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

void main() {
  group('Refactored Program Cycle Management', () {
    late Program program;

    setUp(() {
      program = Program.create(
        name: "Test Program",
        type: ProgramType.strength,
        difficulty: ProgramDifficulty.beginner,
        defaultPeriodicity: const WorkoutPeriodicity.weekly([1, 3, 5]),
      );
    });

    group('Date Range Validation', () {
      test('should allow non-overlapping cycles', () {
        final now = DateTime.now();
        final cycle1End = now.add(const Duration(days: 30));
        final cycle2Start = now.add(const Duration(days: 31));
        final cycle2End = now.add(const Duration(days: 60));

        // Add first cycle
        program = program.createCycle(
          startDate: now,
          endDate: cycle1End,
          notes: "Cycle 1",
        );

        expect(program.cycles.length, 1);

        // Add second cycle (non-overlapping)
        program = program.createCycle(
          startDate: cycle2Start,
          endDate: cycle2End,
          notes: "Cycle 2",
        );

        expect(program.cycles.length, 2);
      });

      test('should reject overlapping cycles', () {
        final now = DateTime.now();
        final cycle1End = now.add(const Duration(days: 30));
        final cycle2Start = now.add(const Duration(days: 15)); // Overlaps!
        final cycle2End = now.add(const Duration(days: 45));

        // Add first cycle
        program = program.createCycle(
          startDate: now,
          endDate: cycle1End,
          notes: "Cycle 1",
        );

        expect(program.cycles.length, 1);

        // Try to add overlapping cycle
        expect(
          () => program.createCycle(
            startDate: cycle2Start,
            endDate: cycle2End,
            notes: "Overlapping Cycle",
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(program.cycles.length, 1); // Should still be 1
      });

      test('should validate cycle overlap with wouldCycleOverlap', () {
        final now = DateTime.now();

        // Add a cycle
        program = program.createCycle(
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          notes: "Existing Cycle",
        );

        // Check overlapping date range
        expect(
          program.wouldCycleOverlap(
            now.add(const Duration(days: 15)),
            now.add(const Duration(days: 45)),
          ),
          isTrue,
        );

        // Check non-overlapping date range
        expect(
          program.wouldCycleOverlap(
            now.add(const Duration(days: 31)),
            now.add(const Duration(days: 60)),
          ),
          isFalse,
        );
      });
    });

    group('Date-based Activation', () {
      test('should activate cycles based on current date', () {
        final now = DateTime.now();
        final pastDate = now.subtract(const Duration(days: 30));
        final futureDate = now.add(const Duration(days: 30));

        // Add a current cycle (should be activated)
        program = program.createCycle(
          startDate: pastDate,
          endDate: futureDate,
          notes: "Current Cycle",
        );

        // Add a future cycle (should not be activated)
        program = program.createCycle(
          startDate: futureDate.add(const Duration(days: 1)),
          endDate: futureDate.add(const Duration(days: 30)),
          notes: "Future Cycle",
        );

        expect(program.cycles.length, 2);
        expect(program.activeCyclesCount, 1);
        expect(program.activeCycle?.notes, "Current Cycle");
      });

      test('should get activatable cycles correctly', () {
        final now = DateTime.now();
        final pastDate = now.subtract(const Duration(days: 30));
        final futureDate = now.add(const Duration(days: 30));

        // Add cycles with different date ranges
        program = program.createCycle(
          startDate: pastDate,
          endDate: futureDate,
          notes: "Current Cycle",
        );

        program = program.createCycle(
          startDate: futureDate.add(const Duration(days: 1)),
          endDate: futureDate.add(const Duration(days: 30)),
          notes: "Future Cycle",
        );

        final activatableCycles = program.getActivatableCycles();
        expect(activatableCycles.length, 1);
        expect(activatableCycles.first.notes, "Current Cycle");
      });

      test('should not allow activation of cycles outside date range', () {
        final now = DateTime.now();
        final futureStart = now.add(const Duration(days: 30));
        final futureEnd = now.add(const Duration(days: 60));

        // Add a future cycle
        program = program.createCycle(
          startDate: futureStart,
          endDate: futureEnd,
          notes: "Future Cycle",
        );

        final futureyCycle = program.cycles.first;

        // Try to activate future cycle
        expect(
          () => program.activateCycle(futureyCycle.id),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('ProgramCycle Date Methods', () {
      test('should correctly check if date is within range', () {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        final cycle = ProgramCycle.create(
          programId: program.id,
          cycleNumber: 1,
          startDate: startDate,
          endDate: endDate,
        );

        expect(cycle.isWithinDateRange(DateTime(2024, 1, 15)), isTrue);
        expect(cycle.isWithinDateRange(DateTime(2024, 1, 1)), isTrue);
        expect(cycle.isWithinDateRange(DateTime(2024, 1, 31)), isTrue);
        expect(cycle.isWithinDateRange(DateTime(2023, 12, 31)), isFalse);
        expect(cycle.isWithinDateRange(DateTime(2024, 2, 1)), isFalse);
      });

      test('should correctly determine if cycle can be activated', () {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 5));
        final endDate = now.add(const Duration(days: 25));

        final cycle = ProgramCycle.create(
          programId: program.id,
          cycleNumber: 1,
          startDate: startDate,
          endDate: endDate,
        );

        expect(cycle.canBeActivatedOn(now), isTrue);
        expect(cycle.canBeActivatedOn(startDate), isTrue);
        expect(cycle.canBeActivatedOn(endDate), isTrue);
        expect(
            cycle.canBeActivatedOn(startDate.subtract(const Duration(days: 1))),
            isFalse);
        expect(cycle.canBeActivatedOn(endDate.add(const Duration(days: 1))),
            isFalse);

        // Completed cycles cannot be activated
        final completedCycle = cycle.complete();
        expect(completedCycle.canBeActivatedOn(now), isFalse);
      });

      test('should enforce date range validation when starting cycle', () {
        final now = DateTime.now();
        final futureStart = now.add(const Duration(days: 30));
        final futureEnd = now.add(const Duration(days: 60));

        final futureCycle = ProgramCycle.create(
          programId: program.id,
          cycleNumber: 1,
          startDate: futureStart,
          endDate: futureEnd,
        );

        // Should not be able to start future cycle now
        expect(
          () => futureCycle.start(),
          throwsA(isA<StateError>()),
        );

        // Should be able to start it on its start date
        expect(
          () => futureCycle.start(currentDate: futureStart),
          returnsNormally,
        );
      });
    });

    group('Convenience Methods', () {
      test('should create immediate cycle correctly', () {
        final initialCycleCount = program.cycles.length;

        program = program.startImmediateCycle(
          endDate: DateTime.now().add(const Duration(days: 30)),
          notes: "Immediate cycle",
        );

        expect(program.cycles.length, initialCycleCount + 1);
        expect(program.activeCyclesCount, 1);
        expect(program.activeCycle?.notes, "Immediate cycle");
      });

      test('should complete current cycle correctly', () {
        // Add and activate a cycle
        program = program.startImmediateCycle(
          endDate: DateTime.now().add(const Duration(days: 30)),
          notes: "Cycle to complete",
        );

        expect(program.activeCyclesCount, 1);
        expect(program.activeCycle?.isCompleted, isFalse);

        // Complete the cycle
        program = program.completeCurrentCycle();

        expect(program.activeCyclesCount, 0);
        expect(program.completedCycles.length, 1);
        expect(program.completedCycles.first.isCompleted, isTrue);
      });
    });

    group('Legacy API Compatibility', () {
      test('should maintain currentCycle getter', () {
        program = program.startImmediateCycle(
          endDate: DateTime.now().add(const Duration(days: 30)),
          notes: "Current cycle",
        );

        expect(program.currentCycle, isNotNull);
        expect(program.currentCycle?.notes, "Current cycle");
        expect(program.currentCycle, equals(program.activeCycle));
      });

      test('should maintain basic cycle properties', () {
        final now = DateTime.now();
        program = program.createCycle(
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          notes: "Test cycle",
        );

        final cycle = program.cycles.first;
        expect(cycle.durationInDays, 31); // 30 days + 1 (inclusive)
        expect(cycle.durationInWeeks, 5); // Ceil(31/7)
        expect(cycle.effectiveEndDate, cycle.endDate);
      });
    });
  });
}
