import 'package:flutter/material.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import '../models/program_models.dart';
import '../models/shared_enums.dart';
import '../utils/date_utils.dart';
import '../utils/program_colors.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/animations/animate_on_load.dart';

/// Screen for displaying detailed information about a program.
///
/// Shows:
/// - Program header with name, description, type, and difficulty
/// - Workout structure preview
/// - Cycle history
/// - Action buttons (Start/Resume cycle)
class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  Program? _program;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showAllCycles = false;
  bool _isStartingCycle = false;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  @override
  void didUpdateWidget(ProgramDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programId != widget.programId) {
      _loadProgram();
    }
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

      // If viewing a default program, check if user already has a copy
      // and redirect to their copy instead
      if (program.isDefault) {
        final userCopy = await repository.getUserCopyOfProgram(program.id);
        if (userCopy != null && mounted) {
          // Redirect to user's copy
          context.pushReplacementProgramDetail(userCopy.id);
          return;
        }
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

  Future<void> _startNewCycle() async {
    if (_program == null || _isStartingCycle) return;

    setState(() {
      _isStartingCycle = true;
    });

    try {
      final repository = ref.read(programRepositoryProvider);

      String programIdToUse = _program!.id;

      // If it's a default program, clone it first
      if (_program!.isDefault) {
        final customProgram = await repository.copyProgramAsCustom(_program!);
        programIdToUse = customProgram.id;

        // Only show message if this is a new copy (not existing)
        // The copyProgramAsCustom returns existing if found, so check cycles
        if (customProgram.cycles.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${customProgram.name}" to your programs'),
              backgroundColor: context.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // Start the new cycle
      final newCycle = await repository.startNewCycle(programIdToUse);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started Cycle ${newCycle.cycleNumber}'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to home screen
        context.goToHome();
      }
    } catch (e) {
      LoggingService.error(
        'Failed to start new cycle: $e',
        e is Exception ? e : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start cycle: $e'),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingCycle = false;
        });
      }
    }
  }

  Future<void> _resumeCycle() async {
    // Navigate to workout screen for active cycle
    context.goToWorkout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Program Details',
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
          if (_program != null && !_program!.isDefault)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit02,
                color: context.onSurface,
                size: AppDimensions.iconMedium,
              ),
              onPressed: () async {
                await context.pushEditProgram(_program!.id);
                _loadProgram(); // Refresh after editing
              },
            ),
          PopupMenuButton<String>(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              color: context.onSurface,
              size: AppDimensions.iconMedium,
            ),
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  if (_program != null && !_program!.isDefault) {
                    await context.pushEditProgram(_program!.id);
                    _loadProgram();
                  }
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (_program != null && !_program!.isDefault)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedEdit02,
                        color: context.textPrimary,
                        size: AppDimensions.iconSmall,
                      ),
                      const HSpace.sm(),
                      Text('Edit Program'),
                    ],
                  ),
                ),
              if (_program != null && !_program!.isDefault)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: context.errorColor,
                        size: AppDimensions.iconSmall,
                      ),
                      const HSpace.sm(),
                      Text(
                        'Delete Program',
                        style: TextStyle(color: context.errorColor),
                      ),
                    ],
                  ),
                ),
            ],
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

    return _buildContent(context, ref, _program!);
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonText(width: 200, height: 28),
          const VSpace.sm(),
          Row(
            children: [
              SkeletonCard(width: 100, height: 32),
              const HSpace.sm(),
              SkeletonCard(width: 80, height: 32),
            ],
          ),
          const VSpace.md(),
          const SkeletonText(width: double.infinity),
          const VSpace.xs(),
          const SkeletonText(width: 250),
          const VSpace.lg(),
          SkeletonCard(height: 150),
          const VSpace.lg(),
          SkeletonCard(height: 200),
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
              'Error Loading Program',
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text(
          'Are you sure you want to delete "${_program?.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProgram();
            },
            style: FilledButton.styleFrom(backgroundColor: context.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProgram() async {
    if (_program == null) return;

    try {
      final repository = ref.read(programRepositoryProvider);
      await repository.deleteProgram(_program!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${_program!.name}"'),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete program: $e'),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Program program) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program header
          SlideInWidget(
            delay: const Duration(milliseconds: 100),
            child: _buildHeader(context, program),
          ),
          const VSpace.lg(),

          // Program info
          SlideInWidget(
            delay: const Duration(milliseconds: 200),
            child: _buildInfoSection(context, program),
          ),
          const VSpace.lg(),

          // Cycle history
          SlideInWidget(
            delay: const Duration(milliseconds: 300),
            child: _buildCycleHistorySection(context, program),
          ),
          const VSpace.lg(),

          // Action buttons
          SlideInWidget(
            delay: const Duration(milliseconds: 400),
            child: _buildActionButtons(context, ref, program),
          ),
          const VSpace.xxl(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Program program) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Program name
        Text(
          program.name,
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const VSpace.sm(),

        // Badges row
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            // Type badge
            _buildBadge(
              context,
              program.type.displayName,
              program.type.getColor(context),
            ),
            // Difficulty badge
            _buildBadge(
              context,
              program.difficulty.displayName,
              program.difficulty.getColor(context),
            ),
            if (program.isDefault)
              _buildBadge(context, 'Default', context.secondaryColor),
          ],
        ),
        const VSpace.md(),

        // Description
        if (program.description != null && program.description!.isNotEmpty)
          Text(
            program.description!,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Program program) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Program Info',
              style: AppTextStyles.titleMedium.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const VSpace.md(),
            _buildInfoRow(
              context,
              icon: HugeIcons.strokeRoundedCalendar03,
              label: 'Schedule',
              value: program.frequencyDescription,
            ),
            const VSpace.sm(),
            _buildInfoRow(
              context,
              icon: HugeIcons.strokeRoundedRepeat,
              label: 'Cycles Completed',
              value: '${program.completedCycles.length}',
            ),
            if (program.lastUsedAt != null) ...[
              const VSpace.sm(),
              _buildInfoRow(
                context,
                icon: HugeIcons.strokeRoundedClock01,
                label: 'Last Used',
                value: DateFormatUtils.formatRelativeDate(program.lastUsedAt!),
              ),
            ],
            if (program.tags.isNotEmpty) ...[
              const VSpace.md(),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: program.tags.map((tag) {
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
                      tag,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          size: AppDimensions.iconSmall,
          color: context.textSecondary,
        ),
        const HSpace.sm(),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCycleHistorySection(BuildContext context, Program program) {
    final cycles = program.cycles;
    final displayCycles = _showAllCycles ? cycles : cycles.take(5).toList();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle History',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (cycles.length > 5)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllCycles = !_showAllCycles;
                      });
                    },
                    child: Text(
                      _showAllCycles
                          ? 'Show Less'
                          : 'Show All (${cycles.length})',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: context.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const VSpace.md(),
            if (cycles.isEmpty)
              _buildEmptyCycleState(context)
            else
              ...displayCycles.map((cycle) => _buildCycleCard(context, cycle)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCycleState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedChart,
              size: 48,
              color: context.textSecondary,
            ),
            const VSpace.sm(),
            Text(
              'No cycles yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            const VSpace.xs(),
            Text(
              'Start a cycle to begin tracking progress',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleCard(BuildContext context, ProgramCycle cycle) {
    final completedWorkouts = cycle.scheduledSessions
        .where((s) => s.isCompleted)
        .length;
    final totalWorkouts = cycle.scheduledSessions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cycle.isActive
                  ? context.primaryColor
                  : cycle.isCompleted
                  ? context.successColor
                  : context.textSecondary,
            ),
          ),
          const HSpace.sm(),
          // Cycle info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Cycle ${cycle.cycleNumber}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (totalWorkouts > 0) ...[
                      const HSpace.sm(),
                      Text(
                        '$completedWorkouts/$totalWorkouts workouts',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const VSpace.xs(),
                Text(
                  '${DateFormatUtils.formatDate(cycle.startDate)} - ${cycle.endDate != null ? DateFormatUtils.formatDate(cycle.endDate!) : 'Ongoing'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cycle.isActive
                  ? context.primaryColor.withValues(alpha: 0.1)
                  : cycle.isCompleted
                  ? context.successColor.withValues(alpha: 0.1)
                  : context.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cycle.isActive
                  ? 'Active'
                  : cycle.isCompleted
                  ? 'Completed'
                  : 'Ended',
              style: AppTextStyles.labelSmall.copyWith(
                color: cycle.isActive
                    ? context.primaryColor
                    : cycle.isCompleted
                    ? context.successColor
                    : context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) {
    final hasActiveCycle = program.activeCycle != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasActiveCycle) ...[
          FilledButton.icon(
            onPressed: _isStartingCycle ? null : _resumeCycle,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPlay,
              color: context.onPrimary,
              size: AppDimensions.iconSmall,
            ),
            label: const Text('Resume Cycle'),
          ),
          const VSpace.sm(),
          OutlinedButton.icon(
            onPressed: _isStartingCycle
                ? null
                : () => _showStartNewCycleConfirmation(program),
            icon: _isStartingCycle
                ? SizedBox(
                    width: AppDimensions.iconSmall,
                    height: AppDimensions.iconSmall,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.primaryColor,
                    ),
                  )
                : HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: context.primaryColor,
                    size: AppDimensions.iconSmall,
                  ),
            label: Text(_isStartingCycle ? 'Starting...' : 'Start New Cycle'),
          ),
        ] else ...[
          FilledButton.icon(
            onPressed: _isStartingCycle ? null : _startNewCycle,
            icon: _isStartingCycle
                ? SizedBox(
                    width: AppDimensions.iconSmall,
                    height: AppDimensions.iconSmall,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.onPrimary,
                    ),
                  )
                : HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    color: context.onPrimary,
                    size: AppDimensions.iconSmall,
                  ),
            label: Text(
              _isStartingCycle
                  ? 'Starting...'
                  : program.isDefault
                  ? 'Use This Program'
                  : 'Start New Cycle',
            ),
          ),
        ],
        if (!program.isDefault) ...[
          const VSpace.sm(),
          OutlinedButton.icon(
            onPressed: () async {
              await context.pushEditProgram(program.id);
              _loadProgram();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              color: context.primaryColor,
              size: AppDimensions.iconSmall,
            ),
            label: const Text('Edit Program'),
          ),
        ],
      ],
    );
  }

  void _showStartNewCycleConfirmation(Program program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Cycle?'),
        content: const Text(
          'This will end your current active cycle and start a new one. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewCycle();
            },
            child: const Text('Start New Cycle'),
          ),
        ],
      ),
    );
  }
}
