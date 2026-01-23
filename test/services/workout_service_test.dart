import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/services/app_settings_service.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/services/workout_service.dart';

/// Mock implementation of ProgramRepository for testing WorkoutService
class MockProgramRepository implements ProgramRepository {
  final Map<String, WorkoutSession> _savedSessions = {};
  bool saveWorkoutCalled = false;
  int saveWorkoutCallCount = 0;

  @override
  Future<void> saveWorkoutSession(
    WorkoutSession session, {
    bool propagateToFuture = true,
  }) async {
    saveWorkoutCalled = true;
    saveWorkoutCallCount++;
    _savedSessions[session.id] = session;
  }

  @override
  Future<WorkoutSession?> getWorkoutSessionById(String sessionId) async {
    return _savedSessions[sessionId];
  }

  @override
  Future<void> deleteWorkoutSession(String sessionId) async {
    _savedSessions.remove(sessionId);
  }

  @override
  Future<void> cancelOtherInProgressSessions(String exceptSessionId) async {
    // Mock implementation - do nothing
  }

  @override
  Future<List<WorkoutSession>> getWorkoutHistory() async {
    return _savedSessions.values.toList();
  }

  // Stub implementations for unused methods
  @override
  Future<List<Program>> getPrograms() async => [];

  @override
  Future<Program?> getProgramById(String id) async => null;

  @override
  Future<void> createProgram(Program program) async {}

  @override
  Future<void> updateProgram(Program program) async {}

  @override
  Future<void> deleteProgram(String id) async {}

  @override
  Future<List<Program>> searchPrograms(String query) async => [];

  @override
  Future<List<Program>> getProgramsByDifficulty(
    ProgramDifficulty difficulty,
  ) async => [];

  @override
  Future<List<Program>> getProgramsByType(ProgramType type) async => [];

  @override
  Future<void> refreshCache() async {}

  @override
  Future<ProgramCycle?> getProgramCycleWithProgram(String cycleId) async =>
      null;

  @override
  Future<List<ProgramCycle>> getProgramCyclesWithProgram(
    String programId,
  ) async => [];

  @override
  Future<void> propagateExercisesToFutureSessions({
    required WorkoutSession sourceSession,
    required String cycleId,
  }) async {}

  @override
  Future<void> rescheduleFutureSessions({
    required WorkoutSession session,
    required DateTime originalDate,
  }) async {}

  @override
  Future<WorkoutSession?> getInProgressSession() async => null;

  @override
  Future<WorkoutSession?> getPlannedStandaloneSession() async => null;

  @override
  // Future<List<WorkoutSession>> getUpcomingWorkouts({int limit = 7}) async => [];
  // @override
  // Future<void> createProgramCycleWithSessions(ProgramCycle cycle) async {}
  // @override
  // Future<void> deleteProgramCycle(String cycleId) async {}
  // @override
  // Future<void> updateProgramCycle(ProgramCycle cycle) async {}
  // @override
  // Future<List<ProgramCycle>> getActiveProgramCycles() async => [];
  // @override
  // Future<void> completeProgramCycle(String cycleId) async {}
  @override
  Future<List<WorkoutSession>> getCompletedSessions({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    int offset = 0,
  }) async => [];

  @override
  Future<List<Program>> getProgramsBySource({
    ProgramSource source = ProgramSource.all,
  }) async => [];

  @override
  Future<List<Program>> getDefaultPrograms() async => [];

  @override
  Future<List<Program>> getCustomPrograms() async => [];

  @override
  Future<List<Program>> getRecentPrograms({int limit = 5}) async => [];

  @override
  Future<ProgramCycle?> getActiveCycle() async => null;

  @override
  Future<void> endActiveCycle() async {}

  @override
  Future<ProgramCycle> startNewCycle(String programId) async {
    throw UnimplementedError('Not needed for workout service tests');
  }

  @override
  Future<Program> copyProgramAsCustom(Program template) async {
    throw UnimplementedError('Not needed for workout service tests');
  }

  @override
  Future<Program?> getUserCopyOfProgram(String templateId) async => null;

  @override
  Future<void> publishProgram(String programId) async {}

  @override
  Future<Program> importProgram(Program program) async {
    throw UnimplementedError('Not needed for workout service tests');
  }
}

/// Helper to create test exercises
Exercise createTestExercise({
  String? id,
  String name = 'Test Exercise',
  ExerciseCategory category = ExerciseCategory.strength,
}) {
  return Exercise(
    id: id ?? 'exercise-${DateTime.now().microsecondsSinceEpoch}',
    name: name,
    category: category,
    targetMuscleGroups: [MuscleGroup.chest],
    defaultSets: 3,
    defaultReps: 10,
  );
}

/// Helper to create test workout exercises
WorkoutExercise createTestWorkoutExercise({
  String? id,
  String exerciseName = 'Test Exercise',
  int setCount = 3,
}) {
  return WorkoutExercise(
    id: id ?? 'workout-exercise-${DateTime.now().microsecondsSinceEpoch}',
    exercise: createTestExercise(name: exerciseName),
    sets: List.generate(setCount, (_) => ExerciseSet.create(targetReps: 10)),
  );
}

/// Helper to create test workout sessions
WorkoutSession createTestWorkoutSession({
  String? id,
  List<WorkoutExercise>? exercises,
}) {
  return WorkoutSession(
    id: id ?? 'session-${DateTime.now().microsecondsSinceEpoch}',
    date: DateTime.now(),
    exercises: exercises ?? [],
    programName: 'Test Program',
  );
}

void main() {
  late MockProgramRepository mockRepository;
  late WorkoutService workoutService;

  setUpAll(() async {
    // Initialize SharedPreferences for tests
    SharedPreferences.setMockInitialValues({});

    // Initialize AppSettingsService and LoggingService
    final appSettingsService = AppSettingsService();
    await appSettingsService.init();
    await LoggingService.init(appSettingsService);
  });

  setUp(() {
    mockRepository = MockProgramRepository();
    workoutService = WorkoutService(mockRepository);
  });

  tearDown(() {
    workoutService.dispose();
  });

  group('WorkoutService', () {
    group('addExercise', () {
      test('adds exercise to empty workout session', () async {
        // Arrange
        final session = createTestWorkoutSession(exercises: []);
        await workoutService.startWorkout(session);

        final newExercise = createTestWorkoutExercise(
          exerciseName: 'Bench Press',
        );

        // Act
        workoutService.addExercise(newExercise);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises.first.exercise.name,
          equals('Bench Press'),
        );
      });

      test('appends exercise to existing exercises list', () async {
        // Arrange
        final existingExercise = createTestWorkoutExercise(
          exerciseName: 'Squat',
        );
        final session = createTestWorkoutSession(exercises: [existingExercise]);
        await workoutService.startWorkout(session);

        final newExercise = createTestWorkoutExercise(exerciseName: 'Deadlift');

        // Act
        workoutService.addExercise(newExercise);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(2));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Squat'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('Deadlift'),
        );
      });

      test('handles workout with const empty list', () async {
        // Arrange - WorkoutSession uses const [] by default
        final session = WorkoutSession(
          id: 'test-session',
          date: DateTime.now(),
          // exercises defaults to const []
        );
        await workoutService.startWorkout(session);

        final newExercise = createTestWorkoutExercise(
          exerciseName: 'Overhead Press',
        );

        // Act - This should not throw despite const list
        workoutService.addExercise(newExercise);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises.first.exercise.name,
          equals('Overhead Press'),
        );
      });

      test('does nothing when no current workout', () {
        // Arrange
        final exercise = createTestWorkoutExercise();

        // Act - Should not throw
        workoutService.addExercise(exercise);

        // Assert
        expect(workoutService.currentWorkout, isNull);
      });

      test('preserves existing exercise data when adding', () async {
        // Arrange
        final existingExercise = createTestWorkoutExercise(
          exerciseName: 'Bench Press',
          setCount: 4,
        );
        final session = createTestWorkoutSession(exercises: [existingExercise]);
        await workoutService.startWorkout(session);

        final newExercise = createTestWorkoutExercise(
          exerciseName: 'Incline Press',
          setCount: 3,
        );

        // Act
        workoutService.addExercise(newExercise);

        // Assert - Original exercise should be unchanged
        final originalExercise = workoutService.currentWorkout!.exercises[0];
        expect(originalExercise.sets.length, equals(4));
        expect(originalExercise.exercise.name, equals('Bench Press'));
      });

      test('can add multiple exercises sequentially', () async {
        // Arrange
        final session = createTestWorkoutSession(exercises: []);
        await workoutService.startWorkout(session);

        // Act
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'Exercise 1'),
        );
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'Exercise 2'),
        );
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'Exercise 3'),
        );

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(3));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Exercise 1'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('Exercise 2'),
        );
        expect(
          workoutService.currentWorkout!.exercises[2].exercise.name,
          equals('Exercise 3'),
        );
      });
    });

    group('removeExerciseAt', () {
      test('removes exercise at valid index', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Exercise 1'),
          createTestWorkoutExercise(exerciseName: 'Exercise 2'),
          createTestWorkoutExercise(exerciseName: 'Exercise 3'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        // Act
        workoutService.removeExerciseAt(1);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(2));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Exercise 1'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('Exercise 3'),
        );
      });

      test('removes first exercise (index 0)', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'First'),
          createTestWorkoutExercise(exerciseName: 'Second'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        // Act
        workoutService.removeExerciseAt(0);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Second'),
        );
      });

      test('removes last exercise', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'First'),
          createTestWorkoutExercise(exerciseName: 'Last'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        // Act
        workoutService.removeExerciseAt(1);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('First'),
        );
      });

      test('handles removal of only exercise', () async {
        // Arrange
        final exercises = [createTestWorkoutExercise(exerciseName: 'Only')];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        // Act
        workoutService.removeExerciseAt(0);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(0));
        expect(workoutService.currentWorkout!.exercises.isEmpty, isTrue);
      });

      test('does nothing for negative index', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Exercise 1'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        // Act
        workoutService.removeExerciseAt(-1);

        // Assert - List should be unchanged
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
      });

      test('does nothing for index out of bounds', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Exercise 1'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        // Act
        workoutService.removeExerciseAt(5);

        // Assert - List should be unchanged
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
      });

      test('does nothing for index equal to list length', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Exercise 1'),
          createTestWorkoutExercise(exerciseName: 'Exercise 2'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        // Act
        workoutService.removeExerciseAt(
          2,
        ); // Length is 2, so index 2 is invalid

        // Assert - List should be unchanged
        expect(workoutService.currentWorkout!.exercises.length, equals(2));
      });

      test('does nothing when no current workout', () {
        // Act - Should not throw
        workoutService.removeExerciseAt(0);

        // Assert
        expect(workoutService.currentWorkout, isNull);
      });

      test('handles workout with const empty list gracefully', () async {
        // Arrange
        final session = WorkoutSession(
          id: 'test-session',
          date: DateTime.now(),
          // exercises defaults to const []
        );
        await workoutService.startWorkout(session);

        // Act - Should not throw
        workoutService.removeExerciseAt(0);

        // Assert
        expect(workoutService.currentWorkout!.exercises.isEmpty, isTrue);
      });
    });

    group('swapExercise', () {
      test('swaps exercise at valid index', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Original'),
          createTestWorkoutExercise(exerciseName: 'Keep This'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'Replacement',
        );

        // Act
        workoutService.swapExercise(0, replacementExercise);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(2));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Replacement'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('Keep This'),
        );
      });

      test('swaps last exercise in list', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'First'),
          createTestWorkoutExercise(exerciseName: 'Original Last'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'New Last',
        );

        // Act
        workoutService.swapExercise(1, replacementExercise);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(2));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('First'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('New Last'),
        );
      });

      test('swaps middle exercise preserving order', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'First'),
          createTestWorkoutExercise(exerciseName: 'Middle'),
          createTestWorkoutExercise(exerciseName: 'Last'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'New Middle',
        );

        // Act
        workoutService.swapExercise(1, replacementExercise);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(3));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('First'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('New Middle'),
        );
        expect(
          workoutService.currentWorkout!.exercises[2].exercise.name,
          equals('Last'),
        );
      });

      test('does nothing for negative index', () async {
        // Arrange
        final exercises = [createTestWorkoutExercise(exerciseName: 'Original')];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'Replacement',
        );

        // Act
        workoutService.swapExercise(-1, replacementExercise);

        // Assert - List should be unchanged
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Original'),
        );
      });

      test('does nothing for index out of bounds', () async {
        // Arrange
        final exercises = [createTestWorkoutExercise(exerciseName: 'Original')];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'Replacement',
        );

        // Act
        workoutService.swapExercise(5, replacementExercise);

        // Assert - List should be unchanged
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Original'),
        );
      });

      test('does nothing for index equal to list length', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Exercise 1'),
          createTestWorkoutExercise(exerciseName: 'Exercise 2'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'Replacement',
        );

        // Act
        workoutService.swapExercise(2, replacementExercise);

        // Assert - List should be unchanged
        expect(workoutService.currentWorkout!.exercises.length, equals(2));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Exercise 1'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('Exercise 2'),
        );
      });

      test('does nothing when no current workout', () {
        // Arrange
        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'Replacement',
        );

        // Act - Should not throw
        workoutService.swapExercise(0, replacementExercise);

        // Assert
        expect(workoutService.currentWorkout, isNull);
      });

      test('handles workout with const empty list gracefully', () async {
        // Arrange
        final session = WorkoutSession(
          id: 'test-session',
          date: DateTime.now(),
          // exercises defaults to const []
        );
        await workoutService.startWorkout(session);

        final replacementExercise = createTestWorkoutExercise(
          exerciseName: 'Replacement',
        );

        // Act - Should not throw even for empty list
        workoutService.swapExercise(0, replacementExercise);

        // Assert
        expect(workoutService.currentWorkout!.exercises.isEmpty, isTrue);
      });

      test('preserves replacement exercise properties', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Original', setCount: 3),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);

        final replacementExercise = WorkoutExercise(
          id: 'replacement-id',
          exercise: createTestExercise(
            name: 'Replacement',
            category: ExerciseCategory.cardio,
          ),
          sets: List.generate(5, (_) => ExerciseSet.create(targetReps: 8)),
          restTime: const Duration(seconds: 90),
          notes: 'Special notes',
        );

        // Act
        workoutService.swapExercise(0, replacementExercise);

        // Assert
        final swappedExercise = workoutService.currentWorkout!.exercises[0];
        expect(swappedExercise.id, equals('replacement-id'));
        expect(swappedExercise.exercise.name, equals('Replacement'));
        expect(
          swappedExercise.exercise.category,
          equals(ExerciseCategory.cardio),
        );
        expect(swappedExercise.sets.length, equals(5));
        expect(swappedExercise.restTime, equals(const Duration(seconds: 90)));
        expect(swappedExercise.notes, equals('Special notes'));
      });
    });

    group('immutability patterns', () {
      test('addExercise creates new exercises list reference', () async {
        // Arrange
        final session = createTestWorkoutSession(exercises: []);
        await workoutService.startWorkout(session);
        final originalWorkout = workoutService.currentWorkout;

        // Act
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'New Exercise'),
        );

        // Assert - currentWorkout should be a new instance
        expect(
          identical(workoutService.currentWorkout, originalWorkout),
          isFalse,
        );
      });

      test('removeExerciseAt creates new exercises list reference', () async {
        // Arrange
        final exercises = [
          createTestWorkoutExercise(exerciseName: 'Exercise 1'),
        ];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);
        final originalWorkout = workoutService.currentWorkout;

        // Act
        workoutService.removeExerciseAt(0);

        // Assert - currentWorkout should be a new instance
        expect(
          identical(workoutService.currentWorkout, originalWorkout),
          isFalse,
        );
      });

      test('swapExercise creates new exercises list reference', () async {
        // Arrange
        final exercises = [createTestWorkoutExercise(exerciseName: 'Original')];
        final session = createTestWorkoutSession(exercises: exercises);
        await workoutService.startWorkout(session);
        final originalWorkout = workoutService.currentWorkout;

        // Act
        workoutService.swapExercise(
          0,
          createTestWorkoutExercise(exerciseName: 'Replacement'),
        );

        // Assert - currentWorkout should be a new instance
        expect(
          identical(workoutService.currentWorkout, originalWorkout),
          isFalse,
        );
      });
    });

    group('combined operations', () {
      test('add then remove maintains correct state', () async {
        // Arrange
        final session = createTestWorkoutSession(exercises: []);
        await workoutService.startWorkout(session);

        // Act
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'First'),
        );
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'Second'),
        );
        workoutService.removeExerciseAt(0);

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Second'),
        );
      });

      test('add then swap maintains correct state', () async {
        // Arrange
        final session = createTestWorkoutSession(exercises: []);
        await workoutService.startWorkout(session);

        // Act
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'Original'),
        );
        workoutService.swapExercise(
          0,
          createTestWorkoutExercise(exerciseName: 'Swapped'),
        );

        // Assert
        expect(workoutService.currentWorkout!.exercises.length, equals(1));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('Swapped'),
        );
      });

      test('complex sequence of operations', () async {
        // Arrange
        final session = createTestWorkoutSession(exercises: []);
        await workoutService.startWorkout(session);

        // Act - Complex sequence
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'A'),
        );
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'B'),
        );
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'C'),
        );
        workoutService.swapExercise(
          1,
          createTestWorkoutExercise(exerciseName: 'B-Replaced'),
        );
        workoutService.removeExerciseAt(0);
        workoutService.addExercise(
          createTestWorkoutExercise(exerciseName: 'D'),
        );

        // Assert - Final state: B-Replaced, C, D
        expect(workoutService.currentWorkout!.exercises.length, equals(3));
        expect(
          workoutService.currentWorkout!.exercises[0].exercise.name,
          equals('B-Replaced'),
        );
        expect(
          workoutService.currentWorkout!.exercises[1].exercise.name,
          equals('C'),
        );
        expect(
          workoutService.currentWorkout!.exercises[2].exercise.name,
          equals('D'),
        );
      });
    });
  });
}
