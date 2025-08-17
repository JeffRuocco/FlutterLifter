import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lifter/examples/periodicity_examples.dart';
import 'package:flutter_lifter/examples/program_cycle_examples.dart';

void main() {
  group('Updated Examples', () {
    test('periodicity examples should run without errors', () {
      expect(() => PeriodicityExamples.createWeeklyProgram(), returnsNormally);
      expect(() => PeriodicityExamples.createCyclicProgram(), returnsNormally);
      expect(
          () => PeriodicityExamples.createIntervalProgram(), returnsNormally);
      expect(() => PeriodicityExamples.createCustomProgram(), returnsNormally);

      // Test the main demonstration methods
      expect(() => PeriodicityExamples.demonstrateScheduleGeneration(),
          returnsNormally);
      expect(() => PeriodicityExamples.demonstrateWorkoutChecking(),
          returnsNormally);
      expect(() => PeriodicityExamples.demonstrateCompleteWorkflow(),
          returnsNormally);
      expect(() => PeriodicityExamples.demonstrateRefactoredFeatures(),
          returnsNormally);
    });

    test('program cycle examples should run without errors', () {
      expect(() => ProgramCycleExamples.exampleProgramWithMultipleCycles(),
          returnsNormally);
      expect(() => ProgramCycleExamples.exampleWorkingWithCycles(),
          returnsNormally);
      expect(
          () => ProgramCycleExamples.exampleQueryingCycles(), returnsNormally);
      expect(() => ProgramCycleExamples.exampleTemplateVsExecution(),
          returnsNormally);
      expect(() => ProgramCycleExamples.exampleDateBasedActivation(),
          returnsNormally);
      expect(() => ProgramCycleExamples.exampleOverlapValidation(),
          returnsNormally);
      expect(() => ProgramCycleExamples.exampleSingleActiveCycleConstraint(),
          returnsNormally);
    });

    test('examples should demonstrate new refactored features', () {
      // Test that the new API methods are being used
      final program = PeriodicityExamples.createWeeklyProgram();

      // Should be able to create cycles with new API
      final programWithCycle = program.createCycle(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 28)),
        notes: "Test cycle",
      );

      expect(programWithCycle.cycles.length, 1);
      expect(programWithCycle.activeCycle, isNotNull);

      // Should be able to check for overlaps
      final wouldOverlap = programWithCycle.wouldCycleOverlap(
        DateTime.now().add(const Duration(days: 10)),
        DateTime.now().add(const Duration(days: 40)),
      );
      expect(wouldOverlap, isTrue);

      // Should be able to get activatable cycles
      final activatable = programWithCycle.getActivatableCycles();
      expect(activatable, isNotEmpty);
    });
  });
}
