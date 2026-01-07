import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';

/// Bottom navigation indices for the main shell
enum ShellTab {
  home(0),
  programs(1),
  exercises(2),
  workout(3),
  progress(4);

  final int tabIndex;
  const ShellTab(this.tabIndex);
}

/// Main application shell with bottom navigation
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Get current tab index based on route location
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.programs)) {
      return ShellTab.programs.tabIndex;
    } else if (location.startsWith(AppRoutes.exercises)) {
      return ShellTab.exercises.tabIndex;
    } else if (location.startsWith(AppRoutes.workout)) {
      return ShellTab.workout.tabIndex;
    } else if (location.startsWith(AppRoutes.progress)) {
      return ShellTab.progress.tabIndex;
    }
    return ShellTab.home.tabIndex;
  }

  /// Navigate to tab by index
  void _onTabSelected(int index) async {
    final currentIndex = _getCurrentIndex(context);

    // If leaving the workout tab, check for uncompleted recorded sets
    if (currentIndex == ShellTab.workout.tabIndex &&
        index != ShellTab.workout.tabIndex) {
      final workoutService = ref.read(workoutServiceProvider);

      if (workoutService.hasUncompletedRecordedSets()) {
        final shouldLeave = await _showLeaveWorkoutDialog();
        if (!shouldLeave) return; // User chose to stay
      }
    }

    if (!mounted) return;

    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.programs);
        break;
      case 2:
        context.go(AppRoutes.exercises);
        break;
      case 3:
        context.go(AppRoutes.workout);
        break;
      case 4:
        context.go(AppRoutes.progress);
        break;
    }
  }

  /// Show warning dialog when leaving workout with uncompleted sets
  Future<bool> _showLeaveWorkoutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Incomplete Sets',
              style: AppTextStyles.headlineSmall.copyWith(
                color: dialogContext.textPrimary,
              ),
            ),
            content: Text(
              'You have sets with recorded data that are not marked as complete. '
              'Are you sure you want to leave this screen?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: dialogContext.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogContext.warningColor,
                  foregroundColor: dialogContext.onWarningColor,
                ),
                child: const Text('Leave Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTabSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: AppDurations.medium,
        destinations: [
          NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: context.onSurfaceVariant,
              size: AppDimensions.iconMedium,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: context.onSecondary,
              size: AppDimensions.iconMedium,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedWorkoutGymnastics,
              color: context.onSurfaceVariant,
              size: AppDimensions.iconMedium,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedWorkoutGymnastics,
              color: context.onSecondary,
              size: AppDimensions.iconMedium,
            ),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedBookOpen01,
              color: context.onSurfaceVariant,
              size: AppDimensions.iconMedium,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedBookOpen01,
              color: context.onSecondary,
              size: AppDimensions.iconMedium,
            ),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDumbbell01,
              color: context.onSurfaceVariant,
              size: AppDimensions.iconMedium,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDumbbell01,
              color: context.onSecondary,
              size: AppDimensions.iconMedium,
            ),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAnalytics01,
              color: context.onSurfaceVariant,
              size: AppDimensions.iconMedium,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedAnalytics01,
              color: context.onSecondary,
              size: AppDimensions.iconMedium,
            ),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
