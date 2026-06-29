import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/import_wizard_type.dart';
import 'import_header_intelligence.dart';

/// Обучение mapping: компания запоминает исправления пользователя.
class ImportMappingLearning {
  ImportMappingLearning({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    if (companyId.isEmpty) {
      throw ArgumentError('companyId is required');
    }
  }

  final String companyId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('import_learned_mappings');

  /// normalizedHeader → fieldKey для подсказок confidence.
  Future<Map<String, String>> loadLearnedHeaders(ImportWizardType type) async {
    final snap = await _col
        .where('importType', isEqualTo: type.value)
        .limit(200)
        .get();
    final out = <String, String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final h = data['headerNormalized']?.toString() ?? '';
      final f = data['fieldKey']?.toString() ?? '';
      if (h.isNotEmpty && f.isNotEmpty) out[h] = f;
    }
    return out;
  }

  /// Записать исправление пользователя (header → field).
  Future<void> recordCorrection({
    required ImportWizardType importType,
    required String originalHeader,
    required String fieldKey,
    required String uid,
  }) async {
    if (originalHeader.trim().isEmpty || fieldKey.isEmpty) return;
    final normalized = ImportHeaderIntelligence.normalize(originalHeader);
    final docId = '${importType.value}_$normalized';
    final ref = _col.doc(docId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final prev = snap.data();
      final hits = ((prev?['hitCount'] as num?)?.toInt() ?? 0) + 1;
      tx.set(ref, {
        'importType': importType.value,
        'headerNormalized': normalized,
        'originalHeader': originalHeader.trim(),
        'fieldKey': fieldKey,
        'hitCount': hits,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
        if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
