import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dashboard_exceptions.dart';

/// Mixin для обработки ошибок Firestore в репозиториях.
///
/// Преобразует FirebaseException в типизированные DashboardException.
/// Requirements: 10.6
mixin FirestoreErrorHandler {
  /// Оборачивает Future-вызов Firestore в try/catch с типизированными исключениями.
  Future<T> handleFirestoreCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'PERMISSION_DENIED') {
        throw PermissionDeniedException('אין הרשאה לפעולה זו', e);
      }
      if (e.code == 'not-found') {
        throw CompanyNotFoundException('המסמך לא נמצא', e);
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw NetworkException('שגיאת רשת — נסה שוב', e);
      }
      rethrow;
    }
  }

  /// Оборачивает Stream Firestore, преобразуя ошибки в типизированные исключения.
  Stream<T> handleFirestoreStream<T>(Stream<T> Function() streamFactory) {
    return streamFactory().handleError((error) {
      if (error is FirebaseException) {
        if (error.code == 'permission-denied' ||
            error.code == 'PERMISSION_DENIED') {
          throw PermissionDeniedException('אין הרשאה לפעולה זו', error);
        }
        if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
          throw NetworkException('שגיאת רשת — נסה שוב', error);
        }
      }
      throw error;
    });
  }
}
