import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MicButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const MicButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isRecording ? 64 : 56,
        height: isRecording ? 64 : 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? AppColors.secondaryContainer
              : AppColors.primary,
          boxShadow: isRecording
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
          color: isRecording ? AppColors.onSecondaryContainer : AppColors.onPrimary,
        ),
      ),
    );
  }
}
