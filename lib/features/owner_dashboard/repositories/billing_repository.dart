import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/billing_invoice.dart';

/// Поля биллинга, чувствительные для owner/admin.
///
/// Эти поля исключаются из результата [watchBillingInfo] для ролей
/// owner и admin. Только super_admin видит их.
const _sensitiveFields = {'subscriptionId', 'paymentCustomerId'};

/// Репозиторий для чтения биллинговой информации компании.
///
/// Работает с документом `/companies/{companyId}` (billing-поля)
/// и подколлекцией `/companies/{companyId}/billing_invoices/{invoiceId}`.
///
/// Read-only: owner/admin не могут изменять биллинговые данные.
/// Проекция: [subscriptionId] и [paymentCustomerId] исключаются
/// для owner/admin (контролируется флагом [isSuperAdmin]).
class BillingRepository {
  final FirebaseFirestore _firestore;
  final String companyId;
  final bool isSuperAdmin;

  BillingRepository({
    required this.companyId,
    this.isSuperAdmin = false,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на документ компании.
  DocumentReference<Map<String, dynamic>> get _companyDoc =>
      _firestore.collection('companies').doc(companyId);

  /// Ссылка на коллекцию billing_invoices компании.
  CollectionReference<Map<String, dynamic>> get _invoicesCollection =>
      _companyDoc.collection('billing_invoices');

  /// Стрим биллинговой информации из документа компании.
  ///
  /// Возвращает `Map<String, dynamic>` с полями биллинга.
  /// Для owner/admin чувствительные поля ([subscriptionId],
  /// [paymentCustomerId]) удаляются из результата.
  /// Для super_admin — все поля включены.
  Stream<Map<String, dynamic>> watchBillingInfo() {
    return _companyDoc.snapshots().map((snapshot) {
      final raw = snapshot.data();
      final data = raw != null
          ? Map<String, dynamic>.from(raw as Map)
          : <String, dynamic>{};
      if (!isSuperAdmin) {
        for (final field in _sensitiveFields) {
          data.remove(field);
        }
      }
      return data;
    });
  }

  /// Загружает список счетов биллинга, отсортированных по [issuedAt] (новые первые).
  Future<List<BillingInvoice>> getBillingInvoices() async {
    final snapshot =
        await _invoicesCollection.orderBy('issuedAt', descending: true).get();

    return snapshot.docs
        .map((doc) => BillingInvoice.fromMap(
            Map<String, dynamic>.from(doc.data() as Map)))
        .toList();
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for BillingRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
