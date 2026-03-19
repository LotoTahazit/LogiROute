import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/company_settings.dart';
import 'firestore_paths.dart';

class CompanySettingsService {
  static const String _defaultDocId = 'settings';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  CompanySettingsService({required this.companyId});

  /// Получить путь к настройкам компании
  DocumentReference get _settingsDoc =>
      FirestorePaths(firestore: _firestore)
          .companySettings(companyId)
          .doc(_defaultDocId);

  /// Получить настройки компании
  Future<CompanySettings?> getSettings() async {
    try {
      // 1. Новое место: companies/{companyId}/settings/settings
      debugPrint(
          '🔍 [CompanySettings] Trying subcollection: companies/$companyId/settings/$_defaultDocId');
      final doc = await _settingsDoc.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ [CompanySettings] Timeout reading subcollection');
          throw Exception('Timeout reading settings subcollection');
        },
      );
      if (doc.exists) {
        debugPrint('✅ [CompanySettings] Found in subcollection');
        return CompanySettings.fromFirestore(doc);
      }
      debugPrint(
          '⚠️ [CompanySettings] Not found in subcollection, trying root doc');

      // 2. Fallback: корневой документ companies/{companyId}
      final rootDoc = await FirestorePaths(firestore: _firestore)
          .companyDoc(companyId)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ [CompanySettings] Timeout reading root doc');
          throw Exception('Timeout reading root doc');
        },
      );
      if (rootDoc.exists) {
        debugPrint('✅ [CompanySettings] Found in root doc');
        return CompanySettings.fromFirestore(rootDoc);
      }

      debugPrint('⚠️ [CompanySettings] No settings found anywhere');
      return null;
    } catch (e) {
      debugPrint(
          '❌ [CompanySettings] Error getting settings for company $companyId: $e');
      return null;
    }
  }

  /// Получить настройки компании (stream)
  Stream<CompanySettings?> getSettingsStream() async* {
    // Сначала проверяем есть ли данные в новом месте
    final existing = await _settingsDoc.get();
    if (existing.exists) {
      yield* _settingsDoc.snapshots().map((doc) {
        if (doc.exists) return CompanySettings.fromFirestore(doc);
        return null;
      });
    } else {
      // Fallback: стримим корневой документ компании
      yield* _firestore
          .collection('companies')
          .doc(companyId)
          .snapshots()
          .map((doc) {
        if (doc.exists) return CompanySettings.fromFirestore(doc);
        return null;
      });
    }
  }

  /// Сохранить настройки компании
  Future<void> saveSettings(CompanySettings settings) async {
    try {
      await _settingsDoc.set(settings.toFirestore(), SetOptions(merge: true));
      debugPrint(
          '✅ [CompanySettings] Settings saved successfully for company $companyId');
    } catch (e) {
      debugPrint(
          '❌ [CompanySettings] Error saving settings for company $companyId: $e');
      rethrow;
    }
  }

  /// Обновить настройки компании
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      await _settingsDoc.update(updates);
      debugPrint(
          '✅ [CompanySettings] Settings updated successfully for company $companyId');
    } catch (e) {
      debugPrint(
          '❌ [CompanySettings] Error updating settings for company $companyId: $e');
      rethrow;
    }
  }

  /// Создать настройки по умолчанию (для первого запуска)
  Future<void> createDefaultSettings() async {
    try {
      final existing = await getSettings();
      if (existing != null) {
        debugPrint(
            '⚠️ [CompanySettings] Settings already exist for company $companyId');
        return;
      }

      final defaultSettings = CompanySettings(
        id: _defaultDocId,
        nameHebrew: 'שם החברה',
        nameEnglish: 'Company Name',
        taxId: '000000000',
        addressHebrew: 'כתובת',
        addressEnglish: 'Address',
        poBox: '',
        city: '',
        zipCode: '',
        phone: '',
        fax: '',
        email: '',
        website: '',
        invoiceFooterText: 'תודה על הקנייה!',
        paymentTerms: 'תשלום עד 30 יום',
        bankDetails: '',
        driverName: '',
        driverPhone: '',
        departureTime: '07:00',
      );

      await saveSettings(defaultSettings);
      debugPrint(
          '✅ [CompanySettings] Default settings created for company $companyId');
    } catch (e) {
      debugPrint(
          '❌ [CompanySettings] Error creating default settings for company $companyId: $e');
      rethrow;
    }
  }
}
