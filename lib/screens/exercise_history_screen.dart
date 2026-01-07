import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../core/providers/repository_providers.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import '../models/exercise/exercise_history.dart';
import '../models/exercise/exercise_session_record.dart';
import '../models/exercise/exercise_set_record.dart';
import '../models/models.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/animations/animate_on_load.dart';

/// Screen displaying the full exercise history for a single exercise.
///
/// Shows PR progression chart, session list with expandable sets,
/// and options to edit/delete past sessions.
class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseHistoryScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<ExerciseHistoryScreen> createState() =>
      _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen> {
  Exercise? _exercise;
  ExerciseHistory? _history;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _expandedSessions = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final exerciseRepo = ref.read(exerciseRepositoryProvider);
      final historyRepo = ref.read(exerciseHistoryRepositoryProvider);

      final exercise = await exerciseRepo.getExerciseById(widget.exerciseId);

      if (exercise == null) {
        setState(() {
          _errorMessage = 'Exercise not found';
          _isLoading = false;
        });
        return;
      }

      final history = await historyRepo.getExerciseHistory(exercise);

      setState(() {
        _exercise = exercise;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load history: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleSessionExpansion(String sessionId) {
    setState(() {
      if (_expandedSessions.contains(sessionId)) {
        _expandedSessions.remove(sessionId);
      } else {
        _expandedSessions.add(sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          _exercise?.name ?? 'Exercise History',
          style: AppTextStyles.titleMedium.copyWith(color: context.onSurface),
        ),
        backgroundColor: context.surfaceColor,
        iconTheme: IconThemeData(color: context.onSurface),
      ),
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
            onRetry: _loadHistory,
          ),
        ),
      );
    }

    if (_history == null || !_history!.hasHistory) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: EmptyState(
            icon: HugeIcons.strokeRoundedChartLineData01,
            title: 'No History Yet',
            description:
                'Complete a workout with this exercise to start tracking your progress.',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: CustomScrollView(
        slivers: [
          // PR Summary Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: _buildPRSummaryCard(),
              ),
            ),
          ),

          // Quick Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildQuickStatsRow(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: VSpace.lg()),

          // PR Progression Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: SlideInWidget(
                delay: const Duration(milliseconds: 300),
                child: _buildPRProgressionChart(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: VSpace.lg()),

          // Session History Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Text(
                'Session History',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: VSpace.sm()),

          // Session List
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final session = _history!.sessions[index];
                return SlideInWidget(
                  delay: Duration(milliseconds: 400 + (index * 50)),
                  child: _buildSessionCard(session, index),
                );
              }, childCount: _history!.sessions.length),
            ),
          ),

          const SliverToBoxAdapter(child: VSpace.xxl()),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonCard(height: 120),
            VSpace.lg(),
            SkeletonCard(height: 80),
            VSpace.lg(),
            SkeletonCard(height: 200),
            VSpace.lg(),
            SkeletonText(width: 150),
            VSpace.sm(),
            SkeletonCard(height: 100),
            VSpace.sm(),
            SkeletonCard(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPRSummaryCard() {
    final pr = _history!.allTimePR;
    final prDate = _history!.prDate;

    return AppCard.gradient(
      gradientColors: context.successGradient,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.onSuccessColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMedal01,
                color: context.onSuccessColor,
                size: 32,
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
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.onSuccessColor.withValues(alpha: 0.9),
                  ),
                ),
                const VSpace.xs(),
                Text(
                  pr != null ? '${pr.toStringAsFixed(1)} lbs' : 'N/A',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: context.onSuccessColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (prDate != null) ...[
                  const VSpace.xs(),
                  Text(
                    'Set on ${DateFormat('MMM d, yyyy').format(prDate)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.onSuccessColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Est. 1RM',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.onSuccessColor.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'Epley',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.onSuccessColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            icon: HugeIcons.strokeRoundedCalendar01,
            label: 'Sessions',
            value: '${_history!.totalSessions}',
            color: context.infoColor,
          ),
        ),
        const HSpace.sm(),
        Expanded(
          child: _buildQuickStatCard(
            icon: HugeIcons.strokeRoundedDumbbell01,
            label: 'Max Weight',
            value: '${_history!.maxWeight.toStringAsFixed(0)} lbs',
            color: context.primaryColor,
          ),
        ),
        const HSpace.sm(),
        Expanded(
          child: _buildQuickStatCard(
            icon: HugeIcons.strokeRoundedRepeat,
            label: 'Total Sets',
            value: '${_history!.totalWorkingSets}',
            color: context.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required HugeIconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: color, size: AppDimensions.iconMedium),
          const VSpace.xs(),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
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

  Widget _buildPRProgressionChart() {
    final progression = _history!.prProgression;

    if (progression.length < 2) {
      return AppCard(
        child: Column(
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedChartLineData01,
                  color: context.primaryColor,
                  size: AppDimensions.iconMedium,
                ),
                const HSpace.sm(),
                Text(
                  'PR Progression',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const VSpace.lg(),
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedChart,
                    color: context.textSecondary,
                    size: AppDimensions.iconLarge,
                  ),
                  const VSpace.sm(),
                  Text(
                    'Need more sessions to show chart',
                    style: AppTextStyles.bodyMedium.copyWith(
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

    // Build a simple chart visualization
    final maxPR = progression
        .map((e) => e.epleyScore)
        .reduce((a, b) => a > b ? a : b);
    final minPR = progression
        .map((e) => e.epleyScore)
        .reduce((a, b) => a < b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedChartLineData01,
                color: context.primaryColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Text(
                'PR Progression',
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Est. 1RM over time',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          const VSpace.lg(),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _PRChartPainter(
                progression: progression,
                maxValue: maxPR,
                minValue: minPR,
                lineColor: context.primaryColor,
                prColor: context.successColor,
                gridColor: context.outlineVariant,
                textColor: context.textSecondary,
              ),
              size: Size.infinite,
            ),
          ),
          const VSpace.sm(),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const HSpace.xs(),
              Text(
                'Session',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const HSpace.lg(),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.successColor,
                  shape: BoxShape.circle,
                ),
              ),
              const HSpace.xs(),
              Text(
                'New PR',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ExerciseSessionRecord session, int index) {
    final isExpanded = _expandedSessions.contains(session.id);
    final isPR =
        session.sessionPR != null && session.sessionPR == _history!.allTimePR;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => _toggleSessionExpansion(session.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Header
            Row(
              children: [
                // Date and workout info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, MMM d',
                            ).format(session.performedAt),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isPR) ...[
                            const HSpace.sm(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.successColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedMedal01,
                                    color: context.successColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PR',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: context.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const VSpace.xs(),
                      Text(
                        DateFormat('yyyy').format(session.performedAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Session summary
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${session.workingSets} sets',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '${session.totalVolume.toStringAsFixed(0)} lbs',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),

                const HSpace.sm(),

                // Expand indicator
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.5 : 0,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    color: context.textSecondary,
                    size: AppDimensions.iconMedium,
                  ),
                ),
              ],
            ),

            // Expanded set details
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VSpace.md(),
                  const Divider(),
                  const VSpace.sm(),
                  ...session.sets.map((set) => _buildSetRow(set, session)),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const VSpace.sm(),
                    const Divider(),
                    const VSpace.sm(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedNote01,
                          color: context.textSecondary,
                          size: 16,
                        ),
                        const HSpace.xs(),
                        Expanded(
                          child: Text(
                            session.notes!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(ExerciseSetRecord set, ExerciseSessionRecord session) {
    final isPRSet = session.prSet?.id == set.id && !set.isWarmup;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Set number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: set.isWarmup
                  ? context.outlineVariant.withValues(alpha: 0.3)
                  : isPRSet
                  ? context.successColor.withValues(alpha: 0.15)
                  : context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                set.isWarmup ? 'W' : '${set.setNumber}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: set.isWarmup
                      ? context.textSecondary
                      : isPRSet
                      ? context.successColor
                      : context.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const HSpace.md(),

          // Weight × Reps
          Expanded(
            child: Row(
              children: [
                Text(
                  set.displayString,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: set.isWarmup
                        ? context.textSecondary
                        : context.textPrimary,
                    fontWeight: set.isWarmup
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                ),
                if (isPRSet) ...[
                  const HSpace.sm(),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedFire,
                    color: context.successColor,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),

          // Epley score (for working sets only)
          if (!set.isWarmup)
            Text(
              '1RM: ${set.epleyScore.toStringAsFixed(0)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: isPRSet ? context.successColor : context.textSecondary,
                fontWeight: isPRSet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the PR progression chart
class _PRChartPainter extends CustomPainter {
  final List<PRProgressionEntry> progression;
  final double maxValue;
  final double minValue;
  final Color lineColor;
  final Color prColor;
  final Color gridColor;
  final Color textColor;

  _PRChartPainter({
    required this.progression,
    required this.maxValue,
    required this.minValue,
    required this.lineColor,
    required this.prColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progression.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    final range = maxValue - minValue;
    final effectiveRange = range > 0 ? range : 1.0;
    final padding = effectiveRange * 0.1;
    final chartMin = minValue - padding;
    final chartMax = maxValue + padding;
    final chartRange = chartMax - chartMin;

    // Draw horizontal grid lines
    final gridCount = 3;
    for (var i = 0; i <= gridCount; i++) {
      final y = size.height * (1 - i / gridCount);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw line chart
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < progression.length; i++) {
      final entry = progression[i];
      final x = progression.length == 1
          ? size.width / 2
          : (i / (progression.length - 1)) * size.width;
      final normalizedY = (entry.epleyScore - chartMin) / chartRange;
      final y = size.height * (1 - normalizedY);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots
    for (var i = 0; i < points.length; i++) {
      final entry = progression[i];
      dotPaint.color = entry.isPR ? prColor : lineColor;
      canvas.drawCircle(points[i], entry.isPR ? 6 : 4, dotPaint);

      // White center for PR dots
      if (entry.isPR) {
        dotPaint.color = ColorUtils.getContrastingTextColor(dotPaint.color);
        canvas.drawCircle(points[i], 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PRChartPainter oldDelegate) {
    return progression != oldDelegate.progression ||
        lineColor != oldDelegate.lineColor;
  }
}
