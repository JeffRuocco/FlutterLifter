# Riverpod State Management Guide

This document explains how Riverpod is used throughout the FlutterLifter application for dependency injection and state management.

## Table of Contents

- [Overview](#overview)
- [What is a Provider?](#what-is-a-provider)
- [Why Riverpod?](#why-riverpod)
- [Architecture](#architecture)
- [Provider Types Used](#provider-types-used)
- [Provider Organization](#provider-organization)
- [Usage Patterns](#usage-patterns)
- [Testing with Riverpod](#testing-with-riverpod)
- [Best Practices](#best-practices)

---

## Overview

FlutterLifter uses [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) (version ^2.6.1) for:

- **Dependency Injection**: Providing services, repositories, and configurations throughout the app
- **State Management**: Managing UI state with reactive updates
- **Async Operations**: Handling loading states and errors gracefully

---

## What is a Provider?

A **provider** is a declarative way to expose and manage a piece of state or a dependency. Think of it as a "smart global variable" that:

1. **Creates objects on demand** - The object is only created when first accessed
2. **Manages lifecycle** - Automatically disposes resources when no longer needed
3. **Enables reactivity** - UI components can subscribe to changes and rebuild automatically
4. **Supports dependency injection** - Providers can depend on other providers

### The Problem Providers Solve

Without providers, you might pass dependencies through constructors:

```dart
// ❌ Without providers: Constructor drilling
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repository = ProgramRepository();
    final service = WorkoutService(repository);
    
    return HomeScreen(service: service); // Must pass to every screen
  }
}

class HomeScreen extends StatelessWidget {
  final WorkoutService service;
  HomeScreen({required this.service});
  // ...
}
```

With providers, dependencies are available anywhere:

```dart
// ✅ With providers: Access anywhere via ref
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(workoutServiceProvider);
    // No constructor drilling needed!
  }
}
```

### Provider as a Contract

A provider defines:

- **What** is being provided (the type)
- **How** to create it (the factory function)
- **When** to recreate it (dependencies via `ref.watch`)

```dart
// This provider promises to give you a WorkoutService
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  // It depends on programRepositoryProvider
  final repository = ref.watch(programRepositoryProvider);
  // And creates the service like this
  return WorkoutService(repository);
});
```

### Key Concept: Services Should Be Accessed Through Providers

> ⚠️ **Important**: Never instantiate services directly (e.g., `WorkoutService(repo)`).
> Always access them through their corresponding provider.

This ensures:

- Consistent instance across the app (singleton behavior)
- Proper dependency injection
- Testability via provider overrides
- Correct lifecycle management

```dart
// ❌ WRONG: Direct instantiation
final service = WorkoutService(someRepository);

// ✅ CORRECT: Access via provider
final service = ref.read(workoutServiceProvider);

// ✅ EVEN BETTER: Use the notifier for UI state
final notifier = ref.read(workoutNotifierProvider.notifier);
await notifier.startWorkout(session);
```

## Why Riverpod?

| Benefit | Description |
| ------- | ----------- |
| **Type-safe** | Compile-time safety when accessing providers |
| **No BuildContext dependency** | Access state anywhere without context |
| **Automatic disposal** | Resources are cleaned up when no longer needed |
| **Easy testing** | Override providers in tests without mocking frameworks |
| **Reactive** | UI automatically rebuilds when state changes |

---

## Architecture

FlutterLifter follows a layered architecture where Riverpod connects each layer:

```text
┌─────────────────────────────────────────────────────────────────┐
│  UI Layer (Screens & Widgets)                                   │
│  - ConsumerWidget / ConsumerStatefulWidget                      │
│  - Uses ref.watch() for reactive state                          │
│  - Uses ref.read() for one-time access / actions                │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  State Management Layer (Providers)                             │
│  - StateNotifierProvider for complex state                      │
│  - Provider for simple dependencies                             │
│  - FutureProvider for async data                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  Business Logic Layer (Services)                                │
│  - Framework-agnostic services                                  │
│  - Business rules and operations                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  Data Layer (Repositories & Datasources)                        │
│  - Data access abstraction                                      │
│  - Caching and persistence                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Provider Types Used

### 1. `Provider` - Simple Dependency Injection

Used for services, repositories, and configurations that don't change.

```dart
// lib/core/providers/repository_providers.dart
final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  final mockDataSource = ref.watch(mockProgramDataSourceProvider);
  final localDataSource = ref.watch(programLocalDataSourceProvider);
  return ProgramRepositoryImpl(
    mockDataSource: mockDataSource,
    localDataSource: localDataSource,
  );
});

// lib/core/providers/storage_provider.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  return InMemoryStorageService();
});

// lib/core/providers/api_provider.dart
final apiServiceProvider = Provider<ApiService>((ref) {
  return MockApiService();
});
```

### 2. `StateNotifierProvider` - Complex State Management

Used when state changes over time and the UI needs to react.

```dart
// lib/core/theme/theme_provider.dart
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_themeModeKey, mode.name);
  }
}

final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  throw UnimplementedError(
    'themeModeNotifierProvider must be overridden with SharedPreferences',
  );
});
```

```dart
// lib/core/providers/workout_provider.dart
class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final WorkoutService _workoutService;
  final Ref _ref;

  WorkoutNotifier(this._workoutService, this._ref) : super(const WorkoutState());

  Future<void> startWorkout(WorkoutSession session) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _workoutService.startWorkout(session);
      state = state.copyWith(
        currentWorkout: _workoutService.currentWorkout,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final workoutNotifierProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final workoutService = ref.watch(workoutServiceProvider);
  return WorkoutNotifier(workoutService, ref);
});
```

### 3. `FutureProvider` - Async Data Loading

Used for one-time async data fetching with built-in loading/error states.

```dart
// lib/core/providers/settings_provider.dart
final appSettingsServiceProvider =
    FutureProvider<AppSettingsService>((ref) async {
  final service = AppSettingsService();
  await service.init();
  return service;
});

// lib/core/providers/storage_provider.dart
final storageInitProvider = FutureProvider<void>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  await storage.init();
});

// lib/core/providers/workout_provider.dart
final workoutHistoryProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getWorkoutHistory();
});
```

### 4. `StreamProvider` - Reactive Streams

Used for continuous data streams like connectivity status.

```dart
// lib/core/providers/network_provider.dart
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.connectivityStream;
});
```

### 5. Convenience Providers (Derived State)

Providers that derive state from other providers for cleaner UI access.

```dart
// lib/core/providers/workout_provider.dart
final currentWorkoutProvider = Provider<WorkoutSession?>((ref) {
  return ref.watch(workoutNotifierProvider).currentWorkout;
});

final hasActiveWorkoutProvider = Provider<bool>((ref) {
  return ref.watch(workoutNotifierProvider).hasActiveWorkout;
});

// lib/core/theme/theme_provider.dart
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeNotifierProvider);
  return themeMode == ThemeMode.dark;
});

// lib/core/providers/accessibility_provider.dart
final reduceMotionProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).reduceMotion;
});
```

---

## Provider Organization

All providers are organized in `lib/core/providers/`:

| File | Purpose |
| ---- | ------- |
| `providers.dart` | Barrel file exporting all providers |
| `repository_providers.dart` | Data repositories and datasources |
| `workout_provider.dart` | Workout state management |
| `storage_provider.dart` | Storage service providers |
| `settings_provider.dart` | App settings providers |
| `network_provider.dart` | Network/connectivity providers |
| `api_provider.dart` | API service providers |
| `accessibility_provider.dart` | Accessibility settings |

Additional providers in other locations:

| File | Purpose |
| ---- | ------- |
| `lib/core/theme/theme_provider.dart` | Theme mode management |
| `lib/core/router/app_router.dart` | GoRouter provider |

### Import Pattern

Use the barrel file for clean imports:

```dart
import '../core/providers/providers.dart';
```

---

## Usage Patterns

### In ConsumerWidget (Stateless)

```dart
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for reactive updates
    final themeMode = ref.watch(themeModeNotifierProvider);
    
    return Scaffold(
      body: Text('Current theme: $themeMode'),
    );
  }
}
```

### In ConsumerStatefulWidget (Stateful)

```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to safely read providers in initState
    Future.microtask(() {
      ref.read(workoutNotifierProvider.notifier).loadNextWorkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch state for reactive rebuilds
    final workoutState = ref.watch(workoutNotifierProvider);
    
    if (workoutState.isLoading) {
      return const CircularProgressIndicator();
    }
    
    return Text('Workout: ${workoutState.currentWorkout?.programName}');
  }
}
```

### ref.watch() vs ref.read()

| Method | When to Use | Rebuilds UI? |
| ------ | ----------- | ------------ |
| `ref.watch()` | In `build()` method for reactive state | ✅ Yes |
| `ref.read()` | In callbacks, `initState`, event handlers | ❌ No |

```dart
@override
Widget build(BuildContext context) {
  // ✅ CORRECT: watch in build for reactive updates
  final workout = ref.watch(currentWorkoutProvider);
  
  return ElevatedButton(
    onPressed: () {
      // ✅ CORRECT: read in callback for one-time access
      ref.read(workoutNotifierProvider.notifier).finishWorkout();
    },
    child: Text('Finish Workout'),
  );
}
```

### Accessing Notifier Methods

```dart
// Get the notifier to call methods
final notifier = ref.read(workoutNotifierProvider.notifier);
await notifier.startWorkout(session);
await notifier.saveWorkout();
await notifier.finishWorkout();
```

### Handling Async State (FutureProvider)

```dart
final historyAsync = ref.watch(workoutHistoryProvider);

historyAsync.when(
  data: (sessions) => ListView.builder(
    itemCount: sessions.length,
    itemBuilder: (context, index) => Text(sessions[index].programName),
  ),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

---

## Testing with Riverpod

### Override Providers in Tests

```dart
// test/widget_test.dart
void main() {
  testWidgets('Login page loads correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override provider with test implementation
          themeModeNotifierProvider.overrideWith(
            (ref) => ThemeModeNotifier(prefs),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('FlutterLifter'), findsOneWidget);
  });
}
```

### Mock Repository for Testing

```dart
class MockProgramRepository extends ProgramRepository {
  @override
  Future<List<Program>> getPrograms() async {
    return [Program(id: '1', name: 'Test Program')];
  }
}

testWidgets('Programs screen shows mock data', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        programRepositoryProvider.overrideWithValue(MockProgramRepository()),
      ],
      child: const MaterialApp(home: ProgramsScreen()),
    ),
  );
});
```

---

## Best Practices

### 1. Provider Initialization at App Start

For providers that require async initialization (like SharedPreferences), override them in `main()`:

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        themeModeNotifierProvider.overrideWith(
          (ref) => ThemeModeNotifier(sharedPreferences),
        ),
      ],
      child: const FlutterLifterApp(),
    ),
  );
}
```

### 2. Immutable State Classes

Use immutable state with `copyWith()` for StateNotifier:

```dart
class WorkoutState {
  final WorkoutSession? currentWorkout;
  final bool isLoading;
  final String? error;

  const WorkoutState({
    this.currentWorkout,
    this.isLoading = false,
    this.error,
  });

  WorkoutState copyWith({
    WorkoutSession? currentWorkout,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutState(
      currentWorkout: currentWorkout ?? this.currentWorkout,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
```

### 3. Separate Services from Providers

Keep business logic in framework-agnostic services, wrap with providers for UI:

```dart
// Service: Pure business logic (no Riverpod)
class WorkoutService {
  Future<void> startWorkout(WorkoutSession session) async { ... }
}

// Provider: Wraps service for reactive UI state
class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final WorkoutService _workoutService;
  
  Future<void> startWorkout(WorkoutSession session) async {
    state = state.copyWith(isLoading: true);
    await _workoutService.startWorkout(session);
    state = state.copyWith(isLoading: false);
  }
}
```

### 4. Use Convenience Providers for Clean UI Code

Create derived providers to simplify widget code:

```dart
// Instead of this in every widget:
final hasActive = ref.watch(workoutNotifierProvider).currentWorkout?.isInProgress == true;

// Create a convenience provider:
final hasActiveWorkoutProvider = Provider<bool>((ref) {
  return ref.watch(workoutNotifierProvider).hasActiveWorkout;
});

// Then use simply:
final hasActive = ref.watch(hasActiveWorkoutProvider);
```

### 5. Avoid Provider in Provider Anti-Pattern

Use `ref.watch()` for dependencies, not `ref.read()`:

```dart
// ✅ CORRECT: Dependencies will update when programRepositoryProvider changes
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  final repository = ref.watch(programRepositoryProvider);
  return WorkoutService(repository);
});

// ❌ AVOID: Won't update if programRepositoryProvider changes
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  final repository = ref.read(programRepositoryProvider);
  return WorkoutService(repository);
});
```

---

## Quick Reference

### Common Provider Patterns

| Need | Provider Type | Example |
| ---- | ------------- | ------- |
| Singleton service | `Provider` | `apiServiceProvider` |
| Mutable UI state | `StateNotifierProvider` | `workoutNotifierProvider` |
| One-time async load | `FutureProvider` | `workoutHistoryProvider` |
| Continuous stream | `StreamProvider` | `connectivityStreamProvider` |
| Derived/computed state | `Provider` | `hasActiveWorkoutProvider` |

### Widget Type Selection

| Widget Type | Use When |
| ----------- | -------- |
| `ConsumerWidget` | Stateless widget that needs providers |
| `ConsumerStatefulWidget` | Stateful widget that needs providers |
| `HookConsumerWidget` | Using flutter_hooks with Riverpod |

---

## Related Documentation

- [Design Guidelines](design-guidelines.md) - Overall architecture patterns
- [Data Architecture](data-architecture.md) - Repository and datasource patterns
- [Workout Service Integration](workout-service-integration.md) - Service/provider relationship example
