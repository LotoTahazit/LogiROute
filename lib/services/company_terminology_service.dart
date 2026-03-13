import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_terminology.dart';

/// Сервис управления терминологией компании
class CompanyTerminologyService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CompanyTerminologyService({required this.companyId});

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('companies').doc(companyId);

  /// Получить терминологию компании
  Future<CompanyTerminology> getTerminology() async {
    final doc = await _doc.get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('terminology')) {
        return CompanyTerminology.fromMap(data['terminology']);
      }
    }

    // Возвращаем дефолтную терминологию
    return CompanyTerminology(companyId: companyId);
  }

  /// Stream терминологии
  Stream<CompanyTerminology> watchTerminology() {
    return _doc.snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('terminology')) {
          return CompanyTerminology.fromMap(data['terminology']);
        }
      }
      return CompanyTerminology(companyId: companyId);
    });
  }

  /// Сохранить терминологию
  Future<void> saveTerminology(CompanyTerminology terminology) async {
    await _doc.set({
      'terminology': terminology.toMap(),
    }, SetOptions(merge: true));
    print('✅ [Terminology] Saved for company: $companyId');
  }

  /// Установить шаблон по типу бизнеса
  Future<void> setBusinessTypeTemplate(String businessType) async {
    final terminology = CompanyTerminology.getTemplate(businessType, companyId);
    await saveTerminology(terminology);
    print('✅ [Terminology] Set template: $businessType');
  }
}
