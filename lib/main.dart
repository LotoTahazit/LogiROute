import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/company_selection_service.dart';
import 'widgets/role_router.dart';
import 'widgets/invoice_deep_link_viewer.dart';
import 'core/navigation/register_documents.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 🔐 Загрузка переменных окружения из .env файла
  try {
    await dotenv.load(fileName: ".env");
    debugPrint(
        '✅ [dotenv] Loaded ${dotenv.env.length} vars: ${dotenv.env.keys.toList()}');
    debugPrint(
        '✅ [dotenv] GOOGLE_MAPS_WEB_KEY=${dotenv.env['GOOGLE_MAPS_WEB_KEY']?.isNotEmpty == true ? '***set***' : 'EMPTY'}');
  } catch (e) {
    debugPrint('❌ [dotenv] Failed to load .env: $e');
  }

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
    return const RoleRouter();
  }
}
