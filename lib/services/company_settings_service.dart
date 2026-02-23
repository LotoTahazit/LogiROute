import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_settings.dart';

class CompanySettingsService {
  static const String _collectionName = 'companySettings';
  static const String _defaultDocId = 'default';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить настройки компании
  Future<CompanySettings?> getSettings() async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(_defaultDocId).get();

      if (doc.exists) {
        return CompanySettings.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ [CompanySettings] Error getting settings: $e');
      return null;
    }
  }

  /// Получить настройки компании (stream)
  Stream<CompanySettings?> getSettingsStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_defaultDocId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return CompanySettings.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Сохранить настройки компании
  Future<void> saveSettings(CompanySettings settings) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(_defaultDocId)
          .set(settings.toFirestore());
      print('✅ [CompanySettings] Settings saved successfully');
    } catch (e) {
      print('❌ [CompanySettings] Error saving settings: $e');
      rethrow;
    }
  }

  /// Обновить настройки компании
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(_defaultDocId)
          .update(updates);
      print('✅ [CompanySettings] Settings updated successfully');
    } catch (e) {
      print('❌ [CompanySettings] Error updating settings: $e');
      rethrow;
    }
  }

  /// Создать настройки по умолчанию (для первого запуска)
  Future<void> createDefaultSettings() async {
    try {
      final existing = await getSettings();
      if (existing != null) {
        print('⚠️ [CompanySettings] Settings already exist');
        return;
      }

      final defaultSettings = CompanySettings(
        id: _defaultDocId,
        nameHebrew: 'י.כ. פלסט בע״מ',
        nameEnglish: 'Y.C PLAST L.T.D',
        taxId: '513322760',
        addressHebrew: 'פרדס חנה מיקוד 37100',
        addressEnglish: 'PARDESS HANA Z.C. 37100',
        poBox: '1057',
        city: 'פרדס חנה',
        zipCode: '37100',
        phone: '04-6288547/9',
        fax: '04-6288579',
        email: '',
        website: 'www.ycplast.co.il',
        invoiceFooterText:
            'חובה להחזיר משטחים-לקוח שלא יחזיר יחוייב בגינם\n*הסחורה עד לפרעון התשלום בבעלות י.כ.פלסט בע״מ\nהסמכות הבלעדית נשוא ח-ו זו, נתון לבית המשפט בחדרה\nערעורים והשגות יתקבלו 15 יום מיום קבלת הח-ו\nאם הקונה היינו חברה בע״מ - בעלי החברה ערבים אישית לתשלום.',
        paymentTerms: 'תשלום עד 30 יום',
        bankDetails: '',
        driverName: 'יבגני',
        driverPhone: '892-94-902',
        departureTime: '7:00',
      );

      await saveSettings(defaultSettings);
      print('✅ [CompanySettings] Default settings created');
    } catch (e) {
      print('❌ [CompanySettings] Error creating default settings: $e');
      rethrow;
    }
  }
}
