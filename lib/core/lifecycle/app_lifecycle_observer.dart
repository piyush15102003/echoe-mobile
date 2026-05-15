import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/app_lock_provider.dart';

/// Re-locks the app whenever it moves to the background.
class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef _ref;

  AppLifecycleObserver(this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _ref.read(appUnlockedProvider.notifier).state = false;
    }
  }
}
