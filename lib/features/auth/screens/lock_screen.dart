import 'dart:async';

import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pin_input.dart';
import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;
  bool _biometricAvailable = false;
  bool _isVerifying = false;
  Timer? _lockoutTimer;
  Duration _lockoutRemaining = Duration.zero;

  final List<GlobalKey<PinDotState>> _dotKeys =
      List.generate(4, (_) => GlobalKey<PinDotState>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAuth());
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    final biometricEnabled = await SecureStorage.isBiometricEnabled();
    if (biometricEnabled) {
      setState(() => _biometricAvailable = true);
      await _attemptBiometric();
    }
  }

  Future<void> _attemptBiometric() async {
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) return;

      final success = await auth.authenticate(
        localizedReason: 'Unlock Echoe',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (success && mounted) {
        ref.read(appUnlockedProvider.notifier).state = true;
      }
    } catch (_) {
      // Biometric failed or unavailable — fall through to PIN
    }
  }

  void _onDigit(int digit) {
    if (_pin.length >= 4 || _isVerifying || _lockoutRemaining > Duration.zero) {
      return;
    }

    setState(() {
      _pin += digit.toString();
      _error = null;
    });

    _dotKeys[_pin.length - 1].currentState?.pop();

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);

    try {
      // Try online verification first
      final result = await ref.read(authRepositoryProvider).verifyPin(_pin);
      final success = result['success'] as bool? ?? false;

      if (success) {
        _unlock();
        return;
      }

      // Check for lockout
      final lockedUntil = result['locked_until'] as String?;
      if (lockedUntil != null) {
        _startLockout(DateTime.parse(lockedUntil));
        setState(() {
          _pin = '';
          _isVerifying = false;
        });
        return;
      }

      final attemptsLeft = result['attempts_left'] as int?;
      setState(() {
        _error = attemptsLeft != null
            ? 'Wrong PIN. $attemptsLeft attempts left.'
            : 'Wrong PIN. Try again.';
        _pin = '';
        _isVerifying = false;
      });
    } catch (e) {
      // Check if it's a 429 lockout response
      if (e.toString().contains('429')) {
        setState(() {
          _error = 'Too many attempts. Please wait.';
          _pin = '';
          _isVerifying = false;
        });
        return;
      }

      // Network error — try offline fallback
      await _verifyPinOffline();
    }
  }

  Future<void> _verifyPinOffline() async {
    try {
      final storedHash = await SecureStorage.getPinHash();
      if (storedHash == null) {
        setState(() {
          _error = 'No network and no local PIN. Please connect to the internet.';
          _pin = '';
          _isVerifying = false;
        });
        return;
      }

      final matches = DBCrypt().checkpw(_pin, storedHash);
      if (matches) {
        _unlock();
      } else {
        setState(() {
          _error = 'Wrong PIN. Try again.';
          _pin = '';
          _isVerifying = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Could not verify PIN.';
        _pin = '';
        _isVerifying = false;
      });
    }
  }

  void _unlock() {
    ref.read(appUnlockedProvider.notifier).state = true;
    // GoRouter redirect will handle navigation to /home
  }

  void _startLockout(DateTime until) {
    ref.read(pinLockoutUntilProvider.notifier).state = until;
    _updateLockoutRemaining(until);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateLockoutRemaining(until);
    });
  }

  void _updateLockoutRemaining(DateTime until) {
    final remaining = until.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _lockoutTimer?.cancel();
      ref.read(pinLockoutUntilProvider.notifier).state = null;
      setState(() {
        _lockoutRemaining = Duration.zero;
        _error = null;
      });
    } else {
      setState(() {
        _lockoutRemaining = remaining;
        _error =
            'Too many attempts. Try again in ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _forgotPin() async {
    final biometricEnabled = await SecureStorage.isBiometricEnabled();

    if (biometricEnabled) {
      // Authenticate with biometric, then let them set a new PIN
      final auth = LocalAuthentication();
      try {
        final success = await auth.authenticate(
          localizedReason: 'Verify your identity to change PIN',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (success && mounted) {
          // Navigate to PIN setup to set a new PIN
          ref.read(appUnlockedProvider.notifier).state = true;
          context.go('/home');
          // TODO: Could navigate to a Change PIN flow in settings instead
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric verification failed.')),
          );
        }
      }
    } else {
      // No biometric — only option is full reset
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Reset Echoe?'),
          content: const Text(
            'The only way to recover is to reset Echoe. This deletes everything.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Yes, reset',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await SecureStorage.clearAll();
        if (mounted) context.go('/onboarding/language');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLockedOut = _lockoutRemaining > Duration.zero;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.onSurfaceVariant,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 24),
              Text(
                'Welcome back.',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    delay: 100.ms,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to continue.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms),
              const SizedBox(height: 48),
              PinDots(
                filledCount: _pin.length,
                error: _error != null,
                dotKeys: _dotKeys,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              if (_isVerifying)
                const CircularProgressIndicator()
              else
                IgnorePointer(
                  ignoring: isLockedOut,
                  child: Opacity(
                    opacity: isLockedOut ? 0.4 : 1.0,
                    child: PinNumpad(
                      onDigit: _onDigit,
                      onDelete: _onDelete,
                      onBiometric: _biometricAvailable ? _attemptBiometric : null,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _forgotPin,
                child: Text(
                  'Forgot PIN?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
