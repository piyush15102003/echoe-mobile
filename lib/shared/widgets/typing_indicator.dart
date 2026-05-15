import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final t = (_controller.value - delay).clamp(0.0, 1.0);
                // Create a pulsing effect: scale up then down
                final pulse = _pulseCurve(t);
                return Transform.scale(
                  scale: 0.8 + 0.4 * pulse,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.onSurfaceVariant.withValues(
                        alpha: 0.3 + 0.5 * pulse,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  double _pulseCurve(double t) {
    // Creates a smooth pulse: rises then falls within a cycle
    if (t < 0.5) {
      return Curves.easeOut.transform(t * 2);
    } else {
      return Curves.easeIn.transform(2 - t * 2);
    }
  }
}
