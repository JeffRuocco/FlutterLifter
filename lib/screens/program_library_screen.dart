import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/program_library_filter_provider.dart';
import '../core/providers/repository_providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import '../models/models.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/animations/animate_on_load.dart';

/// Screen for browsing and managing the program library.
///
/// Features two tabs:
/// - My Programs: Custom programs and used default programs
/// - Discover: All default programs and community programs
class ProgramLibraryScreen extends ConsumerStatefulWidget {
  const ProgramLibraryScreen({super.key});

  @override
  ConsumerState<ProgramLibraryScreen> createState() =>
      _ProgramLibraryScreenState();
}

class _ProgramLibraryScreenState extends ConsumerState<ProgramLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Program> _programs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Track expanded sections for collapsible program type groups
  final Map<ProgramType, bool> _expandedTypes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initialize all program types as expanded
    for (final type in ProgramType.values) {
      _expandedTypes[type] = true;
    }

    // Set initial source filter for "My Programs" tab and load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(programLibraryFilterProvider.notifier)
          .setSourceFilter(ProgramSource.myPrograms);
      _loadPrograms();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Only respond after animation completes (not during)
    if (!_tabController.indexIsChanging) {
      // Update source filter based on tab
      final notifier = ref.read(programLibraryFilterProvider.notifier);
      if (_tabController.index == 0) {
        // My Programs tab - show custom + used default programs
        notifier.setSourceFilter(ProgramSource.myPrograms);
      } else {
        // Discover tab - show default programs
        notifier.setSourceFilter(ProgramSource.defaultOnly);
      }
      _loadPrograms();
    }
  }

  Future<void> _loadPrograms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = ref.read(programRepositoryProvider);
      final filterState = ref.read(programLibraryFilterProvider);

      // Get all programs and apply filters
      final allPrograms = await repository.getPrograms();
      final filteredPrograms = allPrograms.applyFilters(filterState);

      setState(() {
        _programs = filteredPrograms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load programs: $e';
        _isLoading = false;
      });
    }
  }

  void _updateFilter(ProgramLibraryFilterState newState) {
    // Update via provider
    final notifier = ref.read(programLibraryFilterProvider.notifier);
    notifier.setSearchQuery(newState.searchQuery);
    if (newState.selectedType != null) {
      notifier.setTypeFilter(newState.selectedType);
    } else {
      notifier.clearTypeFilter();
    }
    if (newState.selectedDifficulty != null) {
      notifier.setDifficultyFilter(newState.selectedDifficulty);
    } else {
      notifier.clearDifficultyFilter();
    }
    notifier.setSortOption(newState.sortOption);
    _loadPrograms();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(programLibraryFilterProvider.notifier).clearFiltersKeepSort();
    // Re-set source filter based on current tab
    if (_tabController.index == 0) {
      ref
          .read(programLibraryFilterProvider.notifier)
          .setSourceFilter(ProgramSource.myPrograms);
    } else {
      ref
          .read(programLibraryFilterProvider.notifier)
          .setSourceFilter(ProgramSource.defaultOnly);
    }
    _loadPrograms();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(programLibraryFilterProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Program Library',
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
          // Sort dropdown
          PopupMenuButton<ProgramSortOption>(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSorting01,
              color: context.onSurface,
              size: AppDimensions.iconMedium,
            ),
            tooltip: 'Sort by',
            onSelected: (option) {
              ref
                  .read(programLibraryFilterProvider.notifier)
                  .setSortOption(option);
              _loadPrograms();
            },
            itemBuilder: (context) => ProgramSortOption.values.map((option) {
              final isSelected = filterState.sortOption == option;
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (isSelected)
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        color: context.primaryColor,
                        size: AppDimensions.iconSmall,
                      )
                    else
                      SizedBox(width: AppDimensions.iconSmall),
                    const HSpace.sm(),
                    Text(
                      option.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? context.primaryColor
                            : context.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: context.primaryColor,
          tabs: const [
            Tab(text: 'My Programs'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMyProgramsTab(), _buildDiscoverTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushCreateProgram();
        },
        backgroundColor: context.primaryColor,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: context.onPrimary,
          size: AppDimensions.iconMedium,
        ),
      ),
    );
  }

  Widget _buildMyProgramsTab() {
    return Column(
      children: [
        // Search and Filter Bar
        SlideInWidget(
          delay: const Duration(milliseconds: 100),
          child: _buildSearchBar(),
        ),

        // Active Filters
        if (ref.watch(programLibraryFilterProvider).hasActiveFilters)
          SlideInWidget(
            delay: const Duration(milliseconds: 150),
            child: _buildActiveFilters(),
          ),

        // Content
        Expanded(child: _buildProgramList()),
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Search and Filter Bar
        SlideInWidget(
          delay: const Duration(milliseconds: 100),
          child: _buildSearchBar(),
        ),

        // Active Filters
        if (ref.watch(programLibraryFilterProvider).hasActiveFilters)
          SlideInWidget(
            delay: const Duration(milliseconds: 150),
            child: _buildActiveFilters(),
          ),

        // Content
        Expanded(child: _buildProgramList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    final filterState = ref.watch(programLibraryFilterProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      color: context.surfaceColor,
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search programs...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: context.textSecondary,
                  size: AppDimensions.iconMedium,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: context.textSecondary,
                          size: AppDimensions.iconMedium,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(programLibraryFilterProvider.notifier)
                              .clearSearchQuery();
                          _loadPrograms();
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textPrimary,
              ),
              onChanged: (value) {
                ref
                    .read(programLibraryFilterProvider.notifier)
                    .setSearchQuery(value);
                _loadPrograms();
              },
            ),
          ),

          const HSpace.sm(),

          // Filter Button
          IconButton(
            onPressed: () => _showFilterBottomSheet(),
            style: IconButton.styleFrom(
              backgroundColor: filterState.hasActiveFilters
                  ? context.primaryColor.withValues(alpha: 0.1)
                  : context.surfaceVariant,
            ),
            icon: Badge(
              isLabelVisible: filterState.activeFilterCount > 0,
              label: Text(
                filterState.activeFilterCount.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.onPrimary,
                ),
              ),
              backgroundColor: context.primaryColor,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFilterHorizontal,
                color: filterState.hasActiveFilters
                    ? context.primaryColor
                    : context.textSecondary,
                size: AppDimensions.iconMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filterState = ref.watch(programLibraryFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (filterState.selectedType != null)
                    _buildFilterChip(
                      filterState.selectedType!.displayName,
                      onRemove: () {
                        ref
                            .read(programLibraryFilterProvider.notifier)
                            .clearTypeFilter();
                        _loadPrograms();
                      },
                    ),
                  if (filterState.selectedDifficulty != null)
                    _buildFilterChip(
                      filterState.selectedDifficulty!.displayName,
                      onRemove: () {
                        ref
                            .read(programLibraryFilterProvider.notifier)
                            .clearDifficultyFilter();
                        _loadPrograms();
                      },
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Clear all',
              style: AppTextStyles.labelMedium.copyWith(
                color: context.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Chip(
        label: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: context.primaryColor),
        ),
        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
        deleteIcon: HugeIcon(
          icon: HugeIcons.strokeRoundedCancel01,
          color: context.primaryColor,
          size: 16,
        ),
        onDeleted: onRemove,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
    );
  }

  Widget _buildProgramList() {
    if (_isLoading) {
      return SkeletonList(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.xs,
          ),
          child: SkeletonCard(height: 100),
        ),
      );
    }

    if (_errorMessage != null) {
      return EmptyState.error(message: _errorMessage!, onRetry: _loadPrograms);
    }

    if (_programs.isEmpty) {
      final filterState = ref.watch(programLibraryFilterProvider);
      final isMyPrograms = _tabController.index == 0;

      return EmptyState(
        icon: isMyPrograms
            ? HugeIcons.strokeRoundedFolder01
            : HugeIcons.strokeRoundedSearch01,
        title: isMyPrograms ? 'No custom programs yet' : 'No programs found',
        description: filterState.hasActiveFilters
            ? 'Try adjusting your filters or search term'
            : isMyPrograms
            ? 'Create your first custom program to get started'
            : 'Browse our default programs to find one that fits your goals',
        actionLabel: filterState.hasActiveFilters
            ? 'Clear Filters'
            : isMyPrograms
            ? 'Create Program'
            : null,
        onAction: filterState.hasActiveFilters
            ? _clearFilters
            : isMyPrograms
            ? () {
                context.pushCreateProgram();
              }
            : null,
      );
    }

    final filterState = ref.watch(programLibraryFilterProvider);

    // Group programs by type if no search/filter
    if (!filterState.hasActiveFilters ||
        filterState.searchQuery.isEmpty &&
            filterState.selectedType == null &&
            filterState.selectedDifficulty == null) {
      return _buildGroupedProgramList();
    }

    // Flat list for search/filtered results
    return RefreshIndicator(
      onRefresh: _loadPrograms,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: _programs.length,
        itemBuilder: (context, index) {
          final program = _programs[index];
          return SlideInWidget(
            delay: Duration(milliseconds: 50 * (index % 10)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ProgramLibraryCard(
                program: program,
                onTap: () => _navigateToProgramDetail(program),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedProgramList() {
    // Group programs by type
    final Map<ProgramType, List<Program>> groupedPrograms = {};

    for (final program in _programs) {
      groupedPrograms.putIfAbsent(program.type, () => []).add(program);
    }

    // Filter out empty groups
    final nonEmptyTypes = ProgramType.values
        .where((type) => groupedPrograms[type]?.isNotEmpty ?? false)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadPrograms,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: nonEmptyTypes.length,
        itemBuilder: (context, index) {
          final type = nonEmptyTypes[index];
          final programs = groupedPrograms[type] ?? [];

          return SlideInWidget(
            delay: Duration(milliseconds: 100 * index),
            child: _buildTypeSection(type, programs),
          );
        },
      ),
    );
  }

  Widget _buildTypeSection(ProgramType type, List<Program> programs) {
    final isExpanded = _expandedTypes[type] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type Header
        InkWell(
          onTap: () {
            setState(() {
              _expandedTypes[type] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const HSpace.sm(),
                Expanded(
                  child: Text(
                    type.displayName,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${programs.length}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const HSpace.xs(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    color: context.textSecondary,
                    size: AppDimensions.iconMedium,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Programs
        AnimatedCrossFade(
          firstChild: Column(
            children: programs
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ProgramLibraryCard(
                      program: p,
                      onTap: () => _navigateToProgramDetail(p),
                    ),
                  ),
                )
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),

        const VSpace.md(),
      ],
    );
  }

  Color _getTypeColor(ProgramType type) {
    switch (type) {
      case ProgramType.strength:
        return AppColors.muscleChest;
      case ProgramType.hypertrophy:
        return AppColors.muscleBack;
      case ProgramType.powerlifting:
        return AppColors.muscleCore;
      case ProgramType.bodybuilding:
        return AppColors.muscleLegs;
      case ProgramType.cardio:
      case ProgramType.hiit:
        return AppColors.cardio;
      case ProgramType.flexibility:
      case ProgramType.rehabilitation:
        return context.warningColor;
      case ProgramType.general:
      case ProgramType.sport:
        return context.primaryColor;
    }
  }

  void _navigateToProgramDetail(Program program) {
    context.pushProgramDetail(program.id);
  }

  void _showFilterBottomSheet() {
    final filterState = ref.read(programLibraryFilterProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ProgramFilterBottomSheet(
        currentFilter: filterState,
        onFilterChanged: (newFilter) {
          Navigator.pop(context);
          _updateFilter(newFilter);
        },
      ),
    );
  }
}

/// A card widget for displaying a program in the library
class _ProgramLibraryCard extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;

  const _ProgramLibraryCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(context, program.type);
    final hasActiveCycle = program.activeCycle != null;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
                bottomLeft: Radius.circular(AppDimensions.borderRadiusLarge),
              ),
            ),
          ),

          const HSpace.md(),

          // Program info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and active indicator
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          program.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasActiveCycle) ...[
                        const HSpace.xs(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusSmall,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: context.successColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const HSpace.xs(),
                              Text(
                                'Active',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: context.successColor,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const VSpace.xs(),

                  // Description
                  if (program.description != null &&
                      program.description!.isNotEmpty)
                    Text(
                      program.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const VSpace.sm(),

                  // Badges row
                  Row(
                    children: [
                      // Type badge
                      _buildBadge(context, program.type.displayName, typeColor),
                      const HSpace.xs(),
                      // Difficulty badge
                      _buildBadge(
                        context,
                        program.difficulty.displayName,
                        _getDifficultyColor(context, program.difficulty),
                      ),
                      const Spacer(),
                      // Last used
                      if (program.lastUsedAt != null)
                        Text(
                          _formatLastUsed(program.lastUsedAt!),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Custom indicator and chevron
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!program.isDefault)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: context.warningColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      color: context.warningColor,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),

          // Chevron
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: context.textSecondary,
              size: AppDimensions.iconMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  Color _getTypeColor(BuildContext context, ProgramType type) {
    switch (type) {
      case ProgramType.strength:
        return AppColors.muscleChest;
      case ProgramType.hypertrophy:
        return AppColors.muscleBack;
      case ProgramType.powerlifting:
        return AppColors.muscleCore;
      case ProgramType.bodybuilding:
        return AppColors.muscleLegs;
      case ProgramType.cardio:
      case ProgramType.hiit:
        return AppColors.cardio;
      case ProgramType.flexibility:
      case ProgramType.rehabilitation:
        return context.warningColor;
      case ProgramType.general:
      case ProgramType.sport:
        return context.primaryColor;
    }
  }

  Color _getDifficultyColor(
    BuildContext context,
    ProgramDifficulty difficulty,
  ) {
    switch (difficulty) {
      case ProgramDifficulty.beginner:
        return context.successColor;
      case ProgramDifficulty.intermediate:
        return context.warningColor;
      case ProgramDifficulty.advanced:
      case ProgramDifficulty.expert:
        return context.errorColor;
    }
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}

/// Bottom sheet for filtering programs
class _ProgramFilterBottomSheet extends StatefulWidget {
  final ProgramLibraryFilterState currentFilter;
  final ValueChanged<ProgramLibraryFilterState> onFilterChanged;

  const _ProgramFilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<_ProgramFilterBottomSheet> createState() =>
      _ProgramFilterBottomSheetState();
}

class _ProgramFilterBottomSheetState extends State<_ProgramFilterBottomSheet> {
  late ProgramLibraryFilterState _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            const VSpace.md(),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Programs',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = ProgramLibraryFilterState(
                        selectedSource: _filter.selectedSource,
                        sortOption: _filter.sortOption,
                      );
                    });
                  },
                  child: Text(
                    'Reset',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const VSpace.md(),

            // Filters
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // Program Type Filter
                  _buildSectionTitle('Program Type'),
                  const VSpace.sm(),
                  _buildTypeChips(),
                  const VSpace.lg(),

                  // Difficulty Filter
                  _buildSectionTitle('Difficulty'),
                  const VSpace.sm(),
                  _buildDifficultyChips(),
                ],
              ),
            ),

            // Apply Button
            const VSpace.md(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onFilterChanged(_filter),
                child: Text(
                  'Apply Filters',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: context.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(
        color: context.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeChips() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ProgramType.values.map((type) {
        final isSelected = _filter.selectedType == type;
        return FilterChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filter = _filter.copyWith(
                selectedType: selected ? type : null,
                clearSelectedType: !selected,
              );
            });
          },
          selectedColor: context.primaryColor.withValues(alpha: 0.2),
          checkmarkColor: context.primaryColor,
          labelStyle: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? context.primaryColor : context.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyChips() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ProgramDifficulty.values.map((difficulty) {
        final isSelected = _filter.selectedDifficulty == difficulty;
        final color = _getDifficultyColor(difficulty);
        return FilterChip(
          label: Text(difficulty.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filter = _filter.copyWith(
                selectedDifficulty: selected ? difficulty : null,
                clearSelectedDifficulty: !selected,
              );
            });
          },
          selectedColor: color.withValues(alpha: 0.2),
          checkmarkColor: color,
          labelStyle: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? color : context.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Color _getDifficultyColor(ProgramDifficulty difficulty) {
    switch (difficulty) {
      case ProgramDifficulty.beginner:
        return context.successColor;
      case ProgramDifficulty.intermediate:
        return context.warningColor;
      case ProgramDifficulty.advanced:
      case ProgramDifficulty.expert:
        return context.errorColor;
    }
  }
}
