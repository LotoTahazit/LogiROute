import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AccountingSyncEntry {
  const AccountingSyncEntry({
    required this.invoiceId,
    required this.provider,
    required this.status,
    this.attempts = 0,
    this.externalNumber,
    this.distributionNumber,
    this.lastError,
    this.pdfUrl,
  });

  final String invoiceId;
  final String provider;
  final String status;
  final int attempts;
  final String? externalNumber;
  final String? distributionNumber;
  final String? lastError;
  final String? pdfUrl;

  factory AccountingSyncEntry.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final ext = data['externalResult'] as Map<String, dynamic>?;
    return AccountingSyncEntry(
      invoiceId: id,
      provider: data['provider'] as String? ?? '',
      status: data['status'] as String? ?? 'unknown',
      attempts: (data['attempts'] as num?)?.toInt() ?? 0,
      externalNumber: data['externalNumber'] as String? ??
          ext?['externalNumber']?.toString(),
      distributionNumber: data['distributionNumber'] as String? ??
          ext?['distributionNumber']?.toString(),
      lastError: data['lastError'] as String?,
      pdfUrl: data['pdfUrl'] as String? ?? ext?['pdfUrl'] as String?,
    );
  }
}

class AccountingSyncService {
  AccountingSyncService({required this.companyId});

  final String companyId;
  final _firestore = FirebaseFirestore.instance;

  Stream<List<AccountingSyncEntry>> watchLedger({int limit = 20}) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('sync_ledger')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => AccountingSyncEntry.fromFirestore(
                  d.id,
                  d.data(),
                ),
              )
              .toList(),
        );
  }

  Stream<Map<String, AccountingSyncEntry>> watchLedgerMap({int limit = 200}) {
    return watchLedger(limit: limit).map(
      (entries) => {for (final e in entries) e.invoiceId: e},
    );
  }

  Future<void> retry(String docId) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('retryAccountingSync');
    await callable.call({
      'companyId': companyId,
      'invoiceId': docId,
    });
  }
}
