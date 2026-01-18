import 'package:flutter_lifter/data/datasources/mock/default_programs.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/services/storage_service.dart';

/// Local data source for program-related operations (SQLite, Hive, etc.)
abstract class ProgramLocalDataSource {
  static const Duration _defaultCacheMaxAge = Duration(minutes: 5);

  Future<List<Program>> getCachedPrograms();
  Future<Program?> getCachedProgramById(String id);
  Future<void> cachePrograms(List<Program> programs);
  Future<void> cacheProgram(Program program);
  Future<void> removeCachedProgram(String id);
  Future<void> clearCache();
  Future<DateTime?> getLastCacheUpdate();
  Future<bool> isCacheExpired({Duration maxAge = _defaultCacheMaxAge});

  // Workout session methods
  Future<void> saveWorkoutSession(WorkoutSession session);
  Future<WorkoutSession?> getWorkoutSessionById(String sessionId);
  Future<List<WorkoutSession>> getAllWorkoutSessions();
  Future<void> deleteWorkoutSession(String sessionId);
  Future<void> clearWorkoutSessions();
}

/// Implementation of ProgramLocalDataSource using Hive for persistent storage
class ProgramLocalDataSourceImpl implements ProgramLocalDataSource {
  /// Cache timestamp key for programs
  static const String _cacheTimestampKey = 'programs';

  @override
  Future<List<Program>> getCachedPrograms() async {
    final programsJson = HiveStorageService.getAllPrograms();
    final hivePrograms = programsJson.values
        .map((json) => Program.fromJson(json))
        .toList();

    // Get all built-in defaults
    final defaultPrograms = DefaultPrograms.programs;

    // Merge: add any default not present in Hive
    final hiveIds = hivePrograms.map((p) => p.id).toSet();
    final missingDefaults = defaultPrograms
        .where((p) => !hiveIds.contains(p.id))
        .toList();

    return [...hivePrograms, ...missingDefaults];
  }

  @override
  Future<Program?> getCachedProgramById(String id) async {
    final json = HiveStorageService.getProgram(id);
    if (json != null) return Program.fromJson(json);
    // Fallback: check built-in defaults
    return DefaultPrograms.getProgramById(id);
  }

  @override
  Future<void> cachePrograms(List<Program> programs) async {
    await HiveStorageService.clearPrograms();
    // TODO: Consider implementing a batch operation in HiveStorageService or using Future.wait to parallelize the storage operations.
    for (final program in programs) {
      await HiveStorageService.storeProgram(program.id, program.toJson());
    }
    await HiveStorageService.setCacheTimestamp(
      _cacheTimestampKey,
      DateTime.now(),
    );
  }

  @override
  Future<void> cacheProgram(Program program) async {
    await HiveStorageService.storeProgram(program.id, program.toJson());
    await HiveStorageService.setCacheTimestamp(
      _cacheTimestampKey,
      DateTime.now(),
    );
  }

  @override
  Future<void> removeCachedProgram(String id) async {
    await HiveStorageService.deleteProgram(id);
  }

  @override
  Future<void> clearCache() async {
    await HiveStorageService.clearPrograms();
    await HiveStorageService.clearCacheTimestamp(_cacheTimestampKey);
  }

  @override
  Future<DateTime?> getLastCacheUpdate() async {
    return HiveStorageService.getCacheTimestamp(_cacheTimestampKey);
  }

  @override
  Future<bool> isCacheExpired({
    Duration maxAge = ProgramLocalDataSource._defaultCacheMaxAge,
  }) async {
    final lastUpdate = HiveStorageService.getCacheTimestamp(_cacheTimestampKey);
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate).compareTo(maxAge) > 0;
  }

  // Workout session methods using Hive storage

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    await HiveStorageService.storeWorkoutSession(session.id, session.toJson());
  }

  @override
  Future<WorkoutSession?> getWorkoutSessionById(String sessionId) async {
    final json = HiveStorageService.getWorkoutSession(sessionId);
    if (json == null) return null;
    return WorkoutSession.fromJson(json);
  }

  @override
  Future<List<WorkoutSession>> getAllWorkoutSessions() async {
    final sessionsJson = HiveStorageService.getAllWorkoutSessions();
    return sessionsJson.values
        .map((json) => WorkoutSession.fromJson(json))
        .toList();
  }

  @override
  Future<void> deleteWorkoutSession(String sessionId) async {
    await HiveStorageService.deleteWorkoutSession(sessionId);
  }

  @override
  Future<void> clearWorkoutSessions() async {
    await HiveStorageService.clearWorkoutSessions();
  }
}

/// In-memory implementation of ProgramLocalDataSource
///
/// Used for development and testing. Provides instance-level caches for
/// proper test isolation - each instance maintains its own independent cache.
class InMemoryProgramLocalDataSource implements ProgramLocalDataSource {
  final Map<String, Program> _cache = {};
  DateTime? _lastUpdate;

  @override
  Future<List<Program>> getCachedPrograms() async {
    return _cache.values.toList();
  }

  @override
  Future<Program?> getCachedProgramById(String id) async {
    return _cache[id];
  }

  @override
  Future<void> cachePrograms(List<Program> programs) async {
    _cache.clear();
    for (final program in programs) {
      _cache[program.id] = program;
    }
    _lastUpdate = DateTime.now();
  }

  @override
  Future<void> cacheProgram(Program program) async {
    _cache[program.id] = program;
    _lastUpdate = DateTime.now();
  }

  @override
  Future<void> removeCachedProgram(String id) async {
    _cache.remove(id);
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
    _lastUpdate = null;
  }

  @override
  Future<DateTime?> getLastCacheUpdate() async {
    return _lastUpdate;
  }

  @override
  Future<bool> isCacheExpired({
    Duration maxAge = ProgramLocalDataSource._defaultCacheMaxAge,
  }) async {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!).compareTo(maxAge) > 0;
  }

  // Workout session methods using in-memory storage
  final Map<String, WorkoutSession> _workoutSessions = {};

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    _workoutSessions[session.id] = session;
  }

  @override
  Future<WorkoutSession?> getWorkoutSessionById(String sessionId) async {
    return _workoutSessions[sessionId];
  }

  @override
  Future<List<WorkoutSession>> getAllWorkoutSessions() async {
    return _workoutSessions.values.toList();
  }

  @override
  Future<void> deleteWorkoutSession(String sessionId) async {
    _workoutSessions.remove(sessionId);
  }

  @override
  Future<void> clearWorkoutSessions() async {
    _workoutSessions.clear();
  }
}
