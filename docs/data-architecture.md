# Data Architecture Guide

## 🏗️ Overview

FlutterLifter implements a comprehensive **Clean Architecture** data layer with the **Repository Pattern** for managing fitness and workout data. The architecture provides separation of concerns, testability, offline support, and efficient caching mechanisms.

## 🎯 Architecture Principles

The app follows the **Repository Pattern** with **Clean Architecture** principles:

- **Single Source of Truth**: Repository layer serves as the unified interface for data access
- **Cache-First Strategy**: Local cache prioritized for performance, with API fallback
- **Multiple Data Sources**: Support for mock, local, and remote data sources
- **Clean Separation**: Clear boundaries between data sources, repositories, and business logic
- **Testability**: Each layer can be independently mocked and tested

## 📁 File Structure

```
lib/data/
├── repositories/                    # Repository layer (business logic)
│   └── program_repository.dart     # Program data management
├── datasources/                    # Data source implementations
│   ├── local/                      # Local storage (cache)
│   │   └── program_local_datasource.dart
│   ├── remote/                     # API/Network layer
│   │   └── program_api_datasource.dart
│   └── mock/                       # Mock data for development
│       ├── mock_program_datasource.dart
│       └── mock_data.dart
├── models/                         # Data transfer objects
│   └── responses/
│       ├── api_response.dart
│       └── program_response.dart
└── services/                       # Service layer
    ├── api_service.dart            # HTTP client management
    ├── storage_service.dart        # Local storage operations
    └── service_locator.dart        # Dependency injection
```

## 🔄 Data Flow Architecture

### Repository Pattern Implementation

```dart
// Repository interface
abstract class ProgramRepository {
  Future<List<Program>> getPrograms();
  Future<Program?> getProgramById(String id);
  Future<Program> createProgram(Program program);
  Future<Program> updateProgram(Program program);
  Future<void> deleteProgram(String id);
}

// Repository implementation with multiple data sources
class ProgramRepositoryImpl implements ProgramRepository {
  final ProgramLocalDataSource localDataSource;
  final ProgramRemoteDataSource remoteDataSource;
  final ProgramMockDataSource mockDataSource;
}
```

### Cache-Aside Pattern

The repository implements a **cache-aside pattern** with intelligent cache management:

1. **Read Operations**:
   - Check local cache first
   - If cache miss or expired, fetch from remote
   - Store response in cache
   - Return data to caller

2. **Write Operations**:
   - Update remote data source
   - Update local cache (write-through)
   - Return updated data

## 💾 Data Sources

### 1. Local Data Source (Cache Layer)

**Purpose**: Provides fast, offline-capable data access with automatic cache management.

**Current Implementation**: [`ProgramLocalDataSourceImpl`](lib/data/datasources/local/program_local_datasource.dart)
- In-memory cache for development
- 5-minute TTL (Time To Live)
- Automatic cache expiration
- Future: SQLite/Hive for persistent storage

**Features**:
```dart
// Cache management
Future<bool> isCacheExpired({Duration maxAge = Duration(minutes: 5)});
Future<DateTime?> getLastCacheUpdate();
Future<void> clearCache();

// Data operations
Future<List<Program>> getCachedPrograms();
Future<Program?> getCachedProgramById(String id);
Future<void> cacheProgram(Program program);
```

### 2. Remote Data Source (API Layer)

**Purpose**: Handles all network communication with the backend API.

**Implementation**: [`ProgramApiDataSource`](lib/data/datasources/remote/program_api_datasource.dart)
- RESTful API communication
- Response transformation
- Error handling and retries
- Network status awareness

**API Endpoints**:
```dart
// CRUD operations
GET    /api/programs              # List all programs
GET    /api/programs/{id}         # Get specific program
POST   /api/programs              # Create new program
PUT    /api/programs/{id}         # Update program
DELETE /api/programs/{id}         # Delete program
```

### 3. Mock Data Source (Development)

**Purpose**: Provides realistic test data for development and testing.

**Implementation**: [`MockProgramDataSource`](lib/data/datasources/mock/mock_program_datasource.dart)
- Predefined workout programs
- Simulated network delays
- Consistent test data
- Development environment support

**Sample Programs**:
- **Push/Pull/Legs**: 6-day advanced strength program
- **Upper/Lower Split**: 4-day intermediate program  
- **Full Body**: 3-day beginner program
- **Strength Focus**: 5-day powerlifting program

## 🧠 Cache Management Strategy

### Cache Behavior

**Cache Duration**: 5 minutes (configurable)
**Cache Strategy**: Cache-aside with write-through
**Cache Invalidation**: Time-based TTL + manual invalidation

### Cache Flow Examples

#### Reading Programs
```dart
// 1. Repository called
final programs = await repository.getPrograms();

// 2. Check cache validity
if (!await localDataSource.isCacheExpired()) {
  // Return cached data (fast path)
  return await localDataSource.getCachedPrograms();
}

// 3. Cache expired - fetch from API
final remotePrograms = await remoteDataSource.getPrograms();

// 4. Update cache
await localDataSource.cachePrograms(remotePrograms);

// 5. Return fresh data
return remotePrograms;
```

#### Creating a Program
```dart
// 1. Create on remote API
final createdProgram = await remoteDataSource.createProgram(program);

// 2. Update local cache (write-through)
await localDataSource.cacheProgram(createdProgram);

// 3. Return created program
return createdProgram;
```

### Cache Invalidation Scenarios

1. **Time-based Expiration**: Automatic after 5 minutes
2. **Manual Invalidation**: After write operations
3. **App Restart**: In-memory cache cleared
4. **Force Refresh**: User-triggered cache clear

## 📱 Different Update Scenarios

### Scenario 1: User Updates Program in App

**Flow**: User edits a program through the UI
```dart
// User edits program in UI
final updatedProgram = program.copyWith(name: 'New Name');

// Repository handles the flow:
await programRepository.updateProgram(updatedProgram);

// What happens internally:
// 1. API call: PUT /programs/{id} with updated data
// 2. Cache update: Store the updated program locally (write-through)
// 3. UI refresh: New data is immediately available from cache
```

**Timeline**:
- ⚡ **0ms**: User submits form
- 🔄 **50ms**: Repository validates and calls API
- 🌐 **200ms**: API responds with updated program
- 💾 **210ms**: Cache updated with new data
- ✅ **220ms**: UI shows updated program

**Benefits**:
- Immediate UI feedback
- Consistent data across app
- Offline resilience (write operations queued)

### Scenario 2: Program Updated by Another User/Device

**Flow**: Another user or device updates the same program
```dart
// Next time user opens the app or pulls to refresh:
await programRepository.getPrograms();

// What happens internally:
// 1. Check cache expiration (5 minutes)
// 2. If expired: Fetch from API (gets the latest data)
// 3. Update cache with fresh data including changes from other users
// 4. Return updated programs to UI
```

**Timeline**:
- 🕐 **T+0**: Other user updates program on their device
- 🌐 **T+1s**: Update reaches API server
- ⏰ **T+5min**: Current user's cache expires
- 🔄 **T+5min+1s**: User navigates to programs screen
- 📡 **T+5min+200ms**: Fresh data fetched from API
- ✅ **T+5min+300ms**: User sees updated program

**Conflict Handling**:
- Last-write-wins strategy (current implementation)
- Future: Conflict resolution with user choice
- Version-based updates with conflict detection

### Scenario 3: Manual Cache Refresh

**Flow**: User pulls to refresh or force refreshes data
```dart
// User pulls to refresh
await programRepository.refreshCache();

// What happens internally:
// 1. Clear all cached data immediately
// 2. Force fetch from API regardless of TTL
// 3. Update cache with fresh data
// 4. Trigger UI rebuild with new data
```

**Implementation**:
```dart
@override
Future<void> refreshCache() async {
  // Clear local cache
  if (localDataSource != null) {
    await localDataSource!.clearCache();
  }

  // Trigger fresh fetch
  await getPrograms();
}
```

**UI Integration**:
```dart
RefreshIndicator(
  onRefresh: () async {
    await programRepository.refreshCache();
    setState(() {}); // Trigger rebuild
  },
  child: ProgramsList(),
)
```

## 🎯 Cache Optimization Recommendations

### 1. Granular Caching Strategy

**Current**: Cache all programs as a single unit
**Recommended**: Individual program caching for better performance

```dart
// Instead of caching all programs as one file
await localDataSource.cachePrograms(allPrograms);

// Cache individual programs with specific keys
for (final program in programs) {
  await localDataSource.cacheProgram(program); // Key: "program_${program.id}"
}

// Benefits:
// - Faster individual program updates
// - Reduced memory usage
// - Partial cache invalidation
```

### 2. Background Sync Strategy

**Implementation**: Periodic background synchronization
```dart
// Background sync service
class BackgroundSyncService {
  Timer? _syncTimer;

  void startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(hours: 1), (_) async {
      await _syncProgramsInBackground();
    });
  }

  Future<void> _syncProgramsInBackground() async {
    try {
      // Sync only if network available
      if (await NetworkInfo.isConnected()) {
        await programRepository.refreshCache();
      }
    } catch (e) {
      // Log error but don't interrupt user experience
      print('Background sync failed: $e');
    }
  }
}
```

### 3. Optimistic Updates Pattern

**Purpose**: Immediate UI feedback with background API sync
```dart
Future<void> updateProgramOptimistically(Program updatedProgram) async {
  // 1. Update UI immediately (optimistic)
  await localDataSource.cacheProgram(updatedProgram);
  notifyListeners(); // Update UI instantly

  try {
    // 2. Sync with API in background
    final apiProgram = await remoteDataSource.updateProgram(updatedProgram);
    
    // 3. Update cache with API response (may have server-generated fields)
    await localDataSource.cacheProgram(apiProgram);
    
  } catch (e) {
    // 4. Rollback on API failure
    await localDataSource.revertProgram(updatedProgram.id);
    notifyListeners(); // Show original state
    
    // Show error to user
    throw RepositoryException('Update failed, please try again');
  }
}
```

### 4. Smart Cache Preloading

**Strategy**: Preload likely-to-be-accessed data
```dart
class SmartCachePreloader {
  Future<void> preloadUserPrograms() async {
    // Preload user's active programs
    final activePrograms = await repository.getActivePrograms();
    
    // Preload workout sessions for next 7 days
    for (final program in activePrograms) {
      final upcomingWorkouts = program.getUpcomingWorkouts(days: 7);
      for (final workout in upcomingWorkouts) {
        // Preload workout details
        await repository.preloadWorkoutSession(workout.id);
      }
    }
  }
}
```

### 5. Memory-Efficient Caching

**Implementation**: LRU cache with size limits
```dart
class LRUProgramCache {
  final int maxSize;
  final LinkedHashMap<String, Program> _cache = LinkedHashMap();

  LRUProgramCache({this.maxSize = 50});

  Program? get(String id) {
    final program = _cache.remove(id);
    if (program != null) {
      _cache[id] = program; // Move to end (most recently used)
    }
    return program;
  }

  void put(String id, Program program) {
    _cache.remove(id);
    _cache[id] = program;

    // Remove oldest if over limit
    while (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }
}
```

### 6. Cache Compression

**Purpose**: Reduce storage space for large datasets
```dart
import 'dart:convert';
import 'dart:io';

class CompressedCache {
  Future<void> cacheCompressedPrograms(List<Program> programs) async {
    final json = jsonEncode(programs.map((p) => p.toJson()).toList());
    final bytes = utf8.encode(json);
    final compressed = gzip.encode(bytes);
    
    await storageService.writeBytes('programs_cache.gz', compressed);
  }

  Future<List<Program>> getCompressedPrograms() async {
    final compressed = await storageService.readBytes('programs_cache.gz');
    final bytes = gzip.decode(compressed);
    final json = utf8.decode(bytes);
    final List<dynamic> data = jsonDecode(json);
    
    return data.map((item) => Program.fromJson(item)).toList();
  }
}
```

### 7. Network-Aware Caching

**Strategy**: Adjust cache behavior based on network conditions
```dart
class NetworkAwareRepository extends ProgramRepositoryImpl {
  @override
  Future<List<Program>> getPrograms() async {
    final networkInfo = await NetworkInfo.getNetworkInfo();
    
    // Adjust cache TTL based on network quality
    Duration cacheTTL;
    if (networkInfo.isWiFi) {
      cacheTTL = Duration(minutes: 2); // Shorter TTL on WiFi
    } else if (networkInfo.isMobile) {
      cacheTTL = Duration(minutes: 10); // Longer TTL on mobile data
    } else {
      cacheTTL = Duration(hours: 1); // Much longer when offline
    }

    final isExpired = await localDataSource.isCacheExpired(maxAge: cacheTTL);
    
    if (!isExpired) {
      return await localDataSource.getCachedPrograms();
    }

    // Proceed with normal cache miss handling
    return await super.getPrograms();
  }
}
```

### 8. Cache Performance Monitoring

**Implementation**: Track cache effectiveness
```dart
class CacheMetrics {
  static int _hits = 0;
  static int _misses = 0;
  static int _writes = 0;

  static void recordHit() => _hits++;
  static void recordMiss() => _misses++;
  static void recordWrite() => _writes++;

  static double get hitRatio => _hits / (_hits + _misses);
  static Map<String, dynamic> get metrics => {
    'hits': _hits,
    'misses': _misses,
    'writes': _writes,
    'hitRatio': hitRatio,
  };
}
```

These optimizations can be implemented incrementally, starting with the most impactful ones like granular caching and optimistic updates.

## 🔧 Service Layer

### API Service
**File**: [`api_service.dart`](lib/services/api_service.dart)
- HTTP client management (Dio/http)
- Request/response interceptors
- Authentication header injection
- Error handling and retries

### Storage Service  
**File**: [`storage_service.dart`](lib/services/storage_service.dart)
- Persistent local storage
- Secure storage for tokens
- User preferences
- Offline data management

### Service Locator
**File**: [`service_locator.dart`](lib/services/service_locator.dart)
- Dependency injection
- Service instance management
- Environment-specific configuration
- Singleton pattern implementation

## 🔀 Environment Configuration

### Development Environment
```dart
ProgramRepositoryImpl.development()
// Uses: MockDataSource + InMemoryCache
// Purpose: Fast development with realistic data
```

### Testing Environment
```dart
ProgramRepositoryImpl.testing()
// Uses: MockDataSource + NoCache
// Purpose: Predictable test scenarios
```

### Production Environment
```dart
ProgramRepositoryImpl.production()
// Uses: ApiDataSource + SQLiteCache
// Purpose: Real API with persistent cache
```

## 📊 Data Models

### Core Models
Located in [`lib/models/workout_models.dart`](lib/models/workout_models.dart):

- **`Program`**: Complete workout program with scheduling
- **`WorkoutSession`**: Individual workout instance
- **`WorkoutExercise`**: Exercise within a workout
- **`ExerciseSet`**: Individual set tracking (weight, reps, notes)
- **`Exercise`**: Exercise definition and metadata

### Response Models
Located in [`lib/data/models/responses/`](lib/data/models/responses/):

- **`ApiResponse<T>`**: Standardized API response wrapper
- **`ProgramResponse`**: API-specific program data transfer object

### Model Features
- **JSON Serialization**: Full toJson/fromJson support
- **Null Safety**: Comprehensive null safety implementation
- **Validation**: Built-in data validation
- **Copy Methods**: Immutable updates with copyWith
- **Equality**: Proper equality and hashCode implementation

## 🚀 Usage Examples

### Basic Repository Usage
```dart
// Inject repository (typically through service locator)
final repository = ServiceLocator.get<ProgramRepository>();

// Get all programs (cache-first)
final programs = await repository.getPrograms();

// Get specific program
final program = await repository.getProgramById('push_pull_legs');

// Create new program
final newProgram = Program.create(
  name: 'Custom Strength',
  type: ProgramType.strength,
  difficulty: ProgramDifficulty.intermediate,
);
final created = await repository.createProgram(newProgram);
```

### UI Integration Example
```dart
class ProgramsScreen extends StatefulWidget {
  final ProgramRepository programRepository;

  const ProgramsScreen({
    super.key,
    ProgramRepository? programRepository,
  }) : programRepository = programRepository ?? 
       ServiceLocator.get<ProgramRepository>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Program>>(
      future: programRepository.getPrograms(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ProgramList(programs: snapshot.data!);
        }
        return LoadingIndicator();
      },
    );
  }
}
```

### Cache Management
```dart
// Force cache refresh
await repository.clearCache();
final freshPrograms = await repository.getPrograms();

// Check cache status
final isExpired = await localDataSource.isCacheExpired();
final lastUpdate = await localDataSource.getLastCacheUpdate();
```

## 🧪 Testing Strategy

### Unit Tests
- **Repository Layer**: Mock data sources, test cache logic
- **Data Sources**: Test individual source implementations
- **Models**: Validate serialization and business logic

### Integration Tests
- **End-to-End**: Test complete data flow
- **Cache Behavior**: Verify cache invalidation and updates
- **Network Scenarios**: Test offline/online transitions

### Example Test Structure
```dart
group('ProgramRepository', () {
  late MockProgramLocalDataSource mockLocal;
  late MockProgramRemoteDataSource mockRemote;
  late ProgramRepositoryImpl repository;

  setUp(() {
    mockLocal = MockProgramLocalDataSource();
    mockRemote = MockProgramRemoteDataSource();
    repository = ProgramRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
    );
  });

  test('should return cached programs when cache is valid', () async {
    // Arrange
    when(() => mockLocal.isCacheExpired()).thenAnswer((_) async => false);
    when(() => mockLocal.getCachedPrograms()).thenAnswer((_) async => programs);

    // Act
    final result = await repository.getPrograms();

    // Assert
    expect(result, equals(programs));
    verifyNever(() => mockRemote.getPrograms());
  });
});
```

## 🔮 Future Enhancements

### Planned Improvements

1. **SQLite Integration**: Replace in-memory cache with persistent SQLite storage
2. **Offline Sync**: Queue changes for sync when network returns
3. **Real-time Updates**: WebSocket support for live data updates
4. **Advanced Caching**: LRU cache with size limits
5. **Data Encryption**: Encrypt sensitive local data
6. **Pagination**: Support for large dataset pagination
7. **Background Sync**: Periodic data synchronization
8. **Conflict Resolution**: Handle data conflicts during sync

### Performance Optimizations

1. **Lazy Loading**: Load program details on demand
2. **Image Caching**: Efficient workout image management
3. **Incremental Updates**: Delta sync for changed data only
4. **Memory Management**: Optimized cache size and cleanup

## 📈 Monitoring & Analytics

### Metrics to Track
- Cache hit/miss ratios
- API response times
- Network failure rates
- Data sync success rates
- User engagement with cached vs fresh data

### Error Handling
- Graceful degradation when API unavailable
- User-friendly error messages
- Automatic retry mechanisms
- Offline state indicators

## 🔗 Related Documentation

- **[Programs Feature Documentation](docs/programs-feature.md)**: User-facing program features
- **[Authentication Guide](docs/authentication.md)**: User authentication setup
- **[Styling System](docs/styling-system.md)**: UI styling and theming
- **[Color Theming Guide](docs/color-theming-guide.md)**: Color system usage

---

> **Note**: This data architecture provides a solid foundation for the FlutterLifter fitness tracking application, with room for growth and enhancement as the application scales.