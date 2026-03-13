/// Типизированные исключения для Owner Dashboard.
///
/// Используются в сервисном и репозиторном слоях для обработки ошибок.
/// Requirements: 10.6
library;

/// Базовый класс исключений Owner Dashboard.
abstract class DashboardException implements Exception {
  final String message;
  final Object? cause;

  const DashboardException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Ошибка доступа — Firestore permission denied или RBAC-отказ.
class PermissionDeniedException extends DashboardException {
  const PermissionDeniedException(
      [super.message = 'אין הרשאה לפעולה זו', super.cause]);
}

/// Компания не найдена или companyId пуст.
class CompanyNotFoundException extends DashboardException {
  const CompanyNotFoundException(
      [super.message = 'לא נמצאה חברה', super.cause]);
}

/// Ошибка сети — таймаут, нет интернета.
class NetworkException extends DashboardException {
  const NetworkException(
      [super.message = 'שגיאת רשת — נסה שוב', super.cause]);
}

/// Ошибка валидации данных.
class ValidationException extends DashboardException {
  final Map<String, String> fieldErrors;

  const ValidationException({
    String message = 'שגיאת אימות נתונים',
    this.fieldErrors = const {},
    Object? cause,
  }) : super(message, cause);
}

/// Лимит плана превышен (напр. usersLimit).
class PlanLimitExceededException extends DashboardException {
  final String limitType;
  final int currentUsage;
  final int limit;

  const PlanLimitExceededException({
    required this.limitType,
    required this.currentUsage,
    required this.limit,
    String? message,
  }) : super(message ??
            'חריגה ממגבלת התוכנית: $limitType ($currentUsage/$limit)');
}
