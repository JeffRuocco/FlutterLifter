import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../models/models.dart';
import 'common/app_widgets.dart';
import 'skeleton_loader.dart';
import 'empty_state.dart';

/// A reusable exercise picker widget that can be shown in a bottom sheet or dialog.
///
/// Use [ExercisePicker.show] to display as a modal bottom sheet.
class ExercisePicker extends ConsumerStatefulWidget {
  /// Called when an exercise is selected
  final ValueChanged<Exercise> onExerciseSelected;

  /// Title displayed at the top of the picker
  final String title;

  /// Optional subtitle/description
  final String? subtitle;

  /// If true, shows a swap indicator instead of add indicator
  final bool isSwapping;

  /// The current exercise being swapped (for context)
  final Exercise? currentExercise;

  const ExercisePicker({
    super.key,
    required this.onExerciseSelected,
    this.title = 'Select Exercise',
    this.subtitle,
    this.isSwapping = false,
    this.currentExercise,
  });

  /// Shows the exercise picker as a modal bottom sheet.
  ///
  /// Returns the selected [Exercise] or null if dismissed.
  static Future<Exercise?> show(
    BuildContext context, {
    String title = 'Select Exercise',
    String? subtitle,
    bool isSwapping = false,
    Exercise? currentExercise,
  }) async {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExercisePicker(
        title: title,
        subtitle: subtitle,
        isSwapping: isSwapping,
        currentExercise: currentExercise,
        onExerciseSelected: (exercise) {
          Navigator.of(context).pop(exercise);
        },
      ),
    );
  }

  @override
  ConsumerState<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<ExercisePicker> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String? _errorMessage;
  ExerciseCategory? _selectedCategory;

  // Track expanded regions for collapsible sections
  final Map<MuscleGroupRegion, bool> _expandedRegions = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();

    // Initialize all regions as expanded
    for (final region in MuscleGroupRegion.values) {
      _expandedRegions[region] = true;
    }
  }

  @override
  void dispose() {
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
      final exercises = await repository.getExercises();

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

  List<Exercise> get _filteredExercises {
    var filtered = _exercises;

    // Apply search filter
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      filtered = filtered.where((exercise) {
        return exercise.name.toLowerCase().contains(query) ||
            exercise.targetMuscleGroups
                .any((m) => m.displayName.toLowerCase().contains(query));
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered =
          filtered.where((e) => e.category == _selectedCategory).toList();
    }

    return filtered;
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty || _selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.borderRadiusXLarge),
            topRight: Radius.circular(AppDimensions.borderRadiusXLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
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
                              widget.title,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: context.textPrimary,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const VSpace.xs(),
                              Text(
                                widget.subtitle!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: context.textSecondary,
                          size: AppDimensions.iconMedium,
                        ),
                      ),
                    ],
                  ),
                  const VSpace.md(),

                  // Search Bar
                  _buildSearchBar(),
                  const VSpace.md(),

                  // Category Filter
                  _buildCategoryFilter(),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: context.outlineVariant),

            // Exercise List
            Expanded(
              child: _buildExerciseList(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
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
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: context.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
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
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(null, 'All'),
          ...ExerciseCategory.values.map(
            (category) => _buildCategoryChip(category, category.displayName),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ExerciseCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? context.onPrimary : context.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: context.surfaceVariant,
        selectedColor: context.primaryColor,
        checkmarkColor: context.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildExerciseList(ScrollController scrollController) {
    if (_isLoading) {
      return SkeletonList(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: SkeletonCard(height: 72),
        ),
      );
    }

    if (_errorMessage != null) {
      return EmptyState.error(
        message: _errorMessage!,
        onRetry: _loadExercises,
      );
    }

    final filtered = _filteredExercises;

    if (filtered.isEmpty) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedSearch01,
        title: 'No exercises found',
        description: _hasActiveFilters
            ? 'Try adjusting your search or filters'
            : 'No exercises available',
      );
    }

    // If searching/filtering, show flat list
    if (_hasActiveFilters) {
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final exercise = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ExercisePickerTile(
              exercise: exercise,
              onTap: () => widget.onExerciseSelected(exercise),
              isCurrentExercise: widget.currentExercise?.id == exercise.id,
            ),
          );
        },
      );
    }

    // Group by muscle region
    return _buildGroupedList(scrollController, filtered);
  }

  Widget _buildGroupedList(
      ScrollController scrollController, List<Exercise> exercises) {
    // Group exercises by primary muscle group's region
    final Map<MuscleGroupRegion, List<Exercise>> groupedExercises = {};

    for (final exercise in exercises) {
      if (exercise.targetMuscleGroups.isEmpty) {
        groupedExercises
            .putIfAbsent(MuscleGroupRegion.other, () => [])
            .add(exercise);
      } else {
        final region = exercise.targetMuscleGroups.first.region;
        groupedExercises.putIfAbsent(region, () => []).add(exercise);
      }
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: MuscleGroupRegion.values.length,
      itemBuilder: (context, index) {
        final region = MuscleGroupRegion.values[index];
        final regionExercises = groupedExercises[region] ?? [];

        if (regionExercises.isEmpty) return const SizedBox.shrink();

        return _buildRegionSection(region, regionExercises);
      },
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
                      child: _ExercisePickerTile(
                        exercise: e,
                        onTap: () => widget.onExerciseSelected(e),
                        isCurrentExercise: widget.currentExercise?.id == e.id,
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
}

/// A tile widget for displaying an exercise in the picker
class _ExercisePickerTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final bool isCurrentExercise;

  const _ExercisePickerTile({
    required this.exercise,
    required this.onTap,
    this.isCurrentExercise = false,
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
      onTap: isCurrentExercise ? null : onTap,
      padding: EdgeInsets.zero,
      child: Opacity(
        opacity: isCurrentExercise ? 0.5 : 1.0,
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
                        // Defaults info
                        Text(
                          '${exercise.defaultSets} sets • ${exercise.defaultReps} reps',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const HSpace.sm(),
                        // Muscle groups
                        Expanded(
                          child: Text(
                            exercise.targetMuscleGroups
                                .take(2)
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

            // Current exercise indicator or add button
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: isCurrentExercise
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.outlineVariant,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusSmall),
                      ),
                      child: Text(
                        'Current',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: context.primaryColor,
                      size: AppDimensions.iconMedium,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
