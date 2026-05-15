import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/breathing_orb.dart';
import '../../session/providers/session_provider.dart';

final _activeSessionProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    return await ref.read(sessionRepositoryProvider).getActiveSession();
  } catch (_) {
    return null;
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final activeSession = ref.watch(_activeSessionProvider);

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
                  // Shimmer lock icon — single pass
                  const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant)
                      .animate()
                      .shimmer(
                        duration: 1500.ms,
                        delay: 800.ms,
                        color: AppColors.mutedGold.withValues(alpha: 0.6),
                      ),
                  Text('Echoe', style: GoogleFonts.notoSerif(fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.onSurfaceVariant),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 64),
              // Hero text — staggered entry
              Text(
                'How are you\nfeeling, truly?',
                style: textTheme.headlineLarge?.copyWith(height: 1.3),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'The world is loud. This is your space to be quiet, to listen, and to let it all out.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut),
              const SizedBox(height: 48),

              // Resume card (if paused session exists)
              activeSession.when(
                data: (session) {
                  if (session == null || session['paused'] != true) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _resumeSession(context, ref, session),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Resume your session'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.secondary),
                          foregroundColor: AppColors.secondary,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // CTAs — staggered with press scale
              _PressableButton(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _startSession(context, ref, 'voice');
                    },
                    child: const Text('Speak freely'),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
              const SizedBox(height: 12),
              _PressableButton(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _startSession(context, ref, 'text');
                    },
                    child: const Text('Write it down'),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 64),
              // Breathing orb — fade in last
              const BreathingOrb(size: 160)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 600.ms, delay: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resumeSession(
      BuildContext context, WidgetRef ref, Map<String, dynamic> session) async {
    final sessionId = session['session_id'] as String;
    final mode = session['input_mode'] as String? ?? 'text';

    try {
      final data =
          await ref.read(sessionRepositoryProvider).resumeSession(sessionId);

      ref.read(activeSessionIdProvider.notifier).state = sessionId;

      final messages = data['messages'] as List<dynamic>? ?? [];
      ref.read(chatMessagesProvider.notifier).loadMessages(
            messages.cast<Map<String, dynamic>>(),
          );

      if (context.mounted) {
        context.push('/session/$sessionId?mode=$mode');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resume session. Please try again.')),
        );
      }
    }
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
          const SnackBar(content: Text('Could not start session. Please try again.')),
        );
      }
    }
  }
}

/// A wrapper that scales down slightly on press for tactile feedback
class _PressableButton extends StatefulWidget {
  final Widget child;

  const _PressableButton({required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
