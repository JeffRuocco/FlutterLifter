import 'package:flutter_lifter/models/program_models.dart';
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
}

/// Implementation of ProgramLocalDataSource using Hive for persistent storage
class ProgramLocalDataSourceImpl implements ProgramLocalDataSource {
  /// Cache timestamp key for programs
  static const String _cacheTimestampKey = 'programs';

  @override
  Future<List<Program>> getCachedPrograms() async {
    final programsJson = HiveStorageService.getAllPrograms();
    return programsJson.values.map((json) => Program.fromJson(json)).toList();
  }

  @override
  Future<Program?> getCachedProgramById(String id) async {
    final json = HiveStorageService.getProgram(id);
    if (json == null) return null;
    return Program.fromJson(json);
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
}
