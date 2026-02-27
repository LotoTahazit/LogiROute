// Бекфилл: добавляет billingStatus и modules в каждый company doc.
// Запуск: flutter run -t scripts/backfill_companies.dart
// Или добавь временную кнопку в admin panel.

// Этот файл — НЕ для запуска напрямую. Используй функцию backfillCompanies()
// из admin panel или вызови вручную из main.dart.

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> backfillCompanies() async {
  final db = FirebaseFirestore.instance;
  final snap = await db.collection('companies').get();

  int updated = 0;
  int skipped = 0;

  for (final doc in snap.docs) {
    final data = doc.data();
    final patch = <String, dynamic>{};

    if (data['billingStatus'] == null) {
      patch['billingStatus'] = 'active';
    }

    if (data['modules'] == null || data['modules'] is! Map) {
      patch['modules'] = {
        'logistics': true,
        'warehouse': true,
        'dispatcher': true,
        'accounting': true,
      };
    }

    if (patch.isNotEmpty) {
      patch['updatedAt'] = FieldValue.serverTimestamp();
      await doc.reference.set(patch, SetOptions(merge: true));
      updated++;
      print('✅ Patched company "${doc.id}": ${patch.keys.join(', ')}');
    } else {
      skipped++;
      print(
          '⏭️  Skipped company "${doc.id}" (already has billingStatus + modules)');
    }
  }

  print(
      '\nDone. Updated: $updated, Skipped: $skipped, Total: ${snap.docs.length}');
}
