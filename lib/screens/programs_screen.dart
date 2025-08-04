import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import 'create_program_screen.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Workout Programs',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'Choose Your Training Program',
                style: AppTextStyles.titleLarge.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Select a program that matches your goals and schedule',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Predefined Programs Section
              Text(
                'Recommended Programs',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: ListView(
                  children: [
                    // Upper/Lower Program
                    _ProgramCard(
                      title: 'Upper/Lower Split',
                      description:
                          'Train upper body and lower body on alternating days. Perfect for intermediate lifters.',
                      duration: '4 days/week',
                      difficulty: 'Intermediate',
                      icon: HugeIcons.strokeRoundedDumbbell01,
                      color: context.primaryColor,
                      onTap: () => _selectProgram('Upper/Lower Split'),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Full Body Program
                    _ProgramCard(
                      title: 'Full Body',
                      description:
                          'Complete full-body workouts that target all major muscle groups in each session.',
                      duration: '3 days/week',
                      difficulty: 'Beginner',
                      icon: HugeIcons.strokeRoundedBodyPartMuscle,
                      color: context.successColor,
                      onTap: () => _selectProgram('Full Body'),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Push/Pull/Legs Program
                    _ProgramCard(
                      title: 'Push/Pull/Legs',
                      description:
                          'Split training by movement patterns. Push, pull, and leg focused workouts.',
                      duration: '6 days/week',
                      difficulty: 'Advanced',
                      icon: HugeIcons.strokeRoundedFire,
                      color: context.warningColor,
                      onTap: () => _selectProgram('Push/Pull/Legs'),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Custom Program Section
                    Text(
                      'Custom Programs',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Create Custom Program Card
                    _CreateProgramCard(
                      onTap: () => _createCustomProgram(),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectProgram(String programName) {
    showSuccessMessage(context, 'Selected: $programName');
    // TODO: Navigate to program details or start program
  }

  void _createCustomProgram() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateProgramScreen(),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusMedium),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: color,
                  size: AppDimensions.iconMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _InfoChip(
                          label: duration,
                          color: context.primaryColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _InfoChip(
                          label: difficulty,
                          color: _getDifficultyColor(context, difficulty),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                HugeIcons.strokeRoundedArrowRight01,
                size: AppDimensions.iconSmall,
                color: context.textSecondary,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(BuildContext context, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return context.successColor;
      case 'intermediate':
        return context.warningColor;
      case 'advanced':
        return context.errorColor;
      default:
        return context.primaryColor;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CreateProgramCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateProgramCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: AppDimensions.avatarLarge,
            height: AppDimensions.avatarLarge,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: context.primaryColor,
                size: AppDimensions.iconLarge,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Create Custom Program',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Design your own workout program with our guided creation system',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
            child: Text(
              'Get Started',
              style: AppTextStyles.labelMedium.copyWith(
                color: context.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
