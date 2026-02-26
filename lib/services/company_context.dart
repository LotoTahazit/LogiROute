import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'company_selection_service.dart';
import 'firestore_paths.dart';

/// Контекст компании - единый источник правды для текущей компании
///
/// Используйте этот класс во всех экранах для получения:
/// - effectiveCompanyId (какую компанию сейчас просматриваем)
/// - paths (пути к коллекциям Firestore)
///
/// Пример использования:
/// ```dart
/// final companyCtx = CompanyContext.of(context);
/// final companyId = companyCtx.effectiveCompanyId;
/// final prices = await companyCtx.paths.prices(companyId).get();
/// ```
class CompanyContext {
  final AuthService authService;
  final CompanySelectionService companyService;
  final FirestorePaths paths;

  CompanyContext({
    required this.authService,
    required this.companyService,
    required this.paths,
  });

  /// Получить эффективный companyId (единственный источник правды!)
  ///
  /// Для super_admin - выбранная компания из dropdown
  /// Для обычных пользователей - их companyId
  ///
  /// ВАЖНО: Всегда используйте этот метод вместо прямого обращения к userModel.companyId!
  String? get effectiveCompanyId {
    return companyService.getEffectiveCompanyId(authService);
  }

  /// Получить эффективный companyId с проверкой (бросает исключение если null)
  String get requireCompanyId {
    final id = effectiveCompanyId;
    if (id == null || id.isEmpty) {
      throw Exception(
        'CompanyId is required but not available. '
        'Make sure user is logged in and company is selected.',
      );
    }
    return id;
  }

  /// Проверить что пользователь - super_admin
  bool get isSuperAdmin {
    return authService.userModel?.isSuperAdmin ?? false;
  }

  /// Получить текущего пользователя
  get currentUser => authService.userModel;

  /// Статический метод для получения CompanyContext из BuildContext
  static CompanyContext of(BuildContext context) {
    final authService = context.read<AuthService>();
    final companyService = context.read<CompanySelectionService>();
    final paths = FirestorePaths();

    return CompanyContext(
      authService: authService,
      companyService: companyService,
      paths: paths,
    );
  }

  /// Статический метод для получения CompanyContext с watch (для автообновления)
  static CompanyContext watch(BuildContext context) {
    final authService = context.watch<AuthService>();
    final companyService = context.watch<CompanySelectionService>();
    final paths = FirestorePaths();

    return CompanyContext(
      authService: authService,
      companyService: companyService,
      paths: paths,
    );
  }
}
