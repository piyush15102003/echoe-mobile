import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/echo_card.dart';
import '../../../shared/widgets/emotion_tag.dart';
import '../../../shared/widgets/skeleton_card.dart';
import '../../vault/providers/vault_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>>? _sessions;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVaultAndLoad());
  }

  Future<void> _checkVaultAndLoad() async {
    try {
      final settings = await ref.read(vaultRepositoryProvider).getSettings();
      final vaultEnabled = settings['vault_enabled'] as bool? ?? false;

      if (!vaultEnabled) {
        setState(() => _error = 'not_enabled');
        return;
      }

      await _loadSessions();
    } catch (e) {
      setState(() => _error = 'Could not check vault settings.');
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions =
          await ref.read(vaultRepositoryProvider).listSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load sessions.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Text('Echoe',
                          style: GoogleFonts.notoSerif(fontSize: 20)),
                    ),
                    const SizedBox(height: 32),
                    Text('Your Echoes', style: textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'A sanctuary of moments you\'ve released into the quiet.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Loading — skeleton shimmer cards
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                sliver: SliverList.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: const SkeletonCard()
                          .animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: index * 100),
                          ),
                    );
                  },
                ),
              )
            else if (_error == 'not_enabled')
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Breathing lock icon
                        const _BreathingLockIcon(),
                        const SizedBox(height: 16),
                        Text(
                          'Enable Vault Mode in Settings to save your echoes.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => context.push('/settings'),
                          child: const Text('Open Settings'),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 300.ms),
                      ],
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _error!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else if (_sessions != null && _sessions!.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No echoes yet. Your story starts with you.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                ),
              )
            else if (_sessions != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                sliver: SliverList.builder(
                  itemCount: _sessions!.length,
                  itemBuilder: (context, index) {
                    final s = _sessions![index];
                    final summary =
                        s['summary_text'] as String? ?? 'A moment held.';
                    final emotionTags =
                        (s['emotion_tags'] as List<dynamic>?)?.cast<String>() ??
                            [];
                    final sessionId = s['session_id'] as String;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EchoCard(
                            quote: summary,
                            dateLabel:
                                s['ended_at']?.toString().substring(0, 10),
                            onTap: () =>
                                context.push('/vault/detail/$sessionId'),
                          ),
                          if (emotionTags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: emotionTags
                                  .map((t) => EmotionTag(label: t))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                          duration: 200.ms,
                          delay: Duration(milliseconds: index * 80),
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 200.ms,
                          delay: Duration(milliseconds: index * 80),
                          curve: Curves.easeOut,
                        );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _sessions != null
          ? FloatingActionButton.small(
              onPressed: _refresh,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}

/// Lock icon with subtle breathing animation
class _BreathingLockIcon extends StatefulWidget {
  const _BreathingLockIcon();

  @override
  State<_BreathingLockIcon> createState() => _BreathingLockIconState();
}

class _BreathingLockIconState extends State<_BreathingLockIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Icon(Icons.lock_outline, size: 48, color: AppColors.outlineVariant),
    );
  }
}
