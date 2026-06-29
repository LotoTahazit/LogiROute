import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/import_wizard_type.dart';
import '../../models/saved_import_mapping.dart';
import 'import_column_matcher.dart';

/// CRUD сохранённых шаблонов сопоставления колонок импорта.
class ImportMappingRepository {
  final String companyId;
  final FirebaseFirestore _firestore;

  ImportMappingRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance {
    if (companyId.isEmpty) {
      throw ArgumentError('companyId is required');
    }
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection('import_mappings');

  Future<List<SavedImportMapping>> listMappings(ImportWizardType type) async {
    final snap = await _col
        .where('importType', isEqualTo: type.value)
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => SavedImportMapping.fromMap(d.data(), d.id))
        .toList();
  }

  /// Лучший сохранённый шаблон при similarity заголовков ≥ 0.7.
  Future<SavedImportMapping?> findBestMatch(
    List<String> headers,
    ImportWizardType type,
  ) async {
    final all = await listMappings(type);
    SavedImportMapping? best;
    var bestScore = 0.0;
    for (final m in all) {
      final score = ImportColumnMatcher.headersSimilarity(headers, m.sourceHeaders);
      if (score >= 0.7 && score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  Future<String> save(SavedImportMapping mapping) async {
    final now = DateTime.now();
    final data = mapping.toMap()
      ..['updatedAt'] = Timestamp.fromDate(now);
    if (mapping.id.isEmpty) {
      data['createdAt'] = Timestamp.fromDate(now);
      final ref = await _col.add(data);
      return ref.id;
    }
    await _col.doc(mapping.id).set(data, SetOptions(merge: true));
    return mapping.id;
  }

  Future<void> markUsed(String mappingId) async {
    await _col.doc(mappingId).update({
      'lastUsedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String mappingId) async {
    await _col.doc(mappingId).delete();
  }
}
