import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/home/presentation/screens/home_shell_screen.dart';
import '../features/swipe/presentation/screens/swipe_screen.dart';
import '../features/library/presentation/screens/library_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/domain/enums/auth_status.dart';
import 'routes.dart';

/// A [ChangeNotifier] that bridges Riverpod auth state to GoRouter.
///
/// GoRouter listens to this via [refreshListenable] so it re-evaluates
/// [redirect] whenever auth status changes — without recreating the
/// entire router (which would reset to [initialLocation]).
class AuthNotifier extends ChangeNotifier {
  AuthStatus _status = AuthStatus.loading;
  bool _splashComplete = false;

  AuthStatus get status => _status;
  bool get splashComplete => _splashComplete;

  void update(AuthStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  void markSplashComplete() {
    _splashComplete = true;
    notifyListeners();
  }
}

/// Singleton auth notifier shared between GoRouter and Riverpod.
final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final notifier = AuthNotifier();

  // Bridge Riverpod auth state → AuthNotifier → GoRouter
  ref.listen(authControllerProvider, (_, next) {
    notifier.update(next.status);
  });

  // Set initial value
  final currentState = ref.read(authControllerProvider);
  notifier.update(currentState.status);

  return notifier;
});

/// GoRouter configuration provider.
///
/// Uses [refreshListenable] instead of re-watching auth state,
/// so the router instance is created once and only re-evaluates
/// [redirect] when auth changes.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final status = authNotifier.status;
      final isAuthenticated = status == AuthStatus.authenticated;
      final isLoading = status == AuthStatus.loading;
      final currentPath = state.matchedLocation;
      final isSplashDone = authNotifier.splashComplete;

      // While splash is still showing, don't redirect
      if (!isSplashDone && currentPath == Routes.splash) {
        return null;
      }

      // Don't redirect while auth is loading (splash handles it)
      if (isLoading) return null;

      // Auth routes that don't require authentication
      final authRoutes = [
        Routes.splash,
        Routes.login,
        Routes.signup,
        Routes.forgotPassword,
      ];
      final isOnAuthRoute = authRoutes.contains(currentPath);

      // If authenticated and on auth route, go to home
      if (isAuthenticated && isOnAuthRoute) {
        return Routes.home;
      }

      // If not authenticated and NOT on auth route, go to login
      if (!isAuthenticated && !isOnAuthRoute) {
        return Routes.login;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: Routes.splash,
        name: Routes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: Routes.login,
        name: Routes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        name: Routes.signupName,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: Routes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Swipe / Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: Routes.homeName,
                builder: (context, state) => const SwipeScreen(),
              ),
            ],
          ),
          // Tab 2: Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.library,
                name: Routes.libraryName,
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                name: Routes.profileName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
