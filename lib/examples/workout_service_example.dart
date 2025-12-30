import 'package:flutter/material.dart';
import 'package:flutter_lifter/models/models.dart';
import 'package:flutter_lifter/services/service_locator.dart';
import 'package:flutter_lifter/services/workout_service.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_utils.dart';

/// Example showing how to integrate WorkoutService with your workout screen
///
/// This demonstrates the recommended patterns for:
/// - Starting and managing workouts
/// - Auto-saving workout progress
/// - Handling workout completion with validation
/// - Error handling and user feedback
class WorkoutServiceExample extends StatefulWidget {
  final WorkoutSession workoutSession;

  const WorkoutServiceExample({
    super.key,
    required this.workoutSession,
  });

  @override
  State<WorkoutServiceExample> createState() => _WorkoutServiceExampleState();
}

class _WorkoutServiceExampleState extends State<WorkoutServiceExample> {
  late WorkoutService _workoutService;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _workoutService = serviceLocator.get<WorkoutService>();
    _initializeWorkout();
  }

  @override
  void dispose() {
    // WorkoutService is managed by ServiceLocator, so no need to dispose here
    // But if you were managing it locally, you would call _workoutService.dispose()
    super.dispose();
  }

  Future<void> _initializeWorkout() async {
    try {
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  /// Start workout with automatic saving
  Future<void> _startWorkout() async {
    try {
      await _workoutService.startWorkout(widget.workoutSession);
      setState(() {}); // Refresh UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout started! Auto-save enabled 💪'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update workout data and trigger save
  Future<void> _updateWorkoutData() async {
    try {
      await _workoutService.saveWorkout();
      // No need to show success message for auto-save
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress: $error'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Finish workout with validation
  Future<void> _finishWorkout() async {
    // Check for unfinished sets before finishing
    if (_workoutService.hasUnfinishedExercises()) {
      final shouldContinue = await _showUnfinishedSetsDialog();
      if (!shouldContinue) return;
    }

    try {
      await _workoutService.finishWorkout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout completed! Great job! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or to summary screen
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to finish workout: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cancel workout with confirmation
  Future<void> _cancelWorkout() async {
    final shouldCancel = await _showCancelConfirmationDialog();
    if (!shouldCancel) return;

    try {
      await _workoutService.cancelWorkout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout cancelled'),
            backgroundColor: Colors.orange,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel workout: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show dialog for unfinished sets warning
  Future<bool> _showUnfinishedSetsDialog() async {
    final unfinishedCount = _workoutService.getUnfinishedSetsCount();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unfinished Sets',
          style: AppTextStyles.headlineSmall.copyWith(
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'You have $unfinishedCount unfinished sets with recorded data. '
          'Are you sure you want to finish the workout?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Workout'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Finish Anyway'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show confirmation dialog for cancelling workout
  Future<bool> _showCancelConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Workout?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this workout? All progress will be lost.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Workout'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Workout'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Example of how to handle set completion with auto-save
  Future<void> _onSetCompleted(int exerciseIndex, int setIndex) async {
    final exercise = widget.workoutSession.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    setState(() {
      set.isCompleted = !set.isCompleted;
    });

    // Auto-save the change
    await _updateWorkoutData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              ElevatedButton(
                onPressed: _initializeWorkout,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isWorkoutActive = _workoutService.hasActiveWorkout;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutSession.programName ?? 'Workout'),
        actions: [
          if (isWorkoutActive)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateWorkoutData,
              tooltip: 'Save Progress',
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelWorkout,
            tooltip: 'Cancel Workout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Workout status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color:
                isWorkoutActive ? Colors.green.shade100 : Colors.grey.shade100,
            child: Row(
              children: [
                Icon(
                  isWorkoutActive ? Icons.play_circle : Icons.pause_circle,
                  color: isWorkoutActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isWorkoutActive
                      ? 'Workout in progress (auto-saving every 30s)'
                      : 'Workout not started',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isWorkoutActive
                        ? Colors.green.shade800
                        : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Workout content would go here
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Workout Screen Content',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Exercise cards, sets, and other workout UI would go here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: (widget.workoutSession.exercises.isNotEmpty &&
                            widget.workoutSession.exercises[0].sets.isNotEmpty)
                        ? () => _onSetCompleted(0, 0)
                        : null,
                    child: const Text('Toggle Set Completion (Example)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Action buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!isWorkoutActive) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _startWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Start Workout',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _finishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Finish Workout',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
