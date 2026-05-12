import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine initial route
  final onboarded = await SecureStorage.isOnboardingComplete();
  final initialLocation = onboarded ? '/home' : '/onboarding/language';

  runApp(
    ProviderScope(
      child: EchoeApp(initialLocation: initialLocation),
    ),
  );
}

class EchoeApp extends StatelessWidget {
  final String initialLocation;

  const EchoeApp({super.key, required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    final router = createRouter(initialLocation);

    return MaterialApp.router(
      title: 'Echoe',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
