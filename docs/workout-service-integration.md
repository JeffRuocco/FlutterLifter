# WorkoutService Integration Guide

This guide shows how to integrate the new `WorkoutService` into your existing workout screen for automatic workout persistence and better state management.

## Overview

The `WorkoutService` provides:
- ✅ Automatic saving every 30 seconds during workouts
- ✅ Workout lifecycle management (start, update, finish, cancel)
- ✅ Validation for unfinished sets
- ✅ Clean separation of concerns
- ✅ Error handling and recovery

## Quick Integration Steps

### 1. Update WorkoutScreen Constructor

```dart
class WorkoutScreen extends StatefulWidget {
  final WorkoutSession workoutSession;

  const WorkoutScreen({
    super.key,
    required this.workoutSession,
  });
  // Remove programRepository parameter - WorkoutService handles this
}
```

### 2. Initialize WorkoutService in State

```dart
class _WorkoutScreenState extends State<WorkoutScreen> {
  late WorkoutService _workoutService;

  @override
  void initState() {
    super.initState();
    _workoutService = serviceLocator.get<WorkoutService>();
  }
}
```

### 3. Update Start Workout Method

Replace your existing `_startWorkout` method:

```dart
Future<void> _startWorkout() async {
  try {
    await _workoutService.startWorkout(widget.workoutSession);
    setState(() {}); // Refresh UI
    showSuccessMessage(context, 'Workout started! Auto-save enabled 💪');
  } catch (error) {
    showErrorMessage(context, 'Failed to start workout: $error');
  }
}
```

### 4. Update Finish Workout Method

Replace your existing `_finishWorkout` method:

```dart
Future<void> _finishWorkout() async {
  // Check for unfinished sets
  if (_workoutService.hasUnfinishedSets()) {
    final shouldContinue = await _showUnfinishedSetsDialog();
    if (!shouldContinue) return;
  }

  try {
    await _workoutService.finishWorkout();
    showSuccessMessage(context, 'Workout completed! 🎉');
    Navigator.of(context).pop();
  } catch (error) {
    showErrorMessage(context, 'Failed to finish workout: $error');
  }
}
```

### 5. Add Auto-Save to Set Operations

Whenever you update workout data (sets, weights, reps), call:

```dart
// After updating set data
setState(() {
  // Your existing set update logic
  workoutSession.exercises[exerciseIndex].sets[setIndex].isCompleted = true;
});

// Auto-save the change
await _workoutService.updateWorkout();
```

### 6. Update Widget Tree

Use the service's current workout state:

```dart
Widget build(BuildContext context) {
  final isWorkoutActive = _workoutService.hasActiveWorkout;
  
  return Scaffold(
    appBar: AppBar(
      title: Text(isWorkoutActive ? 'Workout Active' : 'Workout'),
      // ... rest of app bar
    ),
    // ... rest of widget tree
  );
}
```

## Key Methods to Use

### Starting/Managing Workouts
```dart
// Start a workout with auto-save
await _workoutService.startWorkout(workoutSession);

// Update workout data (triggers save)
await _workoutService.updateWorkout();

// Finish workout
await _workoutService.finishWorkout();

// Cancel workout (discards changes)
await _workoutService.cancelWorkout();
```

### Validation Helpers
```dart
// Check for unfinished sets
bool hasUnfinished = _workoutService.hasUnfinishedSets();
int count = _workoutService.getUnfinishedSetsCount();

// Check if workout is active
bool isActive = _workoutService.hasActiveWorkout;
```

### Data Access
```dart
// Get current workout
WorkoutSession? current = _workoutService.currentWorkout;

// Get workout history
List<WorkoutSession> history = await _workoutService.getWorkoutHistory();
```

## Error Handling Pattern

Always wrap service calls in try-catch:

```dart
Future<void> _someWorkoutAction() async {
  try {
    await _workoutService.someMethod();
    // Success feedback
  } catch (error) {
    if (mounted) {
      showErrorMessage(context, 'Action failed: $error');
    }
  }
}
```

## Benefits of This Integration

1. **Automatic Data Safety**: No more lost workouts due to app crashes
2. **Clean Code**: UI focuses on presentation, service handles persistence
3. **Better UX**: Users get warned about unfinished sets
4. **Consistent State**: Single source of truth for workout status
5. **Easy Testing**: Service can be mocked for unit tests

## Migration Checklist

- [ ] Remove `ProgramRepository` parameter from `WorkoutScreen`
- [ ] Initialize `WorkoutService` in `initState()`
- [ ] Update `_startWorkout()` to use service
- [ ] Update `_finishWorkout()` with validation
- [ ] Add `_workoutService.updateWorkout()` calls after data changes
- [ ] Update UI to use `_workoutService.hasActiveWorkout`
- [ ] Add error handling for all service calls
- [ ] Test auto-save functionality
- [ ] Test unfinished sets validation

## Next Steps

After integration:
1. Test the auto-save functionality (wait 30+ seconds during a workout)
2. Test the unfinished sets validation
3. Verify workout history is being saved
4. Consider adding rest timer integration with the service
5. Add workout summary screen using the service data

The `WorkoutService` is now ready to be the foundation for more advanced features like workout analytics, progress tracking, and social sharing!