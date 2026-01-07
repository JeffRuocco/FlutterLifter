import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/animations/animate_on_load.dart';
import '../widgets/progress_ring.dart';

/// Progress tracking screen placeholder
///
/// This screen will eventually display:
/// - Workout history and statistics
/// - Progress charts and graphs
/// - Personal records tracking
/// - Goal setting and achievement
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Progress',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              // Stats Preview Section
              SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: AppCard.glass(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.all(AppSpacing.none),
                  // decoration: BoxDecoration(
                  //   color: context.surfaceVariant,
                  //   borderRadius:
                  //       BorderRadius.circular(AppDimensions.borderRadiusLarge),
                  // ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Progress',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                      const VSpace.md(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatWithRing(
                            context,
                            label: 'Workouts',
                            value: 3,
                            target: 5,
                            color: context.primaryColor,
                          ),
                          _buildStatWithRing(
                            context,
                            label: 'Exercises',
                            value: 24,
                            target: 30,
                            color: context.secondaryColor,
                          ),
                          _buildStatWithRing(
                            context,
                            label: 'Sets',
                            value: 72,
                            target: 100,
                            color: context.successColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const VSpace.lg(),

              // Streak Preview
              SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.primaryColor.withValues(alpha: 0.2),
                        context.secondaryColor.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusLarge,
                    ),
                  ),
                  child: Row(
                    children: [
                      PulseWidget(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedFire,
                            color: ColorUtils.getContrastingTextColor(
                              context.primaryColor,
                            ),
                            size: AppDimensions.iconLarge,
                          ),
                        ),
                      ),
                      const HSpace.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AnimatedCounter(
                                  value: 7,
                                  duration: const Duration(milliseconds: 1500),
                                  style: AppTextStyles.headlineLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  ' Day Streak!',
                                  style: AppTextStyles.headlineLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Keep up the great work! 🔥',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const VSpace.xl(),

              // Icon
              FadeInWidget(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAnalytics01,
                    color: context.primaryColor,
                    size: 64,
                  ),
                ),
              ),
              const VSpace.lg(),

              // Title
              FadeInWidget(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Full Analytics Coming Soon',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const VSpace.sm(),

              // Description
              FadeInWidget(
                delay: const Duration(milliseconds: 500),
                child: Text(
                  'Track your fitness journey with detailed progress analytics, workout history, and personal records.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
              const VSpace.xl(),

              // Feature list with staggered animation
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedChartLineData01,
                title: 'Progress Charts',
                subtitle: 'Visualize your strength gains over time',
                delay: const Duration(milliseconds: 600),
              ),
              const VSpace.md(),
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedAward01,
                title: 'Personal Records',
                subtitle: 'Track your all-time bests',
                delay: const Duration(milliseconds: 700),
              ),
              const VSpace.md(),
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedCalendar01,
                title: 'Workout History',
                subtitle: 'Review past workouts and performance',
                delay: const Duration(milliseconds: 800),
              ),
              const VSpace.md(),
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedTarget01,
                title: 'Goal Tracking',
                subtitle: 'Set and achieve your fitness goals',
                delay: const Duration(milliseconds: 900),
              ),
              const VSpace.xl(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatWithRing(
    BuildContext context, {
    required String label,
    required int value,
    required int target,
    required Color color,
  }) {
    final progress = (value / target).clamp(0.0, 1.0);

    return Column(
      children: [
        AnimatedProgressRing(
          progress: progress,
          size: 70,
          strokeWidth: 6,
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCounter(
                value: value,
                duration: const Duration(milliseconds: 1200),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              Text(
                '/$target',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const VSpace.sm(),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Duration delay,
  }) {
    return SlideInWidget(
      delay: delay,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall,
                ),
              ),
              child: HugeIcon(
                icon: icon,
                color: context.primaryColor,
                size: AppDimensions.iconMedium,
              ),
            ),
            const HSpace.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
