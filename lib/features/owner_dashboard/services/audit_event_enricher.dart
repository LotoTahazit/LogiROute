import '../../../services/firestore_paths.dart';
import '../models/audit_event.dart';

/// Метаданные документа для строки аудита (номер, клиент, тип).
class AuditEventMeta {
  final String? docNumber;
  final String? clientName;
  final String? documentType;

  const AuditEventMeta({this.docNumber, this.clientName, this.documentType});
}

/// Подгружает номер/клиента из Firestore для старых audit-событий без extra.
abstract final class AuditEventEnricher {
  static Future<Map<String, AuditEventMeta>> enrich(
    String companyId,
    List<CrossModuleAuditEvent> events,
  ) async {
    final ids = <String>{};
    for (final e in events) {
      if (e.entity.collection != 'invoices') continue;
      final hasDocType = _firstStr(e.extra['documentType']) != null;
      final hasNumber = e.extra.containsKey('docNumber') ||
          e.extra.containsKey('docNumberFormatted') ||
          e.extra.containsKey('sequentialNumber');
      if (hasDocType && hasNumber && e.extra.containsKey('clientName')) continue;
      ids.add(e.entity.docId);
    }
    if (ids.isEmpty) return {};

    final paths = FirestorePaths();
    final out = <String, AuditEventMeta>{};
    // Не более 8 догрузок за раз — лента не должна «вешать» старт.
    for (final id in ids.take(8)) {
      try {
        final snap = await paths.invoices(companyId).doc(id).get();
        if (!snap.exists) continue;
        final d = snap.data()!;
        final num = d['sequentialNumber'] ?? d['docNumber'];
        out[id] = AuditEventMeta(
          docNumber: num?.toString(),
          clientName: d['clientName'] as String?,
          documentType: d['documentType'] as String?,
        );
      } catch (_) {}
    }
    return out;
  }

  static String? _firstStr(Object? a) {
    if (a == null) return null;
    final s = a.toString().trim();
    return s.isEmpty ? null : s;
  }
}
