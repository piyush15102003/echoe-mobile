import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/lifecycle/app_lifecycle_observer.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/app_lock_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine initial route
  final onboarded = await SecureStorage.isOnboardingComplete();
  final initialLocation = onboarded ? '/lock' : '/onboarding/language';

  runApp(
    ProviderScope(
      child: EchoeApp(initialLocation: initialLocation),
    ),
  );
}

class EchoeApp extends ConsumerStatefulWidget {
  final String initialLocation;

  const EchoeApp({super.key, required this.initialLocation});

  @override
  ConsumerState<EchoeApp> createState() => _EchoeAppState();
}

class _EchoeAppState extends ConsumerState<EchoeApp> {
  late final AppLifecycleObserver _lifecycleObserver;
  late final ValueNotifier<bool> _unlockNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    // Bridge Riverpod → GoRouter: sync appUnlockedProvider into a ValueNotifier
    _unlockNotifier = ValueNotifier<bool>(false);
    _router = createRouter(
      widget.initialLocation,
      unlockNotifier: _unlockNotifier,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _unlockNotifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the ValueNotifier in sync with the Riverpod provider
    final isUnlocked = ref.watch(appUnlockedProvider);
    _unlockNotifier.value = isUnlocked;

    return MaterialApp.router(
      title: 'Echoe',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
