import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/privacy/presentation/screens/privacy_policy_screen.dart';
import '../../features/shell/presentation/screens/app_shell.dart';
import '../../shared/auth/models/auth_state.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/startup',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/startup',
        builder: (context, state) => const _StartupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) => const AppShell(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;

      final location = state.matchedLocation;

      final isStartup = location == '/startup';
      final isOnboarding = location == '/onboarding';
      final isLogin = location == '/login';
      final isRegister = location == '/register';
      final isForgotPassword = location == '/forgot-password';
      final isPrivacy = location == '/privacy';

      final isAuthRoute = isLogin || isRegister || isForgotPassword;
      final isPublicRoute = isOnboarding || isAuthRoute || isPrivacy;

      if (!isInitialized) {
        return isStartup ? null : '/startup';
      }

      if (isStartup) {
        return isLoggedIn ? '/app' : '/onboarding';
      }

      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      if (isLoggedIn && (isOnboarding || isAuthRoute)) {
        return '/app';
      }

      return null;
    },
  );
});

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}