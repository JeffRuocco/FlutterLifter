import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import '../models/workout_models.dart';

class AddExerciseBottomSheet extends StatefulWidget {
  final Function(WorkoutExercise exercise) onExerciseAdded;
  final bool isSwapping;
  final WorkoutExercise? currentExercise;

  const AddExerciseBottomSheet({
    super.key,
    required this.onExerciseAdded,
    this.isSwapping = false,
    this.currentExercise,
  });

  @override
  State<AddExerciseBottomSheet> createState() => _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState extends State<AddExerciseBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseTemplate> _allExercises = [];
  List<ExerciseTemplate> _filteredExercises = [];
  ExerciseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializeExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeExercises() {
    // Sample exercises - in a real app, this would come from a database
    // TODO: initialize from database
    // TODO: support pre-defined exercises and user's custom exercises
    _allExercises = [
      ExerciseTemplate(
        id: 'squat',
        name: 'Barbell Back Squat',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Quadriceps', 'Glutes', 'Hamstrings'],
        defaultSets: 4,
        defaultReps: 8,
        defaultRestTimeSeconds: 180,
      ),
      ExerciseTemplate(
        id: 'bench',
        name: 'Bench Press',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Chest', 'Triceps', 'Shoulders'],
        defaultSets: 3,
        defaultReps: 8,
        defaultRestTimeSeconds: 120,
      ),
      ExerciseTemplate(
        id: 'deadlift',
        name: 'Deadlift',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Hamstrings', 'Glutes', 'Back'],
        defaultSets: 3,
        defaultReps: 5,
        defaultRestTimeSeconds: 180,
      ),
      ExerciseTemplate(
        id: 'ohp',
        name: 'Overhead Press',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Shoulders', 'Triceps', 'Core'],
        defaultSets: 3,
        defaultReps: 8,
        defaultRestTimeSeconds: 120,
      ),
      ExerciseTemplate(
        id: 'row',
        name: 'Bent-Over Barbell Row',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Lats', 'Rhomboids', 'Rear Delts'],
        defaultSets: 3,
        defaultReps: 8,
        defaultRestTimeSeconds: 90,
      ),
      ExerciseTemplate(
        id: 'pullup',
        name: 'Pull-ups',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Lats', 'Biceps', 'Rhomboids'],
        defaultSets: 3,
        defaultReps: 10,
        defaultRestTimeSeconds: 90,
      ),
      ExerciseTemplate(
        id: 'dips',
        name: 'Dips',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Triceps', 'Chest', 'Shoulders'],
        defaultSets: 3,
        defaultReps: 12,
        defaultRestTimeSeconds: 90,
      ),
      ExerciseTemplate(
        id: 'lunges',
        name: 'Lunges',
        category: ExerciseCategory.strength,
        targetMuscleGroups: ['Quadriceps', 'Glutes', 'Hamstrings'],
        defaultSets: 3,
        defaultReps: 12,
        defaultRestTimeSeconds: 60,
      ),
      ExerciseTemplate(
        id: 'plank',
        name: 'Plank',
        category: ExerciseCategory.flexibility,
        targetMuscleGroups: ['Core', 'Shoulders'],
        defaultSets: 3,
        defaultReps: 30,
        defaultRestTimeSeconds: 60,
      ),
      ExerciseTemplate(
        id: 'running',
        name: 'Running',
        category: ExerciseCategory.cardio,
        targetMuscleGroups: ['Legs', 'Cardiovascular'],
        defaultSets: 1,
        defaultReps: 30,
        defaultRestTimeSeconds: 0,
      ),
    ];

    _filteredExercises = List.from(_allExercises);
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        final matchesSearch = exercise.name.toLowerCase().contains(query) ||
            exercise.targetMuscleGroups
                .any((muscle) => muscle.toLowerCase().contains(query));

        final matchesCategory =
            _selectedCategory == null || exercise.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _selectExercise(ExerciseTemplate template) {
    final workoutExercise = WorkoutExercise.create(
      name: template.name,
      category: template.category,
      targetMuscleGroups: template.targetMuscleGroups,
      sets: List.generate(
        template.defaultSets,
        (index) => ExerciseSet.create(
          targetReps: template.defaultReps,
          targetWeight: template.defaultWeight,
        ),
      ),
      restTime: Duration(seconds: template.defaultRestTimeSeconds),
      notes: template.notes,
      instructions: template.instructions,
    );

    widget.onExerciseAdded(workoutExercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.borderRadiusXLarge),
          topRight: Radius.circular(AppDimensions.borderRadiusXLarge),
        ),
      ),
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

          // Title
          Text(
            widget.isSwapping ? 'Swap Exercise' : 'Add Exercise',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const VSpace.md(),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: context.textSecondary,
                size: AppDimensions.iconMedium,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
                borderSide: BorderSide(color: context.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
                borderSide: BorderSide(color: context.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
                borderSide: BorderSide(color: context.primaryColor),
              ),
            ),
          ),
          const VSpace.md(),

          // Category Filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(null, 'All'),
                ...ExerciseCategory.values.map(
                  (category) =>
                      _buildCategoryChip(category, category.displayName),
                ),
              ],
            ),
          ),
          const VSpace.md(),

          // Exercise List
          Expanded(
            child: _filteredExercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      return _buildExerciseListItem(exercise);
                    },
                  ),
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
          _filterExercises();
        },
        backgroundColor: context.surfaceVariant,
        selectedColor: context.primaryColor,
        checkmarkColor: context.onPrimary,
      ),
    );
  }

  Widget _buildExerciseListItem(ExerciseTemplate exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        title: Text(
          exercise.name,
          style: AppTextStyles.titleMedium.copyWith(
            color: context.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VSpace.xs(),
            Text(
              exercise.targetMuscleGroups.join(', '),
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
              ),
            ),
            const VSpace.xs(),
            Row(
              children: [
                _buildInfoChip(exercise.category.displayName),
                const HSpace.sm(),
                _buildInfoChip('${exercise.defaultSets} sets'),
                const HSpace.sm(),
                _buildInfoChip('${exercise.defaultReps} reps'),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: AppDimensions.iconMedium,
          color: context.textSecondary,
        ),
        onTap: () => _selectExercise(exercise),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: context.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            color: context.textSecondary,
            size: AppDimensions.iconXLarge,
          ),
          const VSpace.md(),
          Text(
            'No exercises found',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const VSpace.sm(),
          Text(
            'Try adjusting your search or category filter',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Template for creating workout exercises
class ExerciseTemplate {
  final String id;
  final String name;
  final ExerciseCategory category;
  final List<String> targetMuscleGroups;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeight;
  final int defaultRestTimeSeconds; // seconds
  final String? notes;
  final String? instructions;
  final String? imageUrl;

  ExerciseTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.targetMuscleGroups,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultWeight,
    required this.defaultRestTimeSeconds,
    this.notes,
    this.instructions,
    this.imageUrl,
  });
}
