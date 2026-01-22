import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import 'common/app_widgets.dart';

class SetInputWidget extends StatefulWidget {
  final int setNumber;
  final ExerciseSet exerciseSet;
  final bool isWorkoutStarted;

  /// Callback function that will be called when the completed state of the set is toggled
  final VoidCallback? onCompletedToggle;

  /// Callback function that will be called when the set data (weight, reps, notes) is updated
  final Function(
    double? weight,
    int? reps,
    String? notes,
    bool? markAsCompleted,
  )?
  onUpdated;

  const SetInputWidget({
    super.key,
    required this.setNumber,
    required this.exerciseSet,
    required this.isWorkoutStarted,
    this.onCompletedToggle,
    this.onUpdated,
  });

  @override
  State<SetInputWidget> createState() => _SetInputWidgetState();
}

class _SetInputWidgetState extends State<SetInputWidget> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  bool _showNotes = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize weight controller. If the workout hasn't started yet,
    // show the planned target weight so users can edit their planned weights.
    final weightValue = widget.isWorkoutStarted
        ? widget.exerciseSet.actualWeight
        : widget.exerciseSet.targetWeight;
    _weightController = TextEditingController(
      text: weightValue != null
          ? weightValue.toStringAsFixed(weightValue % 1 == 0 ? 0 : 1)
          : '',
    );

    // Initialize reps controller (actual when started, otherwise target)
    final repsValue = widget.isWorkoutStarted
        ? widget.exerciseSet.actualReps
        : widget.exerciseSet.targetReps;
    _repsController = TextEditingController(text: repsValue?.toString() ?? '');

    // Initialize notes controller
    _notesController.text = widget.exerciseSet.notes ?? '';
  }

  @override
  void didUpdateWidget(SetInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If it's a completely different ExerciseSet object, always update
    if (oldWidget.exerciseSet != widget.exerciseSet) {
      _updateControllersFromModel();
      return;
    }

    // Compare model data to current text field values
    final currentWeightText =
        (widget.isWorkoutStarted
                ? widget.exerciseSet.actualWeight
                : widget.exerciseSet.targetWeight) !=
            null
        ? (widget.isWorkoutStarted
                  ? widget.exerciseSet.actualWeight!
                  : widget.exerciseSet.targetWeight!)
              .toStringAsFixed(
                (widget.isWorkoutStarted
                                ? widget.exerciseSet.actualWeight!
                                : widget.exerciseSet.targetWeight!) %
                            1 ==
                        0
                    ? 0
                    : 1,
              )
        : '';

    final currentRepsText =
        (widget.isWorkoutStarted
                ? widget.exerciseSet.actualReps
                : widget.exerciseSet.targetReps)
            ?.toString() ??
        '';
    final currentNotesText = widget.exerciseSet.notes ?? '';

    // Check if model data differs from what's in the text fields
    if (_weightController.text != currentWeightText ||
        _repsController.text != currentRepsText ||
        _notesController.text != currentNotesText) {
      _updateControllersFromModel();
    }
  }

  void _updateControllersFromModel() {
    // Update the controllers directly without listeners
    final weightValue = widget.isWorkoutStarted
        ? widget.exerciseSet.actualWeight
        : widget.exerciseSet.targetWeight;
    _weightController.text = weightValue != null
        ? weightValue.toStringAsFixed(weightValue % 1 == 0 ? 0 : 1)
        : '';

    final repsValue = widget.isWorkoutStarted
        ? widget.exerciseSet.actualReps
        : widget.exerciseSet.targetReps;
    _repsController.text = repsValue?.toString() ?? '';
    _notesController.text = widget.exerciseSet.notes ?? '';
  }

  void _onInputFinished() {
    FocusScope.of(context).unfocus();
    final weight = double.tryParse(_weightController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    // Only call onUpdated when user finishes editing
    widget.onUpdated?.call(weight, reps, notes, false);
  }

  void _toggleCompleted() {
    if (widget.exerciseSet.isCompleted) {
      _showUnmarkConfirmation();
    } else {
      // Call the completion toggle callback
      widget.onCompletedToggle?.call();
    }
  }

  void _quickToggle() {
    // Quick toggle without confirmation on long press
    if (!widget.isWorkoutStarted) return;

    widget.onCompletedToggle?.call();
  }

  void _showUnmarkConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unmark Set?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to mark this set as incomplete?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCompletedToggle?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.errorColor,
              foregroundColor: context.onError,
            ),
            child: const Text('Unmark', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.exerciseSet.isCompleted;
    // Allow editing planned targets when the workout hasn't started yet.
    // If workout is started, edits affect actual values as before.
    final isEditable = !isCompleted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isCompleted
            ? context.successColor.withValues(alpha: 0.05)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(
          color: isCompleted
              ? context.successColor.withValues(alpha: 0.3)
              : context.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Set Number
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    '${widget.setNumber}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isCompleted
                          ? context.successColor
                          : context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Weight Input
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: _buildInputField(
                    controller: _weightController,
                    enabled: isEditable,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    suffix: 'lbs',
                    placeholder:
                        widget.exerciseSet.targetWeight?.toStringAsFixed(
                          widget.exerciseSet.targetWeight! % 1 == 0 ? 0 : 1,
                        ) ??
                        '--',
                  ),
                ),
              ),

              // Reps Input
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: _buildInputField(
                    controller: _repsController,
                    enabled: isEditable,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    placeholder:
                        widget.exerciseSet.targetReps?.toString() ?? '--',
                  ),
                ),
              ),

              // Complete Button
              SizedBox(
                width: 48,
                child: GestureDetector(
                  onTap: widget.isWorkoutStarted ? _toggleCompleted : null,
                  onLongPress: widget.isWorkoutStarted && isCompleted
                      ? _quickToggle
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? context.successColor
                            : context.outlineVariant,
                        shape: BoxShape.circle,
                        // Add subtle shadow when completed for depth
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: context.successColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                              color: context.onSuccessColor,
                              size: 16,
                            )
                          : Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: context.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Notes Section
          if (_showNotes || (widget.exerciseSet.notes?.isNotEmpty == true)) ...[
            const VSpace.sm(),
            _buildNotesField(),
          ],

          // Toggle Notes Button
          if (!_showNotes &&
              (widget.exerciseSet.notes?.isEmpty ?? true) &&
              widget.isWorkoutStarted) ...[
            const VSpace.xs(),
            InkWell(
              onTap: () => setState(() => _showNotes = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: context.textSecondary,
                      size: 14,
                    ),
                    const HSpace.xs(),
                    Text(
                      'Add Notes',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
    String? placeholder,
  }) {
    return AppTextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: TextAlign.center,
      onFieldSubmitted: (_) => _onInputFinished(),
      onEditingComplete: _onInputFinished,
      onTapOutside: (_) => _onInputFinished(),
      hintText: placeholder,
      suffixText: suffix,
      isDense: true,
    );
  }

  Widget _buildNotesField() {
    return AppTextFormField(
      controller: _notesController,
      enabled: widget.isWorkoutStarted,
      maxLines: 2,
      onFieldSubmitted: (_) => _onInputFinished(),
      onEditingComplete: _onInputFinished,
      onTapOutside: (_) => _onInputFinished(),
      hintText: 'Add notes for this set...',
      isDense: true,
      suffixIcon: _showNotes && (widget.exerciseSet.notes?.isEmpty ?? true)
          ? IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: context.textSecondary,
                size: AppDimensions.iconMedium,
              ),
              onPressed: () => setState(() => _showNotes = false),
            )
          : null,
    );
  }
}
