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
import '../widgets/exercise_detail_content.dart';

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

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  Exercise? _exercise;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void didUpdateWidget(ExerciseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) {
      _loadExercise();
    }
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

        // Content - using shared ExerciseDetailContent
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseDetailContent(
                  exercise: _exercise!,
                  showMediaSection: true,
                  onViewAllHistory: () async =>
                      await context.pushExerciseHistory(_exercise!.id),
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
          const SkeletonCard(height: 200),

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
        ? AppColors.getMuscleGroupColor(primaryMuscle)
        : context.primaryColor;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: context.surfaceColor,
      iconTheme: IconThemeData(color: context.onSurface),
      actions: [
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
                _loadExercise(); // Refresh after returning from edit screen
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
}
