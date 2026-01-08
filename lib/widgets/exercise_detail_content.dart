import 'package:flutter/material.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../core/providers/repository_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../models/exercise/exercise_history.dart';
import '../models/models.dart';
import 'common/app_widgets.dart';
import 'skeleton_loader.dart';

/// Shared content widget for displaying exercise details.
///
/// Used by both [ExerciseDetailScreen] and [ExerciseDetailBottomSheet]
/// to avoid code duplication.
class ExerciseDetailContent extends ConsumerStatefulWidget {
  /// The exercise to display details for
  final Exercise exercise;

  /// Whether to show the media section (placeholder for future)
  final bool showMediaSection;

  /// Optional callback when "View All" history is tapped
  final VoidCallback? onViewAllHistory;

  const ExerciseDetailContent({
    super.key,
    required this.exercise,
    this.showMediaSection = false,
    this.onViewAllHistory,
  });

  @override
  ConsumerState<ExerciseDetailContent> createState() =>
      _ExerciseDetailContentState();
}

class _ExerciseDetailContentState extends ConsumerState<ExerciseDetailContent> {
  ExerciseHistory? _history;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(ExerciseDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final historyRepo = ref.read(exerciseHistoryRepositoryProvider);
      final history = await historyRepo.getExerciseHistory(widget.exercise);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Info Section
        _buildBasicInfoSection(),

        const VSpace.xl(),

        // Default Values Section
        _buildDefaultValuesSection(),

        const VSpace.xl(),

        // History Section
        _buildHistorySection(),

        const VSpace.xl(),

        // Instructions Section
        _buildInstructionsSection(),

        // Notes Section
        if (widget.exercise.notes != null &&
            widget.exercise.notes!.isNotEmpty) ...[
          const VSpace.xl(),
          _buildNotesSection(),
        ],

        // Media Section (optional)
        if (widget.showMediaSection) ...[
          const VSpace.xl(),
          _buildMediaSection(),
        ],
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category and Source badges
        Row(
          children: [
            _buildInfoBadge(
              widget.exercise.category.displayName,
              context.primaryColor,
            ),
            const HSpace.xs(),
            _buildInfoBadge(
              widget.exercise.isDefault ? 'Default' : 'Custom',
              widget.exercise.isDefault
                  ? context.infoColor
                  : context.warningColor,
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
          children: widget.exercise.targetMuscleGroups.map((mg) {
            final color = AppColors.getMuscleGroupColor(mg);
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall,
                ),
                border: Border.all(color: color.withValues(alpha: 0.3)),
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
                  value: '${widget.exercise.defaultSets}',
                  color: context.primaryColor,
                ),
              ),
              Container(width: 1, height: 60, color: context.outlineVariant),
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedTarget01,
                  label: 'Reps',
                  value: '${widget.exercise.defaultReps}',
                  color: context.infoColor,
                ),
              ),
              Container(width: 1, height: 60, color: context.outlineVariant),
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedClock01,
                  label: 'Rest',
                  value: _formatRestTime(
                    widget.exercise.defaultRestTimeSeconds,
                  ),
                  color: context.warningColor,
                ),
              ),
            ],
          ),
          if (widget.exercise.defaultWeight != null) ...[
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
                  '${widget.exercise.defaultWeight} lbs',
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
    required HugeIconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: color, size: AppDimensions.iconLarge),
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

  Widget _buildHistorySection() {
    if (_isLoadingHistory) {
      return const AppCard(child: SkeletonCard(height: 100));
    }

    final hasHistory = _history != null && _history!.hasHistory;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedChart,
                color: context.successColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Expanded(
                child: Text(
                  'Your Progress',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasHistory && widget.onViewAllHistory != null)
                TextButton(
                  onPressed: widget.onViewAllHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.primaryColor,
                        ),
                      ),
                      const HSpace.xs(),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: context.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const VSpace.md(),
          if (!hasHistory) _buildNoHistoryState() else _buildHistoryContent(),
        ],
      ),
    );
  }

  Widget _buildNoHistoryState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedChartLineData01,
            color: context.textSecondary,
            size: AppDimensions.iconLarge,
          ),
          const VSpace.sm(),
          Text(
            'No history yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const VSpace.xs(),
          Text(
            'Complete a workout with this exercise to start tracking your progress',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PR Card
        _buildPRCard(),

        const VSpace.md(),

        // Quick Stats Row
        _buildHistoryQuickStats(),

        const VSpace.md(),

        // Last 3 Sessions Preview
        if (_history!.sessions.isNotEmpty) _buildRecentSessionsPreview(),
      ],
    );
  }

  Widget _buildPRCard() {
    final pr = _history!.allTimePR;
    final prDate = _history!.prDate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.successColor.withValues(alpha: 0.15),
            context.successColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: context.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMedal01,
                color: context.successColor,
                size: AppDimensions.iconMedium,
              ),
            ),
          ),
          const HSpace.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All-Time PR',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  pr != null ? '${pr.toStringAsFixed(1)} lbs' : 'No PR yet',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (prDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Est. 1RM',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(prDate),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryQuickStats() {
    final daysSince = _history!.daysSinceLastPerformed;

    return Row(
      children: [
        Expanded(
          child: _buildHistoryStatItem(
            icon: HugeIcons.strokeRoundedCalendar01,
            label: 'Sessions',
            value: '${_history!.totalSessions}',
          ),
        ),
        const HSpace.sm(),
        Expanded(
          child: _buildHistoryStatItem(
            icon: HugeIcons.strokeRoundedDumbbell01,
            label: 'Max Weight',
            value: '${_history!.maxWeight.toStringAsFixed(0)} lbs',
          ),
        ),
        const HSpace.sm(),
        Expanded(
          child: _buildHistoryStatItem(
            icon: HugeIcons.strokeRoundedClock01,
            label: 'Last Done',
            value: daysSince != null
                ? (daysSince == 0
                      ? 'Today'
                      : daysSince == 1
                      ? 'Yesterday'
                      : '$daysSince days')
                : 'Never',
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryStatItem({
    required HugeIconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: context.textSecondary, size: 16),
          const VSpace.xs(),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsPreview() {
    final recentSessions = _history!.getRecentSessions(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: AppTextStyles.labelMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        const VSpace.sm(),
        ...recentSessions.map((session) => _buildSessionPreviewItem(session)),
      ],
    );
  }

  Widget _buildSessionPreviewItem(dynamic session) {
    final isPR =
        session.sessionPR != null && session.sessionPR == _history!.allTimePR;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: isPR ? context.successColor : context.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const HSpace.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(session.performedAt),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${session.workingSets} sets • ${session.totalVolume.toStringAsFixed(0)} lbs',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isPR)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.successColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PR',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
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
            widget.exercise.instructions ??
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
            widget.exercise.notes!,
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
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusMedium,
              ),
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
