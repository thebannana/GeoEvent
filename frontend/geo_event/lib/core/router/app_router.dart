import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/privacy/presentation/screens/privacy_policy_screen.dart';
import '../../features/shell/presentation/screens/app_shell.dart';
import '../../shared/auth/models/auth_state.dart';
import '../../shared/payment/data/paypal_return_coordinator.dart';
import '../config/app_environment.dart';
import '../constants/app_roles.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, _) {
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

class ResetPasswordLinkData {
  const ResetPasswordLinkData({
    required this.email,
    required this.token,
  });

  final String email;
  final String token;
}

final resetPasswordLinkDataProvider =
    StateProvider<ResetPasswordLinkData?>((ref) => null);

class DeepLinkController {
  DeepLinkController(this.ref);

  final Ref ref;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (error) {
      debugPrint('Initial deep link error: $error');
    }

    _sub = _appLinks!.uriLinkStream.listen(
      _handleUri,
      onError: (error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  void _handleUri(Uri uri) {
    final scheme = uri.scheme.trim().toLowerCase();
    final host = uri.host.trim().toLowerCase();
    final expectedScheme = AppEnvironment.appDeepLinkScheme.toLowerCase();
    final expectedHost = AppEnvironment.appDeepLinkHost.toLowerCase();

    if (scheme != expectedScheme || host != expectedHost) {
      return;
    }

    final path = '/${uri.pathSegments.join('/')}';
    final context = _rootNavigatorKey.currentContext;

    if (context == null) {
      return;
    }

    if (path == '/reset-password') {
      final email = uri.queryParameters['email']?.trim() ?? '';
      final token = uri.queryParameters['token']?.trim() ?? '';

      if (email.isEmpty || token.isEmpty) {
        debugPrint('Reset password deep link ignored: missing email/token');
        return;
      }

      ref.read(resetPasswordLinkDataProvider.notifier).state =
          ResetPasswordLinkData(
        email: email,
        token: token,
      );

      context.go('/reset-password');
      return;
    }

    if (path == '/paypal/return') {
      final reservationId =
          int.tryParse(uri.queryParameters['reservationId']?.trim() ?? '');
      final orderId = (uri.queryParameters['token'] ??
              uri.queryParameters['orderId'] ??
              uri.queryParameters['paymentId'])
          ?.trim();

      if (reservationId == null || orderId == null || orderId.isEmpty) {
        debugPrint('PayPal return ignored: missing reservationId/orderId');
        return;
      }

      debugPrint(
        'PayPal return received: reservationId=$reservationId, orderId=$orderId',
      );

      ref.read(payPalReturnCoordinatorProvider.notifier).complete(
            reservationId: reservationId,
            result: PayPalReturnResult.approved(orderId: orderId),
          );

      return;
    }

    if (path == '/paypal/cancel') {
      final reservationId =
          int.tryParse(uri.queryParameters['reservationId']?.trim() ?? '');

      if (reservationId == null) {
        debugPrint('PayPal cancel ignored: missing reservationId');
        return;
      }

      debugPrint('PayPal cancel received: reservationId=$reservationId');

      ref.read(payPalReturnCoordinatorProvider.notifier).complete(
            reservationId: reservationId,
            result: const PayPalReturnResult.cancelled(),
          );

      return;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}

final deepLinkControllerProvider = Provider<DeepLinkController>((ref) {
  final controller = DeepLinkController(ref);
  unawaited(controller.start());
  ref.onDispose(() {
    unawaited(controller.dispose());
  });
  return controller;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(deepLinkControllerProvider);
  ref.watch(authStateProvider);
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
        path: '/reset-password',
        builder: (context, state) {
          final resetLinkData = ref.read(resetPasswordLinkDataProvider);

          return ResetPasswordScreen(
            initialEmail: resetLinkData?.email,
            initialToken: resetLinkData?.token,
          );
        },
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AppShell(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final role = authState.user?.role;

      final location = state.matchedLocation;
      final isStartup = location == '/startup';
      final isOnboarding = location == '/onboarding';
      final isLogin = location == '/login';
      final isRegister = location == '/register';
      final isForgotPassword = location == '/forgot-password';
      final isResetPassword = location == '/reset-password';
      final isPrivacy = location == '/privacy';
      final isAdminRoute = location.startsWith('/admin');

      final isAuthRoute =
          isLogin || isRegister || isForgotPassword || isResetPassword;
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

      if (isAdminRoute && role != AppRoles.admin) {
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