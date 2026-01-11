import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/utils/utils.dart';

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
  Future<void> saveWorkoutSession(WorkoutSession session);
  Future<WorkoutSession?> getWorkoutSessionById(String sessionId);
  Future<List<WorkoutSession>> getWorkoutHistory();
  Future<void> deleteWorkoutSession(String sessionId);

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
  final bool useRemoteApi;
  final bool useMockData;

  ProgramRepositoryImpl({
    this.remoteDataSource,
    this.localDataSource,
    this.mockDataSource,
    this.useRemoteApi = false,
    this.useMockData = true,
  });

  /// Factory constructor for development with mock data
  factory ProgramRepositoryImpl.development() {
    return ProgramRepositoryImpl(
      mockDataSource: MockProgramDataSource(),
      localDataSource: ProgramLocalDataSourceImpl(),
      useMockData: true,
      useRemoteApi: false,
    );
  }

  /// Factory constructor for production with API
  factory ProgramRepositoryImpl.production({
    required ProgramApiDataSource apiDataSource,
    required ProgramLocalDataSource localDataSource,
  }) {
    return ProgramRepositoryImpl(
      remoteDataSource: apiDataSource,
      localDataSource: localDataSource,
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
      if (!isExpired) {
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
        // Fall back to cache if remote fails
        if (localDataSource != null) {
          final cachedPrograms = await localDataSource!.getCachedPrograms();
          if (cachedPrograms.isNotEmpty) {
            return cachedPrograms;
          }
        }
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

  @override
  Future<void> createProgram(Program program) async {
    if (useMockData && mockDataSource != null) {
      await mockDataSource!.createProgram(program);
      return;
    }

    if (useRemoteApi && remoteDataSource != null) {
      final createdProgram = await remoteDataSource!.createProgram(program);

      // Update local cache
      if (localDataSource != null) {
        await localDataSource!.cacheProgram(createdProgram);
      }
    }
  }

  @override
  Future<void> updateProgram(Program program) async {
    if (useMockData && mockDataSource != null) {
      await mockDataSource!.updateProgram(program);
      return;
    }

    if (useRemoteApi && remoteDataSource != null) {
      final updatedProgram = await remoteDataSource!.updateProgram(program);

      // Update local cache
      if (localDataSource != null) {
        await localDataSource!.cacheProgram(updatedProgram);
      }
    }
  }

  @override
  Future<void> deleteProgram(String id) async {
    if (useMockData && mockDataSource != null) {
      await mockDataSource!.deleteProgram(id);
      return;
    }

    if (useRemoteApi && remoteDataSource != null) {
      await remoteDataSource!.deleteProgram(id);

      // Remove from local cache
      if (localDataSource != null) {
        await localDataSource!.removeCachedProgram(id);
      }
    }
  }

  @override
  Future<List<Program>> searchPrograms(String query) async {
    if (useMockData && mockDataSource != null) {
      return await mockDataSource!.searchPrograms(query);
    }

    if (useRemoteApi && remoteDataSource != null) {
      return await remoteDataSource!.searchPrograms(query);
    }

    return [];
  }

  @override
  Future<List<Program>> getProgramsByDifficulty(
    ProgramDifficulty difficulty,
  ) async {
    if (useMockData && mockDataSource != null) {
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
  // TODO: These are temporary in-memory implementations
  // In a real app, these would be persisted via local storage or API
  final Map<String, WorkoutSession> _workoutSessions = {};

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    if (useMockData || localDataSource != null) {
      // For now, store in memory
      _workoutSessions[session.id] = session;

      // TODO: Implement actual persistence
      // if (localDataSource != null) {
      //   await localDataSource!.saveWorkoutSession(session);
      // }
    }
  }

  @override
  Future<WorkoutSession?> getWorkoutSessionById(String sessionId) async {
    // For now, return from memory
    return _workoutSessions[sessionId];

    // TODO: Implement actual retrieval
    // if (localDataSource != null) {
    //   return await localDataSource!.getWorkoutSessionById(sessionId);
    // }
  }

  @override
  Future<List<WorkoutSession>> getWorkoutHistory() async {
    // For now, return from memory
    final sessions = _workoutSessions.values.toList();
    // Sort by date, most recent first
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;

    // TODO: Implement actual retrieval
    // if (localDataSource != null) {
    //   return await localDataSource!.getWorkoutHistory();
    // }
  }

  @override
  Future<void> deleteWorkoutSession(String sessionId) async {
    // For now, remove from memory
    _workoutSessions.remove(sessionId);

    // TODO: Implement actual deletion
    // if (localDataSource != null) {
    //   await localDataSource!.deleteWorkoutSession(sessionId);
    // }
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
    final newCycle = ProgramCycle.create(
      programId: programId,
      cycleNumber: program.nextCycleNumber,
      startDate: DateTime.now(),
      isActive: true,
      periodicity: program.defaultPeriodicity,
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
