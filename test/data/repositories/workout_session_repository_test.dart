import 'package:flutter_lifter/data/datasources/local/program_local_datasource.dart';
import 'package:flutter_lifter/data/datasources/mock/mock_program_datasource.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/services/app_settings_service.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WorkoutSession Repository Persistence', () {
    late ProgramRepository repository;

    setUpAll(() async {
      // Initialize SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});

      // Initialize AppSettingsService and LoggingService
      final appSettingsService = AppSettingsService();
      await appSettingsService.init();
      await LoggingService.init(appSettingsService);

      // Initialize Hive for testing (use unique directory to avoid conflicts)
      Hive.init('./test_hive_workout_sessions');
      await HiveStorageService.initializeBoxes();
    });

    setUp(() async {
      // Clear workout sessions before each test
      await HiveStorageService.clearWorkoutSessions();

      // Create repository that uses Hive storage via localDataSource
      repository = ProgramRepositoryImpl(
        mockDataSource: MockProgramDataSource(),
        localDataSource: ProgramLocalDataSourceImpl(),
        useMockData: true,
        useRemoteApi: false,
      );
    });

    tearDownAll(() async {
      await HiveStorageService.clearWorkoutSessions();
      await HiveStorageService.closeBoxes();
    });

    group('saveWorkoutSession', () {
      test('should save a workout session to Hive', () async {
        final session = WorkoutSession(
          id: 'test_session_1',
          programId: 'prog1',
          programName: 'Test Program',
          date: DateTime(2026, 1, 18),
          exercises: [],
        );

        await repository.saveWorkoutSession(session);

        // Verify it was saved to Hive
        final storedJson = HiveStorageService.getWorkoutSession(
          'test_session_1',
        );
        expect(storedJson, isNotNull);
        expect(storedJson!['id'], equals('test_session_1'));
        expect(storedJson['programId'], equals('prog1'));
        expect(storedJson['programName'], equals('Test Program'));
      });

      test('should update an existing workout session', () async {
        final session = WorkoutSession(
          id: 'test_session_update',
          programId: 'prog1',
          programName: 'Original Name',
          date: DateTime(2026, 1, 18),
          notes: 'Original notes',
        );

        await repository.saveWorkoutSession(session);

        // Update the session
        final updatedSession = session.copyWith(
          programName: 'Updated Name',
          notes: 'Updated notes',
        );
        await repository.saveWorkoutSession(updatedSession);

        // Verify the update
        final storedJson = HiveStorageService.getWorkoutSession(
          'test_session_update',
        );
        expect(storedJson!['programName'], equals('Updated Name'));
        expect(storedJson['notes'], equals('Updated notes'));
      });

      test('should save workout session with timing info', () async {
        final startTime = DateTime(2026, 1, 18, 10, 0);
        final endTime = DateTime(2026, 1, 18, 11, 30);

        final session = WorkoutSession(
          id: 'timed_session',
          date: DateTime(2026, 1, 18),
          startTime: startTime,
          endTime: endTime,
        );

        await repository.saveWorkoutSession(session);

        final storedJson = HiveStorageService.getWorkoutSession(
          'timed_session',
        );
        expect(storedJson, isNotNull);
        expect(storedJson!['startTime'], equals(startTime.toIso8601String()));
        expect(storedJson['endTime'], equals(endTime.toIso8601String()));
      });

      test('should save workout session with exercises array', () async {
        // Directly store JSON to test raw storage functionality
        final sessionJson = {
          'id': 'session_with_exercises',
          'programId': 'prog1',
          'date': DateTime(2026, 1, 18).toIso8601String(),
          'exercises': [
            {
              'id': 'we1',
              'exercise': {
                'id': 'ex1',
                'name': 'Bench Press',
                'category': 'chest',
                'isDefault': true,
              },
              'sets': [
                {
                  'id': 's1',
                  'targetWeight': 135.0,
                  'targetReps': 10,
                  'isCompleted': true,
                },
              ],
            },
          ],
        };

        await HiveStorageService.storeWorkoutSession(
          'session_with_exercises',
          sessionJson,
        );

        final storedJson = HiveStorageService.getWorkoutSession(
          'session_with_exercises',
        );
        expect(storedJson, isNotNull);
        expect(storedJson!['exercises'], isA<List>());
        expect((storedJson['exercises'] as List).length, equals(1));
      });
    });

    group('getWorkoutSessionById', () {
      test('should retrieve a saved workout session', () async {
        final session = WorkoutSession(
          id: 'retrieve_test',
          programId: 'prog1',
          programName: 'Test Program',
          date: DateTime(2026, 1, 18),
          notes: 'Test notes',
        );

        await repository.saveWorkoutSession(session);
        final retrieved = await repository.getWorkoutSessionById(
          'retrieve_test',
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('retrieve_test'));
        expect(retrieved.programId, equals('prog1'));
        expect(retrieved.programName, equals('Test Program'));
        expect(retrieved.notes, equals('Test notes'));
      });

      test('should return null for non-existent session', () async {
        final retrieved = await repository.getWorkoutSessionById(
          'non_existent_session',
        );
        expect(retrieved, isNull);
      });

      test('should retrieve session date correctly', () async {
        final sessionDate = DateTime(2026, 1, 18, 14, 30);
        final session = WorkoutSession(id: 'date_test', date: sessionDate);

        await repository.saveWorkoutSession(session);
        final retrieved = await repository.getWorkoutSessionById('date_test');

        expect(retrieved, isNotNull);
        expect(retrieved!.date.year, equals(2026));
        expect(retrieved.date.month, equals(1));
        expect(retrieved.date.day, equals(18));
      });
    });

    group('getWorkoutHistory', () {
      test('should return empty list when no sessions exist', () async {
        final history = await repository.getWorkoutHistory();
        expect(history, isEmpty);
      });

      test('should return all saved sessions', () async {
        final session1 = WorkoutSession(
          id: 'history_1',
          date: DateTime(2026, 1, 15),
        );
        final session2 = WorkoutSession(
          id: 'history_2',
          date: DateTime(2026, 1, 16),
        );
        final session3 = WorkoutSession(
          id: 'history_3',
          date: DateTime(2026, 1, 17),
        );

        await repository.saveWorkoutSession(session1);
        await repository.saveWorkoutSession(session2);
        await repository.saveWorkoutSession(session3);

        final history = await repository.getWorkoutHistory();
        expect(history.length, equals(3));
      });

      test(
        'should return sessions sorted by date (most recent first)',
        () async {
          // Save sessions out of order
          final older = WorkoutSession(
            id: 'older',
            date: DateTime(2026, 1, 10),
          );
          final newest = WorkoutSession(
            id: 'newest',
            date: DateTime(2026, 1, 18),
          );
          final middle = WorkoutSession(
            id: 'middle',
            date: DateTime(2026, 1, 14),
          );

          await repository.saveWorkoutSession(older);
          await repository.saveWorkoutSession(newest);
          await repository.saveWorkoutSession(middle);

          final history = await repository.getWorkoutHistory();

          expect(history.length, equals(3));
          expect(history[0].id, equals('newest'));
          expect(history[1].id, equals('middle'));
          expect(history[2].id, equals('older'));
        },
      );
    });

    group('deleteWorkoutSession', () {
      test('should delete a workout session', () async {
        final session = WorkoutSession(
          id: 'delete_test',
          date: DateTime(2026, 1, 18),
        );

        await repository.saveWorkoutSession(session);

        // Verify it exists
        var retrieved = await repository.getWorkoutSessionById('delete_test');
        expect(retrieved, isNotNull);

        // Delete it
        await repository.deleteWorkoutSession('delete_test');

        // Verify it's gone
        retrieved = await repository.getWorkoutSessionById('delete_test');
        expect(retrieved, isNull);
      });

      test('should not throw when deleting non-existent session', () async {
        // Should complete without error
        await expectLater(
          repository.deleteWorkoutSession('non_existent'),
          completes,
        );
      });

      test('should only delete the specified session', () async {
        final session1 = WorkoutSession(
          id: 'keep_1',
          date: DateTime(2026, 1, 15),
        );
        final session2 = WorkoutSession(
          id: 'delete_me',
          date: DateTime(2026, 1, 16),
        );
        final session3 = WorkoutSession(
          id: 'keep_2',
          date: DateTime(2026, 1, 17),
        );

        await repository.saveWorkoutSession(session1);
        await repository.saveWorkoutSession(session2);
        await repository.saveWorkoutSession(session3);

        await repository.deleteWorkoutSession('delete_me');

        final history = await repository.getWorkoutHistory();
        expect(history.length, equals(2));
        expect(history.any((s) => s.id == 'keep_1'), isTrue);
        expect(history.any((s) => s.id == 'keep_2'), isTrue);
        expect(history.any((s) => s.id == 'delete_me'), isFalse);
      });
    });

    group('persistence across repository instances', () {
      test('should persist data across new repository instances', () async {
        // Save with first repository instance
        final session = WorkoutSession(
          id: 'persist_test',
          programId: 'prog1',
          programName: 'Persistent Program',
          date: DateTime(2026, 1, 18),
          notes: 'This should persist',
        );

        await repository.saveWorkoutSession(session);

        // Create a new repository instance (simulating app restart)
        final newRepository = ProgramRepositoryImpl(
          mockDataSource: MockProgramDataSource(),
          localDataSource: ProgramLocalDataSourceImpl(),
          useMockData: true,
          useRemoteApi: false,
        );

        // Retrieve with new instance
        final retrieved = await newRepository.getWorkoutSessionById(
          'persist_test',
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('persist_test'));
        expect(retrieved.programName, equals('Persistent Program'));
        expect(retrieved.notes, equals('This should persist'));
      });

      test('history should persist across repository instances', () async {
        // Save multiple sessions
        for (var i = 1; i <= 5; i++) {
          await repository.saveWorkoutSession(
            WorkoutSession(
              id: 'persist_history_$i',
              date: DateTime(2026, 1, i),
            ),
          );
        }

        // Create new repository instance
        final newRepository = ProgramRepositoryImpl(
          mockDataSource: MockProgramDataSource(),
          localDataSource: ProgramLocalDataSourceImpl(),
          useMockData: true,
          useRemoteApi: false,
        );

        final history = await newRepository.getWorkoutHistory();
        expect(history.length, equals(5));
      });
    });

    group('edge cases', () {
      test('should handle session with empty exercises list', () async {
        final session = WorkoutSession(
          id: 'empty_exercises',
          date: DateTime(2026, 1, 18),
          exercises: [],
        );

        await repository.saveWorkoutSession(session);
        final retrieved = await repository.getWorkoutSessionById(
          'empty_exercises',
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.exercises, isEmpty);
      });

      test('should handle session with null optional fields', () async {
        final session = WorkoutSession(
          id: 'null_fields',
          date: DateTime(2026, 1, 18),
          // programId, programName, startTime, endTime, notes, metadata are null
        );

        await repository.saveWorkoutSession(session);
        final retrieved = await repository.getWorkoutSessionById('null_fields');

        expect(retrieved, isNotNull);
        expect(retrieved!.programId, isNull);
        expect(retrieved.programName, isNull);
        expect(retrieved.startTime, isNull);
        expect(retrieved.endTime, isNull);
        expect(retrieved.notes, isNull);
      });

      test('should handle session with metadata', () async {
        final session = WorkoutSession(
          id: 'metadata_test',
          date: DateTime(2026, 1, 18),
          metadata: {
            'feeling': 'great',
            'energy_level': 8,
            'custom_tags': ['legs', 'heavy'],
          },
        );

        await repository.saveWorkoutSession(session);
        final retrieved = await repository.getWorkoutSessionById(
          'metadata_test',
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.metadata, isNotNull);
        expect(retrieved.metadata!['feeling'], equals('great'));
        expect(retrieved.metadata!['energy_level'], equals(8));
        expect(retrieved.metadata!['custom_tags'], equals(['legs', 'heavy']));
      });

      test('should handle many workout sessions', () async {
        // Create 50 sessions
        for (var i = 0; i < 50; i++) {
          await repository.saveWorkoutSession(
            WorkoutSession(
              id: 'bulk_session_$i',
              date: DateTime(2026, 1, 1).add(Duration(days: i)),
            ),
          );
        }

        final history = await repository.getWorkoutHistory();
        expect(history.length, equals(50));

        // Verify sorting - most recent first
        expect(history[0].id, equals('bulk_session_49'));
        expect(history[49].id, equals('bulk_session_0'));
      });

      test(
        'should correctly serialize and deserialize workout timing',
        () async {
          final session = WorkoutSession(
            id: 'timing_test',
            date: DateTime(2026, 1, 18),
            startTime: DateTime(2026, 1, 18, 9, 0, 0),
            endTime: DateTime(2026, 1, 18, 10, 30, 0),
          );

          await repository.saveWorkoutSession(session);
          final retrieved = await repository.getWorkoutSessionById(
            'timing_test',
          );

          expect(retrieved, isNotNull);
          expect(retrieved!.duration, isNotNull);
          expect(retrieved.duration!.inMinutes, equals(90));
        },
      );

      test('should handle sessions with same date correctly', () async {
        final session1 = WorkoutSession(
          id: 'same_date_1',
          programName: 'Morning Workout',
          date: DateTime(2026, 1, 18),
        );
        final session2 = WorkoutSession(
          id: 'same_date_2',
          programName: 'Evening Workout',
          date: DateTime(2026, 1, 18),
        );

        await repository.saveWorkoutSession(session1);
        await repository.saveWorkoutSession(session2);

        final history = await repository.getWorkoutHistory();
        expect(history.length, equals(2));

        // Both should be retrievable by ID
        final retrieved1 = await repository.getWorkoutSessionById(
          'same_date_1',
        );
        final retrieved2 = await repository.getWorkoutSessionById(
          'same_date_2',
        );
        expect(retrieved1, isNotNull);
        expect(retrieved2, isNotNull);
        expect(retrieved1!.programName, equals('Morning Workout'));
        expect(retrieved2!.programName, equals('Evening Workout'));
      });
    });
  });
}
