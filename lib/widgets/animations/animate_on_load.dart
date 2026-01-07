import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/accessibility_provider.dart';

/// Extension to conditionally apply animations based on accessibility settings
extension AnimateIfAllowed on Widget {
  /// Wraps animations in a check for reduce motion preference
  Widget animateIfAllowed(
    WidgetRef ref, {
    required List<Effect<dynamic>> effects,
    Duration delay = Duration.zero,
  }) {
    final reduceMotion = ref.watch(reduceMotionProvider);
    if (reduceMotion) {
      return this;
    }
    return animate(effects: effects, delay: delay);
  }
}

/// A widget that staggers children with entrance animations
class StaggeredList extends ConsumerWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Axis direction;
  final double slideOffset;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 300),
    this.direction = Axis.vertical,
    this.slideOffset = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(reduceMotionProvider);

    if (reduceMotion) {
      return direction == Axis.vertical
          ? Column(children: children)
          : Row(children: children);
    }

    return direction == Axis.vertical
        ? Column(
            children: children.asMap().entries.map((entry) {
              return entry.value
                  .animate(delay: staggerDelay * entry.key)
                  .fadeIn(duration: animationDuration)
                  .slideY(
                    begin: slideOffset / 100,
                    end: 0,
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                  );
            }).toList(),
          )
        : Row(
            children: children.asMap().entries.map((entry) {
              return entry.value
                  .animate(delay: staggerDelay * entry.key)
                  .fadeIn(duration: animationDuration)
                  .slideX(
                    begin: slideOffset / 100,
                    end: 0,
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                  );
            }).toList(),
          );
  }
}

/// A widget that counts up to a target number with animation
class AnimatedCounter extends ConsumerStatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix,
    this.suffix,
  });

  @override
  ConsumerState<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends ConsumerState<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = IntTween(begin: _previousValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
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
      return Text(
        '${widget.prefix ?? ''}${widget.value}${widget.suffix ?? ''}',
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ''}${_animation.value}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

/// A widget that pulses to draw attention
class PulseWidget extends ConsumerWidget {
  final Widget child;
  final Duration duration;
  final bool infinite;

  const PulseWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.infinite = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(reduceMotionProvider);

    if (reduceMotion) {
      return child;
    }

    return child
        .animate(onPlay: infinite ? (controller) => controller.repeat() : null)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: duration ~/ 2,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.05, 1.05),
          end: const Offset(1, 1),
          duration: duration ~/ 2,
          curve: Curves.easeInOut,
        );
  }
}

/// Fade in animation wrapper
class FadeInWidget extends ConsumerWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(reduceMotionProvider);

    if (reduceMotion) {
      return child;
    }

    return child.animate(delay: delay).fadeIn(duration: duration, curve: curve);
  }
}

/// Slide and fade in animation wrapper
class SlideInWidget extends ConsumerWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;
  final Curve curve;

  const SlideInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.begin = const Offset(0, 0.1),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(reduceMotionProvider);

    if (reduceMotion) {
      return child;
    }

    return child
        .animate(delay: delay)
        .fadeIn(duration: duration)
        .slide(
          begin: begin,
          end: Offset.zero,
          duration: duration,
          curve: curve,
        );
  }
}
