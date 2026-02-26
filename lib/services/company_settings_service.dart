import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_settings.dart';

class CompanySettingsService {
  static const String _defaultDocId = 'settings';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  CompanySettingsService({required this.companyId});

  /// Получить путь к настройкам компании
  DocumentReference get _settingsDoc => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('settings')
      .doc(_defaultDocId);

  /// Получить настройки компании
  Future<CompanySettings?> getSettings() async {
    try {
      // Сначала ищем в новом месте: companies/{companyId}/settings/settings
      final doc = await _settingsDoc.get();
      if (doc.exists) {
        return CompanySettings.fromFirestore(doc);
      }

      // Fallback: ищем в старом месте: companySettings/{companyId}
      final legacyDoc =
          await _firestore.collection('companySettings').doc(companyId).get();
      if (legacyDoc.exists) {
        final settings = CompanySettings.fromFirestore(legacyDoc);
        // Мигрируем в новое место
        await _settingsDoc.set(settings.toFirestore());
        return settings;
      }

      return null;
    } catch (e) {
      print(
          '❌ [CompanySettings] Error getting settings for company $companyId: $e');
      return null;
    }
  }

  /// Получить настройки компании (stream)
  Stream<CompanySettings?> getSettingsStream() async* {
    // Сначала проверяем есть ли данные в новом месте
    final existing = await _settingsDoc.get();
    if (!existing.exists) {
      // Пробуем мигрировать из старого места
      await getSettings();
    }
    yield* _settingsDoc.snapshots().map((doc) {
      if (doc.exists) {
        return CompanySettings.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Сохранить настройки компании
  Future<void> saveSettings(CompanySettings settings) async {
    try {
      await _settingsDoc.set(settings.toFirestore());
      print(
          '✅ [CompanySettings] Settings saved successfully for company $companyId');
    } catch (e) {
      print(
          '❌ [CompanySettings] Error saving settings for company $companyId: $e');
      rethrow;
    }
  }

  /// Обновить настройки компании
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      await _settingsDoc.update(updates);
      print(
          '✅ [CompanySettings] Settings updated successfully for company $companyId');
    } catch (e) {
      print(
          '❌ [CompanySettings] Error updating settings for company $companyId: $e');
      rethrow;
    }
  }

  /// Создать настройки по умолчанию (для первого запуска)
  Future<void> createDefaultSettings() async {
    try {
      final existing = await getSettings();
      if (existing != null) {
        print(
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
      print(
          '✅ [CompanySettings] Default settings created for company $companyId');
    } catch (e) {
      print(
          '❌ [CompanySettings] Error creating default settings for company $companyId: $e');
      rethrow;
    }
  }
}
