import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_environment.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/application/auth_controller.dart';
import 'shared/auth/models/auth_state.dart';
import 'shared/notifications/data/notification_polling_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppEnvironment.validateCore();
  AppEnvironment.validateMaps();

  final prefs = await SharedPreferences.getInstance();

  MapboxOptions.setAccessToken(AppEnvironment.mapboxAccessToken);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GeoEventApp(),
    ),
  );
}

class GeoEventApp extends ConsumerStatefulWidget {
  const GeoEventApp({super.key});

  @override
  ConsumerState<GeoEventApp> createState() => _GeoEventAppState();
}

class _GeoEventAppState extends ConsumerState<GeoEventApp> {
  ProviderSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authStateProvider.notifier).restoreSession();

      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated) {
        ref.read(notificationPollingControllerProvider).start();
      }
    });

    _authSubscription = ref.listenManual<AuthState>(
      authStateProvider,
      (previous, next) {
        final polling = ref.read(notificationPollingControllerProvider);
        final wasAuthenticated = previous?.isAuthenticated ?? false;
        final isAuthenticated = next.isAuthenticated;

        if (!wasAuthenticated && isAuthenticated) {
          polling.start();
        } else if (wasAuthenticated && !isAuthenticated) {
          polling.stop();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final router = ref.watch(appRouterProvider);
    final sessionUserId = ref.watch(sessionUserIdProvider);

    return MaterialApp.router(
      key: ValueKey('app-session-$sessionUserId'),
      debugShowCheckedModeBanner: false,
      title: 'GeoEvent',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}