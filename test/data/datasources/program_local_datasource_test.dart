import 'package:flutter_lifter/data/datasources/local/program_local_datasource.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgramLocalDataSource', () {
    late ProgramLocalDataSource datasource;

    setUp(() {
      // Use InMemoryProgramLocalDataSource for tests to avoid Hive dependency
      // Each instance has its own cache for test isolation
      datasource = InMemoryProgramLocalDataSource();
    });

    /// Creates a test program with required fields
    Program createTestProgram({
      required String id,
      required String name,
      ProgramDifficulty difficulty = ProgramDifficulty.beginner,
      ProgramType type = ProgramType.strength,
    }) {
      return Program(
        id: id,
        name: name,
        type: type,
        difficulty: difficulty,
        createdAt: DateTime.now(),
      );
    }

    /// Creates a test exercise for use in WorkoutExercise
    Exercise createTestExercise({required String id, required String name}) {
      return Exercise(
        id: id,
        name: name,
        category: ExerciseCategory.strength,
        targetMuscleGroups: [MuscleGroup.chest],
        defaultSets: 3,
        defaultReps: 10,
      );
    }

    // =========================================================================
    // Program Cache Tests
    // =========================================================================

    group('Program Cache', () {
      late Program testProgram;

      setUp(() {
        testProgram = createTestProgram(
          id: 'test_program_1',
          name: 'Test Program',
        );
      });

      test('cacheProgram should store a program', () async {
        await datasource.cacheProgram(testProgram);

        final programs = await datasource.getCachedPrograms();
        expect(programs.length, equals(1));
        expect(programs.first.id, equals('test_program_1'));
        expect(programs.first.name, equals('Test Program'));
      });

      test('cacheProgram should update existing program', () async {
        await datasource.cacheProgram(testProgram);

        final updated = testProgram.copyWith(name: 'Updated Program');
        await datasource.cacheProgram(updated);

        final programs = await datasource.getCachedPrograms();
        expect(programs.length, equals(1));
        expect(programs.first.name, equals('Updated Program'));
      });

      test('cachePrograms should replace all programs', () async {
        await datasource.cacheProgram(testProgram);

        final newPrograms = <Program>[
          createTestProgram(
            id: 'new_1',
            name: 'New Program 1',
            difficulty: ProgramDifficulty.intermediate,
          ),
          createTestProgram(
            id: 'new_2',
            name: 'New Program 2',
            difficulty: ProgramDifficulty.advanced,
          ),
        ];

        await datasource.cachePrograms(newPrograms);

        final programs = await datasource.getCachedPrograms();
        expect(programs.length, equals(2));
        expect(programs.any((p) => p.id == 'test_program_1'), isFalse);
        expect(programs.any((p) => p.id == 'new_1'), isTrue);
        expect(programs.any((p) => p.id == 'new_2'), isTrue);
      });

      test('getCachedProgramById should return program when exists', () async {
        await datasource.cacheProgram(testProgram);

        final result = await datasource.getCachedProgramById('test_program_1');
        expect(result, isNotNull);
        expect(result!.id, equals('test_program_1'));
      });

      test('getCachedProgramById should return null when not found', () async {
        final result = await datasource.getCachedProgramById('nonexistent');
        expect(result, isNull);
      });

      test('removeCachedProgram should delete program', () async {
        await datasource.cacheProgram(testProgram);
        await datasource.removeCachedProgram('test_program_1');

        final programs = await datasource.getCachedPrograms();
        expect(programs.isEmpty, isTrue);
      });

      test('clearCache should remove all programs', () async {
        await datasource.cachePrograms([
          testProgram,
          createTestProgram(id: 'test_2', name: 'Test 2'),
        ]);

        await datasource.clearCache();

        final programs = await datasource.getCachedPrograms();
        expect(programs.isEmpty, isTrue);
      });

      test('getLastCacheUpdate should return null initially', () async {
        final lastUpdate = await datasource.getLastCacheUpdate();
        expect(lastUpdate, isNull);
      });

      test(
        'getLastCacheUpdate should return timestamp after caching',
        () async {
          final before = DateTime.now();
          await datasource.cacheProgram(testProgram);
          final after = DateTime.now();

          final lastUpdate = await datasource.getLastCacheUpdate();
          expect(lastUpdate, isNotNull);
          expect(
            lastUpdate!.isAfter(before.subtract(const Duration(seconds: 1))),
            isTrue,
          );
          expect(
            lastUpdate.isBefore(after.add(const Duration(seconds: 1))),
            isTrue,
          );
        },
      );

      test('isCacheExpired should return true when no cache exists', () async {
        final expired = await datasource.isCacheExpired();
        expect(expired, isTrue);
      });

      test('isCacheExpired should return false for fresh cache', () async {
        await datasource.cacheProgram(testProgram);

        final expired = await datasource.isCacheExpired(
          maxAge: const Duration(minutes: 5),
        );
        expect(expired, isFalse);
      });
    });

    // =========================================================================
    // Workout Session Tests
    // =========================================================================

    group('Workout Sessions', () {
      late WorkoutSession testSession;

      setUp(() {
        testSession = WorkoutSession(
          id: 'session_1',
          programId: 'prog_1',
          programName: 'Test Program',
          date: DateTime(2026, 1, 18),
          exercises: [],
        );
      });

      group('saveWorkoutSession', () {
        test('should save a new workout session', () async {
          await datasource.saveWorkoutSession(testSession);

          final retrieved = await datasource.getWorkoutSessionById('session_1');
          expect(retrieved, isNotNull);
          expect(retrieved!.id, equals('session_1'));
          expect(retrieved.programId, equals('prog_1'));
          expect(retrieved.programName, equals('Test Program'));
        });

        test('should update an existing workout session', () async {
          await datasource.saveWorkoutSession(testSession);

          final updated = testSession.copyWith(
            programName: 'Updated Program Name',
            notes: 'Added notes',
          );
          await datasource.saveWorkoutSession(updated);

          final retrieved = await datasource.getWorkoutSessionById('session_1');
          expect(retrieved, isNotNull);
          expect(retrieved!.programName, equals('Updated Program Name'));
          expect(retrieved.notes, equals('Added notes'));

          // Should still be only one session
          final all = await datasource.getAllWorkoutSessions();
          expect(all.length, equals(1));
        });

        test('should save session with exercises', () async {
          final exercise = createTestExercise(id: 'ex_1', name: 'Squat');
          final sessionWithExercises = WorkoutSession(
            id: 'session_with_exercises',
            programId: 'prog_1',
            programName: 'Test Program',
            date: DateTime(2026, 1, 18),
            exercises: [
              WorkoutExercise(
                id: 'we_1',
                exercise: exercise,
                sets: [
                  ExerciseSet(
                    id: 'set_1',
                    targetReps: 5,
                    actualReps: 5,
                    targetWeight: 100,
                    actualWeight: 100,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          );

          await datasource.saveWorkoutSession(sessionWithExercises);

          final retrieved = await datasource.getWorkoutSessionById(
            'session_with_exercises',
          );
          expect(retrieved, isNotNull);
          expect(retrieved!.exercises.length, equals(1));
          expect(retrieved.exercises.first.name, equals('Squat'));
          expect(retrieved.exercises.first.sets.length, equals(1));
          expect(
            retrieved.exercises.first.sets.first.actualWeight,
            equals(100),
          );
        });

        test('should save session with timing info', () async {
          final sessionWithTiming = WorkoutSession(
            id: 'session_with_timing',
            programId: 'prog_1',
            programName: 'Test Program',
            date: DateTime(2026, 1, 18),
            startTime: DateTime(2026, 1, 18, 9, 0),
            endTime: DateTime(2026, 1, 18, 10, 30),
            exercises: [],
          );

          await datasource.saveWorkoutSession(sessionWithTiming);

          final retrieved = await datasource.getWorkoutSessionById(
            'session_with_timing',
          );
          expect(retrieved, isNotNull);
          expect(retrieved!.startTime, equals(DateTime(2026, 1, 18, 9, 0)));
          expect(retrieved.endTime, equals(DateTime(2026, 1, 18, 10, 30)));
        });

        test('should save multiple sessions', () async {
          await datasource.saveWorkoutSession(testSession);
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_2',
              programId: 'prog_1',
              programName: 'Test Program',
              date: DateTime(2026, 1, 19),
              exercises: [],
            ),
          );
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_3',
              programId: 'prog_2',
              programName: 'Another Program',
              date: DateTime(2026, 1, 20),
              exercises: [],
            ),
          );

          final all = await datasource.getAllWorkoutSessions();
          expect(all.length, equals(3));
        });
      });

      group('getWorkoutSessionById', () {
        test('should return session when exists', () async {
          await datasource.saveWorkoutSession(testSession);

          final result = await datasource.getWorkoutSessionById('session_1');
          expect(result, isNotNull);
          expect(result!.id, equals('session_1'));
        });

        test('should return null when session does not exist', () async {
          final result = await datasource.getWorkoutSessionById('nonexistent');
          expect(result, isNull);
        });

        test('should return correct session among multiple', () async {
          await datasource.saveWorkoutSession(testSession);
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_2',
              programId: 'prog_2',
              programName: 'Other Program',
              date: DateTime(2026, 1, 19),
              exercises: [],
            ),
          );

          final result = await datasource.getWorkoutSessionById('session_2');
          expect(result, isNotNull);
          expect(result!.programName, equals('Other Program'));
        });

        test('should preserve date correctly', () async {
          final sessionDate = DateTime(2026, 6, 15, 14, 30, 45);
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'date_test',
              programId: 'prog_1',
              programName: 'Test',
              date: sessionDate,
              exercises: [],
            ),
          );

          final retrieved = await datasource.getWorkoutSessionById('date_test');
          expect(retrieved!.date, equals(sessionDate));
        });
      });

      group('getAllWorkoutSessions', () {
        test('should return empty list when no sessions', () async {
          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions, isEmpty);
        });

        test('should return all saved sessions', () async {
          await datasource.saveWorkoutSession(testSession);
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_2',
              date: DateTime(2026, 1, 19),
              exercises: [],
            ),
          );
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_3',
              date: DateTime(2026, 1, 20),
              exercises: [],
            ),
          );

          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions.length, equals(3));
          expect(sessions.any((s) => s.id == 'session_1'), isTrue);
          expect(sessions.any((s) => s.id == 'session_2'), isTrue);
          expect(sessions.any((s) => s.id == 'session_3'), isTrue);
        });

        test('should return sessions with complete data', () async {
          final exercise = createTestExercise(id: 'ex_1', name: 'Bench Press');
          final fullSession = WorkoutSession(
            id: 'full_session',
            programId: 'prog_1',
            programName: 'Full Program',
            date: DateTime(2026, 1, 18),
            startTime: DateTime(2026, 1, 18, 9, 0),
            endTime: DateTime(2026, 1, 18, 10, 0),
            notes: 'Great workout!',
            exercises: [
              WorkoutExercise(
                id: 'we_1',
                exercise: exercise,
                sets: [
                  ExerciseSet(
                    id: 'set_1',
                    targetReps: 5,
                    actualReps: 5,
                    targetWeight: 80,
                    actualWeight: 80,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          );

          await datasource.saveWorkoutSession(fullSession);

          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions.length, equals(1));

          final retrieved = sessions.first;
          expect(retrieved.programId, equals('prog_1'));
          expect(retrieved.programName, equals('Full Program'));
          expect(retrieved.notes, equals('Great workout!'));
          expect(retrieved.exercises.length, equals(1));
        });
      });

      group('deleteWorkoutSession', () {
        test('should delete an existing session', () async {
          await datasource.saveWorkoutSession(testSession);

          await datasource.deleteWorkoutSession('session_1');

          final retrieved = await datasource.getWorkoutSessionById('session_1');
          expect(retrieved, isNull);
        });

        test('should not throw when deleting non-existent session', () async {
          // Should not throw
          await datasource.deleteWorkoutSession('nonexistent');

          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions, isEmpty);
        });

        test('should only delete specified session', () async {
          await datasource.saveWorkoutSession(testSession);
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_2',
              date: DateTime(2026, 1, 19),
              exercises: [],
            ),
          );
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_3',
              date: DateTime(2026, 1, 20),
              exercises: [],
            ),
          );

          await datasource.deleteWorkoutSession('session_2');

          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions.length, equals(2));
          expect(sessions.any((s) => s.id == 'session_1'), isTrue);
          expect(sessions.any((s) => s.id == 'session_2'), isFalse);
          expect(sessions.any((s) => s.id == 'session_3'), isTrue);
        });
      });

      group('clearWorkoutSessions', () {
        test('should remove all sessions', () async {
          await datasource.saveWorkoutSession(testSession);
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_2',
              date: DateTime(2026, 1, 19),
              exercises: [],
            ),
          );
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'session_3',
              date: DateTime(2026, 1, 20),
              exercises: [],
            ),
          );

          await datasource.clearWorkoutSessions();

          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions, isEmpty);
        });

        test('should not throw when clearing empty storage', () async {
          // Should not throw
          await datasource.clearWorkoutSessions();

          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions, isEmpty);
        });

        test('should not affect program cache', () async {
          // Cache a program
          await datasource.cacheProgram(
            createTestProgram(id: 'prog_1', name: 'Test Program'),
          );

          // Add and clear workout sessions
          await datasource.saveWorkoutSession(testSession);
          await datasource.clearWorkoutSessions();

          // Program should still exist
          final programs = await datasource.getCachedPrograms();
          expect(programs.length, equals(1));
          expect(programs.first.id, equals('prog_1'));
        });
      });

      group('data isolation', () {
        test('programs and sessions should be stored independently', () async {
          // Store program and session with same ID (edge case)
          await datasource.cacheProgram(
            createTestProgram(id: 'same_id', name: 'Program'),
          );
          await datasource.saveWorkoutSession(
            WorkoutSession(
              id: 'same_id',
              date: DateTime(2026, 1, 18),
              exercises: [],
            ),
          );

          // Both should exist independently
          final program = await datasource.getCachedProgramById('same_id');
          final session = await datasource.getWorkoutSessionById('same_id');

          expect(program, isNotNull);
          expect(session, isNotNull);
          expect(program!.name, equals('Program'));
        });

        test('clearing programs should not affect sessions', () async {
          await datasource.cacheProgram(
            createTestProgram(id: 'prog_1', name: 'Test Program'),
          );
          await datasource.saveWorkoutSession(testSession);

          await datasource.clearCache();

          // Session should still exist
          final session = await datasource.getWorkoutSessionById('session_1');
          expect(session, isNotNull);

          // Program should be gone
          final programs = await datasource.getCachedPrograms();
          expect(programs, isEmpty);
        });
      });

      group('edge cases', () {
        test('should handle session with empty exercises list', () async {
          final emptySession = WorkoutSession(
            id: 'empty_exercises',
            date: DateTime(2026, 1, 18),
            exercises: [],
          );

          await datasource.saveWorkoutSession(emptySession);

          final retrieved = await datasource.getWorkoutSessionById(
            'empty_exercises',
          );
          expect(retrieved, isNotNull);
          expect(retrieved!.exercises, isEmpty);
        });

        test('should handle session with null optional fields', () async {
          final minimalSession = WorkoutSession(
            id: 'minimal',
            date: DateTime(2026, 1, 18),
          );

          await datasource.saveWorkoutSession(minimalSession);

          final retrieved = await datasource.getWorkoutSessionById('minimal');
          expect(retrieved, isNotNull);
          expect(retrieved!.programId, isNull);
          expect(retrieved.programName, isNull);
          expect(retrieved.notes, isNull);
          expect(retrieved.startTime, isNull);
          expect(retrieved.endTime, isNull);
        });

        test('should handle large number of sessions', () async {
          const count = 100;
          for (var i = 0; i < count; i++) {
            await datasource.saveWorkoutSession(
              WorkoutSession(
                id: 'session_$i',
                date: DateTime(2026, 1, 1).add(Duration(days: i)),
                exercises: [],
              ),
            );
          }

          final sessions = await datasource.getAllWorkoutSessions();
          expect(sessions.length, equals(count));
        });

        test('should handle session with complex exercise data', () async {
          final squat = createTestExercise(id: 'ex_squat', name: 'Squat');
          final bench = createTestExercise(id: 'ex_bench', name: 'Bench Press');

          final complexSession = WorkoutSession(
            id: 'complex',
            programId: 'prog_1',
            programName: 'Complex Program',
            date: DateTime(2026, 1, 18),
            exercises: [
              WorkoutExercise(
                id: 'we_1',
                exercise: squat,
                notes: 'Felt strong today',
                sets: [
                  ExerciseSet(
                    id: 'set_1',
                    targetReps: 5,
                    actualReps: 5,
                    targetWeight: 100,
                    actualWeight: 100,
                    isCompleted: true,
                    notes: 'Warmup',
                  ),
                  ExerciseSet(
                    id: 'set_2',
                    targetReps: 5,
                    actualReps: 5,
                    targetWeight: 120,
                    actualWeight: 120,
                    isCompleted: true,
                  ),
                  ExerciseSet(
                    id: 'set_3',
                    targetReps: 5,
                    actualReps: 4,
                    targetWeight: 140,
                    actualWeight: 140,
                    isCompleted: true,
                    notes: 'Failed last rep',
                  ),
                ],
              ),
              WorkoutExercise(
                id: 'we_2',
                exercise: bench,
                sets: [
                  ExerciseSet(
                    id: 'set_4',
                    targetReps: 8,
                    actualReps: 8,
                    targetWeight: 60,
                    actualWeight: 60,
                    isCompleted: true,
                  ),
                ],
              ),
            ],
          );

          await datasource.saveWorkoutSession(complexSession);

          final retrieved = await datasource.getWorkoutSessionById('complex');
          expect(retrieved, isNotNull);
          expect(retrieved!.exercises.length, equals(2));
          expect(retrieved.exercises[0].sets.length, equals(3));
          expect(retrieved.exercises[0].notes, equals('Felt strong today'));
          expect(
            retrieved.exercises[0].sets[2].notes,
            equals('Failed last rep'),
          );
        });
      });
    });

    // =========================================================================
    // Instance Isolation Tests
    // =========================================================================

    group('Instance Isolation', () {
      test('separate instances should have independent caches', () async {
        final datasource1 = InMemoryProgramLocalDataSource();
        final datasource2 = InMemoryProgramLocalDataSource();

        await datasource1.saveWorkoutSession(
          WorkoutSession(
            id: 'session_1',
            date: DateTime(2026, 1, 18),
            exercises: [],
          ),
        );

        final sessions1 = await datasource1.getAllWorkoutSessions();
        final sessions2 = await datasource2.getAllWorkoutSessions();

        expect(sessions1.length, equals(1));
        expect(sessions2.length, equals(0));
      });

      test(
        'separate instances should have independent program caches',
        () async {
          final datasource1 = InMemoryProgramLocalDataSource();
          final datasource2 = InMemoryProgramLocalDataSource();

          await datasource1.cacheProgram(
            createTestProgram(id: 'prog_1', name: 'Program 1'),
          );

          final programs1 = await datasource1.getCachedPrograms();
          final programs2 = await datasource2.getCachedPrograms();

          expect(programs1.length, equals(1));
          expect(programs2.length, equals(0));
        },
      );
    });
  });
}
