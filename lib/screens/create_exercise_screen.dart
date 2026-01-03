import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/repository_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';

/// Screen for creating or editing a custom exercise.
///
/// Pass [exerciseId] to edit an existing exercise, or leave null to create new.
class CreateExerciseScreen extends ConsumerStatefulWidget {
  final String? exerciseId;

  const CreateExerciseScreen({
    super.key,
    this.exerciseId,
  });

  bool get isEditMode => exerciseId != null;

  @override
  ConsumerState<CreateExerciseScreen> createState() =>
      _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  // Form state
  ExerciseCategory _category = ExerciseCategory.strength;
  Set<MuscleGroup> _selectedMuscleGroups = {};
  int _defaultSets = 3;
  int _defaultReps = 10;
  double? _defaultWeight;
  int _defaultRestTimeSeconds = 180;

  // Loading and error state
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Muscle group filter expansion state
  final Map<MuscleGroupRegion, bool> _expandedRegions = {};

  @override
  void initState() {
    super.initState();
    // Initialize all regions as collapsed
    for (final region in MuscleGroupRegion.values) {
      _expandedRegions[region] = false;
    }

    if (widget.isEditMode) {
      _loadExercise();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _shortNameController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    if (widget.exerciseId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(exerciseRepositoryProvider);
      final exercise = await repository.getExerciseById(widget.exerciseId!);

      if (exercise == null) {
        setState(() {
          _errorMessage = 'Exercise not found';
          _isLoading = false;
        });
        return;
      }

      // Cannot edit default exercises
      if (exercise.isDefault) {
        setState(() {
          _errorMessage = 'Cannot edit default exercises';
          _isLoading = false;
        });
        return;
      }

      _populateFormFromExercise(exercise);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exercise: $e';
        _isLoading = false;
      });
    }
  }

  void _populateFormFromExercise(Exercise exercise) {
    _nameController.text = exercise.name;
    _shortNameController.text = exercise.shortName ?? '';
    _instructionsController.text = exercise.instructions ?? '';
    _notesController.text = exercise.notes ?? '';
    _imageUrlController.text = exercise.imageUrl ?? '';

    _category = exercise.category;
    _selectedMuscleGroups = exercise.targetMuscleGroups.toSet();
    _defaultSets = exercise.defaultSets;
    _defaultReps = exercise.defaultReps;
    _defaultWeight = exercise.defaultWeight;
    _defaultRestTimeSeconds = exercise.defaultRestTimeSeconds;
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMuscleGroups.isEmpty) {
      showWarningMessage(
          context, 'Please select at least one target muscle group');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(exerciseRepositoryProvider);

      final exercise = Exercise(
        id: widget.isEditMode ? widget.exerciseId! : Utils.generateId(),
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().isEmpty
            ? null
            : _shortNameController.text.trim(),
        category: _category,
        targetMuscleGroups: _selectedMuscleGroups.toList(),
        defaultSets: _defaultSets,
        defaultReps: _defaultReps,
        defaultWeight: _defaultWeight,
        defaultRestTimeSeconds: _defaultRestTimeSeconds,
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        isDefault: false,
      );

      if (widget.isEditMode) {
        await repository.updateCustomExercise(exercise);
        if (mounted) {
          showSuccessMessage(context, 'Exercise updated successfully!');
          context.pop();
        }
      } else {
        await repository.createCustomExercise(exercise);
        if (mounted) {
          showSuccessMessage(context, 'Exercise created successfully!');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorMessage(context, 'Failed to save exercise: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Edit Exercise' : 'Create Exercise',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.onSurface),
        actions: [
          if (!_isLoading && _errorMessage == null)
            TextButton(
              onPressed: _isSaving ? null : _saveExercise,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.primaryColor,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: EmptyState.error(
            message: _errorMessage!,
            onRetry: widget.isEditMode ? _loadExercise : null,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Basic Info Section
          _buildSectionTitle('Basic Information'),
          const VSpace.sm(),
          _buildNameFields(),

          const VSpace.xl(),

          // Category Section
          _buildSectionTitle('Category'),
          const VSpace.sm(),
          _buildCategorySelector(),

          const VSpace.xl(),

          // Muscle Groups Section
          _buildSectionTitle('Target Muscles'),
          const VSpace.xs(),
          Text(
            'Select the muscle groups this exercise targets',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          const VSpace.sm(),
          _buildMuscleGroupSelector(),

          const VSpace.xl(),

          // Default Values Section
          _buildSectionTitle('Default Values'),
          const VSpace.xs(),
          Text(
            'These values will be pre-filled when adding this exercise to a workout',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          const VSpace.sm(),
          _buildDefaultValuesSection(),

          const VSpace.xl(),

          // Instructions Section
          _buildSectionTitle('Instructions'),
          const VSpace.sm(),
          _buildInstructionsField(),

          const VSpace.xl(),

          // Notes Section
          _buildSectionTitle('Notes'),
          const VSpace.sm(),
          _buildNotesField(),

          const VSpace.xl(),

          // Media Section
          _buildSectionTitle('Media (Optional)'),
          const VSpace.xs(),
          Text(
            'Add image or video URLs for reference',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          const VSpace.sm(),
          _buildMediaFields(),

          const VSpace.xxl(),

          // Save Button
          AppButton(
            text: widget.isEditMode ? 'Update Exercise' : 'Create Exercise',
            onPressed: _isSaving ? null : _saveExercise,
            isLoading: _isSaving,
          ),

          const VSpace.xl(),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonText(width: 120),
          VSpace.sm(),
          SkeletonCard(height: 56),
          VSpace.md(),
          SkeletonCard(height: 56),
          VSpace.xl(),
          SkeletonText(width: 100),
          VSpace.sm(),
          SkeletonCard(height: 100),
          VSpace.xl(),
          SkeletonText(width: 140),
          VSpace.sm(),
          SkeletonCard(height: 150),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: context.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNameFields() {
    return Column(
      children: [
        AppTextFormField(
          controller: _nameController,
          labelText: 'Exercise Name *',
          hintText: 'e.g., Dumbbell Bench Press',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an exercise name';
            }
            if (value.trim().length < 3) {
              return 'Name must be at least 3 characters';
            }
            return null;
          },
        ),
        const VSpace.md(),
        AppTextFormField(
          controller: _shortNameController,
          labelText: 'Short Name (Optional)',
          hintText: 'e.g., DB Bench (shorter name for compact displays)',
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ExerciseCategory.values.map((category) {
        final isSelected = _category == category;
        return ChoiceChip(
          label: Text(category.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _category = category;
              });
            }
          },
          selectedColor: context.primaryColor.withValues(alpha: 0.2),
          checkmarkColor: context.primaryColor,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? context.primaryColor : context.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMuscleGroupSelector() {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected count
          if (_selectedMuscleGroups.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _selectedMuscleGroups.map((mg) {
                final color = AppColors.getMuscleGroupColor(mg);
                return Chip(
                  label: Text(
                    mg.displayName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: color,
                    ),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  deleteIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: color,
                    size: 16,
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedMuscleGroups.remove(mg);
                    });
                  },
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const VSpace.sm(),
            const Divider(),
          ],

          // Muscle group regions
          ...MuscleGroupRegion.values.map((region) {
            final muscleGroups = MuscleGroupExtension.byRegion(region);
            if (muscleGroups.isEmpty) return const SizedBox.shrink();

            final isExpanded = _expandedRegions[region] ?? false;
            final selectedInRegion =
                _selectedMuscleGroups.where((mg) => mg.region == region).length;

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
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                        if (selectedInRegion > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadiusSmall),
                            ),
                            child: Text(
                              '$selectedInRegion',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const HSpace.xs(),
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
                        final isSelected = _selectedMuscleGroups.contains(mg);
                        return FilterChip(
                          label: Text(mg.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMuscleGroups.add(mg);
                              } else {
                                _selectedMuscleGroups.remove(mg);
                              }
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
          }),
        ],
      ),
    );
  }

  Widget _buildDefaultValuesSection() {
    return AppCard(
      child: Column(
        children: [
          // Sets and Reps Row
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  label: 'Sets',
                  value: _defaultSets,
                  min: 1,
                  max: 20,
                  onChanged: (value) {
                    setState(() {
                      _defaultSets = value;
                    });
                  },
                ),
              ),
              const HSpace.md(),
              Expanded(
                child: _buildNumberInput(
                  label: 'Reps',
                  value: _defaultReps,
                  min: 1,
                  max: 100,
                  onChanged: (value) {
                    setState(() {
                      _defaultReps = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const VSpace.md(),
          const Divider(),
          const VSpace.md(),

          // Weight Input
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Weight (lbs)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const VSpace.xs(),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _defaultWeight?.toString() ?? '',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,1}')),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Optional',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: context.textSecondary,
                              ),
                              filled: true,
                              fillColor: context.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.borderRadiusMedium),
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
                              setState(() {
                                _defaultWeight = value.isEmpty
                                    ? null
                                    : double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const HSpace.sm(),
                        Text(
                          'lbs',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const VSpace.md(),
          const Divider(),
          const VSpace.md(),

          // Rest Time Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest Time Between Sets',
                style: AppTextStyles.labelMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const VSpace.sm(),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _defaultRestTimeSeconds.toDouble(),
                      min: 30,
                      max: 300,
                      divisions: 27,
                      label: _formatRestTime(_defaultRestTimeSeconds),
                      onChanged: (value) {
                        setState(() {
                          _defaultRestTimeSeconds = value.round();
                        });
                      },
                    ),
                  ),
                  const HSpace.sm(),
                  Container(
                    width: 60,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatRestTime(_defaultRestTimeSeconds),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        const VSpace.xs(),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMinusSign,
                color: value > min
                    ? context.primaryColor
                    : context.textSecondary.withValues(alpha: 0.3),
                size: AppDimensions.iconMedium,
              ),
              style: IconButton.styleFrom(
                backgroundColor: context.surfaceVariant,
              ),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                color: value < max
                    ? context.primaryColor
                    : context.textSecondary.withValues(alpha: 0.3),
                size: AppDimensions.iconMedium,
              ),
              style: IconButton.styleFrom(
                backgroundColor: context.surfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatRestTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
  }

  Widget _buildInstructionsField() {
    return AppTextFormField(
      controller: _instructionsController,
      labelText: 'Exercise Instructions',
      hintText: 'Describe how to perform this exercise...',
      maxLines: 5,
    );
  }

  Widget _buildNotesField() {
    return AppTextFormField(
      controller: _notesController,
      labelText: 'Personal Notes',
      hintText: 'Any personal tips or reminders...',
      maxLines: 3,
    );
  }

  Widget _buildMediaFields() {
    return Column(
      children: [
        AppTextFormField(
          controller: _imageUrlController,
          labelText: 'Image URL',
          hintText: 'https://example.com/image.jpg',
          keyboardType: TextInputType.url,
          prefixIcon: HugeIcon(
            icon: HugeIcons.strokeRoundedImage01,
            color: context.textSecondary,
            size: AppDimensions.iconMedium,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasScheme) {
                return 'Please enter a valid URL';
              }
            }
            return null;
          },
        ),
        const VSpace.md(),
        AppTextFormField(
          controller: _videoUrlController,
          labelText: 'Video URL (coming soon)',
          hintText: 'https://youtube.com/watch?v=...',
          keyboardType: TextInputType.url,
          prefixIcon: HugeIcon(
            icon: HugeIcons.strokeRoundedVideo01,
            color: context.textSecondary,
            size: AppDimensions.iconMedium,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasScheme) {
                return 'Please enter a valid URL';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
