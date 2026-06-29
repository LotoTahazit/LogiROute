import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/correlation/correlation_context.dart';

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

class AccountingBatchSyncResult {
  const AccountingBatchSyncResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.skipped,
  });

  final int processed;
  final int succeeded;
  final int failed;
  final int skipped;
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

  Future<void> retry(String docId, {String? userId, String? correlationId}) async {
    final trace = correlationIf(
      operation: CorrelatedOperation.accountingSync,
      companyId: companyId,
      userId: userId,
      correlationId: correlationId,
    );
    trace?.log('retryAccountingSync invoice=$docId');
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('retryAccountingSync');
      await callable.call({
        'companyId': companyId,
        'invoiceId': docId,
        if (trace != null) ...trace.cfPayload(),
      });
      trace?.log('retry ok');
    } catch (e, st) {
      trace?.logError(e, st);
      if (trace != null) throw trace.toException(e);
      rethrow;
    }
  }

  Future<AccountingBatchSyncResult> batchSync({
    required String mode,
    int limit = 25,
    String? userId,
    String? correlationId,
  }) async {
    final trace = correlationIf(
      operation: CorrelatedOperation.accountingSync,
      companyId: companyId,
      userId: userId,
      correlationId: correlationId,
    );
    trace?.log('batchAccountingSync mode=$mode limit=$limit');
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('batchAccountingSync');
      final res = await callable.call<Map<String, dynamic>>({
        'companyId': companyId,
        'mode': mode,
        'limit': limit,
        if (trace != null) ...trace.cfPayload(),
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      trace?.log(
          'batch done processed=${data['processed']} failed=${data['failed']}');
      return AccountingBatchSyncResult(
        processed: (data['processed'] as num?)?.toInt() ?? 0,
        succeeded: (data['succeeded'] as num?)?.toInt() ?? 0,
        failed: (data['failed'] as num?)?.toInt() ?? 0,
        skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      );
    } catch (e, st) {
      trace?.logError(e, st);
      if (trace != null) throw trace.toException(e);
      rethrow;
    }
  }

  /// Проверка API-ключей без создания документа.
  Future<AccountingCredentialsTestResult> testCredentials({
    String? provider,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('testAccountingCredentials');
    final res = await callable.call<Map<String, dynamic>>({
      'companyId': companyId,
      if (provider != null) 'provider': provider,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    return AccountingCredentialsTestResult(
      ok: data['ok'] == true,
      provider: data['provider'] as String? ?? provider ?? '',
      message: data['message'] as String?,
    );
  }
}

class AccountingCredentialsTestResult {
  const AccountingCredentialsTestResult({
    required this.ok,
    required this.provider,
    this.message,
  });

  final bool ok;
  final String provider;
  final String? message;
}
