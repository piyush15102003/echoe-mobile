import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'pin_input.dart';

/// Shows a PIN entry dialog and returns the 4-digit PIN string, or null if dismissed.
Future<String?> showPinDialog(
  BuildContext context, {
  String title = 'Enter your PIN',
  String? errorMessage,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _PinDialog(title: title, errorMessage: errorMessage),
  );
}

class _PinDialog extends StatefulWidget {
  final String title;
  final String? errorMessage;

  const _PinDialog({required this.title, this.errorMessage});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _pin = '';
  String? _error;

  final List<GlobalKey<PinDotState>> _dotKeys =
      List.generate(4, (_) => GlobalKey<PinDotState>());

  @override
  void initState() {
    super.initState();
    _error = widget.errorMessage;
  }

  void _onDigit(int digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit.toString();
      _error = null;
    });

    _dotKeys[_pin.length - 1].currentState?.pop();

    if (_pin.length == 4) {
      Navigator.of(context).pop(_pin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PinDots(
              filledCount: _pin.length,
              dotKeys: _dotKeys,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            PinNumpad(
              onDigit: _onDigit,
              onDelete: _onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
