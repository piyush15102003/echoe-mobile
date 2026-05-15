import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pin_input.dart';
import '../providers/app_lock_provider.dart';
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
  bool _showSuccess = false;
  String? _error;

  final List<GlobalKey<PinDotState>> _dotKeys =
      List.generate(4, (_) => GlobalKey<PinDotState>());

  void _onDigit(int digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _pin += digit.toString();
      _error = null;
    });

    _dotKeys[_pin.length - 1].currentState?.pop();

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

    // Show success flash
    setState(() => _showSuccess = true);
    await Future.delayed(const Duration(milliseconds: 400));

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

      // Create anonymous user (gets JWT tokens)
      await ref.read(authRepositoryProvider).createAnonymousUser(
            deviceId: deviceId,
            language: language,
            voicePreference: voice,
          );

      // Register PIN with backend
      await ref.read(authRepositoryProvider).setPin(_pin);

      // Store bcrypt hash locally for offline fallback
      final hash = DBCrypt().hashpw(_pin, DBCrypt().gensalt());
      await SecureStorage.savePinHash(hash);

      await SecureStorage.setOnboardingComplete();

      // User just set up — unlock immediately for this session
      ref.read(appUnlockedProvider.notifier).state = true;

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
        _showSuccess = false;
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
              // Title with crossfade
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isConfirming ? 'Confirm your PIN.' : 'Set a 4-digit PIN.',
                  key: ValueKey(_isConfirming),
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 12),
              Text(
                "This is your backup if biometrics fail. We can't recover it for you \u2014 that's the point.",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut),
              const SizedBox(height: 48),
              // PIN dots
              PinDots(
                filledCount: _pin.length,
                success: _showSuccess,
                dotKeys: _dotKeys,
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
                PinNumpad(
                  onDigit: _onDigit,
                  onDelete: _onDelete,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
