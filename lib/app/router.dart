import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/providers/providers.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/chat/presentation/thread_list_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/chat/presentation/companion_selection_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// App routes
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const companionSelection = '/companion-selection';
  static const home = '/home';
  static const chat = '/chat/:threadId';
  static const settings = '/settings';

  static String chatPath(String threadId) => '/chat/$threadId';
}

/// Router notifier that refreshes when auth state changes
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to auth state changes and notify router to refresh
    _ref.listen(authStateProvider, (_, __) {
      print('🔄 Auth state changed, notifying router to refresh');
      notifyListeners();
    });
  }
}

/// Router notifier provider
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier, // Listen to auth state changes
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isSignedIn = authState.valueOrNull != null;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;

      print('🔍 Router redirect - isLoading: $isLoading, isSignedIn: $isSignedIn, location: ${state.matchedLocation}');

      // Still loading auth state
      if (isLoading) {
        print('⏳ Auth is loading, staying on current location');
        // Allow staying on splash while loading
        if (isOnSplash) return null;
        return AppRoutes.splash;
      }

      // Not signed in, go to login
      if (!isSignedIn) {
        print('❌ Not signed in, redirecting to login');
        if (isOnLogin || isOnSplash) return null;
        return AppRoutes.login;
      }

      print('✅ User is signed in: ${authState.valueOrNull?.uid}');

      // Signed in - check onboarding status
      final userAsync = ref.read(currentUserProvider);
      final isOnboardingComplete = userAsync.whenData((user) => user?.onboarding.completed ?? false).value ?? false;
      
      print('📊 User data - isLoading: ${userAsync.isLoading}, hasValue: ${userAsync.hasValue}, hasError: ${userAsync.hasError}');
      print('📊 Onboarding complete: $isOnboardingComplete');
      
      // If user data is still loading, allow current location
      if (userAsync.isLoading) {
        print('⏳ User data is loading, staying on current location');
        return null;
      }

      if (userAsync.hasError) {
        print('⚠️ Error loading user data: ${userAsync.error}');
      }
      
      // Signed in but onboarding not complete
      if (!isOnboardingComplete && !isOnOnboarding) {
        print('➡️ Redirecting to onboarding');
        return AppRoutes.onboarding;
      }

      // Signed in and onboarding complete, away from splash/login
      if (isOnSplash || isOnLogin) {
        print('➡️ Redirecting to home');
        return AppRoutes.home;
      }

      print('✓ Staying on current location');
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.companionSelection,
        builder: (context, state) => const CompanionSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const ThreadListScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final threadId = state.pathParameters['threadId']!;
          return ChatScreen(threadId: threadId);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
