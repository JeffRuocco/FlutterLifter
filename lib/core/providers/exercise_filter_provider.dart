import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

/// State class for exercise library filtering
class ExerciseFilterState {
  /// Search query text
  final String searchQuery;

  /// Selected muscle groups to filter by (empty = all)
  final Set<MuscleGroup> selectedMuscleGroups;

  /// Selected categories to filter by (empty = all)
  final Set<ExerciseCategory> selectedCategories;

  /// Selected source filter (null = all sources)
  final ExerciseSource? sourceFilter;

  /// Sort option
  final ExerciseSortOption sortOption;

  /// Whether to show favorites first
  final bool favoritesFirst;

  const ExerciseFilterState({
    this.searchQuery = '',
    this.selectedMuscleGroups = const {},
    this.selectedCategories = const {},
    this.sourceFilter,
    this.sortOption = ExerciseSortOption.alphabetical,
    this.favoritesFirst = false,
  });

  /// Whether any filters are active
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedMuscleGroups.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      sourceFilter != null;

  /// Count of active filter categories (not including search)
  int get activeFilterCount {
    var count = 0;
    if (selectedMuscleGroups.isNotEmpty) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (sourceFilter != null) count++;
    return count;
  }

  /// Creates a copy with updated values
  ExerciseFilterState copyWith({
    String? searchQuery,
    Set<MuscleGroup>? selectedMuscleGroups,
    Set<ExerciseCategory>? selectedCategories,
    ExerciseSource? sourceFilter,
    bool clearSourceFilter = false,
    ExerciseSortOption? sortOption,
    bool? favoritesFirst,
  }) {
    return ExerciseFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMuscleGroups: selectedMuscleGroups ?? this.selectedMuscleGroups,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      sourceFilter:
          clearSourceFilter ? null : (sourceFilter ?? this.sourceFilter),
      sortOption: sortOption ?? this.sortOption,
      favoritesFirst: favoritesFirst ?? this.favoritesFirst,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilterState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          selectedMuscleGroups == other.selectedMuscleGroups &&
          selectedCategories == other.selectedCategories &&
          sourceFilter == other.sourceFilter &&
          sortOption == other.sortOption &&
          favoritesFirst == other.favoritesFirst;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      selectedMuscleGroups.hashCode ^
      selectedCategories.hashCode ^
      sourceFilter.hashCode ^
      sortOption.hashCode ^
      favoritesFirst.hashCode;
}

/// Sort options for exercise list
enum ExerciseSortOption {
  alphabetical('A-Z'),
  reverseAlphabetical('Z-A'),
  recentlyUsed('Recently Used'),
  mostUsed('Most Used'),
  muscleGroup('Muscle Group');

  final String displayName;
  const ExerciseSortOption(this.displayName);
}

/// StateNotifier for managing exercise filter state
class ExerciseFilterNotifier extends StateNotifier<ExerciseFilterState> {
  ExerciseFilterNotifier() : super(const ExerciseFilterState());

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear search query
  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  /// Toggle a muscle group filter
  void toggleMuscleGroup(MuscleGroup muscleGroup) {
    final current = Set<MuscleGroup>.from(state.selectedMuscleGroups);
    if (current.contains(muscleGroup)) {
      current.remove(muscleGroup);
    } else {
      current.add(muscleGroup);
    }
    state = state.copyWith(selectedMuscleGroups: current);
  }

  /// Set muscle groups (replace all)
  void setMuscleGroups(Set<MuscleGroup> muscleGroups) {
    state = state.copyWith(selectedMuscleGroups: muscleGroups);
  }

  /// Clear all muscle group filters
  void clearMuscleGroups() {
    state = state.copyWith(selectedMuscleGroups: {});
  }

  /// Toggle a category filter
  void toggleCategory(ExerciseCategory category) {
    final current = Set<ExerciseCategory>.from(state.selectedCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedCategories: current);
  }

  /// Set categories (replace all)
  void setCategories(Set<ExerciseCategory> categories) {
    state = state.copyWith(selectedCategories: categories);
  }

  /// Clear all category filters
  void clearCategories() {
    state = state.copyWith(selectedCategories: {});
  }

  /// Set source filter
  void setSourceFilter(ExerciseSource? source) {
    if (source == null) {
      state = state.copyWith(clearSourceFilter: true);
    } else {
      state = state.copyWith(sourceFilter: source);
    }
  }

  /// Clear source filter
  void clearSourceFilter() {
    state = state.copyWith(clearSourceFilter: true);
  }

  /// Set sort option
  void setSortOption(ExerciseSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  /// Toggle favorites first
  void toggleFavoritesFirst() {
    state = state.copyWith(favoritesFirst: !state.favoritesFirst);
  }

  /// Set favorites first
  void setFavoritesFirst(bool value) {
    state = state.copyWith(favoritesFirst: value);
  }

  /// Clear all filters (reset to default)
  void clearAllFilters() {
    state = const ExerciseFilterState();
  }

  /// Clear all filters except sort option
  void clearFiltersKeepSort() {
    state = ExerciseFilterState(sortOption: state.sortOption);
  }
}

/// Provider for exercise filter state
final exerciseFilterProvider =
    StateNotifierProvider<ExerciseFilterNotifier, ExerciseFilterState>(
  (ref) => ExerciseFilterNotifier(),
);

/// Extension to filter and sort a list of exercises based on filter state
extension ExerciseFilterExtension on List<Exercise> {
  /// Apply filters and sorting from the given state
  List<Exercise> applyFilters(
    ExerciseFilterState filterState, {
    Set<String>? favoriteIds,
    Map<String, DateTime>? lastUsedDates,
    Map<String, int>? usageCounts,
  }) {
    var result = List<Exercise>.from(this);

    // Apply search query
    if (filterState.searchQuery.isNotEmpty) {
      final query = filterState.searchQuery.toLowerCase();
      result = result.where((e) {
        return e.name.toLowerCase().contains(query) ||
            e.targetMuscleGroups
                .any((m) => m.displayName.toLowerCase().contains(query)) ||
            e.category.displayName.toLowerCase().contains(query) ||
            (e.instructions?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply muscle group filter
    if (filterState.selectedMuscleGroups.isNotEmpty) {
      result = result.where((e) {
        return e.targetMuscleGroups
            .any((m) => filterState.selectedMuscleGroups.contains(m));
      }).toList();
    }

    // Apply category filter
    if (filterState.selectedCategories.isNotEmpty) {
      result = result.where((e) {
        return filterState.selectedCategories.contains(e.category);
      }).toList();
    }

    // Apply source filter
    if (filterState.sourceFilter != null) {
      result = result.where((e) {
        switch (filterState.sourceFilter!) {
          case ExerciseSource.all:
            return true;
          case ExerciseSource.defaultOnly:
            return e.isDefault;
          case ExerciseSource.customOnly:
            return !e.isDefault;
        }
      }).toList();
    }

    // Apply sorting
    _applySort(result, filterState.sortOption, lastUsedDates, usageCounts);

    // Apply favorites first if enabled
    if (filterState.favoritesFirst && favoriteIds != null) {
      final favorites =
          result.where((e) => favoriteIds.contains(e.id)).toList();
      final nonFavorites =
          result.where((e) => !favoriteIds.contains(e.id)).toList();
      result = [...favorites, ...nonFavorites];
    }

    return result;
  }

  void _applySort(
    List<Exercise> result,
    ExerciseSortOption sortOption,
    Map<String, DateTime>? lastUsedDates,
    Map<String, int>? usageCounts,
  ) {
    switch (sortOption) {
      case ExerciseSortOption.alphabetical:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ExerciseSortOption.reverseAlphabetical:
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ExerciseSortOption.recentlyUsed:
        if (lastUsedDates != null) {
          result.sort((a, b) {
            final aDate = lastUsedDates[a.id];
            final bDate = lastUsedDates[b.id];
            if (aDate == null && bDate == null) return a.name.compareTo(b.name);
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });
        }
        break;
      case ExerciseSortOption.mostUsed:
        if (usageCounts != null) {
          result.sort((a, b) {
            final aCount = usageCounts[a.id] ?? 0;
            final bCount = usageCounts[b.id] ?? 0;
            if (aCount == bCount) return a.name.compareTo(b.name);
            return bCount.compareTo(aCount);
          });
        }
        break;
      case ExerciseSortOption.muscleGroup:
        result.sort((a, b) {
          // Sort by first target muscle group, or by name if none
          final aGroup = a.targetMuscleGroups.isNotEmpty
              ? a.targetMuscleGroups.first.displayName
              : '';
          final bGroup = b.targetMuscleGroups.isNotEmpty
              ? b.targetMuscleGroups.first.displayName
              : '';
          final groupCompare = aGroup.compareTo(bGroup);
          if (groupCompare != 0) return groupCompare;
          return a.name.compareTo(b.name);
        });
        break;
    }
  }
}
