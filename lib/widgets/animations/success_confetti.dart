import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// A celebratory confetti animation widget for success moments
/// like completing a workout, achieving a goal, etc.
class SuccessConfetti extends StatefulWidget {
  /// Whether to play the confetti animation
  final bool isPlaying;

  /// Duration of the animation
  final Duration duration;

  /// Number of confetti particles
  final int particleCount;

  /// Custom colors for confetti (defaults to app theme colors)
  final List<Color>? colors;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Whether to trigger haptic feedback
  final bool enableHaptics;

  /// Child widget to display behind the confetti
  final Widget? child;

  const SuccessConfetti({
    super.key,
    this.isPlaying = false,
    this.duration = const Duration(milliseconds: 2500),
    this.particleCount = 50,
    this.colors,
    this.onComplete,
    this.enableHaptics = true,
    this.child,
  });

  @override
  State<SuccessConfetti> createState() => _SuccessConfettiState();
}

class _SuccessConfettiState extends State<SuccessConfetti>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final Random _random = Random();

  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    _colors = widget.colors ??
        [
          AppColors.primary,
          AppColors.secondary,
          AppColors.success,
          AppColors.warning,
          AppColors.info,
          const Color(0xFFFFD700), // Gold
          const Color(0xFFFF69B4), // Pink
          const Color(0xFF9370DB), // Purple
        ];

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _particles = _generateParticles();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.isPlaying) {
      _play();
    }
  }

  @override
  void didUpdateWidget(SuccessConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _play();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  void _play() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    _particles = _generateParticles();
    _controller.forward(from: 0);
  }

  List<ConfettiParticle> _generateParticles() {
    return List.generate(widget.particleCount, (index) {
      return ConfettiParticle(
        color: _colors[_random.nextInt(_colors.length)],
        startX: _random.nextDouble(),
        startY: -0.1 - (_random.nextDouble() * 0.3),
        endX: _random.nextDouble() * 2 - 0.5,
        endY: 1.2 + (_random.nextDouble() * 0.3),
        size: 6 + _random.nextDouble() * 8,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        shape:
            ConfettiShape.values[_random.nextInt(ConfettiShape.values.length)],
        delay: _random.nextDouble() * 0.3,
        horizontalWobble: (_random.nextDouble() - 0.5) * 0.3,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (widget.isPlaying)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Confetti particle shape types
enum ConfettiShape {
  circle,
  square,
  rectangle,
  star,
}

/// Individual confetti particle data
class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double rotationSpeed;
  final ConfettiShape shape;
  final double delay;
  final double horizontalWobble;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.rotationSpeed,
    required this.shape,
    required this.delay,
    required this.horizontalWobble,
  });
}

/// Custom painter for rendering confetti particles
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Apply delay
      final adjustedProgress =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);

      if (adjustedProgress <= 0) continue;

      // Calculate position with easing
      final easedProgress = Curves.easeOutQuad.transform(adjustedProgress);
      final gravityProgress = Curves.easeInQuad.transform(adjustedProgress);

      // Horizontal wobble using sine wave
      final wobble = sin(adjustedProgress * 10) * particle.horizontalWobble;

      final x = size.width *
          (particle.startX +
              (particle.endX - particle.startX) * easedProgress +
              wobble);
      final y = size.height *
          (particle.startY +
              (particle.endY - particle.startY) * gravityProgress);

      // Calculate rotation
      final rotation = adjustedProgress * particle.rotationSpeed * pi;

      // Calculate opacity (fade out at the end)
      final opacity =
          adjustedProgress > 0.7 ? 1.0 - ((adjustedProgress - 0.7) / 0.3) : 1.0;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      _drawShape(canvas, particle.shape, particle.size, paint);

      canvas.restore();
    }
  }

  void _drawShape(
      Canvas canvas, ConfettiShape shape, double size, Paint paint) {
    switch (shape) {
      case ConfettiShape.circle:
        canvas.drawCircle(Offset.zero, size / 2, paint);
        break;
      case ConfettiShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size, height: size),
          paint,
        );
        break;
      case ConfettiShape.rectangle:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.5),
          paint,
        );
        break;
      case ConfettiShape.star:
        _drawStar(canvas, size / 2, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRadiusRatio = 0.5;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * innerRadiusRatio;
      final angle = (i * pi / points) - pi / 2;
      final x = r * cos(angle);
      final y = r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// A simple burst confetti that triggers once and completes
class ConfettiBurst extends StatefulWidget {
  /// The child widget to wrap
  final Widget child;

  /// Number of particles in the burst
  final int particleCount;

  /// Duration of the burst animation
  final Duration duration;

  /// Callback to control when to trigger the burst
  final bool trigger;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  const ConfettiBurst({
    super.key,
    required this.child,
    this.particleCount = 30,
    this.duration = const Duration(milliseconds: 1500),
    this.trigger = false,
    this.onComplete,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  bool _isPlaying = false;

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      setState(() => _isPlaying = true);
    }
  }

  void _onComplete() {
    setState(() => _isPlaying = false);
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SuccessConfetti(
      isPlaying: _isPlaying,
      particleCount: widget.particleCount,
      duration: widget.duration,
      onComplete: _onComplete,
      child: widget.child,
    );
  }
}

/// Extension to easily add confetti overlay to any widget
extension ConfettiExtension on Widget {
  /// Wrap widget with confetti that can be triggered
  Widget withConfetti({
    required bool isPlaying,
    int particleCount = 50,
    Duration duration = const Duration(milliseconds: 2500),
    List<Color>? colors,
    VoidCallback? onComplete,
    bool enableHaptics = true,
  }) {
    return SuccessConfetti(
      isPlaying: isPlaying,
      particleCount: particleCount,
      duration: duration,
      colors: colors,
      onComplete: onComplete,
      enableHaptics: enableHaptics,
      child: this,
    );
  }
}
