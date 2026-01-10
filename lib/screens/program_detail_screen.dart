import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/theme/theme_extensions.dart';
import '../models/program_models.dart';
import '../models/shared_enums.dart';
import '../widgets/common/app_widgets.dart';

/// Screen for displaying detailed information about a program.
///
/// Shows:
/// - Program header with name, description, type, and difficulty
/// - Workout structure preview
/// - Cycle history
/// - Action buttons (Start/Resume cycle)
class ProgramDetailScreen extends ConsumerWidget {
  final String programId;

  const ProgramDetailScreen({
    super.key,
    required this.programId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(programByIdProvider(programId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Details'),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: context.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              color: context.onSurface,
            ),
            onPressed: () {
              // TODO: Show options menu (edit, delete, share)
            },
          ),
        ],
      ),
      body: programAsync.when(
        data: (program) {
          if (program == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, ref, program);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 64,
              color: context.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Program Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The program you\'re looking for doesn\'t exist.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 64,
              color: context.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Program',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Program program) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program header
          _buildHeader(context, program),
          const SizedBox(height: 24),

          // Program info
          _buildInfoSection(context, program),
          const SizedBox(height: 24),

          // Cycle history placeholder
          _buildCycleHistorySection(context, program),
          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(context, ref, program),
          const SizedBox(height: 32),
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
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Badges row
        Row(
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                program.type.displayName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.primaryColor,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            // Difficulty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                program.difficulty.displayName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            if (program.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Default',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.secondaryColor,
                      ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Description
        if (program.description != null && program.description!.isNotEmpty)
          Text(
            program.description!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Program program) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Program Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: HugeIcons.strokeRoundedCalendar03,
              label: 'Schedule',
              value: program.frequencyDescription,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: HugeIcons.strokeRoundedRepeat,
              label: 'Cycles Completed',
              value: '${program.completedCycles.length}',
            ),
            if (program.lastUsedAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: HugeIcons.strokeRoundedClock01,
                label: 'Last Used',
                value: _formatDate(program.lastUsedAt!),
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
        HugeIcon(icon: icon, size: 20, color: context.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildCycleHistorySection(BuildContext context, Program program) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (program.cycles.length > 5)
                  TextButton(
                    onPressed: () {
                      // TODO: Show all cycles
                    },
                    child: const Text('Show All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (program.cycles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedChart,
                        size: 48,
                        color: context.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No cycles yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start a cycle to begin tracking progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...program.cycles.take(5).map((cycle) => _buildCycleCard(
                    context,
                    cycle,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleCard(BuildContext context, ProgramCycle cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cycle.isActive
                  ? context.primaryColor
                  : cycle.isCompleted
                      ? context.successColor
                      : context.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          // Cycle info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cycle ${cycle.cycleNumber}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(cycle.startDate)} - ${cycle.endDate != null ? _formatDate(cycle.endDate!) : 'Ongoing'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
      BuildContext context, WidgetRef ref, Program program) {
    final hasActiveCycle = program.activeCycle != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasActiveCycle) ...[
          FilledButton.icon(
            onPressed: () {
              // TODO: Navigate to active workout
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPlay,
              color: context.onPrimary,
            ),
            label: const Text('Resume Cycle'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Start new cycle (will end current)
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: context.primaryColor,
            ),
            label: const Text('Start New Cycle'),
          ),
        ] else ...[
          FilledButton.icon(
            onPressed: () {
              // TODO: Start new cycle
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPlay,
              color: context.onPrimary,
            ),
            label: Text(program.isDefault
                ? 'Use This Program'
                : 'Start New Cycle'),
          ),
        ],
        if (!program.isDefault) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to edit program
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              color: context.primaryColor,
            ),
            label: const Text('Edit Program'),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
