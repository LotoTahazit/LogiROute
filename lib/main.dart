import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/client_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/dispatcher/dispatcher_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/warehouse/warehouse_dashboard.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Загрузка переменных окружения из .env файла
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔒 Активация Firebase App Check для защиты от злоупотребления API
  await FirebaseAppCheck.instance.activate(
    // Web: reCAPTCHA v3
    webProvider:
        ReCaptchaV3Provider('6Lci2bwqAAAAAHLnGRKaFpoX-J7Jg-Z7PrRjrMEg'),
    // Android: Play Integrity API (требует настройки в Firebase Console)
    androidProvider: AndroidProvider.playIntegrity,
    // iOS: DeviceCheck или App Attest
    appleProvider: AppleProvider.deviceCheck,
  );

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
        Provider(create: (_) => ClientService()),
      ],
      child: Consumer<LocaleService>(
        builder: (context, localeService, _) {
          return MaterialApp(
            title: 'LogiRoute',
            debugShowCheckedModeBanner: false,
            // Default locale is Hebrew (he)
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
              fontFamily: 'NotoSansHebrew', // Шрифт по умолчанию для иврита
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black),
                bodySmall: TextStyle(color: Colors.black),
                displayLarge: TextStyle(color: Colors.black),
                displayMedium: TextStyle(color: Colors.black),
                displaySmall: TextStyle(color: Colors.black),
                headlineLarge: TextStyle(color: Colors.black),
                headlineMedium: TextStyle(color: Colors.black),
                headlineSmall: TextStyle(color: Colors.black),
                titleLarge: TextStyle(color: Colors.black),
                titleMedium: TextStyle(color: Colors.black),
                titleSmall: TextStyle(color: Colors.black),
                labelLarge: TextStyle(color: Colors.black),
                labelMedium: TextStyle(color: Colors.black),
                labelSmall: TextStyle(color: Colors.black),
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
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (authService.currentUser == null) {
          return const LoginScreen();
        }

        final role = authService.userRole;
        final viewAs = authService.viewAsRole ?? role;

        switch (viewAs) {
          case 'admin':
          case 'super_admin':
            return const AdminDashboard();
          case 'dispatcher':
            return const DispatcherDashboard();
          case 'driver':
            return const DriverDashboard();
          case 'warehouse_keeper':
            return const WarehouseDashboard();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
