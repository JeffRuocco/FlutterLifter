import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lifter/screens/workout_history_screen.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/core/providers/repository_providers.dart';
import 'package:flutter_lifter/core/providers/workout_provider.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/services/app_settings_service.dart';
import 'package:flutter_lifter/core/theme/app_theme.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/data/datasources/local/program_local_datasource.dart';

class _FakeSettings extends AppSettingsService {
  @override
  Future<bool> isDebugModeEnabled() async => false;

  @override
  Future<bool> isDebugLoggingEnabled() async => false;

  @override
  Future<bool> isVerboseLoggingEnabled() async => false;
}

void main() {
  testWidgets('deletes a workout after confirmation', (tester) async {
    // Arrange: create an in-memory repository (no mock network delays)
    final repo = ProgramRepositoryImpl(
      localDataSource: InMemoryProgramLocalDataSource(),
      mockDataSource: null,
      exerciseRepository: null,
      useMockData: false,
      useRemoteApi: false,
    );

    final now = DateTime.now();
    final session = WorkoutSession.create(
      date: now,
      exercises: [],
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now,
    );

    // Initialize logging service used by repository methods
    await LoggingService.init(_FakeSettings());

    await repo.saveWorkoutSession(session);

    // Ensure seeded
    var history = await repo.getWorkoutHistory();
    expect(history.any((s) => s.id == session.id), isTrue);

    // Build the widget with provider overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programRepositoryProvider.overrideWithValue(repo),
          // No active workout
          currentWorkoutProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const WorkoutHistoryScreen(),
        ),
      ),
    );

    // Wait for history to load
    await tester.pumpAndSettle();

    // Verify delete button exists for the seeded session
    final deleteButton = find.byTooltip('Delete Workout');
    expect(deleteButton, findsWidgets);

    // Act: tap the first delete button
    await tester.tap(deleteButton.first);
    await tester.pumpAndSettle();

    // Confirm dialog should appear - tap the 'Delete' action
    final confirm = find.text('Delete');
    expect(confirm, findsWidgets);
    await tester.tap(confirm.last);
    await tester.pumpAndSettle();

    // Assert: repository no longer contains the session
    history = await repo.getWorkoutHistory();
    expect(history.any((s) => s.id == session.id), isFalse);
  });
}
