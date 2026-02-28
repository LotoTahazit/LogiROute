import 'package:cloud_functions/cloud_functions.dart';

/// Сервис для серверной выдачи номеров документов через Cloud Functions.
/// Заменяет клиентский _getNextSequentialNumberForType + finalizeInvoice.
///
/// Callable: issueInvoice({ companyId, invoiceId, counterKey })
/// Возвращает: { ok, docNumber, docNumberFormatted, issuedAt, ... }
class IssuanceService {
  static final IssuanceService _instance = IssuanceService._();
  factory IssuanceService() => _instance;
  IssuanceService._();

  final _functions = FirebaseFunctions.instance;

  /// Выдать номер документу (invoice/receipt/creditNote/delivery/taxInvoiceReceipt).
  /// Документ должен быть создан как draft (status='draft', sequentialNumber=0).
  /// Функция атомарно: counter++ → status=issued → anchor → chain → audit.
  ///
  /// [companyId] — ID компании
  /// [invoiceId] — ID документа в Firestore
  /// [counterKey] — ключ счётчика (совпадает с InvoiceDocumentType.name)
  ///
  /// Возвращает [IssuanceResult] с номером и метаданными.
  /// Бросает [FirebaseFunctionsException] при ошибках.
  Future<IssuanceResult> issueDocument({
    required String companyId,
    required String invoiceId,
    required String counterKey,
  }) async {
    final callable = _functions.httpsCallable(
      'issueInvoice',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final result = await callable.call<Map<String, dynamic>>({
      'companyId': companyId,
      'invoiceId': invoiceId,
      'counterKey': counterKey,
    });

    final data = result.data;
    // Cloud Functions on web returns numbers as Int64 (fixnum) which dart2js
    // cannot cast directly to int — use num conversion instead.
    final rawDocNumber = data['docNumber'];
    final docNumber =
        rawDocNumber != null ? int.tryParse(rawDocNumber.toString()) ?? 0 : 0;
    return IssuanceResult(
      ok: data['ok'] == true,
      invoiceId: data['invoiceId'] as String? ?? invoiceId,
      docNumber: docNumber,
      docNumberFormatted: data['docNumberFormatted'] as String? ?? '',
      issuedAt: data['issuedAt'] as String?,
      anchorId: data['anchorId'] as String?,
      chainId: data['chainId'] as String?,
      idempotent: data['idempotent'] == true,
    );
  }
}

class IssuanceResult {
  final bool ok;
  final String invoiceId;
  final int docNumber;
  final String docNumberFormatted;
  final String? issuedAt;
  final String? anchorId;
  final String? chainId;
  final bool idempotent;

  IssuanceResult({
    required this.ok,
    required this.invoiceId,
    required this.docNumber,
    required this.docNumberFormatted,
    this.issuedAt,
    this.anchorId,
    this.chainId,
    this.idempotent = false,
  });
}
