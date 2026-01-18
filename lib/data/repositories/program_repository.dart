import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/utils/utils.dart';
import 'package:flutter_lifter/data/repositories/exercise_repository.dart';

import '../datasources/local/program_local_datasource.dart';
import '../datasources/remote/program_api_datasource.dart';
import '../datasources/mock/mock_program_datasource.dart';

/// Repository for program-related operations
/// Implements the Repository pattern to abstract data source details
abstract class ProgramRepository {
  Future<List<Program>> getPrograms();
  Future<Program?> getProgramById(String id);
  Future<void> createProgram(Program program);
  Future<void> updateProgram(Program program);
  Future<void> deleteProgram(String id);
  Future<List<Program>> searchPrograms(String query);
  Future<List<Program>> getProgramsByDifficulty(ProgramDifficulty difficulty);
  Future<List<Program>> getProgramsByType(ProgramType type);
  Future<void> refreshCache();

  // Program cycle methods
  Future<ProgramCycle?> getProgramCycleWithProgram(String cycleId);
  Future<List<ProgramCycle>> getProgramCyclesWithProgram(String programId);

  // Workout session methods
  /// Saves a workout session and optionally propagates exercise changes
  /// to future sessions with the same day template.
  ///
  /// When [propagateToFuture] is true (default), any exercise list changes
  /// (additions, removals, reordering) in this session will be applied to
  /// ALL future sessions in the same cycle that share the same day template.
  Future<void> saveWorkoutSession(
    WorkoutSession session, {
    bool propagateToFuture = true,
  });

  /// Updates future sessions to match the exercise list of a template session.
  ///
  /// This enables "template inheritance" - when a user modifies a session's
  /// exercises, all future sessions of the same day type automatically update.
  ///
  /// Only affects sessions that:
  /// - Are in the same cycle as the source session
  /// - Have the same dayTemplateId in metadata
  /// - Are scheduled AFTER the source session's date
  /// - Have not been started (startTime == null)
  Future<void> propagateExercisesToFutureSessions({
    required WorkoutSession sourceSession,
    required String cycleId,
  });

  /// Reschedules future sessions when a session's date is changed.
  ///
  /// When a session is moved to a new date, this method shifts all subsequent
  /// sessions in the cycle by the same time difference.
  ///
  /// [session] - The session with the new date already set
  /// [originalDate] - The original date before the change
  ///
  /// Only affects sessions that:
  /// - Are in the same cycle
  /// - Were scheduled AFTER the original date
  /// - Have not been completed
  Future<void> rescheduleFutureSessions({
    required WorkoutSession session,
    required DateTime originalDate,
  });

  Future<WorkoutSession?> getWorkoutSessionById(String sessionId);
  Future<List<WorkoutSession>> getWorkoutHistory();
  Future<void> deleteWorkoutSession(String sessionId);

  /// Gets any currently in-progress workout session.
  ///
  /// Returns the first session that has been started but not completed.
  /// This includes standalone workouts (quick workouts) not tied to a program.
  /// Returns null if no workout is currently in progress.
  Future<WorkoutSession?> getInProgressSession();

  /// Cancels all in-progress sessions except the one with the specified ID.
  ///
  /// This ensures only one workout can be active at a time.
  /// Used when starting a new workout to deactivate any previous ones.
  Future<void> cancelOtherInProgressSessions(String exceptSessionId);

  /// Gets completed workout sessions with pagination and optional date filtering.
  ///
  /// Returns sessions sorted by completion date (most recent first).
  /// Use [limit] and [offset] for pagination.
  /// Use [startDate] and [endDate] to filter by date range.
  Future<List<WorkoutSession>> getCompletedSessions({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    int offset = 0,
  });

  // ===== Program Library Methods =====

  /// Gets programs filtered by source (default, custom, or all)
  Future<List<Program>> getProgramsBySource({
    ProgramSource source = ProgramSource.all,
  });

  /// Gets only default (built-in) programs
  Future<List<Program>> getDefaultPrograms();

  /// Gets only custom (user-created) programs
  Future<List<Program>> getCustomPrograms();

  /// Gets recent programs sorted by lastUsedAt, most recent first
  Future<List<Program>> getRecentPrograms({int limit = 5});

  // ===== Active Cycle Management =====

  /// Gets the currently active cycle across all programs (only one allowed)
  Future<ProgramCycle?> getActiveCycle();

  /// Ends the currently active cycle, setting isActive=false and endDate=now
  Future<void> endActiveCycle();

  /// Starts a new cycle for the given program.
  /// Automatically ends any active cycle first.
  /// Updates the program's lastUsedAt timestamp.
  Future<ProgramCycle> startNewCycle(String programId);

  // ===== Program Cloning =====

  /// Creates a copy of a program as a custom (user-owned) program.
  /// Used when starting a default program to allow user customization.
  /// Returns existing copy if one already exists for this template.
  Future<Program> copyProgramAsCustom(Program template);

  /// Gets the user's copy of a default program template, if one exists.
  /// Returns null if the user hasn't started this default program yet.
  Future<Program?> getUserCopyOfProgram(String templateId);

  // ===== Community Sharing (Future) =====

  /// Publishes a program to the community library
  Future<void> publishProgram(String programId);

  /// Imports a community program as a custom program
  Future<Program> importProgram(Program program);
}

/// Implementation of ProgramRepository
class ProgramRepositoryImpl implements ProgramRepository {
  final ProgramApiDataSource? remoteDataSource;
  final ProgramLocalDataSource? localDataSource;
  final MockProgramDataSource? mockDataSource;
  final ExerciseRepository? exerciseRepository;
  final bool useRemoteApi;
  final bool useMockData;

  ProgramRepositoryImpl({
    this.remoteDataSource,
    this.localDataSource,
    this.mockDataSource,
    this.exerciseRepository,
    this.useRemoteApi = false,
    this.useMockData = true,
  });

  /// Factory constructor for development with mock data
  ///
  /// Uses [InMemoryProgramLocalDataSource] by default for testing purposes.
  /// For production, use [ProgramRepositoryImpl.production] with
  /// [ProgramLocalDataSourceImpl] which persists data using Hive.
  factory ProgramRepositoryImpl.development({
    ExerciseRepository? exerciseRepository,
  }) {
    return ProgramRepositoryImpl(
      mockDataSource: MockProgramDataSource(),
      localDataSource: InMemoryProgramLocalDataSource(),
      exerciseRepository: exerciseRepository,
      useMockData: true,
      useRemoteApi: false,
    );
  }

  /// Factory constructor for production with API
  // TODO: Uncomment apiDataSource parameter when API is ready
  factory ProgramRepositoryImpl.production({
    // required ProgramApiDataSource apiDataSource,
    required ProgramLocalDataSource localDataSource,
    ExerciseRepository? exerciseRepository,
  }) {
    return ProgramRepositoryImpl(
      // remoteDataSource: apiDataSource,
      localDataSource: localDataSource,
      exerciseRepository: exerciseRepository,
      useRemoteApi: true,
      useMockData: false,
    );
  }

  // TODO: implement data Streams for reading from multiple sources
  // https://docs.flutter.dev/app-architecture/design-patterns/offline-first#using-a-stream

  @override
  Future<List<Program>> getPrograms() async {
    if (useMockData && mockDataSource != null) {
      return await mockDataSource!.getPrograms();
    }

    // Try local cache first
    if (localDataSource != null) {
      final isExpired = await localDataSource!.isCacheExpired();
      if (!isExpired || !useRemoteApi) {
        final cachedPrograms = await localDataSource!.getCachedPrograms();
        if (cachedPrograms.isNotEmpty) {
          return cachedPrograms;
        }
      }
    }

    // Fetch from remote if available
    if (useRemoteApi && remoteDataSource != null) {
      try {
        final programs = await remoteDataSource!.getPrograms();

        // Cache the results
        if (localDataSource != null) {
          await localDataSource!.cachePrograms(programs);
        }

        return programs;
      } catch (e) {
        LoggingService.error(
          'Failed to fetch programs from remote: $e',
          e is Exception ? e : null,
        );
        // Fall back to cache if remote fails
        if (localDataSource != null) {
          final cachedPrograms = await localDataSource!.getCachedPrograms();
          if (cachedPrograms.isNotEmpty) {
            return cachedPrograms;
          }
        }
        // If no cached data is available, rethrow to allow callers to handle the failure
        rethrow;
      }
    }

    // Fallback to empty list
    return [];
  }

  @override
  Future<Program?> getProgramById(String id) async {
    if (useMockData && mockDataSource != null) {
      return await mockDataSource!.getProgramById(id);
    }

    // Try local cache first
    if (localDataSource != null) {
      final cachedProgram = await localDataSource!.getCachedProgramById(id);
      if (cachedProgram != null) {
        return cachedProgram;
      }
    }

    // Fetch from remote if available
    if (useRemoteApi && remoteDataSource != null) {
      try {
        final program = await remoteDataSource!.getProgramById(id);

        // Cache the result
        if (localDataSource != null) {
          await localDataSource!.cacheProgram(program);
        }

        return program;
      } catch (e) {
        // Remote failed, return null
        return null;
      }
    }

    return null;
  }

  /// Creates a new program in the repository
  @override
  Future<void> createProgram(Program program) async {
    LoggingService.debug('Creating program: ${program.id}');

    if (useMockData && mockDataSource != null) {
      LoggingService.debug('Using mock data source for program creation');
      await mockDataSource!.createProgram(program);
      return;
    }

    // Update local cache
    if (localDataSource != null) {
      LoggingService.debug(
        'Updating local cache for new program: ${program.id}',
      );
      await localDataSource!.cacheProgram(program);
    }

    if (useRemoteApi && remoteDataSource != null) {
      LoggingService.debug(
        'Updating remote API for new program: ${program.id}',
      );
      final createdProgram = await remoteDataSource!.createProgram(program);
      if (localDataSource != null) {
        await localDataSource!.cacheProgram(createdProgram);
      }
    }
  }

  /// Updates a program in the repository
  @override
  Future<void> updateProgram(Program program) async {
    LoggingService.debug('Updating program: ${program.id}');

    if (useMockData && mockDataSource != null) {
      LoggingService.debug('Using mock data source for update');
      await mockDataSource!.updateProgram(program);
      return;
    }

    // Always update local cache
    if (localDataSource != null) {
      LoggingService.debug('Updating local cache for program: ${program.id}');
      await localDataSource!.cacheProgram(program);
    }

    // If using API, also update remote and re-cache result
    if (useRemoteApi && remoteDataSource != null) {
      LoggingService.debug('Updating remote API for program: ${program.id}');
      final updatedProgram = await remoteDataSource!.updateProgram(program);
      if (localDataSource != null) {
        await localDataSource!.cacheProgram(updatedProgram);
      }
    }
  }

  /// Deletes a program from the repository
  @override
  Future<void> deleteProgram(String id) async {
    LoggingService.debug('Deleting program: $id');

    if (useMockData && mockDataSource != null) {
      LoggingService.debug('Using mock data source for deletion');
      await mockDataSource!.deleteProgram(id);
      return;
    }

    // Remove from local cache
    if (localDataSource != null) {
      LoggingService.debug('Removing program from local cache: $id');
      await localDataSource!.removeCachedProgram(id);
    }

    if (useRemoteApi && remoteDataSource != null) {
      LoggingService.debug('Removing program from remote API: $id');
      await remoteDataSource!.deleteProgram(id);
    }
  }

  /// Search programs by name or description
  @override
  Future<List<Program>> searchPrograms(String query) async {
    if (useMockData && mockDataSource != null) {
      LoggingService.debug('Searching programs via mock data: $query');
      return await mockDataSource!.searchPrograms(query);
    }

    if (localDataSource != null) {
      LoggingService.debug('Searching programs via local cache: $query');

      // TODO: move this to local data source
      final cachedPrograms = await localDataSource!.getCachedPrograms();
      final lowercaseQuery = query.toLowerCase();
      final results = cachedPrograms.where((program) {
        return program.name.toLowerCase().contains(lowercaseQuery) ||
            (program.description?.toLowerCase().contains(lowercaseQuery) ??
                false) ||
            program.tags.any(
              (tag) => tag.toLowerCase().contains(lowercaseQuery),
            );
      }).toList();
      if (results.isNotEmpty) {
        return results;
      }
    }

    // Fallback to API
    if (useRemoteApi && remoteDataSource != null) {
      LoggingService.debug('Searching programs via remote API: $query');
      return await remoteDataSource!.searchPrograms(query);
    }

    return [];
  }

  @override
  Future<List<Program>> getProgramsByDifficulty(
    ProgramDifficulty difficulty,
  ) async {
    if (useMockData && mockDataSource != null) {
      LoggingService.debug(
        'Getting programs by difficulty via mock data: $difficulty',
      );
      return await mockDataSource!.getProgramsByDifficulty(difficulty);
    }

    // For API, we could either have a dedicated endpoint or filter client-side
    final allPrograms = await getPrograms();
    return allPrograms
        .where((program) => program.difficulty == difficulty)
        .toList();
  }

  @override
  Future<List<Program>> getProgramsByType(ProgramType type) async {
    if (useMockData && mockDataSource != null) {
      return await mockDataSource!.getProgramsByType(type);
    }

    // For API, we could either have a dedicated endpoint or filter client-side
    final allPrograms = await getPrograms();
    return allPrograms.where((program) => program.type == type).toList();
  }

  @override
  Future<void> refreshCache() async {
    if (localDataSource != null) {
      await localDataSource!.clearCache();
    }

    // Trigger a fresh fetch
    await getPrograms();
  }

  @override
  Future<ProgramCycle?> getProgramCycleWithProgram(String cycleId) async {
    // First, we need to find which program contains this cycle
    final programs = await getPrograms();

    for (final program in programs) {
      for (final cycle in program.cycles) {
        if (cycle.id == cycleId) {
          // Set the program reference on the cycle
          cycle.setProgram(program);
          return cycle;
        }
      }
    }

    return null;
  }

  @override
  Future<List<ProgramCycle>> getProgramCyclesWithProgram(
    String programId,
  ) async {
    final program = await getProgramById(programId);
    if (program == null) return [];

    // Return cycles with program references loaded
    final cyclesWithProgram = <ProgramCycle>[];
    for (final cycle in program.cycles) {
      cycle.setProgram(program);
      cyclesWithProgram.add(cycle);
    }
    return cyclesWithProgram;
  }

  // Workout session methods implementation
  // Uses localDataSource which respects AppConfig.storageMode
  // (Hive for persistent storage, in-memory for development)

  @override
  Future<void> saveWorkoutSession(
    WorkoutSession session, {
    bool propagateToFuture = true,
  }) async {
    LoggingService.debug('Saving workout session: ${session.id}');

    // Save the session itself to local datasource
    if (localDataSource != null) {
      await localDataSource!.saveWorkoutSession(session);
    }

    // Also update the session in the Program's cycle scheduledSessions list
    // This ensures the Program cache stays in sync with session changes
    await _updateSessionInProgramCycle(session);

    // Propagate exercise changes to future sessions if enabled
    if (propagateToFuture && session.metadata != null) {
      final cycleId = session.metadata!['cycleId'] as String?;
      final dayTemplateId = session.metadata!['dayTemplateId'] as String?;

      if (cycleId != null && dayTemplateId != null) {
        await propagateExercisesToFutureSessions(
          sourceSession: session,
          cycleId: cycleId,
        );
      }
    }
  }

  /// Updates a session within its parent Program's cycle scheduledSessions list.
  ///
  /// This ensures the Program cache stays in sync when session properties
  /// (like date, exercises, status) are changed.
  Future<void> _updateSessionInProgramCycle(WorkoutSession session) async {
    final cycleId = session.metadata?['cycleId'] as String?;
    if (cycleId == null) {
      LoggingService.debug(
        'No cycleId in session metadata, skipping program update for: ${session.id}',
      );
      return;
    }

    // Find the program containing this cycle
    final programs = await getPrograms();
    Program? targetProgram;
    ProgramCycle? targetCycle;

    for (final program in programs) {
      for (final cycle in program.cycles) {
        if (cycle.id == cycleId) {
          targetProgram = program;
          targetCycle = cycle;
          break;
        }
      }
      if (targetCycle != null) break;
    }

    if (targetProgram == null || targetCycle == null) {
      LoggingService.debug('Cycle not found for session update: $cycleId');
      return;
    }

    // Update the session in the cycle's scheduledSessions list
    final updatedSessions = targetCycle.scheduledSessions.map((s) {
      return s.id == session.id ? session : s;
    }).toList();

    // Update the cycle with modified sessions
    final updatedCycle = targetCycle.copyWith(
      scheduledSessions: updatedSessions,
    );

    // Update the program with the modified cycle
    final updatedProgram = targetProgram.updateCycle(updatedCycle);
    await updateProgram(updatedProgram);

    LoggingService.debug(
      'Updated session ${session.id} in program cycle $cycleId',
    );
  }

  @override
  Future<void> propagateExercisesToFutureSessions({
    required WorkoutSession sourceSession,
    required String cycleId,
  }) async {
    final dayTemplateId = sourceSession.metadata?['dayTemplateId'] as String?;
    if (dayTemplateId == null) {
      LoggingService.debug(
        'No dayTemplateId found, skipping propagation for session: ${sourceSession.id}',
      );
      return;
    }

    LoggingService.debug(
      'Propagating exercises from session ${sourceSession.id} to future sessions '
      'with dayTemplateId: $dayTemplateId in cycle: $cycleId',
    );

    // Find the program and cycle containing this session
    final programs = await getPrograms();
    Program? targetProgram;
    ProgramCycle? targetCycle;

    for (final program in programs) {
      for (final cycle in program.cycles) {
        if (cycle.id == cycleId) {
          targetProgram = program;
          targetCycle = cycle;
          break;
        }
      }
      if (targetCycle != null) break;
    }

    if (targetProgram == null || targetCycle == null) {
      LoggingService.warning('Cycle not found for propagation: $cycleId');
      return;
    }

    // Find future sessions with the same day template that haven't started
    final updatedSessions = <WorkoutSession>[];
    var changesCount = 0;

    for (final session in targetCycle.scheduledSessions) {
      // Skip the source session itself
      if (session.id == sourceSession.id) {
        updatedSessions.add(session);
        continue;
      }

      // Skip sessions that are before or on the same date
      if (!session.date.isAfter(sourceSession.date)) {
        updatedSessions.add(session);
        continue;
      }

      // Skip sessions that have already started
      if (session.startTime != null) {
        updatedSessions.add(session);
        continue;
      }

      // Skip sessions with different day template
      final sessionTemplateId = session.metadata?['dayTemplateId'] as String?;
      if (sessionTemplateId != dayTemplateId) {
        updatedSessions.add(session);
        continue;
      }

      // Create template exercises from the source session
      // Reset all sets to incomplete with target values only
      final templateExercises = sourceSession.exercises.map((srcExercise) {
        final templateSets = srcExercise.sets.map((srcSet) {
          return ExerciseSet.create(
            targetReps: srcSet.targetReps ?? srcSet.actualReps,
            targetWeight: srcSet.targetWeight ?? srcSet.actualWeight,
          );
        }).toList();

        return WorkoutExercise(
          id: Utils.generateId(), // New ID for the copied exercise
          exercise: srcExercise.exercise,
          sets: templateSets,
          restTime: srcExercise.restTime,
          notes: srcExercise.notes,
        );
      }).toList();

      // Update the session with new exercises
      final updatedSession = session.copyWith(
        exercises: templateExercises,
        metadata: {
          ...?session.metadata,
          'templateUpdatedAt': DateTime.now().toIso8601String(),
          'templateSourceId': sourceSession.id,
        },
      );
      updatedSessions.add(updatedSession);
      changesCount++;
    }

    if (changesCount > 0) {
      // Update the cycle with modified sessions
      final updatedCycle = targetCycle.copyWith(
        scheduledSessions: updatedSessions,
      );

      // Update the program with the modified cycle
      final updatedProgram = targetProgram.updateCycle(updatedCycle);
      await updateProgram(updatedProgram);

      LoggingService.info(
        'Propagated exercises to $changesCount future sessions',
      );
    }
  }

  @override
  Future<void> rescheduleFutureSessions({
    required WorkoutSession session,
    required DateTime originalDate,
  }) async {
    final cycleId = session.metadata?['cycleId'] as String?;
    if (cycleId == null) {
      LoggingService.debug(
        'No cycleId in session metadata, skipping reschedule for: ${session.id}',
      );
      return;
    }

    // Compare calendar dates (ignore time component)
    final sessionDateOnly = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
    );
    final originalDateOnly = DateTime(
      originalDate.year,
      originalDate.month,
      originalDate.day,
    );

    // Calculate difference in calendar days
    final daysDiff = sessionDateOnly.difference(originalDateOnly).inDays;
    if (daysDiff == 0) {
      LoggingService.debug('No calendar date change, skipping reschedule');
      return;
    }

    LoggingService.debug('Rescheduling future sessions by $daysDiff days');

    // Find the program and cycle containing this session
    final programs = await getPrograms();
    Program? targetProgram;
    ProgramCycle? targetCycle;

    for (final program in programs) {
      for (final cycle in program.cycles) {
        if (cycle.id == cycleId) {
          targetProgram = program;
          targetCycle = cycle;
          break;
        }
      }
      if (targetCycle != null) break;
    }

    if (targetProgram == null || targetCycle == null) {
      LoggingService.warning('Cycle not found for rescheduling: $cycleId');
      return;
    }

    // Reschedule future sessions - collect updates first, then batch save
    final updatedSessions = <WorkoutSession>[];
    final sessionsToSave = <WorkoutSession>[];

    for (final s in targetCycle.scheduledSessions) {
      // Keep the modified session as-is (it already has the new date)
      if (s.id == session.id) {
        updatedSessions.add(session);
        continue;
      }

      // Only reschedule sessions that were AFTER the original date
      // and have not been completed
      if (s.date.isAfter(originalDate) && !s.isCompleted) {
        // Add the calendar day difference (preserving time of day)
        final newDate = s.date.add(Duration(days: daysDiff));
        final rescheduledSession = s.copyWith(date: newDate);
        updatedSessions.add(rescheduledSession);
        sessionsToSave.add(rescheduledSession);
      } else {
        updatedSessions.add(s);
      }
    }

    if (sessionsToSave.isNotEmpty) {
      // Batch save all rescheduled sessions in parallel to avoid UI hitching
      if (localDataSource != null) {
        await Future.wait(
          sessionsToSave.map((s) => localDataSource!.saveWorkoutSession(s)),
        );
      }

      // Update the cycle with rescheduled sessions
      final updatedCycle = targetCycle.copyWith(
        scheduledSessions: updatedSessions,
      );

      // Update the program with the modified cycle
      final updatedProgram = targetProgram.updateCycle(updatedCycle);
      await updateProgram(updatedProgram);

      LoggingService.info(
        'Rescheduled ${sessionsToSave.length} future sessions',
      );
    }
  }

  @override
  Future<WorkoutSession?> getWorkoutSessionById(String sessionId) async {
    LoggingService.debug('Getting workout session: $sessionId');
    if (localDataSource == null) return null;
    try {
      return await localDataSource!.getWorkoutSessionById(sessionId);
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'parse',
        'workout_session:$sessionId',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<List<WorkoutSession>> getWorkoutHistory() async {
    LoggingService.debug('Getting workout history');
    if (localDataSource == null) return [];
    try {
      final sessions = await localDataSource!.getAllWorkoutSessions();
      // Sort by date, most recent first
      sessions.sort((a, b) => b.date.compareTo(a.date));
      return sessions;
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'get',
        'workout_history',
        e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<void> deleteWorkoutSession(String sessionId) async {
    LoggingService.debug('Deleting workout session: $sessionId');

    // First, remove from local datasource
    if (localDataSource != null) {
      await localDataSource!.deleteWorkoutSession(sessionId);
    }

    // Also remove from the Program's cycle scheduledSessions list
    await _removeSessionFromProgramCycle(sessionId);
  }

  @override
  Future<WorkoutSession?> getInProgressSession() async {
    LoggingService.debug('Checking for in-progress session');
    if (localDataSource == null) return null;

    try {
      final allSessions = await localDataSource!.getAllWorkoutSessions();
      // Find any session that is in progress (started but not completed)
      final inProgress = allSessions.where((s) => s.isInProgress).toList();

      if (inProgress.isEmpty) {
        LoggingService.debug('No in-progress session found');
        return null;
      }

      // Sort by start time (most recent first) and return the first one
      inProgress.sort((a, b) {
        final aStart = a.startTime ?? DateTime(1970);
        final bStart = b.startTime ?? DateTime(1970);
        return bStart.compareTo(aStart);
      });

      LoggingService.debug('Found in-progress session: ${inProgress.first.id}');
      return inProgress.first;
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'get',
        'in_progress_session',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> cancelOtherInProgressSessions(String exceptSessionId) async {
    LoggingService.debug(
      'Cancelling other in-progress sessions (keeping: $exceptSessionId)',
    );
    if (localDataSource == null) return;

    try {
      final allSessions = await localDataSource!.getAllWorkoutSessions();
      final otherInProgress = allSessions
          .where((s) => s.isInProgress && s.id != exceptSessionId)
          .toList();

      if (otherInProgress.isEmpty) {
        LoggingService.debug('No other in-progress sessions to cancel');
        return;
      }

      // Cancel each other in-progress session by marking it as ended
      for (final session in otherInProgress) {
        LoggingService.debug(
          'Cancelling session: ${session.id} '
          '(${session.programName ?? "Quick Workout"})',
        );
        // Mark the session as cancelled by setting end time
        // We don't delete it - just end it so it shows in history
        session.endTime = DateTime.now();
        await localDataSource!.saveWorkoutSession(session);
      }

      LoggingService.debug(
        'Cancelled ${otherInProgress.length} other in-progress session(s)',
      );
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'cancel',
        'other_in_progress_sessions',
        e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Removes a session from its parent Program's cycle scheduledSessions list.
  Future<void> _removeSessionFromProgramCycle(String sessionId) async {
    final programs = await getPrograms();

    for (final program in programs) {
      for (final cycle in program.cycles) {
        final sessionIndex = cycle.scheduledSessions.indexWhere(
          (s) => s.id == sessionId,
        );

        if (sessionIndex != -1) {
          // Found the session - remove it
          final updatedSessions = List<WorkoutSession>.from(
            cycle.scheduledSessions,
          )..removeAt(sessionIndex);

          final updatedCycle = cycle.copyWith(
            scheduledSessions: updatedSessions,
          );

          final updatedProgram = program.updateCycle(updatedCycle);
          await updateProgram(updatedProgram);

          LoggingService.debug(
            'Removed session $sessionId from program cycle ${cycle.id}',
          );
          return;
        }
      }
    }

    LoggingService.debug('Session $sessionId not found in any program cycle');
  }

  @override
  Future<List<WorkoutSession>> getCompletedSessions({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    int offset = 0,
  }) async {
    LoggingService.debug(
      'Getting completed sessions: limit=$limit, offset=$offset',
    );

    // Get all completed sessions from all program cycles
    final programs = await getPrograms();
    final completedSessions = <WorkoutSession>[];

    for (final program in programs) {
      for (final cycle in program.cycles) {
        for (final session in cycle.scheduledSessions) {
          if (session.isCompleted) {
            completedSessions.add(session);
          }
        }
      }
    }

    // Also get standalone sessions from local storage
    if (localDataSource != null) {
      final allSessions = await localDataSource!.getAllWorkoutSessions();
      for (final session in allSessions) {
        if (session.isCompleted) {
          // Avoid duplicates - check if already in list
          if (!completedSessions.any((s) => s.id == session.id)) {
            completedSessions.add(session);
          }
        }
      }
    }

    // Filter by date range if provided
    var filteredSessions = completedSessions;
    if (startDate != null) {
      filteredSessions = filteredSessions.where((s) {
        final sessionDate = s.endTime ?? s.startTime ?? s.date;
        return sessionDate.isAfter(startDate) ||
            sessionDate.isAtSameMomentAs(startDate);
      }).toList();
    }
    if (endDate != null) {
      filteredSessions = filteredSessions.where((s) {
        final sessionDate = s.endTime ?? s.startTime ?? s.date;
        return sessionDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by completion date, most recent first
    filteredSessions.sort((a, b) {
      final dateA = a.endTime ?? a.startTime ?? a.date;
      final dateB = b.endTime ?? b.startTime ?? b.date;
      return dateB.compareTo(dateA);
    });

    // Apply pagination
    if (offset >= filteredSessions.length) {
      return [];
    }
    final endIndex = (offset + limit).clamp(0, filteredSessions.length);
    return filteredSessions.sublist(offset, endIndex);
  }

  // ===== Program Library Methods Implementation =====

  @override
  Future<List<Program>> getProgramsBySource({
    ProgramSource source = ProgramSource.all,
  }) async {
    final allPrograms = await getPrograms();

    switch (source) {
      case ProgramSource.all:
        return allPrograms;
      case ProgramSource.defaultOnly:
        return allPrograms.where((p) => p.isDefault).toList();
      case ProgramSource.customOnly:
        return allPrograms.where((p) => !p.isDefault).toList();
      case ProgramSource.myPrograms:
        // Custom programs + default programs that have been used
        return allPrograms
            .where((p) => !p.isDefault || (p.isDefault && p.lastUsedAt != null))
            .toList();
      case ProgramSource.communityOnly:
        // Future: filter by community flag
        return [];
    }
  }

  @override
  Future<List<Program>> getDefaultPrograms() async {
    return getProgramsBySource(source: ProgramSource.defaultOnly);
  }

  @override
  Future<List<Program>> getCustomPrograms() async {
    return getProgramsBySource(source: ProgramSource.customOnly);
  }

  @override
  Future<List<Program>> getRecentPrograms({int limit = 5}) async {
    final allPrograms = await getPrograms();

    // Filter to only programs that have been used (have lastUsedAt)
    final usedPrograms = allPrograms
        .where((p) => p.lastUsedAt != null)
        .toList();

    // Sort by lastUsedAt descending (most recent first)
    usedPrograms.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

    // Return up to limit programs
    return usedPrograms.take(limit).toList();
  }

  // ===== Active Cycle Management Implementation =====

  @override
  Future<ProgramCycle?> getActiveCycle() async {
    final programs = await getPrograms();

    for (final program in programs) {
      for (final cycle in program.cycles) {
        if (cycle.isActive) {
          // Set the program reference on the cycle
          cycle.setProgram(program);
          return cycle;
        }
      }
    }

    return null;
  }

  @override
  Future<void> endActiveCycle() async {
    final activeCycle = await getActiveCycle();
    if (activeCycle == null) return;

    final program = await getProgramById(activeCycle.programId);
    if (program == null) return;

    // End the active cycle
    final endedCycle = activeCycle.copyWith(
      isActive: false,
      endDate: DateTime.now(),
    );

    // Update the program with the ended cycle
    final updatedProgram = program.updateCycle(endedCycle);
    await updateProgram(updatedProgram);
  }

  @override
  Future<ProgramCycle> startNewCycle(String programId) async {
    LoggingService.debug('Starting new cycle for program: $programId');

    // End any active cycle across ALL programs first.
    // This is a single-user app, so we trust this operation completes
    // before we proceed. The fresh program fetch below will reflect
    // any changes made by endActiveCycle().
    await endActiveCycle();

    // Get the program with up-to-date cycle state
    final program = await getProgramById(programId);
    if (program == null) {
      throw RepositoryException('Program not found: $programId');
    }

    // Create a new active cycle
    var newCycle = ProgramCycle.create(
      programId: programId,
      cycleNumber: program.nextCycleNumber,
      startDate: DateTime.now(),
      isActive: true,
      periodicity: program.defaultPeriodicity,
    );

    // Generate scheduled sessions based on periodicity
    newCycle = newCycle.generateScheduledSessions();

    // Populate exercises from day templates if available
    if (program.hasDayTemplates && exerciseRepository != null) {
      newCycle = await _populateSessionsWithExercises(newCycle, program);
    }

    LoggingService.debug(
      'Created new active cycle: ${newCycle.id} for program: $programId '
      'with ${newCycle.scheduledSessions.length} sessions',
    );

    // Update the program with the new active cycle.
    // No need to re-deactivate existing cycles - endActiveCycle() already
    // handled that, and the fresh program fetch reflects that state.
    final updatedProgram = program.copyWith(
      cycles: [...program.cycles, newCycle],
      lastUsedAt: DateTime.now(),
    );

    await updateProgram(updatedProgram);

    // Return the cycle with program reference set
    newCycle.setProgram(updatedProgram);
    return newCycle;
  }

  /// Populates workout sessions with exercises from day templates.
  ///
  /// Uses the program's dayTemplates to determine which exercises to include
  /// in each session, rotating through templates as needed.
  Future<ProgramCycle> _populateSessionsWithExercises(
    ProgramCycle cycle,
    Program program,
  ) async {
    if (program.dayTemplates.isEmpty || exerciseRepository == null) {
      return cycle;
    }

    final updatedSessions = <WorkoutSession>[];

    for (var i = 0; i < cycle.scheduledSessions.length; i++) {
      final session = cycle.scheduledSessions[i];

      // Get the day template for this session index (with rotation)
      final template = program.getDayTemplateForIndex(i);
      if (template == null || template.exerciseIds.isEmpty) {
        updatedSessions.add(session);
        continue;
      }

      // Build workout exercises from template
      final workoutExercises = <WorkoutExercise>[];
      for (final exerciseId in template.exerciseIds) {
        final exercise = await exerciseRepository!.getExerciseById(exerciseId);
        if (exercise == null) {
          LoggingService.warning(
            'Exercise not found for template: $exerciseId',
          );
          continue;
        }

        // Create WorkoutExercise with sets from exercise defaults
        final sets = List.generate(
          exercise.defaultSets,
          (_) => ExerciseSet.create(
            targetReps: exercise.defaultReps,
            targetWeight: exercise.defaultWeight,
          ),
        );

        workoutExercises.add(
          WorkoutExercise(
            id: Utils.generateId(),
            exercise: exercise,
            sets: sets,
            restTime: Duration(seconds: exercise.defaultRestTimeSeconds),
          ),
        );
      }

      // Update session with exercises and template metadata
      final updatedSession = session.copyWith(
        programName: program.name,
        exercises: workoutExercises,
        metadata: {
          ...?session.metadata,
          'dayTemplateId': template.id,
          'dayTemplateName': template.displayName,
        },
      );
      updatedSessions.add(updatedSession);
    }

    return cycle.copyWith(scheduledSessions: updatedSessions);
  }

  // ===== Program Cloning Implementation =====

  @override
  Future<Program?> getUserCopyOfProgram(String templateId) async {
    final allPrograms = await getPrograms();
    try {
      return allPrograms.firstWhere(
        (p) => p.templateId == templateId && !p.isDefault,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Program> copyProgramAsCustom(Program template) async {
    // Check if user already has a copy of this program
    final existingCopy = await getUserCopyOfProgram(template.id);
    if (existingCopy != null) {
      return existingCopy;
    }

    // Create a deep copy with new ID, same name, and templateId reference
    // Also copy day templates so user can customize them
    final customProgram = Program(
      id: Utils.generateId(),
      name: template.name, // Keep original name, no "(Copy)" suffix
      description: template.description,
      type: template.type,
      difficulty: template.difficulty,
      defaultPeriodicity: template.defaultPeriodicity,
      createdAt: DateTime.now(),
      createdBy: null, // Will be set to current user in future
      isPublic: false,
      tags: List.from(template.tags),
      imageUrl: template.imageUrl,
      metadata: template.metadata != null ? Map.from(template.metadata!) : null,
      isDefault: false, // Custom copy
      lastUsedAt: null, // Never used yet
      templateId: template.id, // Reference to original template
      cycles: [], // Start fresh with no cycles
      dayTemplates: template.dayTemplates
          .map(
            (t) => WorkoutDayTemplate(
              id: Utils.generateId(), // New IDs for custom templates
              name: t.name,
              dayIndex: t.dayIndex,
              variant: t.variant,
              exerciseIds: List.from(t.exerciseIds),
              description: t.description,
            ),
          )
          .toList(),
    );

    // Save the new program
    await createProgram(customProgram);

    return customProgram;
  }

  // ===== Community Sharing Implementation (Stubs) =====

  @override
  Future<void> publishProgram(String programId) async {
    // TODO: Implement community publishing
    // This would upload the program to a community API
    throw UnimplementedError('Community publishing is not yet implemented');
  }

  @override
  Future<Program> importProgram(Program program) async {
    // Import a community program as a custom program
    final importedProgram = program.copyWith(
      id: Utils.generateId(),
      isDefault: false,
      isPublic: false,
      createdAt: DateTime.now(),
      lastUsedAt: null,
      cycles: [],
    );

    await createProgram(importedProgram);
    return importedProgram;
  }
}

/// Repository exception for handling repository-level errors
class RepositoryException implements Exception {
  final String message;
  final Exception? originalException;

  const RepositoryException(this.message, [this.originalException]);

  @override
  String toString() {
    return 'RepositoryException: $message${originalException != null ? ' ($originalException)' : ''}';
  }
}
