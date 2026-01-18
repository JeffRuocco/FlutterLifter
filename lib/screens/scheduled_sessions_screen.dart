import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/providers/workout_provider.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import '../models/program_models.dart';
import '../models/workout_session_models.dart';
import '../utils/date_utils.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/animations/animate_on_load.dart';
import '../widgets/skeleton_loader.dart';

/// Screen for viewing and managing scheduled workout sessions in a program cycle.
///
/// Features:
/// - View all scheduled sessions for the active cycle
/// - Edit session dates (with conflict warnings)
/// - Add/remove exercises from sessions
/// - Create new manual sessions
/// - Mark sessions as completed
class ScheduledSessionsScreen extends ConsumerStatefulWidget {
  final String programId;

  const ScheduledSessionsScreen({super.key, required this.programId});

  @override
  ConsumerState<ScheduledSessionsScreen> createState() =>
      _ScheduledSessionsScreenState();
}

class _ScheduledSessionsScreenState
    extends ConsumerState<ScheduledSessionsScreen> {
  Program? _program;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = ref.read(programRepositoryProvider);
      final program = await repository.getProgramById(widget.programId);

      if (program == null) {
        setState(() {
          _errorMessage = 'Program not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _program = program;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load program: $e';
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
          'Scheduled Sessions',
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
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: context.onSurface,
              size: AppDimensions.iconMedium,
            ),
            onPressed: _showAddSessionDialog,
            tooltip: 'Add Session',
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

    if (_program == null) {
      return _buildNotFound(context);
    }

    final activeCycle = _program!.activeCycle;
    if (activeCycle == null) {
      return _buildNoCycle(context);
    }

    return _buildContent(context, _program!, activeCycle);
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonText(width: 200, height: 24),
          const VSpace.md(),
          ...List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonCard(height: 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 64,
              color: context.textSecondary,
            ),
            const VSpace.lg(),
            Text(
              'Program Not Found',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
              ),
            ),
            const VSpace.sm(),
            Text(
              'The program you\'re looking for doesn\'t exist.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            const VSpace.lg(),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
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
              'Error Loading Sessions',
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
            FilledButton(onPressed: _loadProgram, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCycle(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar03,
              size: 64,
              color: context.textSecondary,
            ),
            const VSpace.lg(),
            Text(
              'No Active Cycle',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
              ),
            ),
            const VSpace.sm(),
            Text(
              'Start a new cycle to see scheduled sessions.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            const VSpace.lg(),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Program program,
    ProgramCycle cycle,
  ) {
    final sessions = cycle.scheduledSessions;
    final completedSessions = sessions.where((s) => s.isCompleted).toList();
    final upcomingSessions = sessions.where((s) => !s.isCompleted).toList();

    // Sort upcoming by scheduled date
    upcomingSessions.sort((a, b) {
      return a.date.compareTo(b.date);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cycle info header
          SlideInWidget(
            delay: const Duration(milliseconds: 100),
            child: _buildCycleHeader(context, program, cycle),
          ),
          const VSpace.lg(),

          // Upcoming sessions
          if (upcomingSessions.isNotEmpty) ...[
            SlideInWidget(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Upcoming Sessions',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const VSpace.md(),
            ...upcomingSessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              return SlideInWidget(
                delay: Duration(milliseconds: 300 + (index * 50)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _SessionCard(
                    session: session,
                    program: program,
                    isActive: session.isInProgress,
                    onTap: () => _showSessionDetails(session),
                    onEditDate: () => _showDatePicker(session),
                    onStartWorkout: () => _startSession(session),
                    onDelete: () => _deleteSession(session),
                  ),
                ),
              );
            }),
            const VSpace.lg(),
          ],

          // Completed sessions
          if (completedSessions.isNotEmpty) ...[
            SlideInWidget(
              delay: Duration(
                milliseconds: 200 + (upcomingSessions.length * 50),
              ),
              child: Text(
                'Completed Sessions (${completedSessions.length})',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const VSpace.md(),
            ...completedSessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              return SlideInWidget(
                delay: Duration(
                  milliseconds:
                      300 + (upcomingSessions.length * 50) + (index * 50),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _SessionCard(
                    session: session,
                    program: program,
                    isCompleted: true,
                    onTap: () => _showSessionDetails(session),
                  ),
                ),
              );
            }),
          ],

          // Empty state
          if (sessions.isEmpty)
            SlideInWidget(
              delay: const Duration(milliseconds: 200),
              child: _buildEmptyState(context),
            ),

          const VSpace.xxl(),
        ],
      ),
    );
  }

  Widget _buildCycleHeader(
    BuildContext context,
    Program program,
    ProgramCycle cycle,
  ) {
    final completedCount = cycle.scheduledSessions
        .where((s) => s.isCompleted)
        .length;
    final totalCount = cycle.scheduledSessions.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const VSpace.xs(),
                      Text(
                        'Cycle ${cycle.cycleNumber}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$completedCount / $totalCount',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const VSpace.md(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                minHeight: 8,
              ),
            ),
            const VSpace.sm(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Started ${DateFormatUtils.formatRelativeDate(cycle.startDate)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}% complete',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar03,
              size: 64,
              color: context.textSecondary,
            ),
            const VSpace.md(),
            Text(
              'No Sessions Scheduled',
              style: AppTextStyles.titleMedium.copyWith(
                color: context.textPrimary,
              ),
            ),
            const VSpace.sm(),
            Text(
              'Add sessions to start planning your workouts.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const VSpace.lg(),
            FilledButton.icon(
              onPressed: _showAddSessionDialog,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: context.onPrimary,
                size: AppDimensions.iconSmall,
              ),
              label: const Text('Add Session'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSessionDialog() {
    // TODO: Implement add session dialog
    showInfoMessage(context, 'Add session functionality coming soon!');
  }

  void _showSessionDetails(WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionDetailsSheet(
        session: session,
        program: _program!,
        onEditDate: () {
          Navigator.pop(context);
          _showDatePicker(session);
        },
        onStartWorkout: () {
          Navigator.pop(context);
          _startSession(session);
        },
        onRepeatWorkout: () {
          Navigator.pop(context);
          _repeatSession(session);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteSession(session);
        },
      ),
    );
  }

  Future<void> _showDatePicker(WorkoutSession session) async {
    final currentDate = session.date;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Session Date',
    );

    if (selectedDate != null && mounted) {
      // Check for conflicts
      final hasConflict = _checkDateConflict(selectedDate, session.id);

      if (hasConflict) {
        final shouldProceed = await _showConflictWarning(selectedDate);
        if (!shouldProceed) return;
      }

      await _updateSessionDate(session, selectedDate);
    }
  }

  bool _checkDateConflict(DateTime date, String excludeSessionId) {
    final activeCycle = _program?.activeCycle;
    if (activeCycle == null) return false;

    return activeCycle.scheduledSessions.any((s) {
      if (s.id == excludeSessionId) return false;
      final sessionDate = s.date;
      return sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day;
    });
  }

  Future<bool> _showConflictWarning(DateTime date) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Date Conflict'),
            content: Text(
              'There is already a session scheduled for ${DateFormatUtils.formatDate(date)}. '
              'Do you want to schedule anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Schedule Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _updateSessionDate(
    WorkoutSession session,
    DateTime newDate,
  ) async {
    try {
      final repository = ref.read(programRepositoryProvider);
      final originalDate = session.date;
      final updatedSession = session.copyWith(date: newDate);

      // Save the session with updated date
      await repository.saveWorkoutSession(
        updatedSession,
        propagateToFuture: false, // Don't propagate exercise changes
      );

      // Reschedule future sessions based on the date change
      await repository.rescheduleFutureSessions(
        session: updatedSession,
        originalDate: originalDate,
      );

      await _loadProgram();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session moved to ${DateFormatUtils.formatDate(newDate)}',
            ),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update date: $e'),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startSession(WorkoutSession session) async {
    // Set the selected session and navigate to workout screen
    ref.read(workoutNotifierProvider.notifier).setCurrentWorkout(session);
    context.go('/workout');
  }

  Future<void> _repeatSession(WorkoutSession session) async {
    try {
      final newSession = session.cloneAsNewSession(newDate: DateTime.now());
      final repository = ref.read(programRepositoryProvider);
      await repository.saveWorkoutSession(newSession, propagateToFuture: false);
      await _loadProgram();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session duplicated successfully'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate session: $e'),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    // Show confirmation dialog
    final confirmed = await _showDeleteConfirmation(session);
    if (!confirmed) return;

    try {
      final repository = ref.read(programRepositoryProvider);
      await repository.deleteWorkoutSession(session.id);
      await _loadProgram();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session removed'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove session: $e'),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(WorkoutSession session) async {
    final dayTemplateId = session.metadata?['dayTemplateId'] as String?;
    final dayTemplate = dayTemplateId != null
        ? _program?.getDayTemplateById(dayTemplateId)
        : null;
    final sessionName = dayTemplate?.name ?? session.programName ?? 'Workout';

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Remove Session?',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to remove "$sessionName" scheduled for '
              '${DateFormatUtils.formatDate(session.date)}? This cannot be undone.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: context.errorColor,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Card displaying a scheduled workout session
class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final Program program;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onEditDate;
  final VoidCallback? onStartWorkout;
  final VoidCallback? onDelete;

  const _SessionCard({
    required this.session,
    required this.program,
    this.isActive = false,
    this.isCompleted = false,
    this.onTap,
    this.onEditDate,
    this.onStartWorkout,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dayTemplateId = session.metadata?['dayTemplateId'] as String?;
    final dayTemplate = dayTemplateId != null
        ? program.getDayTemplateById(dayTemplateId)
        : null;

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? context.successColor
                        : isActive
                        ? context.primaryColor
                        : context.surfaceVariant,
                    border: Border.all(
                      color: isCompleted
                          ? context.successColor
                          : isActive
                          ? context.primaryColor
                          : context.outlineVariant,
                      width: 2,
                    ),
                  ),
                ),
                const HSpace.sm(),
                // Session name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayTemplate?.name ?? session.programName ?? 'Workout',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const VSpace.xs(),
                      Text(
                        DateFormatUtils.formatDate(session.date),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                _buildStatusBadge(context),
              ],
            ),
            const VSpace.md(),
            // Exercise preview
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
                if (isCompleted && session.endTime != null) ...[
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
              ],
            ),
            if (!isCompleted) ...[
              const VSpace.md(),
              Row(
                children: [
                  if (onEditDate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEditDate,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          size: AppDimensions.iconSmall,
                          color: context.primaryColor,
                        ),
                        label: const Text('Reschedule'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                      ),
                    ),
                  if (onEditDate != null && onStartWorkout != null)
                    const HSpace.sm(),
                  if (onStartWorkout != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onStartWorkout,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          size: AppDimensions.iconSmall,
                          color: context.onPrimary,
                        ),
                        label: Text(isActive ? 'Resume' : 'Start'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final String label;
    final Color color;

    if (isCompleted) {
      label = 'Completed';
      color = context.successColor;
    } else if (isActive) {
      label = 'In Progress';
      color = context.primaryColor;
    } else {
      label = 'Scheduled';
      color = context.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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

/// Bottom sheet for session details
class _SessionDetailsSheet extends StatelessWidget {
  final WorkoutSession session;
  final Program program;
  final VoidCallback? onEditDate;
  final VoidCallback? onStartWorkout;
  final VoidCallback? onRepeatWorkout;
  final VoidCallback? onDelete;

  const _SessionDetailsSheet({
    required this.session,
    required this.program,
    this.onEditDate,
    this.onStartWorkout,
    this.onRepeatWorkout,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dayTemplateId = session.metadata?['dayTemplateId'] as String?;
    final dayTemplate = dayTemplateId != null
        ? program.getDayTemplateById(dayTemplateId)
        : null;

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

            // Session name
            Text(
              dayTemplate?.name ?? session.programName ?? 'Workout',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Date
            const VSpace.xs(),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  size: AppDimensions.iconSmall,
                  color: context.textSecondary,
                ),
                const HSpace.xs(),
                Text(
                  DateFormatUtils.formatDate(session.date),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),

            const VSpace.lg(),

            // Exercises list
            Text(
              'Exercises',
              style: AppTextStyles.titleSmall.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const VSpace.sm(),
            ...session.exercises.map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const HSpace.sm(),
                    Expanded(
                      child: Text(
                        exercise.exercise.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${exercise.sets.length} sets',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const VSpace.lg(),

            // Actions
            if (!session.isCompleted) ...[
              Row(
                children: [
                  if (onEditDate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEditDate,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          size: AppDimensions.iconSmall,
                          color: context.primaryColor,
                        ),
                        label: const Text('Reschedule'),
                      ),
                    ),
                  if (onEditDate != null && onStartWorkout != null)
                    const HSpace.sm(),
                  if (onStartWorkout != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onStartWorkout,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          size: AppDimensions.iconSmall,
                          color: context.onPrimary,
                        ),
                        label: Text(session.isInProgress ? 'Resume' : 'Start'),
                      ),
                    ),
                ],
              ),
            ] else ...[
              if (onRepeatWorkout != null)
                FilledButton.icon(
                  onPressed: onRepeatWorkout,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedRepeat,
                    size: AppDimensions.iconSmall,
                    color: context.onPrimary,
                  ),
                  label: const Text('Repeat This Workout'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
            ],

            // Delete button (for non-completed sessions)
            if (!session.isCompleted && onDelete != null) ...[
              const VSpace.sm(),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: AppDimensions.iconSmall,
                  color: context.errorColor,
                ),
                label: const Text('Remove Session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.errorColor,
                  side: BorderSide(color: context.errorColor),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],

            const VSpace.md(),
          ],
        ),
      ),
    );
  }
}
