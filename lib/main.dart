import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/company_selection_service.dart';
import 'widgets/role_router.dart';
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
  await dotenv.load(fileName: ".env");

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
              // Глобальное улучшение видимости ВСЕХ цифр и текста
              textTheme: const TextTheme(
                bodyLarge: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                bodyMedium: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                // Улучшенная видимость для вторичного текста и цифр
                bodySmall: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                displayLarge: TextStyle(color: Colors.black),
                displayMedium: TextStyle(color: Colors.black),
                displaySmall: TextStyle(color: Colors.black),
                headlineLarge: TextStyle(color: Colors.black),
                headlineMedium: TextStyle(color: Colors.black),
                headlineSmall: TextStyle(color: Colors.black),
                titleLarge:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                titleMedium:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                titleSmall:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                labelLarge: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                labelMedium: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                // Улучшенная видимость для маленьких меток и цифр
                labelSmall: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              // Улучшенная видимость для ListTile subtitle
              listTileTheme: ListTileThemeData(
                subtitleTextStyle: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              // Улучшенная видимость для Chip
              chipTheme: ChipThemeData(
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            home: const AuthWrapper(),
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
