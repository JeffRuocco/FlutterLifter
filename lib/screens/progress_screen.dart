import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_utils.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
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
              const VSpace.xl(),

              // Title
              Text(
                'Coming Soon',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const VSpace.sm(),

              // Description
              Text(
                'Track your fitness journey with detailed progress analytics, workout history, and personal records.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const VSpace.xl(),

              // Feature list
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedChartLineData01,
                title: 'Progress Charts',
                subtitle: 'Visualize your strength gains over time',
              ),
              const VSpace.md(),
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedAward01,
                title: 'Personal Records',
                subtitle: 'Track your all-time bests',
              ),
              const VSpace.md(),
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedCalendar01,
                title: 'Workout History',
                subtitle: 'Review past workouts and performance',
              ),
              const VSpace.md(),
              _buildFeatureItem(
                context,
                icon: HugeIcons.strokeRoundedTarget01,
                title: 'Goal Tracking',
                subtitle: 'Set and achieve your fitness goals',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
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
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
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
    );
  }
}
