import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/export_preset.dart';

/// Сервис управления пресетами экспорта.
/// Хранит пользовательские пресеты в companies/{companyId}/export_presets/
/// Встроенные пресеты доступны всегда.
class ExportPresetService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExportPresetService({required this.companyId});

  CollectionReference<Map<String, dynamic>> _presetsRef() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('export_presets');
  }

  /// Получить все пресеты: встроенные + пользовательские
  Future<List<ExportPreset>> getAll() async {
    final builtIn = ExportPreset.builtInPresets();
    final snap = await _presetsRef().orderBy('name').get();
    final custom = snap.docs
        .map((doc) => ExportPreset.fromMap(doc.data(), doc.id))
        .toList();
    return [...builtIn, ...custom];
  }

  /// Stream всех пресетов
  Stream<List<ExportPreset>> watchAll() {
    return _presetsRef().orderBy('name').snapshots().map((snap) {
      final builtIn = ExportPreset.builtInPresets();
      final custom = snap.docs
          .map((doc) => ExportPreset.fromMap(doc.data(), doc.id))
          .toList();
      return [...builtIn, ...custom];
    });
  }

  /// Сохранить пользовательский пресет
  Future<String> save(ExportPreset preset) async {
    if (preset.id.startsWith('_')) {
      // Built-in preset — save as new custom copy
      final ref = await _presetsRef().add(preset.toMap());
      return ref.id;
    }
    if (preset.id.isEmpty) {
      final ref = await _presetsRef().add(preset.toMap());
      return ref.id;
    }
    await _presetsRef().doc(preset.id).set(preset.toMap());
    return preset.id;
  }

  /// Удалить пользовательский пресет
  Future<void> delete(String presetId) async {
    if (presetId.startsWith('_')) return; // can't delete built-in
    await _presetsRef().doc(presetId).delete();
  }
}
