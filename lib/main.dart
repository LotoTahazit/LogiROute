import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/company_selection_service.dart';
import 'services/driver_auto_close_state.dart';
import 'widgets/role_router.dart';
import 'widgets/invoice_deep_link_viewer.dart';
import 'screens/auth/reset_password_screen.dart';
import 'core/navigation/register_documents.dart';
import 'l10n/app_localizations.dart';
import 'core/error/platform_error_hooks.dart';
import 'services/platform_error_service.dart';
import 'theme/app_theme.dart';

Timer? _bgWatchdogTimer;
bool _bgWatchdogBusy = false;
bool _batteryOptimizationRequested = false;

bool _isWorkingWindow(DateTime now) {
  // ЗАКОММЕНТИРОВАНО: GPS работает всегда, независимо от времени
  // Friday (5) and Saturday (6) are weekend days in this project.
  // if (now.weekday == 5 || now.weekday == 6) return false;
  // return now.hour >= 7 && now.hour < 17;

  // GPS работает ВСЕГДА
  return true;
}

void _startBackgroundServiceWatchdog() {
  if (kIsWeb) return;
  _bgWatchdogTimer?.cancel();
  _bgWatchdogTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
    if (_bgWatchdogBusy) return;
    _bgWatchdogBusy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackingActive = prefs.getBool('bg_tracking_active') ?? false;
      if (!trackingActive) return;

      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      final now = DateTime.now();
      final shouldRun = _isWorkingWindow(now);

      // Outside work window: force-stop and clear tracking flag.
      if (!shouldRun) {
        if (isRunning) {
          service.invoke('stopService');
        }
        await prefs.setBool('bg_tracking_active', false);
        return;
      }

      if (!isRunning) {
        debugPrint('⚠️ [Watchdog] BG service stopped. Restarting...');
        await service.startService();
        final recovered = await service.isRunning();
        if (!recovered) {
          await DriverAutoCloseState.markSystemStoppedBg(true);
        }
      } else {
        await DriverAutoCloseState.clearSystemStoppedBg();
      }
    } catch (e) {
      debugPrint('⚠️ [Watchdog] Error: $e');
    } finally {
      _bgWatchdogBusy = false;
    }
  });
}

Future<void> _requestIgnoreBatteryOptimizationOnce() async {
  if (_batteryOptimizationRequested) return;
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  _batteryOptimizationRequested = true;
  try {
    await Permission.ignoreBatteryOptimizations.request();
  } catch (e) {
    debugPrint('⚠️ [Battery] ignore optimization request failed: $e');
  }
}

void main() {
  runZonedGuarded(() async {
    await _bootstrap();
  }, (error, stack) {
    debugPrint('🔥 Zoned error: $error');
    debugPrint('$stack');
    PlatformErrorService.report(
      error: error,
      stack: stack,
      source: 'run_zoned_guarded',
      operation: 'unhandled_zone',
    );
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Мобильный клиент — только портрет: верстки рассчитаны на портрет, в
  // landscape контент уезжал/пропадал. На web/desktop — без эффекта.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  try {
    await dotenv.load(fileName: '.env.local');
  } catch (e) {
    debugPrint('⚠️ [dotenv] .env.local not loaded: $e');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  initPlatformErrorHooks();

  // 🛡️ App Check: привязывает запросы к настоящему экземпляру приложения, чтобы
  // публичный конфиг Firebase нельзя было использовать из скрипта/бота. Включение
  // enforcement — отдельно в Firebase Console (Firestore/Functions/Storage).
  // На web активируем только при заданном публичном reCAPTCHA v3 site key —
  // иначе пропускаем, чтобы билд работал до настройки в консоли.
  try {
    if (kIsWeb) {
      final recaptchaKey =
          dotenv.env['APP_CHECK_RECAPTCHA_SITE_KEY']?.trim() ?? '';
      if (recaptchaKey.isNotEmpty) {
        // ignore: deprecated_member_use — новые providerWeb/Android/Apple ждут
        // другой тип провайдера; старые параметры работают и стабильны.
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(recaptchaKey),
        );
      } else {
        debugPrint(
            'ℹ️ [AppCheck] web: APP_CHECK_RECAPTCHA_SITE_KEY не задан — пропуск');
      }
    } else {
      // ignore: deprecated_member_use
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
    }
  } catch (e) {
    debugPrint('⚠️ [AppCheck] activate failed: $e');
  }

  AppTheme.setDark(false);

  usePathUrlStrategy();
  registerDocuments();
  _startBackgroundServiceWatchdog();
  runApp(LogiRouteApp(initialResetOobCode: _webResetOobCode()));
}

String? _webResetOobCode() {
  if (!kIsWeb) return null;
  final uri = Uri.base;
  final oobCode = uri.queryParameters['oobCode'];
  if (oobCode == null || oobCode.isEmpty) return null;
  if (uri.path.contains('reset-password') ||
      uri.queryParameters['mode'] == 'resetPassword') {
    return oobCode;
  }
  return null;
}

Route<dynamic> _defaultRoute() =>
    MaterialPageRoute(builder: (_) => const AuthWrapper());

Route<dynamic>? _routeFromUri(String routeName) {
  final uri = Uri.parse(routeName);
  final oobCode = uri.queryParameters['oobCode'];
  final isReset = uri.path == '/reset-password' ||
      uri.queryParameters['mode'] == 'resetPassword';
  if (isReset && oobCode != null && oobCode.isNotEmpty) {
    return MaterialPageRoute(
      builder: (_) => ResetPasswordScreen(oobCode: oobCode),
    );
  }
  if (uri.path == '/doc') {
    final docId = uri.queryParameters['id'] ?? '';
    final companyId = uri.queryParameters['company'] ?? '';
    final col = uri.queryParameters['col'] ?? 'invoices';
    if (docId.isNotEmpty && companyId.isNotEmpty) {
      return MaterialPageRoute(
        builder: (_) => InvoiceDeepLinkViewer(
          companyId: companyId,
          docId: docId,
          collection: col,
        ),
      );
    }
  }
  return null;
}

class LogiRouteApp extends StatelessWidget {
  final String? initialResetOobCode;

  const LogiRouteApp({super.key, this.initialResetOobCode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
        ChangeNotifierProvider(create: (_) => CompanySelectionService()),
        // ClientService создаётся локально в каждом экране с companyId
      ],
      child: Consumer<LocaleService>(
        builder: (context, localeService, _) {
          return MaterialApp(
            title: 'LogiRoute',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            themeMode: ThemeMode.light,
            locale: localeService.locale,
            supportedLocales: const [
              Locale('he', ''),
              Locale('ru', ''),
              Locale('en', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateInitialRoutes: (String initialRoute) {
              if (initialResetOobCode != null) {
                return [
                  MaterialPageRoute(
                    builder: (_) =>
                        ResetPasswordScreen(oobCode: initialResetOobCode!),
                  ),
                ];
              }
              final fromUri = _routeFromUri(initialRoute) ??
                  _routeFromUri(Uri.base.toString());
              return [fromUri ?? _defaultRoute()];
            },
            onGenerateRoute: (settings) {
              return _routeFromUri(settings.name ?? '') ?? _defaultRoute();
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.currentUser != null) {
      Future.microtask(_requestIgnoreBatteryOptimizationOnce);
    }
    return const LocationReadyGate(child: RoleRouter());
  }
}

class LocationReadyGate extends StatefulWidget {
  final Widget child;
  const LocationReadyGate({super.key, required this.child});

  @override
  State<LocationReadyGate> createState() => _LocationReadyGateState();
}

class _LocationReadyGateState extends State<LocationReadyGate>
    with WidgetsBindingObserver {
  bool? _ready;
  bool _serviceEnabled = false;
  LocationPermission _permission = LocationPermission.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationReady();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationReady();
    }
  }

  Future<void> _checkLocationReady() async {
    if (kIsWeb) {
      if (mounted) setState(() => _ready = true);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    // Request permission if not granted yet (so user gets a system prompt)
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final ready = serviceEnabled &&
        permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;

    if (!mounted) return;
    setState(() {
      _serviceEnabled = serviceEnabled;
      _permission = permission;
      _ready = ready;
    });
  }

  Future<void> _openRequiredSettings() async {
    if (!_serviceEnabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready == true) return widget.child;

    if (_ready == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final deniedForever = _permission == LocationPermission.deniedForever;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  l10n.locationNotReady,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _serviceEnabled
                      ? l10n.locationPermissionRequired
                      : l10n.enableDeviceLocation,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openRequiredSettings,
                  icon: const Icon(Icons.settings),
                  label: Text(l10n.openSettings),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _checkLocationReady,
                  child: Text(l10n.checkAgain),
                ),
                if (deniedForever) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.locationDeniedForever,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
