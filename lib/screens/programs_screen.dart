import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import '../models/models.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/animations/animate_on_load.dart';

/// The main screen for viewing and selecting workout programs.
class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  List<Program> _programs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = ref.read(programRepositoryProvider);
      final programs = await repository.getPrograms();

      setState(() {
        _programs = programs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load programs: $e';
        _isLoading = false;
      });
    }
  }

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
              // Header Section with slide-in animation
              SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Choose Your Training Program',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Select a program that matches your goals and schedule',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Predefined Programs Section
              SlideInWidget(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Recommended Programs',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: _buildProgramsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramsList() {
    if (_isLoading) {
      return SkeletonList(
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: SkeletonCard(
            height: 140,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return EmptyState.error(
        message: _errorMessage!,
        onRetry: _loadPrograms,
      );
    }

    if (_programs.isEmpty) {
      return EmptyState.noPrograms(
        onBrowsePrograms: _createCustomProgram,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrograms,
      child: ListView(
        children: [
          // Program cards with staggered animation
          ...List.generate(_programs.length, (index) {
            final program = _programs[index];
            return SlideInWidget(
              delay: Duration(milliseconds: 400 + (index * 100)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ProgramCard(
                  program: program,
                  duration: program.frequencyDescription,
                  onTap: () => _selectProgram(program.id),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.xl),

          // Custom Program Section
          SlideInWidget(
            delay: Duration(milliseconds: 400 + (_programs.length * 100)),
            child: Text(
              'Custom Programs',
              style: AppTextStyles.titleMedium.copyWith(
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Create Custom Program Card
          SlideInWidget(
            delay: Duration(milliseconds: 500 + (_programs.length * 100)),
            child: _CreateProgramCard(
              onTap: () => _createCustomProgram(),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Handles the selection of a program by its ID.
  void _selectProgram(String programId) async {
    try {
      final repository = ref.read(programRepositoryProvider);
      final program = await repository.getProgramById(programId);
      if (!mounted) return;

      if (program != null) {
        showSuccessMessage(context, 'Starting program: ${program.name}');
        // TODO: Navigate to program details or start program
      } else {
        showErrorMessage(context, 'Program not found');
      }
    } catch (e) {
      if (!mounted) return;
      showErrorMessage(context, 'Failed to load program: $e');
    }
  }

  void _createCustomProgram() {
    context.push(AppRoutes.createProgram);
  }
}

class _ProgramCard extends StatelessWidget {
  final Program program;
  final String duration;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.duration,
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
                  color: program.getColor(context).withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusMedium),
                ),
                child: HugeIcon(
                  icon: program.icon,
                  color: program.getColor(context),
                  size: AppDimensions.iconMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
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
                          label: program.difficulty.displayName,
                          color: _getDifficultyColor(
                              context, program.difficulty.displayName),
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
            program.description ?? '',
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
