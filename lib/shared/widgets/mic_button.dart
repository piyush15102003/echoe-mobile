import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MicButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const MicButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isRecording) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing rings when recording
          if (widget.isRecording) ...[
            _PulsingRing(controller: _pulseController, delay: 0.0),
            _PulsingRing(controller: _pulseController, delay: 0.33),
            _PulsingRing(controller: _pulseController, delay: 0.66),
          ],
          // Main button
          GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.isRecording ? 64 : 56,
              height: widget.isRecording ? 64 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? AppColors.secondaryContainer
                    : AppColors.primary,
                boxShadow: widget.isRecording
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.mic,
                size: 24,
                color: widget.isRecording
                    ? AppColors.onSecondaryContainer
                    : AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingRing extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _PulsingRing({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = (controller.value + delay) % 1.0;
        final scale = 1.0 + 0.8 * progress;
        final opacity = (0.3 * (1.0 - progress)).clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: opacity),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
