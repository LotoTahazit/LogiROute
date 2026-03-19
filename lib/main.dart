import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/company_selection_service.dart';
import 'widgets/role_router.dart';
import 'widgets/invoice_deep_link_viewer.dart';
import 'core/navigation/register_documents.dart';
import 'l10n/app_localizations.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_WEB_KEY');

  // 🔥 Глобальный ловец ошибок Flutter
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('🔥 FlutterError: ${details.exception}');
    debugPrint('${details.stack}');
  };

  // 🔥 Глобальный ловец необработанных ошибок
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔥 Unhandled error: $error');
    debugPrint('$stack');
    return true;
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔒 Firebase App Check временно отключен для отладки
  // await FirebaseAppCheck.instance.activate(
  //   // Web: отключен из-за проблем с reCAPTCHA
  //   // webProvider: ReCaptchaV3Provider('6Lci2zWqAAAAAJoAeJbZpCToJz9weyKMmqZE'),
  //   // Android: Play Integrity API (требует настройки в Firebase Console)
  //   androidProvider: AndroidProvider.playIntegrity,
  //   // iOS: DeviceCheck или App Attest
  //   appleProvider: AppleProvider.deviceCheck,
  // );

  usePathUrlStrategy();
  registerDocuments();
  _startBackgroundServiceWatchdog();
  runApp(const LogiRouteApp());
}

class LogiRouteApp extends StatelessWidget {
  const LogiRouteApp({super.key});

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
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'NotoSansHebrew',
              fontFamilyFallback: const ['NotoSans'],
              textTheme: const TextTheme(
                bodyLarge:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                bodyMedium:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                bodySmall: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
                displayLarge:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                displayMedium:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                displaySmall:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                headlineLarge:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                headlineMedium:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                headlineSmall:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                titleLarge:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                titleMedium:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                titleSmall:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                labelLarge:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                labelMedium: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
                labelSmall: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              listTileTheme: ListTileThemeData(
                subtitleTextStyle: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              chipTheme: const ChipThemeData(
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            onGenerateInitialRoutes: (String initialRoute) {
              final uri = Uri.parse(initialRoute);
              if (uri.path == '/doc') {
                final docId = uri.queryParameters['id'] ?? '';
                final companyId = uri.queryParameters['company'] ?? '';
                final col = uri.queryParameters['col'] ?? 'invoices';
                if (docId.isNotEmpty && companyId.isNotEmpty) {
                  return [
                    MaterialPageRoute(
                      builder: (_) => InvoiceDeepLinkViewer(
                        companyId: companyId,
                        docId: docId,
                        collection: col,
                      ),
                    ),
                  ];
                }
              }
              return [
                MaterialPageRoute(builder: (_) => const AuthWrapper()),
              ];
            },
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');
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
              return MaterialPageRoute(builder: (_) => const AuthWrapper());
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
                const Text(
                  'Location is not ready',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _serviceEnabled
                      ? 'Location permission is required to continue.'
                      : 'Please enable device location to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openRequiredSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _checkLocationReady,
                  child: const Text('Check Again'),
                ),
                if (deniedForever) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Permission is permanently denied. Open app settings to allow location.',
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
