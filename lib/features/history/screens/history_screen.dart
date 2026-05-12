import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/echo_card.dart';

final historyProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.post('/vault/sessions', data: {'pin': '0000'});
  if (response.data is List) {
    return (response.data as List).cast<Map<String, dynamic>>();
  }
  return [];
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final asyncHistory = ref.watch(historyProvider);

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
                      child:
                          Text('Echoe', style: GoogleFonts.notoSerif(fontSize: 20)),
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
            asyncHistory.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Enable Vault Mode to see your echoes.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No echoes yet. Your story starts with you.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  sliver: SliverList.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final summary =
                          s['summary_text'] as String? ?? 'A moment held.';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EchoCard(
                          quote: summary,
                          dateLabel: s['ended_at']?.toString().substring(0, 10),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
