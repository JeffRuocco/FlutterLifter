# WorkoutService Integration Guide

This guide explains how `WorkoutService` is integrated into the workout screen via Riverpod providers for automatic workout persistence and state management.

> **Note**: This integration has been completed. This document serves as a reference for how the architecture works.

## Overview

The workout system uses a layered architecture:

```text
┌─────────────────────────────────────────────────────────────────┐
│  WorkoutScreen (UI)                                             │
│  - ConsumerStatefulWidget                                       │
│  - Watches workoutNotifierProvider for reactive state           │
└────────────────────────────┬────────────────────────────────────┘
                             │ ref.watch / ref.read
┌────────────────────────────▼────────────────────────────────────┐
│  WorkoutNotifier + WorkoutState (State Management)              │
│  - Loading/error states for UI feedback                         │
│  - Reactive updates via Riverpod                                │
└────────────────────────────┬────────────────────────────────────┘
                             │ delegates to
┌────────────────────────────▼────────────────────────────────────┐
│  WorkoutService (Business Logic)                                │
│  - Auto-save timer (every 5 seconds)                            │
│  - Debounced saves (500ms)                                      │
│  - Lifecycle management                                         │
└────────────────────────────┬────────────────────────────────────┘
                             │ persists via
┌────────────────────────────▼────────────────────────────────────┐
│  ProgramRepository (Data Layer)                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Features Provided

- ✅ Automatic saving every 5 seconds during workouts
- ✅ Debounced saves to prevent duplicate writes
- ✅ Workout lifecycle management (start, save, finish, cancel)
- ✅ Validation for unfinished sets
- ✅ Change detection (only saves when data changes)
- ✅ Error handling and recovery
- ✅ Reactive UI state via Riverpod

## Current Implementation

### Widget Setup

The `WorkoutScreen` extends `ConsumerStatefulWidget` for Riverpod access:

```dart
class WorkoutScreen extends ConsumerStatefulWidget {
  final WorkoutSession? workoutSession; // Optional override

  const WorkoutScreen({super.key, this.workoutSession});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}
```

### Accessing the Service

Always access via Riverpod providers, never instantiate directly:

```dart
// ✅ CORRECT: Access via provider
final workoutService = ref.read(workoutServiceProvider);
await workoutService.startWorkout(session);

// ❌ WRONG: Direct instantiation
final service = WorkoutService(repository); // Never do this!
```

### Reactive UI State

Watch the notifier provider for automatic UI updates:

```dart
@override
Widget build(BuildContext context) {
  // Watch for reactive rebuilds
  final workoutState = ref.watch(workoutNotifierProvider);
  final workoutSession = workoutState.currentWorkout;

  if (workoutState.isLoading) {
    return LoadingWidget();
  }

  if (workoutState.error != null) {
    return ErrorWidget(workoutState.error!);
  }

  return _buildWorkoutScreen(workoutSession);
}
```

### Starting a Workout

```dart
Future<void> _startWorkout(WorkoutSession workoutSession) async {
  try {
    final workoutService = ref.read(workoutServiceProvider);
    await workoutService.startWorkout(workoutSession);
    if (!mounted) return;
    setState(() {}); // Refresh UI
    showSuccessMessage(context, 'Workout started! Auto-save enabled 💪');
  } catch (error) {
    if (!mounted) return;
    showErrorMessage(context, 'Failed to start workout: $error');
  }
}
```

### Finishing a Workout

```dart
Future<void> _finishWorkout(WorkoutSession workoutSession) async {
  final workoutService = ref.read(workoutServiceProvider);

  // Check for unfinished sets before finishing
  if (workoutService.hasUnfinishedExercises()) {
    final shouldContinue = await _showUnfinishedSetsDialog();
    if (!shouldContinue) return;
  }

  try {
    await workoutService.finishWorkout();
    showSuccessMessage(context, 'Workout completed! 🎉');
    context.pop();
  } catch (error) {
    showErrorMessage(context, 'Failed to finish workout: $error');
  }
}
```

### Saving After Changes

Use `saveWorkout()` (debounced) or `saveWorkoutImmediate()` for critical saves:

```dart
// After updating set data
setState(() {
  workoutSession.exercises[index].sets[setIndex].toggleCompleted();
});

// Debounced save (prevents rapid duplicate saves)
await workoutService.saveWorkout();

// OR immediate save (for critical operations like adding/removing exercises)
await workoutService.saveWorkoutImmediate();
```

## Key Methods Reference

### WorkoutService Methods

| Method | Purpose |
| ------ | ------- |
| `startWorkout(session)` | Start workout, begin auto-save timer |
| `saveWorkout()` | Debounced save (500ms) |
| `saveWorkoutImmediate()` | Save immediately, cancel pending debounce |
| `finishWorkout()` | Mark complete, final save, stop timer |
| `cancelWorkout()` | Discard workout, delete from storage |
| `resumeWorkout(id)` | Resume a previously saved workout |
| `hasUnfinishedExercises()` | Check for incomplete sets |
| `hasUncompletedRecordedSets()` | Sets with data but not marked complete |
| `getUnfinishedSetsCount()` | Count of incomplete sets |

### Provider Reference

| Provider | Purpose |
| -------- | ------- |
| `workoutServiceProvider` | Direct service access |
| `workoutNotifierProvider` | State management with loading/error |
| `currentWorkoutProvider` | Current workout session (convenience) |
| `hasActiveWorkoutProvider` | Boolean for active workout check |
| `workoutHistoryProvider` | FutureProvider for workout history |

## Error Handling Pattern

Always wrap service calls in try-catch with `mounted` checks:

```dart
Future<void> _someWorkoutAction() async {
  try {
    final workoutService = ref.read(workoutServiceProvider);
    await workoutService.someMethod();
    if (!mounted) return;
    showSuccessMessage(context, 'Success!');
  } catch (error) {
    if (!mounted) return;
    showErrorMessage(context, 'Action failed: $error');
  }
}
```

## Benefits

1. **Automatic Data Safety**: No lost workouts due to app crashes (5-second auto-save)
2. **Clean Architecture**: UI focuses on presentation, service handles persistence
3. **Better UX**: Users warned about unfinished sets before finishing
4. **Consistent State**: Single source of truth via Riverpod providers
5. **Easy Testing**: Override providers in tests without mocking frameworks
6. **Performance**: Debounced saves prevent excessive writes

## Related Documentation

- [Riverpod Guide](riverpod-guide.md) - Complete Riverpod usage documentation
- [Data Architecture](data-architecture.md) - Repository and datasource patterns
- [Design Guidelines](design-guidelines.md) - Overall architecture patterns
