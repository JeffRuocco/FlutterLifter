import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/accessibility_provider.dart';
import '../core/theme/theme_utils.dart';

/// A circular progress indicator with customizable appearance
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final List<Color>? gradientColors;
  final Widget? child;
  final StrokeCap strokeCap;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.progressColor,
    this.gradientColors,
    this.strokeCap = StrokeCap.round,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveProgressColor = progressColor ?? context.primaryColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: effectiveBackgroundColor,
              progressColor: effectiveProgressColor,
              gradientColors: gradientColors,
              strokeCap: strokeCap,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Animated version of ProgressRing
class AnimatedProgressRing extends ConsumerStatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final List<Color>? gradientColors;
  final Widget? child;
  final StrokeCap strokeCap;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.progressColor,
    this.gradientColors,
    this.strokeCap = StrokeCap.round,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeOutCubic,
    this.child,
  });

  @override
  ConsumerState<AnimatedProgressRing> createState() =>
      _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends ConsumerState<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceMotionProvider);

    if (reduceMotion) {
      return ProgressRing(
        progress: widget.progress,
        size: widget.size,
        strokeWidth: widget.strokeWidth,
        backgroundColor: widget.backgroundColor,
        progressColor: widget.progressColor,
        gradientColors: widget.gradientColors,
        strokeCap: widget.strokeCap,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return ProgressRing(
          progress: _progressAnimation.value,
          size: widget.size,
          strokeWidth: widget.strokeWidth,
          backgroundColor: widget.backgroundColor,
          progressColor: widget.progressColor,
          gradientColors: widget.gradientColors,
          strokeCap: widget.strokeCap,
          child: widget.child,
        );
      },
    );
  }
}

/// Custom painter for the progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final List<Color>? gradientColors;
  final StrokeCap strokeCap;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    this.gradientColors,
    required this.strokeCap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = strokeCap;

      if (gradientColors != null && gradientColors!.length >= 2) {
        progressPaint.shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: gradientColors!,
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      } else {
        progressPaint.color = progressColor;
      }

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}

/// A mini progress ring for inline use
class MiniProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;

  const MiniProgressRing({
    super.key,
    required this.progress,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedProgressRing(
      progress: progress,
      size: size,
      strokeWidth: 3,
      progressColor: color ?? context.primaryColor,
      animationDuration: const Duration(milliseconds: 500),
    );
  }
}
