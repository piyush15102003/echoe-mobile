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
import '../providers/intention_provider.dart';

final _activeSessionProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    return await ref.read(sessionRepositoryProvider).getActiveSession();
  } catch (_) {
    return null;
  }
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isStarting = false;
  bool _intentionExpanded = false;
  bool _intentionViewed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeSession = ref.watch(_activeSessionProvider);
    final intention = ref.watch(todayIntentionProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // App bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.lock_outline,
                          color: AppColors.onSurfaceVariant)
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

              // Hero heading
              Text(
                'How are you\nfeeling, truly?',
                style: textTheme.headlineLarge?.copyWith(height: 1.3),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut),
              const SizedBox(height: 16),

              // Static subtitle
              Text(
                'The world is loud. This is your space to be quiet, to listen, and to let it all out.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      delay: 100.ms,
                      curve: Curves.easeOut),
              const SizedBox(height: 48),

              // Active / paused session card
              activeSession.when(
                data: (session) {
                  if (session == null) return const SizedBox.shrink();

                  final isPaused = session['paused'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isStarting
                                ? null
                                : () => _resumeSession(context, session),
                            icon: Icon(isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.chat_bubble_outline_rounded),
                            label: Text(isPaused
                                ? 'Resume your session'
                                : 'Continue your session'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.secondary),
                              foregroundColor: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Let them abandon the stuck session so they can start fresh
                        TextButton(
                          onPressed: _isStarting
                              ? null
                              : () => _confirmAbandonSession(context, session),
                          child: Text(
                            'End this session instead',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(
                          begin: -0.05,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // CTAs
              _PressableButton(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isStarting
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            _startSession(context, 'voice');
                          },
                    child: _isStarting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Speak freely'),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      delay: 200.ms,
                      curve: Curves.easeOut),
              const SizedBox(height: 12),
              _PressableButton(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isStarting
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            _startSession(context, 'text');
                          },
                    child: const Text('Write it down'),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      delay: 300.ms,
                      curve: Curves.easeOut),

              const SizedBox(height: 32),

              // ── Daily Intention card ────────────────────────────────────
              intention.when(
                loading: () => const _IntentionCardSkeleton()
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 350.ms),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  if (data == null) return const SizedBox.shrink();
                  return _IntentionCard(
                    intention: data,
                    expanded: _intentionExpanded,
                    onTap: () {
                      setState(() => _intentionExpanded = !_intentionExpanded);
                      if (!_intentionViewed) {
                        _intentionViewed = true;
                        ref
                            .read(intentionRepositoryProvider)
                            .markViewed(data.id);
                      }
                    },
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 350.ms)
                      .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 400.ms,
                          delay: 350.ms,
                          curve: Curves.easeOut);
                },
              ),

              const SizedBox(height: 48),

              // Breathing orb
              const BreathingOrb(size: 160)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 450.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    delay: 450.ms,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resumeSession(
      BuildContext context, Map<String, dynamic> session) async {
    final sessionId = session['session_id'] as String;
    final mode = session['input_mode'] as String? ?? 'text';
    setState(() => _isStarting = true);
    try {
      final data =
          await ref.read(sessionRepositoryProvider).resumeSession(sessionId);
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
      final messages = data['messages'] as List<dynamic>? ?? [];
      ref
          .read(chatMessagesProvider.notifier)
          .loadMessages(messages.cast<Map<String, dynamic>>());
      if (context.mounted) context.push('/session/$sessionId?mode=$mode');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not resume session. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _confirmAbandonSession(
      BuildContext context, Map<String, dynamic> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('End this session?'),
        content: const Text(
          'Your conversation will be saved and a summary will be generated. You can start a fresh session after.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End session'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _isStarting = true);
    try {
      final sessionId = session['session_id'] as String;
      await ref.read(sessionRepositoryProvider).endSession(sessionId);
      // Invalidate the active session provider so the card disappears
      ref.invalidate(_activeSessionProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not end session. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _startSession(BuildContext context, String mode) async {
    setState(() => _isStarting = true);
    try {
      final lang = await SecureStorage.getLanguage() ?? 'en';
      final data = await ref.read(sessionRepositoryProvider).createSession(
            inputMode: mode,
            language: lang,
          );
      final sessionId = data['session_id'] as String;
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
      ref.read(chatMessagesProvider.notifier).clear();

      final opening = data['opening_message'] as String? ??
          'Tell me what\'s on your mind.';
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(role: 'echo', content: opening),
          );

      if (context.mounted) context.push('/session/$sessionId?mode=$mode');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not start session. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }
}

// ── Daily Intention card ──────────────────────────────────────────────────────

class _IntentionCard extends StatelessWidget {
  final dynamic intention; // IntentionResponse
  final bool expanded;
  final VoidCallback onTap;

  const _IntentionCard({
    required this.intention,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.mutedGold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.mutedGold.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Text('✦', style: TextStyle(color: AppColors.mutedGold, fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'Today\'s intention',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedGold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.mutedGold.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

            // Collapsed: first line of text
            if (!expanded) ...[
              const SizedBox(height: 10),
              Text(
                intention.text,
                style: GoogleFonts.notoSerif(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.onSurface.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Expanded: full text
            if (expanded) ...[
              const SizedBox(height: 14),
              Text(
                intention.text,
                style: GoogleFonts.notoSerif(
                  fontSize: 15,
                  height: 1.75,
                  color: AppColors.onSurface,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (intention.generatedFrom.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0x22A88B46)),
                const SizedBox(height: 10),
                Text(
                  'Shaped by what you\'ve shared',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Intention skeleton ────────────────────────────────────────────────────────

class _IntentionCardSkeleton extends StatefulWidget {
  const _IntentionCardSkeleton();

  @override
  State<_IntentionCardSkeleton> createState() => _IntentionCardSkeletonState();
}

class _IntentionCardSkeletonState extends State<_IntentionCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.35 + _ctrl.value * 0.25,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.mutedGold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.mutedGold.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                      color: AppColors.mutedGold.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 12),
              Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Press-scale wrapper ───────────────────────────────────────────────────────

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
