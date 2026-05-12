import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose your language.',
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              _LanguagePill(
                label: 'English',
                onTap: () => _select(context, ref, 'en'),
              ),
              const SizedBox(height: 16),
              _LanguagePill(
                label: 'हिन्दी',
                onTap: () => _select(context, ref, 'hi'),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => _select(context, ref, 'en'),
                child: Text(
                  'Continue in English',
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

  void _select(BuildContext context, WidgetRef ref, String lang) {
    ref.read(selectedLanguageProvider.notifier).state = lang;
    SecureStorage.saveLanguage(lang);
    context.go('/onboarding/voice');
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LanguagePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
