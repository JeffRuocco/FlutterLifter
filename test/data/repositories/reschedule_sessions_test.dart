import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/services/app_settings_service.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/services/storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('Reschedule future sessions', () {
    late ProgramRepository repository;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      final appSettingsService = AppSettingsService();
      await appSettingsService.init();
      await LoggingService.init(appSettingsService);

      // Initialize Hive for tests
      Hive.init('./test_hive_reschedule');
      await HiveStorageService.initializeBoxes();
    });

    setUp(() async {
      await HiveStorageService.clearWorkoutSessions();
      // Use the in-memory development repository for tests
      repository = ProgramRepositoryImpl.development();
    });

    tearDownAll(() async {
      await HiveStorageService.clearWorkoutSessions();
      await HiveStorageService.closeBoxes();
    });

    test('reschedules later sessions by same day difference', () async {
      // Build three sessions in a cycle
      final s1 = WorkoutSession(id: 's1', date: DateTime(2026, 1, 10));
      final s2 = WorkoutSession(id: 's2', date: DateTime(2026, 1, 17));
      final s3 = WorkoutSession(id: 's3', date: DateTime(2026, 1, 24));

      final cycle = ProgramCycle(
        id: 'cycle1',
        programId: 'prog1',
        cycleNumber: 1,
        startDate: DateTime(2026, 1, 10),
        scheduledSessions: [s1, s2, s3],
        isActive: false,
        periodicity: WorkoutPeriodicity.weekly([DateTime(2026, 1, 10).weekday]),
        createdAt: DateTime.now(),
      );

      final program = Program(
        id: 'prog1',
        name: 'Test Program',
        type: ProgramType.general,
        difficulty: ProgramDifficulty.beginner,
        createdAt: DateTime.now(),
        cycles: [cycle],
      );

      // Save program into repository
      await repository.createProgram(program);

      // Change s2 date by +3 days
      final originalDate = s2.date;
      final updatedS2 = s2.copyWith(
        date: DateTime(2026, 1, 20),
        metadata: {'cycleId': 'cycle1'},
      );

      // Persist the updated session and then call reschedule
      await repository.saveWorkoutSession(updatedS2, propagateToFuture: false);
      await repository.rescheduleFutureSessions(
        session: updatedS2,
        originalDate: originalDate,
      );

      // Retrieve program and cycle
      final storedProgram = await repository.getProgramById('prog1');
      expect(storedProgram, isNotNull);
      final storedCycle = storedProgram!.cycles.firstWhere(
        (c) => c.id == 'cycle1',
      );

      // Find rescheduled session s3
      final rescheduled = storedCycle.scheduledSessions.firstWhere(
        (s) => s.id == 's3',
      );
      expect(rescheduled.date.year, equals(2026));
      expect(rescheduled.date.month, equals(1));
      // s3 should have been moved from 24 -> 27 (3 days)
      expect(rescheduled.date.day, equals(27));
    });
  });
}
