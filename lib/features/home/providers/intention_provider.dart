import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/intention_repository.dart';
import '../data/intention_response.dart';

final intentionRepositoryProvider = Provider<IntentionRepository>((ref) {
  return IntentionRepository(ref.watch(dioProvider));
});

/// Fetches today's intention once per home screen load.
/// Returns null if none has been generated yet (new user, or cron hasn't run).
final todayIntentionProvider =
    FutureProvider.autoDispose<IntentionResponse?>((ref) async {
  return ref.read(intentionRepositoryProvider).getTodayIntention();
});
