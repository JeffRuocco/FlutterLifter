import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/providers/workout_provider.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import '../models/exercise_models.dart';
import '../models/workout_session_models.dart';
import '../utils/date_utils.dart';
import '../utils/icon_utils.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/animations/animate_on_load.dart';
import '../widgets/skeleton_loader.dart';

/// Number of sessions to load per page
const int _pageSize = 10;

/// Screen for viewing workout history with pagination and date filtering.
///
/// Features:
/// - Paginated list (10 items default, "Load More" button)
/// - Date range filtering
/// - "Repeat This Workout" action for completed sessions
/// - Duration and exercise count display
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  // Track sessions currently being deleted to prevent duplicate deletes
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _sessions = [];
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final repository = ref.read(programRepositoryProvider);
      final allSessions = await repository.getCompletedSessions(
        startDate: _startDate,
        endDate: _endDate,
        limit: _pageSize,
        offset: reset ? 0 : _sessions.length,
      );

      setState(() {
        if (reset) {
          _sessions = allSessions;
        } else {
          _sessions = [..._sessions, ...allSessions];
        }
        _hasMore = allSessions.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load history: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    await _loadHistory(reset: false);
  }

  void _showDateFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DateFilterSheet(
        startDate: _startDate,
        endDate: _endDate,
        onApply: (start, end) {
          Navigator.pop(context);
          setState(() {
            _startDate = start;
            _endDate = end;
          });
          _loadHistory();
        },
        onClear: () {
          Navigator.pop(context);
          setState(() {
            _startDate = null;
            _endDate = null;
          });
          _loadHistory();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Workout History',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: context.onSurface,
            size: AppDimensions.iconMedium,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _startDate != null || _endDate != null,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFilter,
                color: context.onSurface,
                size: AppDimensions.iconMedium,
              ),
            ),
            onPressed: _showDateFilter,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildError(context, _errorMessage!);
    }

    if (_sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildContent(context);
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SkeletonCard(height: 120),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 64,
              color: context.errorColor,
            ),
            const VSpace.lg(),
            Text(
              'Error Loading History',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
              ),
            ),
            const VSpace.sm(),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            const VSpace.lg(),
            FilledButton(
              onPressed: () => _loadHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasFilter = _startDate != null || _endDate != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              size: 64,
              color: context.textSecondary,
            ),
            const VSpace.lg(),
            Text(
              hasFilter ? 'No Workouts Found' : 'No Workout History',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
              ),
            ),
            const VSpace.sm(),
            Text(
              hasFilter
                  ? 'No completed workouts match your filter criteria.'
                  : 'Complete your first workout to start tracking history.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            if (hasFilter) ...[
              const VSpace.lg(),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _loadHistory();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFilterRemove,
                  size: AppDimensions.iconSmall,
                  color: context.primaryColor,
                ),
                label: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: _sessions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _sessions.length) {
            return _buildLoadMoreButton();
          }

          final session = _sessions[index];
          return SlideInWidget(
            delay: Duration(milliseconds: index * 50),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HistorySessionCard(
                session: session,
                onRepeat: () => _repeatSession(session),
                onTap: () => _showSessionDetails(session),
                onDelete: () => _confirmAndDelete(session),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: _loadMore,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: AppDimensions.iconSmall,
                  color: context.primaryColor,
                ),
                label: const Text('Load More'),
              ),
      ),
    );
  }

  void _showSessionDetails(WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HistoryDetailsSheet(
        session: session,
        onRepeat: () {
          Navigator.pop(context);
          _repeatSession(session);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmAndDelete(session);
        },
      ),
    );
  }

  /// Repeat a completed workout session.
  Future<void> _repeatSession(WorkoutSession session) async {
    try {
      final notifier = ref.read(workoutNotifierProvider.notifier);
      final newSession = session.cloneAsNewSession(newDate: DateTime.now());
      notifier.setCurrentWorkout(newSession);
      await notifier.saveWorkoutImmediate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Starting repeated workout...'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/workout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to repeat workout: $e'),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(WorkoutSession session) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Workout?'),
            content: const Text(
              'This will permanently delete this workout session. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: context.errorColor),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    if (_deletingIds.contains(session.id)) return;
    setState(() => _deletingIds.add(session.id));

    try {
      final repository = ref.read(programRepositoryProvider);
      await repository.deleteWorkoutSession(session.id);

      setState(() {
        _sessions.removeWhere((s) => s.id == session.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout deleted'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete workout: $e'),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _deletingIds.remove(session.id));
    }
  }
}

/// Card displaying a completed workout session in history
class _HistorySessionCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback? onRepeat;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _HistorySessionCard({
    required this.session,
    this.onRepeat,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Date indicator
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusMedium,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDay(),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getMonth(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const HSpace.md(),
                // Session info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.programName ?? 'Standalone Workout',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const VSpace.xs(),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedDumbbell01,
                            size: AppDimensions.iconSmall,
                            color: context.textSecondary,
                          ),
                          const HSpace.xs(),
                          Text(
                            '${session.exercises.length} exercises',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                          const HSpace.md(),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            size: AppDimensions.iconSmall,
                            color: context.textSecondary,
                          ),
                          const HSpace.xs(),
                          Text(
                            _formatDuration(session.duration ?? Duration.zero),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  onPressed: onDelete,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: AppDimensions.iconSmall,
                    color: context.errorColor,
                  ),
                  tooltip: 'Delete Workout',
                ),

                // Repeat button
                IconButton(
                  onPressed: onRepeat,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedRepeat,
                    size: AppDimensions.iconSmall,
                    color: context.primaryColor,
                  ),
                  tooltip: 'Repeat Workout',
                ),
              ],
            ),
            if (session.exercises.isNotEmpty) ...[
              const VSpace.md(),
              // Exercise preview
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: session.exercises.take(3).map((exercise) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall,
                      ),
                    ),
                    child: Text(
                      exercise.exercise.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (session.exercises.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '+${session.exercises.length - 3} more',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDay() {
    final date = session.endTime ?? session.startTime ?? DateTime.now();
    return date.day.toString();
  }

  String _getMonth() {
    final date = session.endTime ?? session.startTime ?? DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = duration.inHours;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}

/// Bottom sheet showing detailed workout history info
class _HistoryDetailsSheet extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback? onRepeat;
  final VoidCallback? onDelete;

  const _HistoryDetailsSheet({
    required this.session,
    this.onRepeat,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = session.endTime ?? session.startTime ?? DateTime.now();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const VSpace.lg(),

                // Session name
                Text(
                  session.programName ?? 'Standalone Workout',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const VSpace.sm(),

                // Date and duration
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      size: AppDimensions.iconSmall,
                      color: context.textSecondary,
                    ),
                    const HSpace.xs(),
                    Text(
                      DateFormatUtils.formatDate(date),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const HSpace.md(),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      size: AppDimensions.iconSmall,
                      color: context.textSecondary,
                    ),
                    const HSpace.xs(),
                    Text(
                      _formatDuration(session.duration ?? Duration.zero),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const VSpace.lg(),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Exercises',
                      value: '${session.exercises.length}',
                      icon: HugeIcons.strokeRoundedDumbbell01,
                    ),
                    _StatItem(
                      label: 'Total Sets',
                      value: '${_getTotalSets()}',
                      icon: HugeIcons.strokeRoundedRepeat,
                    ),
                    _StatItem(
                      label: 'Total Volume',
                      value: _formatVolume(_getTotalVolume()),
                      icon: HugeIcons.strokeRoundedDumbbell02,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exercises list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: session.exercises.length,
              itemBuilder: (context, index) {
                final exercise = session.exercises[index];
                return _ExerciseHistoryItem(
                  workoutExercise: exercise,
                  index: index + 1,
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onDelete != null)
                    AppButton.outlined(
                      onPressed: onDelete,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: AppDimensions.iconSmall,
                        color: context.errorColor,
                      ),
                      text: 'Delete Workout',
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          context.errorColor,
                        ),
                      ),
                      width: double.infinity,
                    ),

                  if (onDelete != null) const VSpace.sm(),

                  AppButton.elevated(
                    onPressed: onRepeat,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedRepeat,
                      size: AppDimensions.iconSmall,
                      color: context.onPrimary,
                    ),
                    text: 'Repeat This Workout',
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalSets() {
    return session.exercises.fold(0, (sum, e) => sum + e.sets.length);
  }

  double _getTotalVolume() {
    double volume = 0;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (set.actualWeight != null && set.actualReps != null) {
          volume += set.actualWeight! * set.actualReps!;
        }
      }
    }
    return volume;
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k lbs';
    }
    return '${volume.toInt()} lbs';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = duration.inHours;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}

/// Stat item for the details sheet
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final HugeIconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: icon,
            size: AppDimensions.iconSmall,
            color: context.primaryColor,
          ),
        ),
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
          style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary),
        ),
      ],
    );
  }
}

/// Exercise item in history details
class _ExerciseHistoryItem extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final int index;

  const _ExerciseHistoryItem({
    required this.workoutExercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const HSpace.sm(),
              Expanded(
                child: Text(
                  workoutExercise.exercise.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const VSpace.sm(),
          // Sets display
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: workoutExercise.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final set = entry.value;
              final weight = set.actualWeight ?? set.targetWeight;
              final reps = set.actualReps ?? set.targetReps;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: set.isCompleted
                      ? context.successColor.withValues(alpha: 0.1)
                      : context.surfaceColor,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusSmall,
                  ),
                  border: Border.all(
                    color: set.isCompleted
                        ? context.successColor.withValues(alpha: 0.3)
                        : context.outlineVariant,
                  ),
                ),
                child: Text(
                  'Set ${setIndex + 1}: ${weight?.toInt() ?? 0} × ${reps ?? 0}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: set.isCompleted
                        ? context.successColor
                        : context.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Date filter bottom sheet
class _DateFilterSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end) onApply;
  final VoidCallback onClear;

  const _DateFilterSheet({
    this.startDate,
    this.endDate,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<_DateFilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: _endDate ?? DateTime.now(),
      helpText: 'Select Start Date',
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
      helpText: 'Select End Date',
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const VSpace.lg(),

            Text(
              'Filter by Date',
              style: AppTextStyles.titleLarge.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const VSpace.lg(),

            // Quick filters
            Text(
              'Quick Filters',
              style: AppTextStyles.labelMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            const VSpace.sm(),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _QuickFilterChip(
                  label: 'Last 7 days',
                  onTap: () {
                    setState(() {
                      _startDate = DateTime.now().subtract(
                        const Duration(days: 7),
                      );
                      _endDate = DateTime.now();
                    });
                  },
                ),
                _QuickFilterChip(
                  label: 'Last 30 days',
                  onTap: () {
                    setState(() {
                      _startDate = DateTime.now().subtract(
                        const Duration(days: 30),
                      );
                      _endDate = DateTime.now();
                    });
                  },
                ),
                _QuickFilterChip(
                  label: 'Last 90 days',
                  onTap: () {
                    setState(() {
                      _startDate = DateTime.now().subtract(
                        const Duration(days: 90),
                      );
                      _endDate = DateTime.now();
                    });
                  },
                ),
              ],
            ),
            const VSpace.lg(),

            // Date range pickers
            Row(
              children: [
                Expanded(
                  child: _DatePickerButton(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: _selectStartDate,
                  ),
                ),
                const HSpace.md(),
                Expanded(
                  child: _DatePickerButton(
                    label: 'End Date',
                    date: _endDate,
                    onTap: _selectEndDate,
                  ),
                ),
              ],
            ),
            const VSpace.lg(),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClear,
                    child: const Text('Clear'),
                  ),
                ),
                const HSpace.md(),
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onApply(_startDate, _endDate),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick filter chip
class _QuickFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickFilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: context.surfaceVariant,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: context.textPrimary,
      ),
    );
  }
}

/// Date picker button
class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: context.textSecondary,
              ),
            ),
            const VSpace.xs(),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  size: AppDimensions.iconSmall,
                  color: context.primaryColor,
                ),
                const HSpace.xs(),
                Text(
                  date != null ? DateFormatUtils.formatDate(date!) : 'Select',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: date != null
                        ? context.textPrimary
                        : context.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
