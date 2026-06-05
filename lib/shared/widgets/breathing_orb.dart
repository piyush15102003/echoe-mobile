import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum BreathingPhase { idle, breatheIn, hold, breatheOut, pause }

class BreathingOrb extends StatefulWidget {
  final double size;

  /// Active breathing phase. Null / idle = gentle ambient loop (home screen).
  final BreathingPhase phase;

  /// Duration of the current phase in seconds (used to pace the animation).
  final int phaseDurationSeconds;

  const BreathingOrb({
    super.key,
    this.size = 200,
    this.phase = BreathingPhase.idle,
    this.phaseDurationSeconds = 4,
  });

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  static const double _idleMin = 1.0;
  static const double _idleMax = 1.08;
  static const double _expandedScale = 1.20;
  static const double _contractedScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _applyPhase(widget.phase, widget.phaseDurationSeconds);
  }

  @override
  void didUpdateWidget(BreathingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.phaseDurationSeconds != widget.phaseDurationSeconds) {
      _applyPhase(widget.phase, widget.phaseDurationSeconds);
    }
  }

  void _applyPhase(BreathingPhase phase, int durationSeconds) {
    _controller.stop();

    switch (phase) {
      case BreathingPhase.idle:
        _controller.duration = const Duration(seconds: 4);
        _scaleAnimation = Tween<double>(begin: _idleMin, end: _idleMax).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );
        _controller.repeat(reverse: true);

      case BreathingPhase.breatheIn:
        _controller.duration = Duration(seconds: durationSeconds);
        _scaleAnimation =
            Tween<double>(begin: _contractedScale, end: _expandedScale).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        _controller.forward(from: 0);

      case BreathingPhase.hold:
        // Orb stays expanded — animate a tiny pulse to show it's alive
        _controller.duration = Duration(seconds: durationSeconds);
        _scaleAnimation =
            Tween<double>(begin: _expandedScale, end: _expandedScale * 1.01)
                .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );
        _controller.repeat(reverse: true);

      case BreathingPhase.breatheOut:
        _controller.duration = Duration(seconds: durationSeconds);
        _scaleAnimation =
            Tween<double>(begin: _expandedScale, end: _contractedScale).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        _controller.forward(from: 0);

      case BreathingPhase.pause:
        // Orb stays contracted — same tiny pulse
        _controller.duration = Duration(seconds: durationSeconds);
        _scaleAnimation =
            Tween<double>(begin: _contractedScale, end: _contractedScale * 1.01)
                .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
        );
        _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  AppColors.surfaceContainerLowest,
                  AppColors.secondaryContainer,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
