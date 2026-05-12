import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/language_screen.dart';
import '../../features/auth/screens/voice_screen.dart';
import '../../features/auth/screens/biometric_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/session/screens/conversation_screen.dart';
import '../../features/session/screens/summary_screen.dart';
import '../../features/breathing/screens/breathing_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    navigatorKey: _rootNavigatorKey,
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding/language',
        builder: (_, _) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/voice',
        builder: (_, _) => const VoiceScreen(),
      ),
      GoRoute(
        path: '/onboarding/biometric',
        builder: (_, _) => const BiometricScreen(),
      ),
      GoRoute(
        path: '/onboarding/pin',
        builder: (_, _) => const PinSetupScreen(),
      ),

      // Main app with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/breathing',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: BreathingScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/session/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final mode = state.uri.queryParameters['mode'] ?? 'text';
          return ConversationScreen(sessionId: sessionId, mode: mode);
        },
      ),
      GoRoute(
        path: '/summary',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return SummaryScreen(sessionData: data);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
}

class _ShellScaffold extends StatelessWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/breathing')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/history');
            case 2:
              context.go('/breathing');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Echoes',
          ),
          NavigationDestination(
            icon: Icon(Icons.air_outlined),
            selectedIcon: Icon(Icons.air),
            label: 'Breathe',
          ),
        ],
      ),
    );
  }
}
