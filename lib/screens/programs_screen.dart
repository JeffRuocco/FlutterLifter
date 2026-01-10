import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
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
  List<Program> _recommendedPrograms = [];
  List<Program> _recentPrograms = [];
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

      // Load recommended (default) programs and recent programs in parallel
      final results = await Future.wait([
        repository.getDefaultPrograms(),
        repository.getRecentPrograms(limit: 5),
      ]);

      setState(() {
        _recommendedPrograms = results[0];
        _recentPrograms = results[1];
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
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: SkeletonList(
          itemCount: 4,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonCard(height: 120),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: EmptyState.error(
          message: _errorMessage!,
          onRetry: _loadPrograms,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrograms,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
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

          // Recent Programs Section (only show if user has recent programs)
          if (_recentPrograms.isNotEmpty) ...[
            SlideInWidget(
              delay: const Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Programs',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushProgramLibrary(),
                    child: Text(
                      'See All',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Recent programs horizontal scroll
            SlideInWidget(
              delay: const Duration(milliseconds: 400),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentPrograms.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final program = _recentPrograms[index];
                    return _RecentProgramCard(
                      program: program,
                      onTap: () => context.pushProgramDetail(program.id),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Recommended Programs Section
          SlideInWidget(
            delay: Duration(
              milliseconds: _recentPrograms.isNotEmpty ? 500 : 300,
            ),
            child: Text(
              'Recommended Programs',
              style: AppTextStyles.titleMedium.copyWith(
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Program cards with staggered animation
          ...List.generate(_recommendedPrograms.length, (index) {
            final program = _recommendedPrograms[index];
            final baseDelay = _recentPrograms.isNotEmpty ? 600 : 400;
            return SlideInWidget(
              delay: Duration(milliseconds: baseDelay + (index * 100)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ProgramCard(
                  program: program,
                  duration: program.frequencyDescription,
                  onTap: () => context.pushProgramDetail(program.id),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.xl),

          // Browse Library Section
          SlideInWidget(
            delay: Duration(
              milliseconds:
                  (_recentPrograms.isNotEmpty ? 600 : 400) +
                  (_recommendedPrograms.length * 100),
            ),
            child: Text(
              'Explore More',
              style: AppTextStyles.titleMedium.copyWith(
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Browse Library Card
          SlideInWidget(
            delay: Duration(
              milliseconds:
                  (_recentPrograms.isNotEmpty ? 700 : 500) +
                  (_recommendedPrograms.length * 100),
            ),
            child: _BrowseLibraryCard(
              onTap: () => context.pushProgramLibrary(),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Create Custom Program Card
          SlideInWidget(
            delay: Duration(
              milliseconds:
                  (_recentPrograms.isNotEmpty ? 800 : 600) +
                  (_recommendedPrograms.length * 100),
            ),
            child: _CreateProgramCard(onTap: _createCustomProgram),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
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
    return AppCard.glass(
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
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
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
                        _InfoChip(label: duration, color: context.primaryColor),
                        const SizedBox(width: AppSpacing.xs),
                        _InfoChip(
                          label: program.difficulty.displayName,
                          color: _getDifficultyColor(
                            context,
                            program.difficulty.displayName,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
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

  const _InfoChip({required this.label, required this.color});

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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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

/// Compact card for displaying recent programs in horizontal scroll.
class _RecentProgramCard extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;

  const _RecentProgramCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: program.getColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusSmall,
                    ),
                  ),
                  child: HugeIcon(
                    icon: program.icon,
                    color: program.getColor(context),
                    size: AppDimensions.iconSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    program.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Last used date
            if (program.lastUsedAt != null) ...[
              Text(
                _formatLastUsed(program.lastUsedAt!),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ] else ...[
              Text(
                program.difficulty.displayName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastUsed(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Used today';
    } else if (difference.inDays == 1) {
      return 'Used yesterday';
    } else if (difference.inDays < 7) {
      return 'Used ${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Used ${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Used ${months}mo ago';
    }
  }
}

/// Prominent card for browsing the full program library.
class _BrowseLibraryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BrowseLibraryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard.glass(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusMedium,
              ),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedLibrary,
              color: context.primaryColor,
              size: AppDimensions.iconLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse Program Library',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Explore all programs, filter by type, and find your perfect workout plan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            size: AppDimensions.iconSmall,
            color: context.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _CreateProgramCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateProgramCard({required this.onTap});

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
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusLarge,
              ),
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
