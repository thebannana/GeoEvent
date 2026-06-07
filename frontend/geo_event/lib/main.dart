import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/application/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const accessToken = String.fromEnvironment('ACCESS_TOKEN');
  MapboxOptions.setAccessToken(accessToken);

  runApp(const ProviderScope(child: GeoEventApp()));
}

class GeoEventApp extends ConsumerStatefulWidget {
  const GeoEventApp({super.key});

  @override
  ConsumerState<GeoEventApp> createState() => _GeoEventAppState();
}

class _GeoEventAppState extends ConsumerState<GeoEventApp> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    Future.microtask(() async {
      await ref.read(authStateProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'GeoEvent',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}