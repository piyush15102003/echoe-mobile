import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/breathing_orb.dart';
import '../../session/providers/session_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // App bar row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant),
                  Text('Echoe', style: GoogleFonts.notoSerif(fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.onSurfaceVariant),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 64),
              // Hero text
              Text(
                'How are you\nfeeling, truly?',
                style: textTheme.headlineLarge?.copyWith(height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The world is loud. This is your space to be quiet, to listen, and to let it all out.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // CTAs
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startSession(context, ref, 'voice'),
                  child: const Text('Speak freely'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _startSession(context, ref, 'text'),
                  child: const Text('Write it down'),
                ),
              ),
              const SizedBox(height: 64),
              // Breathing orb
              const BreathingOrb(size: 160),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startSession(
      BuildContext context, WidgetRef ref, String mode) async {
    try {
      final lang = await SecureStorage.getLanguage() ?? 'en';
      final data = await ref.read(sessionRepositoryProvider).createSession(
            inputMode: mode,
            language: lang,
          );
      final sessionId = data['session_id'] as String;
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
      ref.read(chatMessagesProvider.notifier).clear();

      // Add opening message
      final opening = data['opening_message'] as String? ?? 'Tell me what\'s on your mind.';
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(role: 'echo', content: opening),
          );

      if (context.mounted) {
        context.push('/session/$sessionId?mode=$mode');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start session: $e')),
        );
      }
    }
  }
}
