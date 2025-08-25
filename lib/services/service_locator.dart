import '../data/repositories/program_repository.dart';
import '../data/datasources/mock/mock_program_datasource.dart';
import '../data/datasources/local/program_local_datasource.dart';
import '../data/datasources/remote/program_api_datasource.dart';
import '../core/network/network_info.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/workout_service.dart';

/// Simple service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Initialize all services
  Future<void> init() async {
    // Register core services
    register<StorageService>(InMemoryStorageService());
    register<NetworkInfo>(const MockNetworkInfo(isConnected: true));
    register<ApiService>(MockApiService());

    // Register data sources
    register<MockProgramDataSource>(MockProgramDataSource());
    register<ProgramLocalDataSource>(ProgramLocalDataSourceImpl());

    // Note: API data source would be registered in production
    // register<ProgramApiDataSource>(HttpProgramApiDataSource());

    // Register repositories
    register<ProgramRepository>(ProgramRepositoryImpl.development());

    // Register services
    register<WorkoutService>(WorkoutService(get<ProgramRepository>()));

    // Initialize storage
    await get<StorageService>().init();
  }

  /// Production initialization
  Future<void> initProduction() async {
    // Register production services
    register<StorageService>(
        InMemoryStorageService()); // Would use SharedPreferences/Hive
    register<NetworkInfo>(NetworkInfoImpl()); // Would use connectivity_plus
    register<ApiService>(HttpApiService());

    // Register production data sources
    register<ProgramApiDataSource>(HttpProgramApiDataSource());
    register<ProgramLocalDataSource>(ProgramLocalDataSourceImpl());

    // Register production repository
    register<ProgramRepository>(
      ProgramRepositoryImpl.production(
        apiDataSource: get<ProgramApiDataSource>(),
        localDataSource: get<ProgramLocalDataSource>(),
      ),
    );

    // Register services
    register<WorkoutService>(WorkoutService(get<ProgramRepository>()));

    // Initialize storage
    await get<StorageService>().init();
  }

  /// Clear all services (for testing)
  void clear() {
    _services.clear();
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();
