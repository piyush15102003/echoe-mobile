import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/echo_card.dart';
import '../../../shared/widgets/emotion_tag.dart';

class SummaryScreen extends ConsumerWidget {
  final Map<String, dynamic>? sessionData;

  const SummaryScreen({super.key, this.sessionData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final quote = sessionData?['summary_quote'] as String?;
    final reflection = sessionData?['closing_reflection'] as String?;
    final tags = sessionData?['emotion_tags'] as List<dynamic>?;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 64),
              // Ambient glow behind title
              Stack(
                alignment: Alignment.center,
                children: [
                  // Radial glow
                  Container(
                    width: 200,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(100),
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondaryContainer.withValues(alpha: 0.3),
                          AppColors.secondaryContainer.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 3000.ms,
                        delay: 200.ms,
                        curve: Curves.easeOut,
                      ),
                  Text(
                    'You showed up\nfor yourself.',
                    style: textTheme.headlineLarge?.copyWith(height: 1.3),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'WHAT CAME UP',
                style: textTheme.labelSmall,
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 300.ms),
              const SizedBox(height: 16),
              if (quote != null)
                EchoCard(quote: quote)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 24),
              // Emotion tags — staggered
              if (tags != null && tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: tags.asMap().entries.map((entry) {
                    final delay = 600 + entry.key * 50;
                    return EmotionTag(label: entry.value.toString())
                        .animate()
                        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay))
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                          delay: Duration(milliseconds: delay),
                          curve: Curves.easeOut,
                        );
                  }).toList(),
                ),
              const SizedBox(height: 32),
              if (reflection != null)
                Text(
                  reflection,
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 800.ms),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Start a new session'),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 1000.ms),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Just rest',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 1000.ms),
              const SizedBox(height: 16),
              Text(
                'Saved privately. Only you can see this.',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.outlineVariant,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 1100.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
