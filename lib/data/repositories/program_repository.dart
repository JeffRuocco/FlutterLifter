import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

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
  Future<List<Exercise>> getExercises();
  Future<Exercise?> getExerciseByName(String name);

  // Program cycle methods
  Future<ProgramCycle?> getProgramCycleWithProgram(String cycleId);
  Future<List<ProgramCycle>> getProgramCyclesWithProgram(String programId);
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
      ProgramDifficulty difficulty) async {
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

  // TODO: move this method to ExerciseRepository
  /// Get all exercises from the mock data source
  @override
  Future<List<Exercise>> getExercises() async {
    if (useMockData && mockDataSource != null) {
      return await mockDataSource!.getExercises();
    }

    // If remote API is used, we could implement a similar method in the API data source
    if (useRemoteApi && remoteDataSource != null) {
      // return await remoteDataSource!.get  Exercises();
    }

    // Fallback to empty list if no data source is available
    return [];
  }

  /// Get exercise by name from the available data sources.
  @override
  Future<Exercise?> getExerciseByName(String name) async {
    if (useMockData && mockDataSource != null) {
      return await mockDataSource!.getExerciseByName(name);
    }

    if (useRemoteApi && remoteDataSource != null) {
      // return await remoteDataSource!.getExerciseByName(name);
    }

    return null;
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
      String programId) async {
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
