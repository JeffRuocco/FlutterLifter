import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../models/models.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/animations/animate_on_load.dart';

/// Screen displaying detailed information about a single exercise
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen>
    with RouteAware {
  Exercise? _exercise;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes to refresh when returning from edit screen
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // RouteObserver would be ideal here, but for simplicity we'll use didPopNext
    }
  }

  @override
  void didUpdateWidget(ExerciseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) {
      _loadExercise();
    }
  }

  /// Refresh exercise data - called when returning from edit screen
  void _refreshExercise() {
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = ref.read(exerciseRepositoryProvider);
      final exercise = await repository.getExerciseById(widget.exerciseId);

      setState(() {
        _exercise = exercise;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exercise: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: EmptyState.error(
            message: _errorMessage!,
            onRetry: _loadExercise,
          ),
        ),
      );
    }

    if (_exercise == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: EmptyState(
            icon: HugeIcons.strokeRoundedSearch01,
            title: 'Exercise Not Found',
            description: 'The requested exercise could not be found.',
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Sliver App Bar with Hero Image placeholder
        _buildSliverAppBar(),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info Section
                SlideInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: _buildBasicInfoSection(),
                ),

                const VSpace.xl(),

                // Default Values Section
                SlideInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: _buildDefaultValuesSection(),
                ),

                const VSpace.xl(),

                // Instructions Section
                SlideInWidget(
                  delay: const Duration(milliseconds: 300),
                  child: _buildInstructionsSection(),
                ),

                const VSpace.xl(),

                // Notes Section
                if (_exercise!.notes != null && _exercise!.notes!.isNotEmpty)
                  SlideInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: _buildNotesSection(),
                  ),

                const VSpace.xl(),

                // Media Section (placeholder for future)
                SlideInWidget(
                  delay: const Duration(milliseconds: 500),
                  child: _buildMediaSection(),
                ),

                const VSpace.xxl(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return SafeArea(
      child: Column(
        children: [
          // App bar skeleton
          const SkeletonCard(
            height: 200,
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 200),
                const VSpace.sm(),
                const SkeletonText(width: 150),
                const VSpace.xl(),
                const SkeletonCard(height: 120),
                const VSpace.lg(),
                const SkeletonCard(height: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final primaryMuscle = _exercise!.targetMuscleGroups.isNotEmpty
        ? _exercise!.targetMuscleGroups.first
        : null;
    final muscleColor = primaryMuscle != null
        ? AppColors.getMuscleGroupColor(primaryMuscle.name)
        : context.primaryColor;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: context.surfaceColor,
      iconTheme: IconThemeData(color: context.onSurface),
      actions: [
        // More options
        PopupMenuButton<String>(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedMoreVertical,
            color: context.onSurface,
            size: AppDimensions.iconMedium,
          ),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await context
                    .push('${AppRoutes.exercises}/${_exercise!.id}/edit');
                // Refresh after returning from edit screen
                _refreshExercise();
                break;
              case 'share':
                showInfoMessage(context, 'Share exercise coming soon!');
                break;
            }
          },
          itemBuilder: (context) => [
            if (!_exercise!.isDefault)
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedEdit01,
                      color: context.textSecondary,
                      size: AppDimensions.iconMedium,
                    ),
                    const HSpace.sm(),
                    Text(
                      'Edit Exercise',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedShare01,
                    color: context.textSecondary,
                    size: AppDimensions.iconMedium,
                  ),
                  const HSpace.sm(),
                  Text(
                    'Share',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _exercise!.name,
          style: AppTextStyles.titleMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                muscleColor.withValues(alpha: 0.3),
                muscleColor.withValues(alpha: 0.1),
                context.surfaceColor,
              ],
            ),
          ),
          child: Center(
            child: HugeIcon(
              icon: _getCategoryIcon(_exercise!.category),
              color: muscleColor.withValues(alpha: 0.3),
              size: 120,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return HugeIcons.strokeRoundedDumbbell01;
      case ExerciseCategory.cardio:
        return HugeIcons.strokeRoundedRunningShoes;
      case ExerciseCategory.flexibility:
        return HugeIcons.strokeRoundedYoga01;
      case ExerciseCategory.balance:
        return HugeIcons.strokeRoundedBodyPartMuscle;
      case ExerciseCategory.endurance:
        return HugeIcons.strokeRoundedTimer01;
      case ExerciseCategory.sports:
        return HugeIcons.strokeRoundedBasketball01;
      case ExerciseCategory.other:
        return HugeIcons.strokeRoundedWorkoutGymnastics;
    }
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category and Source badges
        Row(
          children: [
            _buildInfoBadge(
              _exercise!.category.displayName,
              context.primaryColor,
            ),
            const HSpace.xs(),
            _buildInfoBadge(
              _exercise!.isDefault ? 'Default' : 'Custom',
              _exercise!.isDefault ? context.infoColor : context.warningColor,
            ),
          ],
        ),

        const VSpace.md(),

        // Muscle Groups
        Text(
          'Target Muscles',
          style: AppTextStyles.titleSmall.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const VSpace.sm(),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _exercise!.targetMuscleGroups.map((mg) {
            final color = AppColors.getMuscleGroupColor(mg.name);
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                mg.displayName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDefaultValuesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Values',
            style: AppTextStyles.titleSmall.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const VSpace.md(),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedRepeat,
                  label: 'Sets',
                  value: '${_exercise!.defaultSets}',
                  color: context.primaryColor,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: context.outlineVariant,
              ),
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedTarget01,
                  label: 'Reps',
                  value: '${_exercise!.defaultReps}',
                  color: context.infoColor,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: context.outlineVariant,
              ),
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedClock01,
                  label: 'Rest',
                  value: _formatRestTime(_exercise!.defaultRestTimeSeconds),
                  color: context.warningColor,
                ),
              ),
            ],
          ),
          if (_exercise!.defaultWeight != null) ...[
            const VSpace.md(),
            const Divider(),
            const VSpace.md(),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedDumbbell01,
                  color: context.successColor,
                  size: AppDimensions.iconMedium,
                ),
                const HSpace.sm(),
                Text(
                  'Default Weight: ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  '${_exercise!.defaultWeight} lbs',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          HugeIcon(
            icon: icon,
            color: color,
            size: AppDimensions.iconLarge,
          ),
          const VSpace.xs(),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatRestTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
  }

  Widget _buildInstructionsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBook01,
                color: context.primaryColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Text(
                'Instructions',
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const VSpace.md(),
          Text(
            _exercise!.instructions ??
                'No specific instructions available for this exercise. '
                    'Please ensure proper form and consult a fitness professional if needed.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedNote01,
                color: context.infoColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Text(
                'Notes',
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const VSpace.md(),
          Text(
            _exercise!.notes!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedVideo01,
                color: context.errorColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Text(
                'Media',
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const VSpace.md(),

          // Placeholder for media content
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: context.surfaceVariant,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedImage01,
                    color: context.textSecondary,
                    size: AppDimensions.iconXLarge,
                  ),
                  const VSpace.sm(),
                  Text(
                    'Instructional videos and images\ncoming soon',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
