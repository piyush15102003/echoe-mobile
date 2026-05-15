import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// PinDots — row of 4 dots with fill state, pop animation, color variants
// ---------------------------------------------------------------------------

class PinDots extends StatelessWidget {
  final int filledCount;
  final bool success;
  final bool error;
  final List<GlobalKey<PinDotState>>? dotKeys;

  const PinDots({
    super.key,
    required this.filledCount,
    this.success = false,
    this.error = false,
    this.dotKeys,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return PinDot(
          key: dotKeys?[i],
          filled: i < filledCount,
          success: success,
          error: error,
        );
      }),
    );
  }
}

class PinDot extends StatefulWidget {
  final bool filled;
  final bool success;
  final bool error;

  const PinDot({
    super.key,
    required this.filled,
    this.success = false,
    this.error = false,
  });

  @override
  State<PinDot> createState() => PinDotState();
}

class PinDotState extends State<PinDot> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void pop() {
    _scaleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (widget.success) {
      color = const Color(0xFF4CAF50);
    } else if (widget.error) {
      color = AppColors.error;
    } else if (widget.filled) {
      color = AppColors.primary;
    } else {
      color = AppColors.outlineVariant;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PinNumpad — 0-9 grid + backspace, optional biometric button in bottom-left
// ---------------------------------------------------------------------------

class PinNumpad extends StatelessWidget {
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;

  const PinNumpad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row in [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((d) => _numKey(d)).toList(),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bottom-left: biometric or empty
            SizedBox(
              width: 80,
              height: 56,
              child: onBiometric != null
                  ? IconButton(
                      onPressed: onBiometric,
                      icon: const Icon(Icons.fingerprint, size: 28),
                    )
                  : null,
            ),
            _numKey(0),
            SizedBox(
              width: 80,
              height: 56,
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.backspace_outlined, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numKey(int digit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 64,
        height: 56,
        child: TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onDigit(digit);
          },
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColors.surfaceContainerLow,
          ),
          child: Text(
            '$digit',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
