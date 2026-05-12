import 'package:flutter/material.dart';
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
              Text(
                'You showed up\nfor yourself.',
                style: textTheme.headlineLarge?.copyWith(height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'WHAT CAME UP',
                style: textTheme.labelSmall,
              ),
              const SizedBox(height: 16),
              if (quote != null)
                EchoCard(quote: quote),
              const SizedBox(height: 24),
              // Emotion tags
              if (tags != null && tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: tags
                      .map((t) => EmotionTag(label: t.toString()))
                      .toList(),
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
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Start a new session'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Just rest',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Saved privately. Only you can see this.',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.outlineVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
