import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final _auth = LocalAuthentication();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final available = canCheck || isSupported;
      setState(() => _checking = false);

      if (!available) {
        // Skip to PIN if no biometric hardware
        if (mounted) context.go('/onboarding/pin');
      }
    } catch (_) {
      setState(() => _checking = false);
      if (mounted) context.go('/onboarding/pin');
    }
  }

  Future<void> _enableBiometric() async {
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Echoe uses biometrics to keep your conversations private.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuth) {
        await SecureStorage.setBiometricEnabled(true);
      }
    } catch (_) {
      // Biometric enroll or hardware issue — continue to PIN
    }
    if (mounted) context.go('/onboarding/pin');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fingerprint,
                size: 64,
                color: AppColors.primary,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 32),
              Text(
                'Lock Echoe with your fingerprint?',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Text(
                'Only you should be able to open this. Your biometric stays on your device.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
              const SizedBox(height: 64),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enableBiometric,
                  child: const Text('Yes, secure it'),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/onboarding/pin'),
                child: Text(
                  'Skip for now',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
