import 'package:cloud_firestore/cloud_firestore.dart';

/// רישום גרסאות תבניות הדפסה
/// אוסף: companies/{cId}/print_templates/{templateId}
///
/// מטרה: שחזור מסמך כפי שהודפס — גם אחרי שנים
/// כל שינוי בתבנית = גרסה חדשה, הגרסה הישנה נשמרת
class PrintTemplateRegistry {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// גרסה נוכחית של תבנית ההדפסה
  static const String currentVersion = '2.0.0';

  /// תיאור שינויים בגרסה הנוכחית
  static const String currentChangelog =
      'v2.0.0: סוג מסמך דינמי, סימון טיוטה, סימון הדפסה חוזרת, מטא-נתונים בפוטר';

  PrintTemplateRegistry({required this.companyId});

  CollectionReference<Map<String, dynamic>> _templatesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('print_templates');
  }

  /// רישום גרסה חדשה של תבנית
  Future<void> registerVersion({
    required String version,
    required String changelog,
    required String registeredBy,
    Map<String, dynamic>? templateConfig,
  }) async {
    await _templatesCollection().doc(version).set({
      'version': version,
      'changelog': changelog,
      'registeredBy': registeredBy,
      'registeredAt': FieldValue.serverTimestamp(),
      'isActive': true,
      if (templateConfig != null) 'config': templateConfig,
    });

    // סימון גרסאות קודמות כלא פעילות
    final oldVersions =
        await _templatesCollection().where('isActive', isEqualTo: true).get();

    for (final doc in oldVersions.docs) {
      if (doc.id != version) {
        await doc.reference.update({'isActive': false});
      }
    }
  }

  /// קבלת הגרסה הפעילה
  Future<String> getActiveVersion() async {
    final snapshot = await _templatesCollection()
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return currentVersion;
    return snapshot.docs.first.data()['version'] as String? ?? currentVersion;
  }

  /// קבלת היסטוריית גרסאות
  Future<List<Map<String, dynamic>>> getVersionHistory() async {
    final snapshot = await _templatesCollection()
        .orderBy('registeredAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// בדיקה: האם הגרסה הנוכחית רשומה?
  Future<bool> isCurrentVersionRegistered() async {
    final doc = await _templatesCollection().doc(currentVersion).get();
    return doc.exists;
  }

  /// רישום אוטומטי של הגרסה הנוכחית (אם לא רשומה)
  Future<void> ensureCurrentVersionRegistered(String registeredBy) async {
    if (!await isCurrentVersionRegistered()) {
      await registerVersion(
        version: currentVersion,
        changelog: currentChangelog,
        registeredBy: registeredBy,
      );
    }
  }
}
