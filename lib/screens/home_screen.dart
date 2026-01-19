import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/animations/animate_on_load.dart';
import '../widgets/progress_ring.dart';
import '../widgets/skeleton_loader.dart';

// TODO: Need a way to save sessions that are not tied to a program or cycle

/// The home screen and dashboard of the app.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  WorkoutSession? _lastWorkout;

  @override
  void initState() {
    super.initState();
    // Load the next workout session into state
    Future.microtask(() {
      ref.read(workoutNotifierProvider.notifier).loadNextWorkout();
      _loadLastWorkout();
    });
  }

  Future<void> _loadLastWorkout() async {
    final repository = ref.read(programRepositoryProvider);
    final completed = await repository.getCompletedSessions(limit: 1);
    if (mounted && completed.isNotEmpty) {
      setState(() {
        _lastWorkout = completed.first;
      });
    }
  }

  /// Handles starting a workout with session picker for overlapping dates
  Future<void> _handleWorkoutSessionSelection(WorkoutSession session) async {
    final notifier = ref.read(workoutNotifierProvider.notifier);
    final sessionsToday = await notifier.getSessionsForToday();

    if (!mounted) return;

    if (sessionsToday.length > 1) {
      // Show session picker
      _showSessionPicker(sessionsToday);
    } else {
      // Set the selected session and navigate to workout screen
      notifier.setCurrentWorkout(session);
      context.go(AppRoutes.workout);
    }
  }

  /// Shows a bottom sheet to pick between multiple sessions scheduled for today
  void _showSessionPicker(List<WorkoutSession> sessions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionPickerSheet(
        sessions: sessions,
        onSessionSelected: (session) {
          Navigator.pop(context);
          ref.read(workoutNotifierProvider.notifier).setCurrentWorkout(session);
          context.go(AppRoutes.workout);
        },
      ),
    );
  }

  /// Get time-based greeting message
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Get motivational message based on time
  String _getMotivationalMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Start your day strong! 💪';
    } else if (hour < 17) {
      return 'Keep pushing towards your goals!';
    } else {
      return 'End the day with a great workout!';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the workout state for reactive updates
    final workoutState = ref.watch(workoutNotifierProvider);
    final currentWorkoutSession = workoutState.currentWorkout;
    final isLoading = workoutState.isLoading;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'FlutterLifter',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSettings02,
              color: context.onSurface,
            ),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              color: context.onSurface,
            ),
            onPressed: () {
              showInfoMessage(context, 'Profile coming soon!');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section with time-based message
              SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  _getGreeting(),
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  _getMotivationalMessage(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Hero Workout Card
              SlideInWidget(
                delay: const Duration(milliseconds: 300),
                child: isLoading
                    ? const _HeroCardSkeleton()
                    : _HeroWorkoutCard(
                        workoutSession: currentWorkoutSession,
                        onStartWorkout: currentWorkoutSession != null
                            ? () => _handleWorkoutSessionSelection(
                                currentWorkoutSession,
                              )
                            : null,
                      ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Quick Actions Section
              SlideInWidget(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Quick Actions',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Action Cards Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.1,
                children: [
                  SlideInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: _ActionCard(
                      title: 'Programs',
                      subtitle: 'Browse programs',
                      icon: HugeIcons.strokeRoundedDumbbell01,
                      color: context.primaryColor,
                      onTap: () {
                        context.go(AppRoutes.programs);
                      },
                    ),
                  ),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: _ActionCard(
                      title: 'Progress',
                      subtitle: 'Track gains',
                      icon: HugeIcons.strokeRoundedAnalytics01,
                      color: context.infoColor,
                      onTap: () {
                        context.go(AppRoutes.progress);
                      },
                    ),
                  ),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 700),
                    child: _ActionCard(
                      title: 'Exercises',
                      subtitle: 'Exercise library',
                      icon: HugeIcons.strokeRoundedBookOpen01,
                      color: context.warningColor,
                      onTap: () {
                        context.go(AppRoutes.exercises);
                      },
                    ),
                  ),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 800),
                    child: _ActionCard(
                      title: 'History',
                      subtitle: 'Past workouts',
                      icon: HugeIcons.strokeRoundedClock01,
                      color: context.secondaryColor,
                      onTap: () {
                        context.pushWorkoutHistory();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Quick Start Section
              SlideInWidget(
                delay: const Duration(milliseconds: 900),
                child: Text(
                  'Start Workout',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Start buttons
              SlideInWidget(
                delay: const Duration(milliseconds: 1000),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickStartButton(
                        title: 'Quick Start',
                        subtitle: 'Empty workout',
                        icon: HugeIcons.strokeRoundedAdd01,
                        onTap: _startQuickWorkout,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickStartButton(
                        title: 'Repeat Last',
                        subtitle: _lastWorkout != null
                            ? _lastWorkout!.programName ?? 'Workout'
                            : 'No history',
                        icon: HugeIcons.strokeRoundedRepeat,
                        onTap: _lastWorkout != null
                            ? () => _repeatLastWorkout()
                            : null,
                        isEnabled: _lastWorkout != null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startQuickWorkout() async {
    // Create an empty standalone session
    final session = WorkoutSession.create(
      programName: 'Quick Workout',
      date: DateTime.now(),
    );
    final notifier = ref.read(workoutNotifierProvider.notifier);
    await notifier.startWorkout(session);
    if (mounted) {
      context.go(AppRoutes.workout);
    }
  }

  Future<void> _repeatLastWorkout() async {
    if (_lastWorkout == null) return;

    final newSession = _lastWorkout!.cloneAsNewSession(newDate: DateTime.now());
    final notifier = ref.read(workoutNotifierProvider.notifier);
    await notifier.startWorkout(newSession);
    if (mounted) {
      context.go(AppRoutes.workout);
    }
  }
}

/// Hero workout card showing current/next workout with progress ring
class _HeroWorkoutCard extends StatelessWidget {
  final WorkoutSession? workoutSession;
  final VoidCallback? onStartWorkout;

  const _HeroWorkoutCard({required this.workoutSession, this.onStartWorkout});

  @override
  Widget build(BuildContext context) {
    final hasWorkout = workoutSession != null;

    return AppCard.gradient(
      gradientColors: hasWorkout
          ? context.primaryGradient
          : [context.surfaceVariant, context.surfaceVariant],
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onStartWorkout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Progress Ring
              AnimatedProgressRing(
                progress: hasWorkout ? 0.0 : 0.0,
                size: 80,
                strokeWidth: 8,
                progressColor: hasWorkout
                    ? ColorUtils.getContrastingTextColor(context.primaryColor)
                    : context.primaryColor,
                backgroundColor: hasWorkout
                    ? ColorUtils.getContrastingTextColor(
                        context.primaryColor,
                      ).withValues(alpha: 0.3)
                    : context.outlineVariant,
                child: HugeIcon(
                  icon: hasWorkout
                      ? HugeIcons.strokeRoundedPlay
                      : HugeIcons.strokeRoundedAdd01,
                  color: hasWorkout
                      ? ColorUtils.getContrastingTextColor(context.primaryColor)
                      : context.textSecondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Workout Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasWorkout ? 'Ready to Train' : 'No Workout Scheduled',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: hasWorkout
                            ? ColorUtils.getContrastingTextColor(
                                context.primaryColor,
                              )
                            : context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasWorkout
                          ? 'Tap to start your workout'
                          : 'Start a program to get your next workout',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: hasWorkout
                            ? ColorUtils.getContrastingTextColor(
                                context.primaryColor,
                              ).withValues(alpha: 0.9)
                            : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasWorkout) ...[
            const SizedBox(height: AppSpacing.lg),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WorkoutStat(
                  label: 'Exercises',
                  value: '${workoutSession?.exercises.length ?? 0}',
                  icon: HugeIcons.strokeRoundedDumbbell01,
                ),
                _WorkoutStat(
                  label: 'Est. Time',
                  value: '45 min',
                  icon: HugeIcons.strokeRoundedClock01,
                ),
                _WorkoutStat(
                  label: 'Difficulty',
                  value: 'Medium',
                  icon: HugeIcons.strokeRoundedFire,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Stat display for hero workout card
class _WorkoutStat extends StatelessWidget {
  final String label;
  final String value;
  final HugeIconData icon;

  const _WorkoutStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HugeIcon(
          icon: icon,
          color: ColorUtils.getContrastingTextColor(
            context.primaryColor,
          ).withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorUtils.getContrastingTextColor(context.primaryColor),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: ColorUtils.getContrastingTextColor(
              context.primaryColor,
            ).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Skeleton loader for hero card
class _HeroCardSkeleton extends StatelessWidget {
  const _HeroCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const SkeletonAvatar(size: 80),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 24),
                const SizedBox(height: AppSpacing.sm),
                SkeletonText(width: double.infinity, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action card used in the home screen for quick actions.
///
/// Displays an icon, title, and subtitle, and triggers a callback when tapped.
/// Typically used for quick links to other parts of the app such as programs, progress, exercises, and history.
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final HugeIconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.glass(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: icon,
                color: color,
                size: AppDimensions.iconMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick start button for starting workouts directly
class _QuickStartButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final HugeIconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _QuickStartButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = isEnabled && onTap != null;

    return AppCard(
      onTap: effectiveEnabled ? onTap : null,
      child: Opacity(
        opacity: effectiveEnabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: context.primaryColor,
                  size: AppDimensions.iconSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: context.textSecondary,
                size: AppDimensions.iconSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for picking between multiple sessions on the same day
class _SessionPickerSheet extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final void Function(WorkoutSession) onSessionSelected;

  const _SessionPickerSheet({
    required this.sessions,
    required this.onSessionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert02,
                  color: context.warningColor,
                  size: AppDimensions.iconMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Multiple Sessions Today',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You have ${sessions.length} sessions scheduled for today. '
              'Pick which one to start:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Session list
            ...sessions.map((session) {
              final dayName = session.metadata?['dayTemplateName'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => onSessionSelected(session),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusMedium,
                            ),
                          ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedDumbbell01,
                            color: context.primaryColor,
                            size: AppDimensions.iconSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dayName ?? session.programName ?? 'Workout',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${session.exercises.length} exercises',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: context.textSecondary,
                          size: AppDimensions.iconSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
