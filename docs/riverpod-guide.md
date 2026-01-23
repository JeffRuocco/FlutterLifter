# Riverpod State Management Guide

This document explains how Riverpod is used throughout the FlutterLifter application for dependency injection and state management.

## Table of Contents

- [Data Access Cheatsheet](#data-access-cheatsheet) ← **Start here!**
- [Overview](#overview)
- [What is a Provider?](#what-is-a-provider)
- [Why Riverpod?](#why-riverpod)
- [Architecture](#architecture)
- [Provider Types Used](#provider-types-used)
- [Provider Organization](#provider-organization)
- [Usage Patterns](#usage-patterns)
- [Common Usage Examples](#common-usage-examples)
- [Testing with Riverpod](#testing-with-riverpod)
- [Best Practices](#best-practices)

---

## Data Access Cheatsheet

> **Quick reference for choosing the right data access pattern.** Use this when you're unsure which layer to use.

Tip:
> **UI almost always goes through NotifierProvider for actions.** The notifier handles state and delegates to services internally.

### Decision Flowchart

```txt
Need data in a widget?
│
├─► Need reactive UI updates? ──► ref.watch(provider)
│
├─► One-time action (button tap)? ──► ref.read(notifierProvider.notifier).method()
│
├─► Need loading/error states? ──► ref.watch(futureProvider).when(...)
│
└─► Complex multi-step operation? ──► ref.read(serviceProvider).method()
                                      └─► Service uses Repository internally
```

### Layer Responsibilities

| Layer | What It Does | When to Use | Example |
| ----- | ------------ | ----------- | ------- |
| **Provider** | Exposes dependencies to UI | Always (never instantiate directly) | `ref.watch(workoutNotifierProvider)` |
| **Notifier** | Manages UI state + coordinates services | UI needs reactive state updates | `notifier.startWorkout(session)` |
| **Service** | Business logic & orchestration | Complex operations spanning multiple repos | `workoutService.finishWorkout()` |
| **Repository** | Data access abstraction | CRUD operations, caching | `repo.saveWorkout(session)` |
| **DataSource** | Raw data I/O | Direct storage/API calls (rarely used directly) | `localDataSource.write(data)` |

### Quick Decision Table

| I want to... | Use this | Code example |
| ------------ | -------- | ------------ |
| **Display data reactively** | `ref.watch()` + Provider | `final workout = ref.watch(currentWorkoutProvider);` |
| **Trigger an action** | `ref.read()` + Notifier | `ref.read(workoutNotifierProvider.notifier).startWorkout(s);` |
| **Load async data with loading state** | `ref.watch()` + FutureProvider | `ref.watch(programsProvider).when(...)` |
| **Save/update/delete data** | Notifier method (preferred) | `notifier.saveWorkout();` |
| **Complex business operation** | Service via Notifier | `notifier.finishWorkout();` → calls service internally |
| **Direct data query (rare)** | Repository | `final data = await ref.read(repoProvider).getPrograms();` |

### Common Patterns by Use Case

#### Reading Data

```dart
// ✅ Reactive list (rebuilds on changes)
final programs = ref.watch(programsProvider);

// ✅ Reactive single value
final currentWorkout = ref.watch(currentWorkoutProvider);

// ✅ Async data with states
ref.watch(workoutHistoryProvider).when(
  data: (history) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);

// ⚠️ One-time read (use sparingly, only in callbacks)
final repo = ref.read(programRepositoryProvider);
```

#### Writing Data

```dart
// ✅ PREFERRED: Through notifier (manages state + persistence)
final notifier = ref.read(workoutNotifierProvider.notifier);
notifier.updateSet(exerciseIndex, setIndex, newSet);
await notifier.saveWorkout();

// ⚠️ Direct repo access (only when notifier doesn't exist for this data)
final repo = ref.read(programRepositoryProvider);
await repo.saveProgram(program);
```

#### Complex Operations

```dart
// ✅ Notifier orchestrates the operation
await ref.read(workoutNotifierProvider.notifier).finishWorkout();
// Internally: validates → saves → updates history → clears state

// ❌ DON'T: Call service directly from UI
final service = ref.read(workoutServiceProvider);
await service.finishWorkout(); // Bypasses state management!
```

### When to Use Each Layer

#### Use **Notifier** when

- UI needs to react to state changes
- Operation affects displayed data
- Need loading/error states in UI
- Coordinating multiple service calls

```dart
// Notifier handles state + delegates to service
class WorkoutNotifier extends Notifier<WorkoutState> {
  Future<void> startWorkout(WorkoutSession session) async {
    state = state.copyWith(isLoading: true);
    await _workoutService.startWorkout(session);
    state = state.copyWith(currentWorkout: session, isLoading: false);
  }
}
```

#### Use **Service** when

- Business logic spans multiple repositories
- Need framework-agnostic code (testable without Flutter)
- Complex validation or transformation
- Operation doesn't need immediate UI feedback

```dart
// Service contains business logic
class WorkoutService {
  Future<void> finishWorkout() async {
    final session = currentWorkout!.copyWith(endTime: DateTime.now());
    await _repository.saveWorkout(session);
    await _repository.addToHistory(session);
  }
}
```

#### Use **Repository** when

- Simple CRUD operations
- Need caching layer
- Abstracting data source (local vs remote)
- No notifier exists for this data type

```dart
// Repository handles data access
final repo = ref.read(programRepositoryProvider);
final programs = await repo.getPrograms();
await repo.saveProgram(newProgram);
```

### Anti-Patterns to Avoid

| ❌ Don't | ✅ Do Instead | Why |
| -------- | ------------- | --- |
| `WorkoutService(repo)` | `ref.read(workoutServiceProvider)` | Breaks DI, creates multiple instances |
| `ref.watch()` in callbacks | `ref.read()` in callbacks | Watch causes rebuilds |
| `ref.read()` in build | `ref.watch()` in build | Read won't update UI |
| Call service from UI | Call notifier from UI | Service bypasses state management |
| Repository in widget | Notifier/Provider in widget | Repository is too low-level for UI |

### Which Provider Type to Use

All of these are **types of providers** - pick the one that fits your use case:

| Scenario | Provider Type | Example |
| -------- | ------------- | ------- |
| Singleton service/repo | `Provider` | `programRepositoryProvider` |
| Mutable UI state | `NotifierProvider` | `workoutNotifierProvider` |
| One-time async fetch | `FutureProvider` | `programsProvider` |
| Continuous stream | `StreamProvider` | `connectivityStreamProvider` |
| Derived/computed value | `Provider` | `hasActiveWorkoutProvider` |
| Parameterized query | `*.family` variant | `programByIdProvider(id)` |

### ref.watch() vs ref.read() Summary

```dart
@override
Widget build(BuildContext context) {
  // ✅ WATCH in build() - UI rebuilds when state changes
  final state = ref.watch(workoutNotifierProvider);
  final isActive = ref.watch(hasActiveWorkoutProvider);
  
  return ElevatedButton(
    onPressed: () {
      // ✅ READ in callbacks - one-time access, no rebuild
      ref.read(workoutNotifierProvider.notifier).startWorkout(session);
    },
    child: Text('Start'),
  );
}

@override
void initState() {
  super.initState();
  // ✅ READ in initState (wrapped in microtask)
  Future.microtask(() {
    ref.read(workoutNotifierProvider.notifier).loadNextWorkout();
  });
}
```

### Types of Providers

Riverpod offers several **types** of providers. They're all "providers" - each is just optimized for different use cases.

```txt
All Provider Types (each is a flavor of "provider")
│
├── Provider              → Static value (service, repo, config, derived state)
├── NotifierProvider      → Mutable state + methods to change it
├── FutureProvider        → Async data with built-in loading/error states
├── StreamProvider        → Continuous stream of values
└── StateProvider         → Simple mutable primitive (rarely used)
```

#### Quick Comparison

| Provider Type | What It Exposes | State Changes? | Best For |
| ------------- | --------------- | -------------- | -------- |
| **`Provider`** | A single value | No* | Services, repos, configs, derived values |
| **`NotifierProvider`** | State object + notifier with methods | Yes | UI state that changes over time |
| **`FutureProvider`** | Async result with loading/error | No** | One-time data fetches |
| **`StreamProvider`** | Stream values | Yes (each emission) | Real-time updates, connectivity |

\* Value is fixed unless dependencies change, then it recreates  
\** Result is cached; use `.future` or invalidate to refresh

#### `Provider` - Static Dependencies

Use for things that don't change (or only change when dependencies change):

```dart
// Services - stateless utilities
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  return WorkoutService(ref.watch(programRepositoryProvider));
});

// Repositories - data access
final programRepositoryProvider = Provider<ProgramRepository>((ref) => ...);

// Derived/computed values - based on other providers
final hasActiveWorkoutProvider = Provider<bool>((ref) {
  return ref.watch(workoutNotifierProvider).currentWorkout?.isInProgress ?? false;
});

// Configuration
final apiConfigProvider = Provider<ApiConfig>((ref) => ApiConfig(baseUrl: '...'));
```

**Key point**: The value itself doesn't change. You can call methods on services, but `Provider` doesn't track internal state changes.

#### `NotifierProvider` - Mutable UI State

Use when **state changes over time** and **UI needs to react**:

```dart
final workoutNotifierProvider = NotifierProvider<WorkoutNotifier, WorkoutState>(
  WorkoutNotifier.new,
);

class WorkoutNotifier extends Notifier<WorkoutState> {
  @override
  WorkoutState build() => const WorkoutState();  // Initial state
  
  Future<void> startWorkout(WorkoutSession session) async {
    state = state.copyWith(isLoading: true);      // UI rebuilds (shows spinner)
    await _service.startWorkout(session);
    state = state.copyWith(                       // UI rebuilds (shows workout)
      currentWorkout: session,
      isLoading: false,
    );
  }
}
```

**You get two things from a NotifierProvider:**

```dart
// 1. The STATE - watch this for reactive UI
final workoutState = ref.watch(workoutNotifierProvider);  // → WorkoutState

// 2. The NOTIFIER - read this to call methods
final notifier = ref.read(workoutNotifierProvider.notifier);  // → WorkoutNotifier
notifier.startWorkout(session);
```

#### `FutureProvider` - Async Data with Loading States

Use for **one-time async fetches** where you want built-in loading/error handling:

```dart
final programsProvider = FutureProvider<List<Program>>((ref) async {
  final repo = ref.watch(programRepositoryProvider);
  return repo.getPrograms();
});

// In widget - automatic loading/error states!
ref.watch(programsProvider).when(
  data: (programs) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

#### `StreamProvider` - Continuous Updates

Use for **real-time data streams**:

```dart
final connectivityProvider = StreamProvider<bool>((ref) {
  return connectivityService.onConnectivityChanged;
});
```

### Provider vs NotifierProvider: When to Choose

The key question: **"Does the UI need to react to state changes triggered by my code?"**

| Scenario | Provider Type | Why |
| -------- | ------------- | --- |
| Repository for CRUD operations | `Provider` | Repository is stateless; UI doesn't watch it directly |
| API/HTTP client | `Provider` | Client is a utility; no internal state to track |
| Current workout being edited | `NotifierProvider` | State changes (sets added, exercises modified); UI must update |
| Theme mode toggle | `NotifierProvider` | User changes it; entire app must rebuild |
| List of programs (read-only fetch) | `FutureProvider` | One-time load with loading state |
| Derived value (is workout active?) | `Provider` | Computed from other state; auto-updates when source changes |

#### Why Not Make Everything a NotifierProvider?

Overkill. Services and repositories don't need state management - they're stateless utilities:

```dart
// ✅ Simple and correct - repository doesn't change
final programRepositoryProvider = Provider<ProgramRepository>((ref) => ...);

// ❌ Unnecessary complexity - what state would this even track?
final programRepositoryNotifierProvider = NotifierProvider<???, ???>(...);
```

#### The Relationship: NotifierProvider Uses Provider

Notifiers typically depend on services/repos exposed via `Provider`:

```dart
class WorkoutNotifier extends Notifier<WorkoutState> {
  late WorkoutService _service;
  
  @override
  WorkoutState build() {
    // Notifier gets service via Provider
    _service = ref.watch(workoutServiceProvider);  // ← Provider
    return const WorkoutState();
  }
  
  Future<void> startWorkout(WorkoutSession session) async {
    state = state.copyWith(isLoading: true);
    await _service.startWorkout(session);  // ← Delegates to service
    state = state.copyWith(currentWorkout: session, isLoading: false);
  }
}
```

#### Visual Summary

```txt
┌─────────────────────────────────────────────────────────────────────────┐
│                        ALL ARE PROVIDERS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Provider (static dependencies)                                  │   │
│  │  • Services, repositories, configs, derived values               │   │
│  │  • Value doesn't change (unless dependencies do)                 │   │
│  │  • ref.watch() or ref.read() to get the value                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              ▲                                          │
│                              │ depends on                               │
│                              │                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  NotifierProvider (mutable state)                                │   │
│  │  • UI state that changes over time                               │   │
│  │  • Setting state = ... triggers UI rebuilds                      │   │
│  │  • ref.watch() for state, ref.read().notifier for methods        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  FutureProvider (async data)                                     │   │
│  │  • One-time async fetches                                        │   │
│  │  • Built-in loading/error states via .when()                     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  StreamProvider (reactive streams)                               │   │
│  │  • Continuous data streams                                       │   │
│  │  • Each emission triggers UI rebuild                             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Overview

FlutterLifter uses [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) (version ^3.1.0) for:

- **Dependency Injection**: Providing services, repositories, and configurations throughout the app
- **State Management**: Managing UI state with reactive updates
- **Async Operations**: Handling loading states and errors gracefully

> **Note**: As of version 3.0, Riverpod uses the new `Notifier` pattern instead of the deprecated `StateNotifier`. All notifiers in this project have been migrated to use the modern Riverpod 3.x API.

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
│  - NotifierProvider for complex state                           │
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

### 2. `NotifierProvider` - Complex State Management

Used when state changes over time and the UI needs to react. In Riverpod 3.x, we use `Notifier` instead of the deprecated `StateNotifier`.

```dart
// lib/core/theme/theme_provider.dart
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Initial state - this throws because we need SharedPreferences
    throw UnimplementedError(
      'themeModeNotifierProvider must be overridden with SharedPreferences',
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    // Note: SharedPreferences access handled via subclass
  }
}

final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// For initialization with SharedPreferences, use an override helper:
dynamic createThemeModeProviderOverride(SharedPreferences prefs) {
  return themeModeNotifierProvider.overrideWith(
    () => _InitializedThemeModeNotifier(prefs),
  );
}

// Private subclass that provides initial state from SharedPreferences
class _InitializedThemeModeNotifier extends ThemeModeNotifier {
  final SharedPreferences _prefs;
  _InitializedThemeModeNotifier(this._prefs);

  @override
  ThemeMode build() => _loadThemeMode(_prefs);
}
```

```dart
// lib/core/providers/workout_provider.dart
class WorkoutNotifier extends Notifier<WorkoutState> {
  late WorkoutService _workoutService;

  @override
  WorkoutState build() {
    _workoutService = ref.watch(workoutServiceProvider);
    return const WorkoutState();
  }

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
    NotifierProvider<WorkoutNotifier, WorkoutState>(WorkoutNotifier.new);
```

> **Migration Note**: The key differences from the old `StateNotifier` pattern:
>
> - Notifier uses `build()` to return initial state instead of passing to `super()`
> - Access `ref` directly as an inherited property (no need for `Ref _ref` field)
> - Override syntax uses `.overrideWith(() => ...)` instead of `.overrideWith((ref) => ...)`

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

Use immutable state with `copyWith()` for Notifier:

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
class WorkoutNotifier extends Notifier<WorkoutState> {
  late WorkoutService _workoutService;
  
  @override
  WorkoutState build() {
    _workoutService = ref.watch(workoutServiceProvider);
    return const WorkoutState();
  }
  
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

## Common Usage Examples

This section provides copy-paste examples for the most common data access patterns.

### Getting Programs

```dart
// In a ConsumerWidget - watch for reactive updates
class ProgramsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Option 1: Use FutureProvider with .when() for loading/error states
    final programsAsync = ref.watch(programsProvider);

    return programsAsync.when(
      data: (programs) => ListView.builder(
        itemCount: programs.length,
        itemBuilder: (context, index) => Text(programs[index].name),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

// Get a single program by ID
final program = ref.watch(programByIdProvider('program-123'));

// Get programs filtered by difficulty
final beginnerPrograms = ref.watch(
  programsByDifficultyProvider(ProgramDifficulty.beginner),
);

// Direct repository access (when you need more control)
final repository = ref.read(programRepositoryProvider);
final programs = await repository.getPrograms();
```

### Getting Exercises

```dart
// In a ConsumerWidget - all exercises
class ExerciseListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return exercisesAsync.when(
      data: (exercises) => ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) => Text(exercises[index].name),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

// Get exercises by category
final chestExercises = ref.watch(
  exercisesByCategoryProvider(ExerciseCategory.chest),
);

// Search exercises
final searchResults = ref.watch(searchExercisesProvider('bench press'));

// Get a single exercise by ID
final exercise = ref.watch(exerciseByIdProvider('exercise-456'));

// Direct repository access (for saving/deleting or exercises without preferences)
final repository = ref.read(exerciseRepositoryProvider);
await repository.saveExercise(exercise);
await repository.deleteExercise(exerciseId);
```

### Working with Workout Sessions

```dart
// In a ConsumerStatefulWidget - managing workout state
class WorkoutScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Load workout data on screen init
    Future.microtask(() {
      ref.read(workoutNotifierProvider.notifier).loadNextWorkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the workout state for reactive updates
    final workoutState = ref.watch(workoutNotifierProvider);

    // Handle loading state
    if (workoutState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (workoutState.error != null) {
      return Center(child: Text('Error: ${workoutState.error}'));
    }

    // Access current workout
    final workout = workoutState.currentWorkout;
    if (workout == null) {
      return const Center(child: Text('No workout available'));
    }

    return Text('Workout: ${workout.programName}');
  }

  // Start a workout
  Future<void> _startWorkout(WorkoutSession session) async {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    await notifier.startWorkout(session);
  }

  // Save changes (debounced)
  Future<void> _saveChanges() async {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    await notifier.saveWorkout();
  }

  // Save immediately
  Future<void> _saveImmediate() async {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    await notifier.saveWorkoutImmediate();
  }

  // Finish workout
  Future<void> _finishWorkout() async {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    await notifier.finishWorkout();
  }
}

// Convenience providers for simpler access
final currentWorkout = ref.watch(currentWorkoutProvider);  // WorkoutSession?
final isActive = ref.watch(hasActiveWorkoutProvider);       // bool

// Workout history
final historyAsync = ref.watch(workoutHistoryProvider);
historyAsync.when(
  data: (sessions) => ListView.builder(
    itemCount: sessions.length,
    itemBuilder: (context, index) => Text(sessions[index].programName),
  ),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Available Providers Quick Reference

| Provider | Type | Returns | Use Case |
| -------- | ---- | ------- | -------- |
| **Programs** | | | |
| `programRepositoryProvider` | `Provider` | `ProgramRepository` | Save/delete programs |
| `programsProvider` | `FutureProvider` | `List<Program>` | All programs |
| `programByIdProvider(id)` | `FutureProvider.family` | `Program?` | Single program |
| `programsByDifficultyProvider(diff)` | `FutureProvider.family` | `List<Program>` | Filtered by difficulty |
| **Exercises** | | | |
| `exerciseRepositoryProvider` | `Provider` | `ExerciseRepository` | Save/delete exercises |
| `exercisesProvider` | `FutureProvider` | `List<Exercise>` | All exercises (with preferences) |
| `exerciseByIdProvider(id)` | `FutureProvider.family` | `Exercise?` | Single exercise |
| `exercisesByCategoryProvider(cat)` | `FutureProvider.family` | `List<Exercise>` | Filtered by category |
| `searchExercisesProvider(query)` | `FutureProvider.family` | `List<Exercise>` | Search results |
| **Workouts** | | | |
| `workoutServiceProvider` | `Provider` | `WorkoutService` | Direct service access |
| `workoutNotifierProvider` | `NotifierProvider` | `WorkoutState` | Full workout state + notifier |
| `currentWorkoutProvider` | `Provider` | `WorkoutSession?` | Current session only |
| `hasActiveWorkoutProvider` | `Provider` | `bool` | Is workout in progress? |
| `workoutHistoryProvider` | `FutureProvider` | `List<WorkoutSession>` | Past workouts |

---

## Quick Reference

### Common Provider Patterns

| Need | Provider Type | Example |
| ---- | ------------- | ------- |
| Singleton service | `Provider` | `apiServiceProvider` |
| Mutable UI state | `NotifierProvider` | `workoutNotifierProvider` |
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
