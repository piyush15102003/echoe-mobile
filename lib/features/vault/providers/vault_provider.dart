import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/vault_repository.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository(ref.read(dioProvider));
});

final vaultSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await ref.read(vaultRepositoryProvider).getSettings();
});

final vaultSessionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(vaultRepositoryProvider).listSessions();
});
