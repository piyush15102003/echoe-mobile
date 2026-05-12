import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String? _firstPin;
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _error;

  void _onDigit(int digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit.toString();
      _error = null;
    });

    if (_pin.length == 4) {
      _handleComplete();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _handleComplete() async {
    if (!_isConfirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
      return;
    }

    if (_pin != _firstPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _pin = '';
        _firstPin = null;
        _isConfirming = false;
      });
      return;
    }

    // Register with backend
    setState(() => _isLoading = true);
    try {
      final language = ref.read(selectedLanguageProvider);
      final voice = ref.read(selectedVoiceProvider);

      // Generate device ID
      var deviceId = await SecureStorage.getDeviceId();
      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await SecureStorage.saveDeviceId(deviceId);
      }

      await ref.read(authRepositoryProvider).createAnonymousUser(
            deviceId: deviceId,
            language: language,
            voicePreference: voice,
          );

      await SecureStorage.setOnboardingComplete();

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
        _pin = '';
        _firstPin = null;
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isConfirming ? 'Confirm your PIN.' : 'Set a 4-digit PIN.',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "This is your backup if biometrics fail. We can't recover it for you — that's the point.",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                _buildNumpad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
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
            const SizedBox(width: 80),
            _numKey(0),
            SizedBox(
              width: 80,
              height: 56,
              child: IconButton(
                onPressed: _onDelete,
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
          onPressed: () => _onDigit(digit),
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
