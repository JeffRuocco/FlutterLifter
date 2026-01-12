import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_lifter/models/exercise/exercise_session_record.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';

import '../core/providers/repository_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_extensions.dart';
import '../models/exercise/exercise_history.dart';
import '../models/models.dart';
import '../services/photo_storage_service.dart';
import 'common/app_widgets.dart';
import 'full_screen_photo_viewer.dart';
import 'skeleton_loader.dart';

/// Shared content widget for displaying exercise details.
///
/// Used by both [ExerciseDetailScreen] and [ExerciseDetailBottomSheet]
/// to avoid code duplication.
class ExerciseDetailContent extends ConsumerStatefulWidget {
  /// The exercise to display details for
  final Exercise exercise;

  /// Whether to show the media section (placeholder for future)
  final bool showMediaSection;

  /// Optional callback when "View All" history is tapped
  final VoidCallback? onViewAllHistory;

  const ExerciseDetailContent({
    super.key,
    required this.exercise,
    this.showMediaSection = true,
    this.onViewAllHistory,
  });

  @override
  ConsumerState<ExerciseDetailContent> createState() =>
      _ExerciseDetailContentState();
}

class _ExerciseDetailContentState extends ConsumerState<ExerciseDetailContent> {
  ExerciseHistory? _history;
  bool _isLoadingHistory = true;

  // User notes and photos
  UserExercisePreferences? _preferences;
  bool _isLoadingPreferences = true;
  final TextEditingController _userNotesController = TextEditingController();
  bool _isEditingNotes = false;
  bool _isSavingNotes = false;
  final FocusNode _notesFocusNode = FocusNode();

  // Photo service
  PhotoStorageService? _photoService;
  bool _isAddingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadPreferences();
    _initPhotoService();

    // Auto-save notes on focus loss
    _notesFocusNode.addListener(_handleNotesFocusChange);
  }

  @override
  void didUpdateWidget(ExerciseDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _loadHistory();
      _loadPreferences();
    }
  }

  @override
  void dispose() {
    _userNotesController.dispose();
    _notesFocusNode.removeListener(_handleNotesFocusChange);
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _handleNotesFocusChange() {
    if (!_notesFocusNode.hasFocus && _isEditingNotes) {
      _saveUserNotes();
    }
  }

  Future<void> _initPhotoService() async {
    try {
      final service = PhotoStorageService();
      await service.init();
      if (!mounted) return;
      setState(() {
        _photoService = service;
      });
    } catch (e, stackTrace) {
      // Ensure the photo service is not left in a partially initialized state.
      LoggingService.debug(
        'Failed to initialize PhotoStorageService: $e\n$stackTrace',
      );
      if (!mounted) return;
      setState(() {
        _photoService = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to initialize photo features. Photos will be disabled for this session.',
          ),
        ),
      );
    }
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoadingPreferences = true);
    try {
      final repo = ref.read(exerciseRepositoryProvider);
      var prefs = await repo.getPreferenceForExercise(widget.exercise.id);

      // Validate and clean up non-existent local photo paths (native platforms only)
      // TODO: make sure we clean up photos for web as well
      if (prefs != null && prefs.localPhotoPaths.isNotEmpty && !kIsWeb) {
        final validPaths = <String>[];
        final invalidPaths = <String>[];

        for (final path in prefs.localPhotoPaths) {
          final file = File(path);
          if (await file.exists()) {
            validPaths.add(path);
          } else {
            invalidPaths.add(path);
            LoggingService.debug(
              'Photo file not found, removing from preferences: $path',
            );
          }
        }

        // If some paths were invalid, update preferences
        if (invalidPaths.isNotEmpty) {
          // Also clean up pending uploads for invalid paths
          final validPendingUploads = prefs.pendingPhotoUploads
              .where((p) => !invalidPaths.contains(p))
              .toList();

          prefs = prefs.copyWith(
            localPhotoPaths: validPaths,
            pendingPhotoUploads: validPendingUploads,
            updatedAt: DateTime.now(),
          );

          // Persist the cleaned-up preferences
          await repo.setPreference(prefs);
        }
      }

      if (mounted) {
        setState(() {
          _preferences = prefs;
          _userNotesController.text = prefs?.userNotes ?? '';
          _isLoadingPreferences = false;
        });
      }
    } catch (e) {
      LoggingService.error('Error loading preferences: $e');
      if (mounted) {
        setState(() => _isLoadingPreferences = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final historyRepo = ref.read(exerciseHistoryRepositoryProvider);
      final history = await historyRepo.getExerciseHistory(widget.exercise);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _saveUserNotes() async {
    if (_isSavingNotes) return;

    final newNotes = _userNotesController.text.trim();
    final currentNotes = _preferences?.userNotes ?? '';

    // Only save if notes actually changed
    if (newNotes == currentNotes) {
      setState(() => _isEditingNotes = false);
      return;
    }

    setState(() => _isSavingNotes = true);

    try {
      final repo = ref.read(exerciseRepositoryProvider);
      await repo.updateExerciseUserNotes(
        widget.exercise.id,
        newNotes.isEmpty ? null : newNotes,
      );
      await _loadPreferences();
      if (mounted) {
        setState(() => _isEditingNotes = false);
        showSuccessMessage(context, 'Notes saved');
      }
    } catch (e) {
      if (mounted) {
        showErrorMessage(context, 'Failed to save notes');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNotes = false);
      }
    }
  }

  Future<void> _addPhotoFromCamera() async {
    if (_photoService == null || _isAddingPhoto) return;

    setState(() => _isAddingPhoto = true);

    try {
      final photoPath = await _photoService!.pickAndSaveFromCamera(
        widget.exercise.id,
      );

      if (photoPath != null && mounted) {
        final repo = ref.read(exerciseRepositoryProvider);
        await repo.addExercisePhoto(widget.exercise.id, photoPath);
        await _loadPreferences();
        if (mounted) showSuccessMessage(context, 'Photo added');
      }
    } catch (e) {
      LoggingService.error('Failed to add photo from camera: $e');
      if (mounted) {
        showErrorMessage(context, 'Failed to add photo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingPhoto = false);
      }
    }
  }

  Future<void> _addPhotoFromGallery() async {
    if (_photoService == null || _isAddingPhoto) return;

    setState(() => _isAddingPhoto = true);

    try {
      final photoPath = await _photoService!.pickAndSaveFromGallery(
        widget.exercise.id,
      );

      if (photoPath != null && mounted) {
        final repo = ref.read(exerciseRepositoryProvider);
        await repo.addExercisePhoto(widget.exercise.id, photoPath);
        await _loadPreferences();
        if (mounted) showSuccessMessage(context, 'Photo added');
      }
    } catch (e) {
      LoggingService.error('Failed to add photo from gallery: $e');
      if (mounted) {
        showErrorMessage(context, 'Failed to add photo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingPhoto = false);
      }
    }
  }

  Future<bool> _deletePhoto(String photoPath) async {
    try {
      // Delete from storage
      if (_photoService != null) {
        await _photoService!.deletePhoto(photoPath);
      }

      // Remove from preferences
      final repo = ref.read(exerciseRepositoryProvider);
      await repo.removeExercisePhoto(widget.exercise.id, photoPath);
      await _loadPreferences();

      return true;
    } catch (e) {
      LoggingService.error('Failed to delete photo: $e');
      if (mounted) {
        showErrorMessage(context, 'Failed to delete photo');
      }
      return false;
    }
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                color: context.primaryColor,
                size: AppDimensions.iconMedium,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _addPhotoFromCamera();
              },
            ),
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: context.infoColor,
                size: AppDimensions.iconMedium,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _addPhotoFromGallery();
              },
            ),
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: context.textSecondary,
                size: AppDimensions.iconMedium,
              ),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Info Section
        _buildBasicInfoSection(),

        const VSpace.xl(),

        // Default Values Section
        _buildDefaultValuesSection(),

        const VSpace.xl(),

        // History Section
        _buildHistorySection(),

        const VSpace.xl(),

        // Instructions Section
        _buildInstructionsSection(),

        // Notes Section (quick tips from exercise)
        if (widget.exercise.notes != null &&
            widget.exercise.notes!.isNotEmpty) ...[
          const VSpace.xl(),
          _buildNotesSection(),
        ],

        // User Notes Section (always shown for editing)
        const VSpace.xl(),
        _buildUserNotesSection(),

        // Media/Photos Section
        if (widget.showMediaSection) ...[
          const VSpace.xl(),
          _buildMediaSection(),
        ],
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category and Source badges
        Row(
          children: [
            _buildInfoBadge(
              widget.exercise.category.displayName,
              context.primaryColor,
            ),
            const HSpace.xs(),
            _buildInfoBadge(
              widget.exercise.isDefault ? 'Default' : 'Custom',
              widget.exercise.isDefault
                  ? context.infoColor
                  : context.warningColor,
            ),
          ],
        ),

        const VSpace.md(),

        // Muscle Groups
        Text(
          'Target Muscles',
          style: AppTextStyles.titleSmall.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const VSpace.sm(),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: widget.exercise.targetMuscleGroups.map((mg) {
            final color = AppColors.getMuscleGroupColor(mg);
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall,
                ),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                mg.displayName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDefaultValuesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Values',
            style: AppTextStyles.titleSmall.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const VSpace.md(),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedRepeat,
                  label: 'Sets',
                  value: '${widget.exercise.defaultSets}',
                  color: context.primaryColor,
                ),
              ),
              Container(width: 1, height: 60, color: context.outlineVariant),
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedTarget01,
                  label: 'Reps',
                  value: '${widget.exercise.defaultReps}',
                  color: context.infoColor,
                ),
              ),
              Container(width: 1, height: 60, color: context.outlineVariant),
              Expanded(
                child: _buildStatItem(
                  icon: HugeIcons.strokeRoundedClock01,
                  label: 'Rest',
                  value: _formatRestTime(
                    widget.exercise.defaultRestTimeSeconds,
                  ),
                  color: context.warningColor,
                ),
              ),
            ],
          ),
          if (widget.exercise.defaultWeight != null) ...[
            const VSpace.md(),
            const Divider(),
            const VSpace.md(),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedDumbbell01,
                  color: context.successColor,
                  size: AppDimensions.iconMedium,
                ),
                const HSpace.sm(),
                Text(
                  'Default Weight: ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  '${widget.exercise.defaultWeight} lbs',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required HugeIconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: color, size: AppDimensions.iconLarge),
          const VSpace.xs(),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatRestTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
  }

  Widget _buildHistorySection() {
    if (_isLoadingHistory) {
      return const AppCard(child: SkeletonCard(height: 100));
    }

    final hasHistory = _history != null && _history!.hasHistory;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedChart,
                color: context.successColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Expanded(
                child: Text(
                  'Your Progress',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasHistory && widget.onViewAllHistory != null)
                TextButton(
                  onPressed: widget.onViewAllHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.primaryColor,
                        ),
                      ),
                      const HSpace.xs(),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: context.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const VSpace.md(),
          if (!hasHistory) _buildNoHistoryState() else _buildHistoryContent(),
        ],
      ),
    );
  }

  Widget _buildNoHistoryState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedChartLineData01,
            color: context.textSecondary,
            size: AppDimensions.iconLarge,
          ),
          const VSpace.sm(),
          Text(
            'No history yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const VSpace.xs(),
          Text(
            'Complete a workout with this exercise to start tracking your progress',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PR Card
        _buildPRCard(),

        const VSpace.md(),

        // Quick Stats Row
        _buildHistoryQuickStats(),

        const VSpace.md(),

        // Last 3 Sessions Preview
        if (_history!.sessions.isNotEmpty) _buildRecentSessionsPreview(),
      ],
    );
  }

  Widget _buildPRCard() {
    final pr = _history!.allTimePR;
    final prDate = _history!.prDate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.successColor.withValues(alpha: 0.15),
            context.successColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: context.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMedal01,
                color: context.successColor,
                size: AppDimensions.iconMedium,
              ),
            ),
          ),
          const HSpace.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All-Time PR',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  pr != null ? '${pr.toStringAsFixed(1)} lbs' : 'No PR yet',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (prDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Est. 1RM',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(prDate),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryQuickStats() {
    final daysSince = _history!.daysSinceLastPerformed;

    return Row(
      children: [
        Expanded(
          child: _buildHistoryStatItem(
            icon: HugeIcons.strokeRoundedCalendar01,
            label: 'Sessions',
            value: '${_history!.totalSessions}',
          ),
        ),
        const HSpace.sm(),
        Expanded(
          child: _buildHistoryStatItem(
            icon: HugeIcons.strokeRoundedDumbbell01,
            label: 'Max Weight',
            value: '${_history!.maxWeight.toStringAsFixed(0)} lbs',
          ),
        ),
        const HSpace.sm(),
        Expanded(
          child: _buildHistoryStatItem(
            icon: HugeIcons.strokeRoundedClock01,
            label: 'Last Done',
            value: daysSince != null
                ? (daysSince == 0
                      ? 'Today'
                      : daysSince == 1
                      ? 'Yesterday'
                      : '$daysSince days')
                : 'Never',
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryStatItem({
    required HugeIconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: context.textSecondary, size: 16),
          const VSpace.xs(),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsPreview() {
    final recentSessions = _history!.getRecentSessions(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: AppTextStyles.labelMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
        const VSpace.sm(),
        ...recentSessions.map((session) => _buildSessionPreviewItem(session)),
      ],
    );
  }

  Widget _buildSessionPreviewItem(ExerciseSessionRecord session) {
    final isPR =
        session.sessionPR != null && session.sessionPR == _history!.allTimePR;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: isPR ? context.successColor : context.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const HSpace.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(session.performedAt),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  session.detailedSummaryString,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isPR)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.successColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PR',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBook01,
                color: context.primaryColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Text(
                'Instructions',
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const VSpace.md(),
          Text(
            widget.exercise.instructions ??
                'No specific instructions available for this exercise. '
                    'Please ensure proper form and consult a fitness professional if needed.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedNote01,
                color: context.infoColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Text(
                'Exercise Tips',
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const VSpace.md(),
          Text(
            widget.exercise.notes!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNotesSection() {
    final hasNotes = _preferences?.userNotes?.isNotEmpty ?? false;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedEdit01,
                color: context.warningColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Expanded(
                child: Text(
                  'My Notes',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_isEditingNotes && hasNotes)
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedPencilEdit01,
                    color: context.primaryColor,
                    size: AppDimensions.iconSmall,
                  ),
                  onPressed: () {
                    setState(() => _isEditingNotes = true);
                    _notesFocusNode.requestFocus();
                  },
                ),
            ],
          ),
          const VSpace.md(),
          if (_isLoadingPreferences)
            const SkeletonText(width: double.infinity)
          else if (_isEditingNotes || !hasNotes)
            _buildNotesEditor()
          else
            _buildNotesDisplay(),
        ],
      ),
    );
  }

  Widget _buildNotesEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextFormField(
          controller: _userNotesController,
          focusNode: _notesFocusNode,
          hintText: 'Add personal notes, form cues, tips...',
          maxLines: 4,
          onChanged: (_) {
            if (!_isEditingNotes) {
              setState(() => _isEditingNotes = true);
            }
          },
        ),
        const VSpace.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isEditingNotes) ...[
              TextButton(
                onPressed: () {
                  _userNotesController.text = _preferences?.userNotes ?? '';
                  setState(() => _isEditingNotes = false);
                  _notesFocusNode.unfocus();
                },
                child: Text(
                  'Cancel',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
              const HSpace.sm(),
              AppButton.elevated(
                text: 'Save',
                onPressed: _saveUserNotes,
                isLoading: _isSavingNotes,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNotesDisplay() {
    return GestureDetector(
      onTap: () {
        setState(() => _isEditingNotes = true);
        _notesFocusNode.requestFocus();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: Text(
          _preferences?.userNotes ?? '',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textSecondary,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    final localPhotos = _preferences?.localPhotoPaths ?? [];
    final cloudPhotos = _preferences?.cloudPhotoUrls ?? [];
    final allPhotos = [...localPhotos, ...cloudPhotos];
    final hasPhotos = allPhotos.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: context.successColor,
                size: AppDimensions.iconMedium,
              ),
              const HSpace.sm(),
              Expanded(
                child: Text(
                  'My Photos',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Add photo button
              IconButton(
                icon: _isAddingPhoto
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.primaryColor,
                        ),
                      )
                    : HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: context.primaryColor,
                        size: AppDimensions.iconMedium,
                      ),
                onPressed: _isAddingPhoto ? null : _showAddPhotoSheet,
              ),
            ],
          ),
          const VSpace.md(),
          if (_isLoadingPreferences)
            const SkeletonCard(height: 120)
          else if (!hasPhotos)
            _buildEmptyPhotosState()
          else
            _buildPhotoGrid(allPhotos),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotosState() {
    return GestureDetector(
      onTap: _showAddPhotoSheet,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: context.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(
            color: context.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                color: context.textSecondary,
                size: AppDimensions.iconLarge,
              ),
              const VSpace.sm(),
              Text(
                'Add photos of your form or progress',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const VSpace.xs(),
              Text(
                'Tap to add',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photoPath = photos[index];
        return _buildPhotoThumbnail(photoPath, index, photos);
      },
    );
  }

  Widget _buildPhotoThumbnail(
    String photoPath,
    int index,
    List<String> allPhotos,
  ) {
    final isCloudPhoto =
        photoPath.startsWith('http://') || photoPath.startsWith('https://');

    return GestureDetector(
      onTap: () {
        FullScreenPhotoViewer.show(
          context,
          photos: allPhotos,
          initialIndex: index,
          onDelete: (deleteIndex) async {
            final pathToDelete = allPhotos[deleteIndex];
            return await _deletePhoto(pathToDelete);
          },
          showDeleteButton: true,
        );
      },
      onLongPress: () => _showPhotoContextMenu(photoPath, isCloudPhoto),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          border: Border.all(color: context.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPhotoImage(photoPath, isCloudPhoto),
              // Cloud indicator
              if (isCloudPhoto)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const HugeIcon(
                      icon: HugeIconsStrokeRounded.cloudSavingDone02,
                      size: AppDimensions.iconSmall,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoImage(String photoPath, bool isCloudPhoto) {
    // Check if this is a Hive-stored photo (web platform)
    if (PhotoStorageService.isHivePhotoUri(photoPath)) {
      final bytes = PhotoStorageService.loadPhotoFromHive(photoPath);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: context.surfaceVariant,
              child: HugeIcon(
                icon: HugeIconsStrokeRounded.imageNotFound01,
                color: context.textSecondary,
              ),
            );
          },
        );
      } else {
        // Photo not found in Hive
        return Container(
          color: context.surfaceVariant,
          child: HugeIcon(
            icon: HugeIconsStrokeRounded.imageNotFound01,
            color: context.textSecondary,
          ),
        );
      }
    }

    // On web, use Image.network for cloud photos (blob URLs won't work after restart)
    // On native, use Image.network for cloud photos, Image.file for local
    final useNetworkImage = isCloudPhoto || kIsWeb;

    if (useNetworkImage) {
      return Image.network(
        photoPath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: context.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: context.surfaceVariant,
            child: HugeIcon(
              icon: HugeIconsStrokeRounded.imageNotFound01,
              color: context.textSecondary,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: context.surfaceVariant,
            child: HugeIcon(
              icon: HugeIconsStrokeRounded.imageNotFound01,
              color: context.textSecondary,
            ),
          );
        },
      );
    }
  }

  void _showPhotoContextMenu(String photoPath, bool isCloudPhoto) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedMaximize01,
                color: context.primaryColor,
                size: AppDimensions.iconMedium,
              ),
              title: const Text('View Full Screen'),
              onTap: () {
                Navigator.of(context).pop();
                final allPhotos = <String>[
                  ...(_preferences?.localPhotoPaths ?? []),
                  ...(_preferences?.cloudPhotoUrls ?? []),
                ];
                final index = allPhotos.indexOf(photoPath);
                FullScreenPhotoViewer.show(
                  this.context,
                  photos: allPhotos,
                  initialIndex: index >= 0 ? index : 0,
                  onDelete: (deleteIndex) async {
                    final pathToDelete = allPhotos[deleteIndex];
                    return await _deletePhoto(pathToDelete);
                  },
                );
              },
            ),
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color: context.errorColor,
                size: AppDimensions.iconMedium,
              ),
              title: Text(
                'Delete Photo',
                style: TextStyle(color: context.errorColor),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await _showDeleteConfirmation();
                if (confirmed) {
                  await _deletePhoto(photoPath);
                }
              },
            ),
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: context.textSecondary,
                size: AppDimensions.iconMedium,
              ),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Photo?'),
            content: const Text(
              'This photo will be permanently deleted. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
