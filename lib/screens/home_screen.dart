import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';

/// The home screen and dashboard of the app.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load the next workout session into state
    Future.microtask(() {
      ref.read(workoutNotifierProvider.notifier).loadNextWorkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the workout state for reactive updates
    final workoutState = ref.watch(workoutNotifierProvider);
    final currentWorkoutSession = workoutState.currentWorkout;

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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text(
                    'Welcome back!',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(
                      height: isSmallScreen ? AppSpacing.xs : AppSpacing.xs),
                  Text(
                    'Ready to crush your fitness goals?',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: context.textSecondary,
                    ),
                  ),

                  SizedBox(
                      height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(
                      height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),

                  // Action Cards Grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final cardWidth =
                            (gridConstraints.maxWidth - AppSpacing.md) / 2;
                        final shouldUseCompactLayout = cardWidth < 120;

                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: shouldUseCompactLayout
                              ? 0.85
                              : (isSmallScreen ? 0.9 : 1.0),
                          children: [
                            _ActionCard(
                              title: 'Programs',
                              subtitle: 'Browse programs',
                              icon: HugeIcons.strokeRoundedDumbbell01,
                              color: context.primaryColor,
                              onTap: () {
                                context.go(AppRoutes.programs);
                              },
                            ),
                            _ActionCard(
                              title: 'Workouts',
                              subtitle: currentWorkoutSession != null
                                  ? 'Start workout'
                                  : 'No workout available',
                              icon: HugeIcons.strokeRoundedPlay,
                              color: context.successColor.withValues(
                                  alpha: currentWorkoutSession != null
                                      ? 1.0
                                      : 0.4),
                              onTap: currentWorkoutSession != null
                                  ? () {
                                      context.go(AppRoutes.workout);
                                    }
                                  : () {
                                      showInfoMessage(context,
                                          'No workout session available. Start a program first!');
                                    },
                            ),
                            _ActionCard(
                              title: 'Progress',
                              subtitle: 'Track gains',
                              icon: HugeIcons.strokeRoundedAnalytics01,
                              color: context.infoColor,
                              onTap: () {
                                context.go(AppRoutes.progress);
                              },
                            ),
                            _ActionCard(
                              title: 'Exercises',
                              subtitle: 'Exercise library',
                              icon: HugeIcons.strokeRoundedMenu01,
                              color: context.warningColor,
                              onTap: () {
                                showInfoMessage(
                                    context, 'Exercise library coming soon!');
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
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
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            // Adjust icon size and spacing based on available space
            final isVerySmallCard = cardConstraints.maxWidth < 150;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isVerySmallCard ? AppSpacing.xs : AppSpacing.sm,
                  ),
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
                SizedBox(
                    height: isVerySmallCard ? AppSpacing.xs : AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Flexible(
                  flex: 2, // Give more space to subtitle
                  child: Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                      height: 1.2, // Tighter line height for better fit
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
