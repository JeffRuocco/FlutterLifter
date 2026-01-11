import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

/// Sort options for program library list
enum ProgramSortOption {
  lastUsed('Last Used'),
  name('Name'),
  createdAt('Date Created'),
  difficulty('Difficulty');

  final String displayName;
  const ProgramSortOption(this.displayName);
}

/// State class for program library filtering
class ProgramLibraryFilterState {
  /// Search query text
  final String searchQuery;

  /// Selected program type to filter by (null = all)
  final ProgramType? selectedType;

  /// Selected difficulty to filter by (null = all)
  final ProgramDifficulty? selectedDifficulty;

  /// Selected source filter
  final ProgramSource selectedSource;

  /// Sort option
  final ProgramSortOption sortOption;

  const ProgramLibraryFilterState({
    this.searchQuery = '',
    this.selectedType,
    this.selectedDifficulty,
    this.selectedSource = ProgramSource.all,
    this.sortOption = ProgramSortOption.lastUsed,
  });

  /// Whether any filters are active (not including sort)
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedType != null ||
      selectedDifficulty != null ||
      selectedSource != ProgramSource.all;

  /// Count of active filter categories (not including search)
  int get activeFilterCount {
    var count = 0;
    if (selectedType != null) count++;
    if (selectedDifficulty != null) count++;
    if (selectedSource != ProgramSource.all) count++;
    return count;
  }

  /// Creates a copy with updated values
  ProgramLibraryFilterState copyWith({
    String? searchQuery,
    ProgramType? selectedType,
    bool clearSelectedType = false,
    ProgramDifficulty? selectedDifficulty,
    bool clearSelectedDifficulty = false,
    ProgramSource? selectedSource,
    ProgramSortOption? sortOption,
  }) {
    return ProgramLibraryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
      selectedDifficulty: clearSelectedDifficulty
          ? null
          : (selectedDifficulty ?? this.selectedDifficulty),
      selectedSource: selectedSource ?? this.selectedSource,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramLibraryFilterState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          selectedType == other.selectedType &&
          selectedDifficulty == other.selectedDifficulty &&
          selectedSource == other.selectedSource &&
          sortOption == other.sortOption;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      selectedType.hashCode ^
      selectedDifficulty.hashCode ^
      selectedSource.hashCode ^
      sortOption.hashCode;
}

/// Notifier for managing program library filter state
class ProgramLibraryFilterNotifier extends Notifier<ProgramLibraryFilterState> {
  @override
  ProgramLibraryFilterState build() {
    return const ProgramLibraryFilterState();
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear search query
  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  /// Set program type filter
  void setTypeFilter(ProgramType? type) {
    if (type == null) {
      state = state.copyWith(clearSelectedType: true);
    } else {
      state = state.copyWith(selectedType: type);
    }
  }

  /// Clear program type filter
  void clearTypeFilter() {
    state = state.copyWith(clearSelectedType: true);
  }

  /// Set difficulty filter
  void setDifficultyFilter(ProgramDifficulty? difficulty) {
    if (difficulty == null) {
      state = state.copyWith(clearSelectedDifficulty: true);
    } else {
      state = state.copyWith(selectedDifficulty: difficulty);
    }
  }

  /// Clear difficulty filter
  void clearDifficultyFilter() {
    state = state.copyWith(clearSelectedDifficulty: true);
  }

  /// Set source filter
  void setSourceFilter(ProgramSource source) {
    state = state.copyWith(selectedSource: source);
  }

  /// Set sort option
  void setSortOption(ProgramSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  /// Clear all filters (reset to default)
  void clearAllFilters() {
    state = const ProgramLibraryFilterState();
  }

  /// Clear all filters except sort option
  void clearFiltersKeepSort() {
    state = ProgramLibraryFilterState(sortOption: state.sortOption);
  }

  /// Update multiple filter fields at once, preserving source filter.
  /// Used by filter bottom sheet to apply all changes atomically.
  void updateFilters({
    String? searchQuery,
    ProgramType? selectedType,
    bool clearSelectedType = false,
    ProgramDifficulty? selectedDifficulty,
    bool clearSelectedDifficulty = false,
    ProgramSortOption? sortOption,
  }) {
    state = state.copyWith(
      searchQuery: searchQuery,
      selectedType: selectedType,
      clearSelectedType: clearSelectedType,
      selectedDifficulty: selectedDifficulty,
      clearSelectedDifficulty: clearSelectedDifficulty,
      sortOption: sortOption,
      // Note: source filter is preserved, not modified here
    );
  }
}

/// Provider for program library filter state
final programLibraryFilterProvider =
    NotifierProvider<ProgramLibraryFilterNotifier, ProgramLibraryFilterState>(
      ProgramLibraryFilterNotifier.new,
    );

/// Extension to filter and sort a list of programs based on filter state
extension ProgramFilterExtension on List<Program> {
  /// Apply filters and sorting from the given state
  List<Program> applyFilters(ProgramLibraryFilterState filterState) {
    var result = List<Program>.from(this);

    // Apply search query
    if (filterState.searchQuery.isNotEmpty) {
      final query = filterState.searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false) ||
            p.tags.any((t) => t.toLowerCase().contains(query)) ||
            p.type.displayName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply type filter
    if (filterState.selectedType != null) {
      result = result.where((p) => p.type == filterState.selectedType).toList();
    }

    // Apply difficulty filter
    if (filterState.selectedDifficulty != null) {
      result = result
          .where((p) => p.difficulty == filterState.selectedDifficulty)
          .toList();
    }

    // Apply source filter
    switch (filterState.selectedSource) {
      case ProgramSource.all:
        // No filtering needed
        break;
      case ProgramSource.defaultOnly:
        result = result.where((p) => p.isDefault).toList();
        break;
      case ProgramSource.customOnly:
        result = result.where((p) => !p.isDefault).toList();
        break;
      case ProgramSource.myPrograms:
        // Custom programs + default programs that have been used
        result = result
            .where((p) => !p.isDefault || (p.isDefault && p.lastUsedAt != null))
            .toList();
        break;
      case ProgramSource.communityOnly:
        // Future: filter by community flag
        result = [];
        break;
    }

    // Apply sorting
    _applySort(result, filterState.sortOption);

    return result;
  }

  void _applySort(List<Program> result, ProgramSortOption sortOption) {
    switch (sortOption) {
      case ProgramSortOption.lastUsed:
        result.sort((a, b) {
          final aDate = a.lastUsedAt;
          final bDate = b.lastUsedAt;
          // Programs with lastUsedAt come first, sorted by most recent
          if (aDate == null && bDate == null) return a.name.compareTo(b.name);
          if (aDate == null) return 1; // a goes to end
          if (bDate == null) return -1; // b goes to end
          return bDate.compareTo(aDate); // Most recent first
        });
        break;
      case ProgramSortOption.name:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProgramSortOption.createdAt:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProgramSortOption.difficulty:
        result.sort((a, b) {
          final diffCompare = a.difficulty.index.compareTo(b.difficulty.index);
          if (diffCompare != 0) return diffCompare;
          return a.name.compareTo(b.name);
        });
        break;
    }
  }
}
