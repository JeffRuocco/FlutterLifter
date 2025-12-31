import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';

/// Bottom navigation indices for the main shell
enum ShellTab {
  home(0),
  programs(1),
  workout(2),
  progress(3);

  final int tabIndex;
  const ShellTab(this.tabIndex);
}

/// Main application shell with bottom navigation
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Get current tab index based on route location
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.programs)) {
      return ShellTab.programs.tabIndex;
    } else if (location.startsWith(AppRoutes.workout)) {
      return ShellTab.workout.tabIndex;
    } else if (location.startsWith(AppRoutes.progress)) {
      return ShellTab.progress.tabIndex;
    }
    return ShellTab.home.tabIndex;
  }

  /// Navigate to tab by index
  void _onTabSelected(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.programs);
        break;
      case 2:
        context.go(AppRoutes.workout);
        break;
      case 3:
        context.go(AppRoutes.progress);
        break;
    }
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
