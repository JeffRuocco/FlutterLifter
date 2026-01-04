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

/// Filter state for the exercise library
class ExerciseLibraryFilter {
  final String searchQuery;
  final MuscleGroup? selectedMuscleGroup;
  final ExerciseCategory? selectedCategory;
  final ExerciseSource selectedSource;

  const ExerciseLibraryFilter({
    this.searchQuery = '',
    this.selectedMuscleGroup,
    this.selectedCategory,
    this.selectedSource = ExerciseSource.all,
  });

  ExerciseLibraryFilter copyWith({
    String? searchQuery,
    MuscleGroup? selectedMuscleGroup,
    ExerciseCategory? selectedCategory,
    ExerciseSource? selectedSource,
    bool clearMuscleGroup = false,
    bool clearCategory = false,
  }) {
    return ExerciseLibraryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMuscleGroup: clearMuscleGroup
          ? null
          : (selectedMuscleGroup ?? this.selectedMuscleGroup),
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedSource: selectedSource ?? this.selectedSource,
    );
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedMuscleGroup != null ||
      selectedCategory != null ||
      selectedSource != ExerciseSource.all;
}

/// The main screen for browsing and searching exercises
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String? _errorMessage;
  ExerciseLibraryFilter _filter = const ExerciseLibraryFilter();

  // Track expanded regions for collapsible sections
  final Map<MuscleGroupRegion, bool> _expandedRegions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExercises();

    // Initialize all regions as expanded
    for (final region in MuscleGroupRegion.values) {
      _expandedRegions[region] = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = ref.read(exerciseRepositoryProvider);
      List<Exercise> exercises;

      // Apply filters
      if (_filter.searchQuery.isNotEmpty) {
        exercises = await repository.searchExercises(
          _filter.searchQuery,
          source: _filter.selectedSource,
        );
      } else if (_filter.selectedMuscleGroup != null) {
        exercises = await repository.getExercisesByMuscleGroup(
          _filter.selectedMuscleGroup!,
          source: _filter.selectedSource,
        );
      } else if (_filter.selectedCategory != null) {
        exercises = await repository.getExercisesByCategory(
          _filter.selectedCategory!,
          source: _filter.selectedSource,
        );
      } else {
        exercises =
            await repository.getExercises(source: _filter.selectedSource);
      }

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exercises: $e';
        _isLoading = false;
      });
    }
  }

  void _updateFilter(ExerciseLibraryFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
    _loadExercises();
  }

  void _clearFilters() {
    _searchController.clear();
    _updateFilter(const ExerciseLibraryFilter());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Exercise Library',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.onSurface),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: context.primaryColor,
          tabs: const [
            Tab(text: 'My Exercises'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyExercisesTab(),
          _buildDiscoverTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.pushCreateExercise();
          // Refresh the exercise list when returning from create screen
          _loadExercises();
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

  Widget _buildMyExercisesTab() {
    return Column(
      children: [
        // Search and Filter Bar
        SlideInWidget(
          delay: const Duration(milliseconds: 100),
          child: _buildSearchBar(),
        ),

        // Active Filters
        if (_filter.hasActiveFilters)
          SlideInWidget(
            delay: const Duration(milliseconds: 150),
            child: _buildActiveFilters(),
          ),

        // Content
        Expanded(
          child: _buildExerciseList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
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
                hintText: 'Search exercises...',
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
                          _updateFilter(_filter.copyWith(searchQuery: ''));
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusMedium),
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
                _updateFilter(_filter.copyWith(searchQuery: value));
              },
            ),
          ),

          const HSpace.sm(),

          // Filter Button
          IconButton(
            onPressed: () => _showFilterBottomSheet(),
            style: IconButton.styleFrom(
              backgroundColor: _filter.hasActiveFilters
                  ? context.primaryColor.withValues(alpha: 0.1)
                  : context.surfaceVariant,
            ),
            icon: Badge(
              isLabelVisible: _filter.hasActiveFilters,
              smallSize: 8,
              backgroundColor: context.primaryColor,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFilterHorizontal,
                color: _filter.hasActiveFilters
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
                  if (_filter.selectedMuscleGroup != null)
                    _buildFilterChip(
                      _filter.selectedMuscleGroup!.displayName,
                      onRemove: () => _updateFilter(
                          _filter.copyWith(clearMuscleGroup: true)),
                    ),
                  if (_filter.selectedCategory != null)
                    _buildFilterChip(
                      _filter.selectedCategory!.displayName,
                      onRemove: () =>
                          _updateFilter(_filter.copyWith(clearCategory: true)),
                    ),
                  if (_filter.selectedSource != ExerciseSource.all)
                    _buildFilterChip(
                      _filter.selectedSource.displayName,
                      onRemove: () => _updateFilter(
                          _filter.copyWith(selectedSource: ExerciseSource.all)),
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
          style: AppTextStyles.labelSmall.copyWith(
            color: context.primaryColor,
          ),
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

  Widget _buildExerciseList() {
    if (_isLoading) {
      return SkeletonList(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.xs,
          ),
          child: SkeletonCard(height: 80),
        ),
      );
    }

    if (_errorMessage != null) {
      return EmptyState.error(
        message: _errorMessage!,
        onRetry: _loadExercises,
      );
    }

    if (_exercises.isEmpty) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedSearch01,
        title: 'No exercises found',
        description: _filter.hasActiveFilters
            ? 'Try adjusting your filters or search term'
            : 'Start by creating a custom exercise',
        actionLabel: _filter.hasActiveFilters ? 'Clear Filters' : null,
        onAction: _filter.hasActiveFilters ? _clearFilters : null,
      );
    }

    // Group exercises by muscle group region if no search/filter
    if (!_filter.hasActiveFilters) {
      return _buildGroupedExerciseList();
    }

    // Flat list for search/filtered results
    return RefreshIndicator(
      onRefresh: _loadExercises,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          return SlideInWidget(
            delay: Duration(milliseconds: 50 * (index % 10)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ExerciseListTile(
                exercise: exercise,
                onTap: () => _navigateToExerciseDetail(exercise),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedExerciseList() {
    // Group exercises by primary muscle group's region
    final Map<MuscleGroupRegion, List<Exercise>> groupedExercises = {};

    for (final exercise in _exercises) {
      if (exercise.targetMuscleGroups.isEmpty) {
        groupedExercises
            .putIfAbsent(MuscleGroupRegion.other, () => [])
            .add(exercise);
      } else {
        final region = exercise.targetMuscleGroups.first.region;
        groupedExercises.putIfAbsent(region, () => []).add(exercise);
      }
    }

    return RefreshIndicator(
      onRefresh: _loadExercises,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: MuscleGroupRegion.values.length,
        itemBuilder: (context, index) {
          final region = MuscleGroupRegion.values[index];
          final exercises = groupedExercises[region] ?? [];

          if (exercises.isEmpty) return const SizedBox.shrink();

          return SlideInWidget(
            delay: Duration(milliseconds: 100 * index),
            child: _buildRegionSection(region, exercises),
          );
        },
      ),
    );
  }

  Widget _buildRegionSection(
      MuscleGroupRegion region, List<Exercise> exercises) {
    final isExpanded = _expandedRegions[region] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Region Header
        InkWell(
          onTap: () {
            setState(() {
              _expandedRegions[region] = !isExpanded;
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
                    color: _getRegionColor(region),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const HSpace.sm(),
                Expanded(
                  child: Text(
                    region.displayName,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${exercises.length}',
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

        // Exercises
        AnimatedCrossFade(
          firstChild: Column(
            children: exercises
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ExerciseListTile(
                        exercise: e,
                        onTap: () => _navigateToExerciseDetail(e),
                      ),
                    ))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),

        const VSpace.md(),
      ],
    );
  }

  Color _getRegionColor(MuscleGroupRegion region) {
    switch (region) {
      case MuscleGroupRegion.upperPush:
        return AppColors.muscleChest;
      case MuscleGroupRegion.upperPull:
        return AppColors.muscleBack;
      case MuscleGroupRegion.legs:
        return AppColors.muscleLegs;
      case MuscleGroupRegion.core:
        return AppColors.muscleCore;
      case MuscleGroupRegion.cardio:
        return AppColors.cardio;
      case MuscleGroupRegion.other:
        return context.outlineVariant;
    }
  }

  Future<void> _navigateToExerciseDetail(Exercise exercise) async {
    await context.push('${AppRoutes.exercises}/${exercise.id}');
    // Refresh the exercise list when returning from detail/edit screen
    _loadExercises();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FilterBottomSheet(
        currentFilter: _filter,
        onFilterChanged: (newFilter) {
          Navigator.pop(context);
          _updateFilter(newFilter);
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: EmptyState(
          icon: HugeIcons.strokeRoundedGlobe02,
          title: 'Discover Coming Soon',
          description:
              'Browse and download exercises created by the community. This feature is under development.',
        ),
      ),
    );
  }
}

/// A list tile widget for displaying an exercise in the library
class _ExerciseListTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseListTile({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryMuscle = exercise.targetMuscleGroups.isNotEmpty
        ? exercise.targetMuscleGroups.first
        : null;
    final muscleColor = primaryMuscle != null
        ? AppColors.getMuscleGroupColor(primaryMuscle)
        : context.outlineVariant;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: muscleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
                bottomLeft: Radius.circular(AppDimensions.borderRadiusLarge),
              ),
            ),
          ),

          const HSpace.md(),

          // Exercise info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const VSpace.xs(),
                  Row(
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusSmall),
                        ),
                        child: Text(
                          exercise.category.displayName,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.primaryColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const HSpace.xs(),
                      // Muscle groups
                      Expanded(
                        child: Text(
                          exercise.targetMuscleGroups
                              .map((m) => m.displayName)
                              .join(', '),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Custom indicator
          if (!exercise.isDefault)
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
}

/// Bottom sheet for filtering exercises
class _FilterBottomSheet extends StatefulWidget {
  final ExerciseLibraryFilter currentFilter;
  final ValueChanged<ExerciseLibraryFilter> onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late ExerciseLibraryFilter _filter;
  final Map<MuscleGroupRegion, bool> _expandedRegions = {};

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;

    // Initialize all regions as collapsed
    for (final region in MuscleGroupRegion.values) {
      _expandedRegions[region] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
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
                  'Filter Exercises',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = const ExerciseLibraryFilter();
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
                  // Category Filter
                  _buildSectionTitle('Category'),
                  const VSpace.sm(),
                  _buildCategoryChips(),
                  const VSpace.lg(),

                  // Source Filter
                  _buildSectionTitle('Source'),
                  const VSpace.sm(),
                  _buildSourceChips(),
                  const VSpace.lg(),

                  // Muscle Group Filter
                  _buildSectionTitle('Muscle Group'),
                  const VSpace.sm(),
                  _buildMuscleGroupSelector(),
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

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ExerciseCategory.values.map((category) {
        final isSelected = _filter.selectedCategory == category;
        return FilterChip(
          label: Text(category.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filter = _filter.copyWith(
                selectedCategory: selected ? category : null,
                clearCategory: !selected,
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

  Widget _buildSourceChips() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ExerciseSource.values.map((source) {
        final isSelected = _filter.selectedSource == source;
        return FilterChip(
          label: Text(source.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filter = _filter.copyWith(
                selectedSource: selected ? source : ExerciseSource.all,
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

  Widget _buildMuscleGroupSelector() {
    return Column(
      children: MuscleGroupRegion.values.map((region) {
        final muscleGroups = MuscleGroupExtension.byRegion(region);
        if (muscleGroups.isEmpty) return const SizedBox.shrink();

        final isExpanded = _expandedRegions[region] ?? false;

        return Column(
          children: [
            // Region Header
            InkWell(
              onTap: () {
                setState(() {
                  _expandedRegions[region] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        region.displayName,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        color: context.textSecondary,
                        size: AppDimensions.iconSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Muscle Group Chips
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: muscleGroups.map((mg) {
                    final isSelected = _filter.selectedMuscleGroup == mg;
                    return FilterChip(
                      label: Text(mg.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filter = _filter.copyWith(
                            selectedMuscleGroup: selected ? mg : null,
                            clearMuscleGroup: !selected,
                          );
                        });
                      },
                      selectedColor:
                          context.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: context.primaryColor,
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? context.primaryColor
                            : context.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      }).toList(),
    );
  }
}
