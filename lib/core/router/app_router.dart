import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/language_screen.dart';
import '../../features/auth/screens/voice_screen.dart';
import '../../features/auth/screens/biometric_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';
import '../../features/auth/screens/lock_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/session/screens/conversation_screen.dart';
import '../../features/session/screens/summary_screen.dart';
import '../../features/breathing/screens/breathing_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/vault/screens/vault_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Fade transition for bottom nav tabs
CustomTransitionPage<void> _fadeTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// Slide-up transition for full-screen routes
CustomTransitionPage<void> _slideUpTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// Fade-through transition for onboarding
CustomTransitionPage<void> _fadeThroughTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

GoRouter createRouter(
  String initialLocation, {
  required ValueNotifier<bool> unlockNotifier,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: unlockNotifier,
    redirect: (context, state) {
      final isUnlocked = unlockNotifier.value;
      final onLock = state.matchedLocation == '/lock';
      final onOnboarding = state.matchedLocation.startsWith('/onboarding');

      // Don't interfere with onboarding
      if (onOnboarding) return null;

      // Locked but not on lock screen → redirect to lock
      if (!isUnlocked && !onLock) return '/lock';

      // Unlocked but still on lock screen → redirect to home
      if (isUnlocked && onLock) return '/home';

      return null;
    },
    routes: [
      // Lock screen
      GoRoute(
        path: '/lock',
        pageBuilder: (_, state) => _fadeThroughTransitionPage(
          child: const LockScreen(),
          state: state,
        ),
      ),

      // Onboarding — fade-through transitions
      GoRoute(
        path: '/onboarding/language',
        pageBuilder: (_, state) => _fadeThroughTransitionPage(
          child: const LanguageScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/onboarding/voice',
        pageBuilder: (_, state) => _fadeThroughTransitionPage(
          child: const VoiceScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/onboarding/biometric',
        pageBuilder: (_, state) => _fadeThroughTransitionPage(
          child: const BiometricScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/onboarding/pin',
        pageBuilder: (_, state) => _fadeThroughTransitionPage(
          child: const PinSetupScreen(),
          state: state,
        ),
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
            pageBuilder: (_, state) => _fadeTransitionPage(
              child: const HomeScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (_, state) => _fadeTransitionPage(
              child: const HistoryScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/breathing',
            pageBuilder: (_, state) => _fadeTransitionPage(
              child: const BreathingScreen(),
              state: state,
            ),
          ),
        ],
      ),

      // Full-screen routes — slide-up transitions
      GoRoute(
        path: '/session/:sessionId',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final mode = state.uri.queryParameters['mode'] ?? 'text';
          return _slideUpTransitionPage(
            child: ConversationScreen(sessionId: sessionId, mode: mode),
            state: state,
          );
        },
      ),
      GoRoute(
        path: '/summary',
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return _slideUpTransitionPage(
            child: SummaryScreen(sessionData: data),
            state: state,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _slideUpTransitionPage(
          child: const SettingsScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/vault/detail/:sessionId',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return _slideUpTransitionPage(
            child: VaultDetailScreen(sessionId: sessionId),
            state: state,
          );
        },
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
