import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

import 'core/config/environment.dart';
import 'core/deep_link/initial_deep_link.dart';
import 'core/deep_link/windows_protocol_registration.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/application/auth_controller.dart';

final runtimeDeepLinkProvider =
    StateProvider<Uri?>((ref) => null);

class DeepLinkDispatcher {
  static final _controller = StreamController<Uri>.broadcast();

  static Stream<Uri> get stream => _controller.stream;

  static void dispatchArgs(List<String> args) {
    final uri = extractInitialDeepLink(args);
    if (uri != null) {
      _controller.add(uri);
    }
  }
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Text(
                'Widget error:\n\n${details.exceptionAsString()}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNCAUGHT ERROR: $error');
    debugPrintStack(stackTrace: stack);
    return false;
  };

  await WindowsSingleInstance.ensureSingleInstance(
    args,
    'geo_event_desktop_single_instance',
    onSecondWindow: (args) {
      DeepLinkDispatcher.dispatchArgs(args);
    },
  );

  runApp(_BootstrapApp(args: args));
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp({required this.args});

  final List<String> args;

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  SharedPreferences? _prefs;
  Uri? _initialDeepLink;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      AppEnvironment.validateCore();

      final prefs = await SharedPreferences.getInstance();
      final deepLink = extractInitialDeepLink(widget.args);

      await WindowsProtocolRegistration.ensureRegistered();

      if (!mounted) return;

      setState(() {
        _prefs = prefs;
        _initialDeepLink = deepLink;
      });
    } catch (error, stack) {
      debugPrint('BOOTSTRAP ERROR: $error');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _startupError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Text(
                  'Startup failed:\n\n$_startupError',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_prefs == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs!),
        initialDeepLinkProvider.overrideWithValue(_initialDeepLink),
      ],
      child: const _AppBootstrapGate(),
    );
  }
}

class _AppBootstrapGate extends ConsumerStatefulWidget {
  const _AppBootstrapGate();

  @override
  ConsumerState<_AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends ConsumerState<_AppBootstrapGate> {
  bool _started = false;
  StreamSubscription<Uri>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;
    _started = true;

    _subscription = DeepLinkDispatcher.stream.listen((uri) {
      ref.read(runtimeDeepLinkProvider.notifier).state = uri;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(authStateProvider.notifier).restoreSession();
      } catch (error, stack) {
        debugPrint('restoreSession failed: $error');
        debugPrintStack(stackTrace: stack);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const GeoEventDesktopApp();
  }
}

class GeoEventDesktopApp extends ConsumerStatefulWidget {
  const GeoEventDesktopApp({super.key});

  @override
  ConsumerState<GeoEventDesktopApp> createState() => _GeoEventDesktopAppState();
}

class _GeoEventDesktopAppState extends ConsumerState<GeoEventDesktopApp> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.listenManual<Uri?>(
        runtimeDeepLinkProvider,
        (previous, next) {
          if (next == null) return;

          final route = mapDeepLinkToRoute(next);
          if (route != null) {
            rootNavigatorKey.currentContext?.go(route);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'GeoEvent Admin',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}