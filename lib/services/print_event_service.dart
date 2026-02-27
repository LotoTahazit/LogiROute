import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/print_event.dart';
import '../models/invoice.dart';
import 'print_template_registry.dart';

/// שירות אירועי הדפסה — תת-אוסף: companies/{cId}/invoices/{iId}/printEvents/{eId}
/// append-only: אירועים לעולם לא מתעדכנים ולא נמחקים
class PrintEventService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PrintEventService({required this.companyId});

  CollectionReference<Map<String, dynamic>> _printEventsCollection(
      String invoiceId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices')
        .doc(invoiceId)
        .collection('printEvents');
  }

  /// רישום אירוע הדפסה — log-before-action
  /// templateVersion נרשם אוטומטית מ-PrintTemplateRegistry
  Future<String> recordPrintEvent({
    required String documentId,
    required String printedBy,
    String? printedByName,
    required InvoiceCopyType mode,
    int copiesCount = 1,
    String? templateVersion,
    String? device,
    String? pdfSnapshotUrl,
  }) async {
    final event = PrintEvent(
      id: '',
      documentId: documentId,
      printedBy: printedBy,
      printedByName: printedByName,
      mode: mode,
      copiesCount: copiesCount,
      templateVersion: templateVersion ?? PrintTemplateRegistry.currentVersion,
      device: device,
      pdfSnapshotUrl: pdfSnapshotUrl,
    );

    final docRef = await _printEventsCollection(documentId).add(event.toMap());
    return docRef.id;
  }

  /// קבלת כל אירועי ההדפסה של מסמך
  Future<List<PrintEvent>> getPrintEvents(String documentId) async {
    final snapshot = await _printEventsCollection(documentId)
        .orderBy('printedAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => PrintEvent.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// ספירת הדפסות לפי סוג
  Future<Map<String, int>> getPrintCounts(String documentId) async {
    final events = await getPrintEvents(documentId);
    final counts = <String, int>{};
    for (final event in events) {
      counts[event.mode.name] =
          (counts[event.mode.name] ?? 0) + event.copiesCount;
    }
    return counts;
  }
}
