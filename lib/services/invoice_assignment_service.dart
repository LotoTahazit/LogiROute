import 'package:cloud_functions/cloud_functions.dart';
import '../models/invoice.dart';

/// שירות מספר הקצאה — חשבוניות ישראל (Israel Tax Authority allocation number).
///
/// ВСЁ обращение к API налоговой выполняется НА СЕРВЕРЕ (Cloud Functions):
/// `requestAllocationNumber` делает OAuth-refresh, вызывает /Invoices/v2/Approval
/// и пишет статус в счёт. Токен/секрет рשут המסים никогда не попадают в клиент.
/// Здесь — тонкий вызов CF + клиентский гейтинг UI.
class InvoiceAssignmentService {
  final String companyId;
  final FirebaseFunctions _functions;

  InvoiceAssignmentService({
    required this.companyId,
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// Нужен ли счёту מספר הקצаה (клиентский гейтинг UI; реальная проверка — на
  /// сервере). Учитывает флаг `AppConfig.enableAssignmentNumbers` через
  /// [Invoice.requiresAssignment].
  bool isAssignmentRequired(Invoice invoice) => invoice.requiresAssignment;

  /// OAuth-ссылка для РАЗОВОГО подключения компании к מערכת חשבוניות ישראל.
  /// Открыть во внешнем браузере; после авторизации refresh-токен сохраняется
  /// на сервере. Доступно владельцу/админу/бухгалтеру (проверяется в CF).
  Future<String> getConnectUrl() async {
    final res = await _functions
        .httpsCallable(
          'israelInvoiceAuthUrl',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call<Map<String, dynamic>>({'companyId': companyId});
    return (res.data['url'] ?? '') as String;
  }

  /// Запросить מספר הקצаה для счёта. Всю работу (OAuth-refresh, вызов
  /// /Approval, запись `assignmentNumber`/статуса в счёт) делает Cloud Function
  /// `requestAllocationNumber`.
  Future<AssignmentResult> requestAssignmentNumber(String invoiceId) async {
    try {
      final res = await _functions
          .httpsCallable(
            'requestAllocationNumber',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call<Map<String, dynamic>>({
        'companyId': companyId,
        'invoiceId': invoiceId,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      final ok = data['ok'] == true;
      return AssignmentResult(
        success: ok,
        assignmentNumber: data['assignmentNumber']?.toString(),
        message: data['notRequired'] == true
            ? 'לא נדרש מספר הקצאה — מתחת לסף'
            : (data['alreadyApproved'] == true
                ? 'מספר הקצאה כבר התקבל'
                : null),
        error: ok ? null : (data['message']?.toString() ?? 'שגיאה'),
        isRejection: data['rejection'] == true,
      );
    } on FirebaseFunctionsException catch (e) {
      return AssignmentResult(success: false, error: e.message ?? e.code);
    } catch (e) {
      return AssignmentResult(success: false, error: e.toString());
    }
  }
}

/// תוצאת בקשת מספר הקצאה
class AssignmentResult {
  final bool success;
  final String? assignmentNumber;
  final String? error;
  final String? message;
  final String? rawResponse;
  final bool isRejection;

  AssignmentResult({
    required this.success,
    this.assignmentNumber,
    this.error,
    this.message,
    this.rawResponse,
    this.isRejection = false,
  });
}
