import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../shared/auth/models/auth_state.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/privacy/presentation/screens/privacy_policy_screen.dart';
import '../../features/shell/presentation/screens/admin_shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

final initialDeepLinkProvider = Provider<Uri?>((ref) => null);

String? mapDeepLinkToRoute(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme.toLowerCase() != 'geoevent') return null;

  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (host == 'open' && path == '/reset-password') {
    final email = uri.queryParameters['email']?.trim();
    final token = uri.queryParameters['token']?.trim();

    final query = <String, String>{};

    if (email != null && email.isNotEmpty) {
      query['email'] = email;
    }

    if (token != null && token.isNotEmpty) {
      query['token'] = token;
    }

    return Uri(
      path: '/reset-password',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  return null;
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _sub = ref.listen<AuthState>(
      authStateProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.read(_routerRefreshProvider);
  final initialDeepLink = ref.read(initialDeepLinkProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refreshNotifier,
    initialLocation: mapDeepLinkToRoute(initialDeepLink) ?? '/startup',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;

      final isStartup = location == '/startup';
      final isLogin = location == '/login';
      final isForgotPassword = location == '/forgot-password';
      final isResetPassword = location == '/reset-password';
      final isPrivacy = location == '/privacy';
      final isAdmin = location == '/admin' || location == '/app';

      final isPublicRoute =
          isLogin || isForgotPassword || isResetPassword || isPrivacy;

      if (!authState.isInitialized) {
        return isStartup ? null : '/startup';
      }

      if (isPublicRoute) {
        return null;
      }

      if (!authState.isAuthenticated) {
        return '/login';
      }

      if (!authState.isAdmin) {
        return '/login';
      }

      if (isStartup || isLogin) {
        return '/admin';
      }

      if (isAdmin) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/startup',
        builder: (context, state) => const _StartupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final token = state.uri.queryParameters['token'];

          return ResetPasswordScreen(
            initialEmail: email,
            initialToken: token,
          );
        },
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShellScreen(),
      ),
      GoRoute(
        path: '/app',
        redirect: (_, _) => '/admin',
      ),
    ],
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