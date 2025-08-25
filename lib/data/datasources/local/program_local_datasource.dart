import 'package:flutter_lifter/models/program_models.dart';

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

/// Implementation of ProgramLocalDataSource using SharedPreferences/Hive
class ProgramLocalDataSourceImpl implements ProgramLocalDataSource {
  // This would typically use a local database like SQLite or Hive
  // For now, we'll implement a simple in-memory cache

  static final Map<String, Program> _cache = {};
  static DateTime? _lastUpdate;

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
  Future<bool> isCacheExpired(
      {Duration maxAge = ProgramLocalDataSource._defaultCacheMaxAge}) async {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!).compareTo(maxAge) > 0;
  }
}

/// SQLite implementation (future enhancement)
class SqliteProgramLocalDataSource implements ProgramLocalDataSource {
  @override
  Future<List<Program>> getCachedPrograms() async {
    throw UnimplementedError('SQLite implementation pending');
  }

  @override
  Future<Program?> getCachedProgramById(String id) async {
    throw UnimplementedError('SQLite implementation pending');
  }

  @override
  Future<void> cachePrograms(List<Program> programs) async {
    throw UnimplementedError('SQLite implementation pending');
  }

  @override
  Future<void> cacheProgram(Program program) async {
    throw UnimplementedError('SQLite implementation pending');
  }

  @override
  Future<void> removeCachedProgram(String id) async {
    throw UnimplementedError('SQLite implementation pending');
  }

  @override
  Future<void> clearCache() async {
    throw UnimplementedError('SQLite implementation pending');
  }

  @override
  Future<DateTime?> getLastCacheUpdate() async {
    throw UnimplementedError('SQLite implementation pending');
  }

  @override
  Future<bool> isCacheExpired(
      {Duration maxAge = ProgramLocalDataSource._defaultCacheMaxAge}) async {
    throw UnimplementedError('SQLite implementation pending');
  }
}
