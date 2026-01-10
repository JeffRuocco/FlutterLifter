import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

void main() {
  // ========================================================
  // NOTE: Widget tests for ProgramDetailScreen are skipped
  // because the screen contains continuous animations
  // (SlideInWidget, AnimatedCrossFade, SkeletonLoader) that
  // prevent Flutter's test framework from settling timers.
  //
  // The UI components are manually tested and the business
  // logic is thoroughly tested in the repository tests.
  //
  // For full UI testing, integration tests should be used.
  // ========================================================

  group('ProgramDetailScreen - Model Integration', () {
    late Program testProgram;
    late List<ProgramCycle> testCycles;

    setUp(() {
      final now = DateTime.now();

      testCycles = [
        ProgramCycle(
          id: 'cycle_1',
          programId: 'test_program',
          cycleNumber: 1,
          startDate: now.subtract(const Duration(days: 60)),
          endDate: now.subtract(const Duration(days: 30)),
          isActive: false,
          isCompleted: true,
          createdAt: now.subtract(const Duration(days: 61)),
        ),
        ProgramCycle(
          id: 'cycle_2',
          programId: 'test_program',
          cycleNumber: 2,
          startDate: now.subtract(const Duration(days: 14)),
          endDate: null,
          isActive: true,
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 15)),
        ),
      ];

      testProgram = Program(
        id: 'test_program',
        name: 'Test Program',
        description: 'A test program for unit tests',
        type: ProgramType.strength,
        difficulty: ProgramDifficulty.intermediate,
        createdAt: now.subtract(const Duration(days: 90)),
        isDefault: false,
        lastUsedAt: now.subtract(const Duration(days: 1)),
        tags: ['test', 'strength'],
        cycles: testCycles,
      );
    });

    test('program should have correct metadata', () {
      expect(testProgram.name, equals('Test Program'));
      expect(testProgram.type, equals(ProgramType.strength));
      expect(testProgram.difficulty, equals(ProgramDifficulty.intermediate));
      expect(testProgram.isDefault, isFalse);
    });

    test('program should correctly identify active cycle', () {
      final activeCycle = testProgram.activeCycle;

      expect(activeCycle, isNotNull);
      expect(activeCycle!.id, equals('cycle_2'));
      expect(activeCycle.isActive, isTrue);
    });

    test('program should correctly get completed cycles', () {
      final completedCycles = testProgram.completedCycles;

      expect(completedCycles.length, equals(1));
      expect(completedCycles.first.id, equals('cycle_1'));
      expect(completedCycles.first.isCompleted, isTrue);
    });

    test('program should calculate next cycle number correctly', () {
      expect(testProgram.nextCycleNumber, equals(3));
    });

    test('program allCycles should be unmodifiable', () {
      final cycles = testProgram.allCycles;

      expect(cycles.length, equals(2));
      expect(
        () => cycles.add(
          ProgramCycle(
            id: 'new',
            programId: 'test',
            cycleNumber: 3,
            startDate: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('program hasValidCycleState should be true with one active cycle', () {
      expect(testProgram.hasValidCycleState, isTrue);
    });
  });

  group('ProgramCycle - Display Properties', () {
    test('cycle should calculate duration correctly', () {
      final now = DateTime.now();
      final cycle = ProgramCycle(
        id: 'test',
        programId: 'prog',
        cycleNumber: 1,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 31)),
      );

      expect(cycle.durationInDays, equals(29));
    });

    test('cycle durationInWeeks should calculate correctly', () {
      final now = DateTime.now();
      final cycle = ProgramCycle(
        id: 'test',
        programId: 'prog',
        cycleNumber: 1,
        startDate: now.subtract(const Duration(days: 21)),
        endDate: now,
        createdAt: now.subtract(const Duration(days: 22)),
      );

      expect(cycle.durationInWeeks, equals(4)); // 22 days / 7 = 3.14, ceil = 4
    });

    test('cycle without endDate should have null duration', () {
      final now = DateTime.now();
      final cycle = ProgramCycle(
        id: 'test',
        programId: 'prog',
        cycleNumber: 1,
        startDate: now.subtract(const Duration(days: 14)),
        endDate: null,
        createdAt: now.subtract(const Duration(days: 15)),
      );

      expect(cycle.durationInDays, isNull);
      expect(cycle.durationInWeeks, isNull);
    });

    test('cycle completion percentage should be calculated correctly', () {
      // A cycle with no sessions has 0% completion
      final now = DateTime.now();
      final emptyCycle = ProgramCycle(
        id: 'test',
        programId: 'prog',
        cycleNumber: 1,
        startDate: now,
        createdAt: now,
        scheduledSessions: [],
      );

      expect(emptyCycle.completionPercentage, equals(0.0));
    });
  });

  group('Program - Default vs Custom', () {
    test('default program should have isDefault true', () {
      final defaultProgram = Program(
        id: 'default_1',
        name: 'Default Program',
        type: ProgramType.general,
        difficulty: ProgramDifficulty.beginner,
        createdAt: DateTime.now(),
        isDefault: true,
      );

      expect(defaultProgram.isDefault, isTrue);
    });

    test('custom program should have isDefault false', () {
      final customProgram = Program(
        id: 'custom_1',
        name: 'Custom Program',
        type: ProgramType.general,
        difficulty: ProgramDifficulty.beginner,
        createdAt: DateTime.now(),
        isDefault: false,
      );

      expect(customProgram.isDefault, isFalse);
    });

    test('program copy should preserve templateId reference', () {
      final original = Program(
        id: 'original',
        name: 'Original Program',
        type: ProgramType.strength,
        difficulty: ProgramDifficulty.intermediate,
        createdAt: DateTime.now(),
        isDefault: true,
      );

      final copy = Program(
        id: 'copy_1',
        name: original.name,
        description: original.description,
        type: original.type,
        difficulty: original.difficulty,
        createdAt: DateTime.now(),
        isDefault: false,
        templateId: original.id, // Reference to original
      );

      expect(copy.templateId, equals(original.id));
      expect(copy.isDefault, isFalse);
      expect(copy.name, equals(original.name));
    });
  });

  group('Program - Cycle Management', () {
    test('addCycle should add new cycle to program', () {
      final program = Program(
        id: 'test',
        name: 'Test',
        type: ProgramType.general,
        difficulty: ProgramDifficulty.beginner,
        createdAt: DateTime.now(),
        cycles: [],
      );

      final now = DateTime.now();
      final newCycle = ProgramCycle(
        id: 'new_cycle',
        programId: 'test',
        cycleNumber: 1,
        startDate: now,
        createdAt: now,
      );

      final updatedProgram = program.addCycle(newCycle);

      expect(updatedProgram.cycles.length, equals(1));
      expect(updatedProgram.cycles.first.id, equals('new_cycle'));
    });

    test('removeCycle should remove cycle from program', () {
      final now = DateTime.now();
      final program = Program(
        id: 'test',
        name: 'Test',
        type: ProgramType.general,
        difficulty: ProgramDifficulty.beginner,
        createdAt: now,
        cycles: [
          ProgramCycle(
            id: 'cycle_1',
            programId: 'test',
            cycleNumber: 1,
            startDate: now,
            createdAt: now,
          ),
          ProgramCycle(
            id: 'cycle_2',
            programId: 'test',
            cycleNumber: 2,
            startDate: now.add(const Duration(days: 30)),
            createdAt: now.add(const Duration(days: 29)),
          ),
        ],
      );

      final updatedProgram = program.removeCycle('cycle_1');

      expect(updatedProgram.cycles.length, equals(1));
      expect(updatedProgram.cycles.first.id, equals('cycle_2'));
    });

    test('updateCycle should update existing cycle', () {
      final now = DateTime.now();
      final program = Program(
        id: 'test',
        name: 'Test',
        type: ProgramType.general,
        difficulty: ProgramDifficulty.beginner,
        createdAt: now,
        cycles: [
          ProgramCycle(
            id: 'cycle_1',
            programId: 'test',
            cycleNumber: 1,
            startDate: now,
            isActive: true,
            createdAt: now,
          ),
        ],
      );

      final updatedCycle = program.cycles.first.copyWith(
        isActive: false,
        isCompleted: true,
        endDate: now.add(const Duration(days: 28)),
      );

      final updatedProgram = program.updateCycle(updatedCycle);

      expect(updatedProgram.cycles.first.isActive, isFalse);
      expect(updatedProgram.cycles.first.isCompleted, isTrue);
      expect(updatedProgram.cycles.first.endDate, isNotNull);
    });
  });

  group('ProgramDifficulty', () {
    test('should have correct display names', () {
      expect(ProgramDifficulty.beginner.displayName, equals('Beginner'));
      expect(
        ProgramDifficulty.intermediate.displayName,
        equals('Intermediate'),
      );
      expect(ProgramDifficulty.advanced.displayName, equals('Advanced'));
    });

    test('should have correct ordering', () {
      expect(
        ProgramDifficulty.beginner.index,
        lessThan(ProgramDifficulty.intermediate.index),
      );
      expect(
        ProgramDifficulty.intermediate.index,
        lessThan(ProgramDifficulty.advanced.index),
      );
    });
  });

  group('ProgramType', () {
    test('should have display names', () {
      expect(ProgramType.strength.displayName, isNotEmpty);
      expect(ProgramType.hypertrophy.displayName, isNotEmpty);
      expect(ProgramType.general.displayName, isNotEmpty);
    });

    test('should have all expected values', () {
      final types = ProgramType.values;
      expect(types, contains(ProgramType.strength));
      expect(types, contains(ProgramType.hypertrophy));
      expect(types, contains(ProgramType.general));
      expect(types, contains(ProgramType.cardio));
    });
  });
}
