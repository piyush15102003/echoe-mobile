import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app is currently unlocked. Defaults to `false` and resets on
/// every app restart. Set to `true` after successful PIN or biometric auth.
final appUnlockedProvider = StateProvider<bool>((ref) => false);

/// Tracks the backend's 429 lockout expiry so the UI can show a countdown.
final pinLockoutUntilProvider = StateProvider<DateTime?>((ref) => null);
