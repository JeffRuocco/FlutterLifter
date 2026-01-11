import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import 'common/app_widgets.dart';

/// A full-screen photo viewer with zoom and pan capabilities.
///
/// Features:
/// - Pinch to zoom
/// - Pan when zoomed
/// - Double-tap to zoom in/out
/// - Swipe up/down to close
/// - Delete button with confirmation
/// - Page indicator when viewing multiple photos
class FullScreenPhotoViewer extends StatefulWidget {
  /// List of photo paths or URLs to display
  final List<String> photos;

  /// Initial index to display
  final int initialIndex;

  /// Callback when delete is requested for a photo at index
  final Future<bool> Function(int index)? onDelete;

  /// Whether to show the delete button
  final bool showDeleteButton;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.onDelete,
    this.showDeleteButton = true,
  });

  /// Show the viewer as a modal route with hero animation support
  static Future<void> show(
    BuildContext context, {
    required List<String> photos,
    int initialIndex = 0,
    Future<bool> Function(int index)? onDelete,
    bool showDeleteButton = true,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenPhotoViewer(
            photos: photos,
            initialIndex: initialIndex,
            onDelete: onDelete,
            showDeleteButton: showDeleteButton,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late List<String> _photos;
  bool _isDeleting = false;

  // For vertical drag to dismiss
  double _dragOffset = 0;
  double _dragOpacity = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _photos = List.from(widget.photos);
    _pageController = PageController(initialPage: _currentIndex);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      // Calculate opacity based on drag distance
      _dragOpacity = (1 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    // If dragged far enough, close the viewer
    if (_dragOffset.abs() > 100 ||
        details.velocity.pixelsPerSecond.dy.abs() > 500) {
      Navigator.of(context).pop();
    } else {
      // Reset position
      setState(() {
        _dragOffset = 0;
        _dragOpacity = 1;
      });
    }
  }

  Future<void> _handleDelete() async {
    if (_isDeleting || widget.onDelete == null) return;

    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      final deleted = await widget.onDelete!(_currentIndex);
      if (deleted && mounted) {
        setState(() {
          _photos.removeAt(_currentIndex);
          if (_photos.isEmpty) {
            Navigator.of(context).pop();
            return;
          }
          // Adjust current index if needed
          if (_currentIndex >= _photos.length) {
            _currentIndex = _photos.length - 1;
          }
        });

        if (_photos.isNotEmpty) {
          showSuccessMessage(context, 'Photo deleted');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _dragOpacity,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Stack(
              children: [
                // Photo PageView
                _buildPhotoPageView(),

                // Top bar with close and delete
                _buildTopBar(),

                // Page indicator (if multiple photos)
                if (_photos.length > 1) _buildPageIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _photos.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
      },
      itemBuilder: (context, index) {
        return _buildZoomablePhoto(_photos[index]);
      },
    );
  }

  Widget _buildZoomablePhoto(String photoPath) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(child: _buildPhotoWidget(photoPath)),
    );
  }

  Widget _buildPhotoWidget(String photoPath) {
    // Check if it's a network URL, blob URL (web), or local file
    // On web, local files are blob URLs which need Image.network
    final isNetworkOrBlobUrl =
        photoPath.startsWith('http://') ||
        photoPath.startsWith('https://') ||
        photoPath.startsWith('blob:') ||
        kIsWeb;

    if (isNetworkOrBlobUrl) {
      return Image.network(
        photoPath,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      // Local file (native platforms only)
      return Image.file(
        File(photoPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HugeIcon(
          icon: HugeIconsStrokeRounded.imageNotFound01,
          size: AppDimensions.iconXLarge,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Could not load photo',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIconsStrokeRounded.cancel01,
                  color: Colors.white,
                  size: AppDimensions.iconMedium,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),

              // Photo counter
              if (_photos.length > 1)
                Text(
                  '${_currentIndex + 1} / ${_photos.length}',
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                ),

              // Delete button
              if (widget.showDeleteButton && widget.onDelete != null)
                IconButton(
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const HugeIcon(
                          icon: HugeIconsStrokeRounded.delete02,
                          color: Colors.white,
                          size: AppDimensions.iconMedium,
                        ),
                  onPressed: _isDeleting ? null : _handleDelete,
                )
              else
                const SizedBox(width: 48), // Placeholder for alignment
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _photos.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: index == _currentIndex ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: index == _currentIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dismissible photo wrapper that supports swipe-to-delete and long-press menu.
///
/// Used in photo grids to provide consistent delete interaction.
class DismissiblePhoto extends StatelessWidget {
  /// The photo path or URL
  final String photoPath;

  /// The child widget (usually the photo thumbnail)
  final Widget child;

  /// Called when swipe-to-delete is completed
  final VoidCallback? onDelete;

  /// Called when the photo is tapped
  final VoidCallback? onTap;

  /// Whether the photo can be deleted
  final bool canDelete;

  const DismissiblePhoto({
    super.key,
    required this.photoPath,
    required this.child,
    this.onDelete,
    this.onTap,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget photo = GestureDetector(
      onTap: onTap,
      onLongPress: canDelete && onDelete != null
          ? () => _showContextMenu(context)
          : null,
      child: child,
    );

    if (!canDelete || onDelete == null) {
      return photo;
    }

    return Dismissible(
      key: Key(photoPath),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const HugeIcon(
          icon: HugeIconsStrokeRounded.delete02,
          color: Colors.white,
        ),
      ),
      child: photo,
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Photo?'),
            content: const Text('This action cannot be undone.'),
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

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: HugeIcon(
                icon: HugeIconsStrokeRounded.delete02,
                color: context.errorColor,
              ),
              title: Text(
                'Delete Photo',
                style: TextStyle(color: context.errorColor),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await _confirmDelete(context);
                if (confirmed) {
                  onDelete?.call();
                }
              },
            ),
            ListTile(
              leading: const HugeIcon(
                icon: HugeIconsStrokeRounded.cancelCircle,
              ),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
