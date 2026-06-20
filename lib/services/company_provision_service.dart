import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/company_settings.dart';
import 'company_settings_service.dart';
import 'firestore_paths.dart';

/// Создание и первичная инициализация компании (super_admin).
class CompanyProvisionService {
  static final _counterKeys = [
    'invoice',
    'receipt',
    'creditNote',
    'delivery',
    'taxInvoiceReceipt',
  ];

  static final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$');

  static bool isValidCompanyId(String id) => _idPattern.hasMatch(id);

  final FirebaseFirestore _firestore;

  CompanyProvisionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Создаёт компанию, если её ещё нет. Возвращает false если ID занят.
  Future<bool> createCompany({
    required String companyId,
    required String nameHebrew,
    required String nameEnglish,
    required String createdByUid,
    int trialDays = 14,
  }) async {
    if (!isValidCompanyId(companyId)) {
      throw ArgumentError('invalid company id');
    }

    final ref = FirestorePaths(firestore: _firestore).companyDoc(companyId);
    final existing = await ref.get();
    if (existing.exists) return false;

    final trialUntil = DateTime.now().add(Duration(days: trialDays));

    await ref.set({
      'nameHebrew': nameHebrew,
      'nameEnglish': nameEnglish.isNotEmpty ? nameEnglish : nameHebrew,
      'name': nameHebrew,
      'billingStatus': 'trial',
      'trialUntil': Timestamp.fromDate(trialUntil),
      'plan': 'full',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdByUid,
    });

    final settings = CompanySettings(
      id: 'settings',
      nameHebrew: nameHebrew,
      nameEnglish: nameEnglish.isNotEmpty ? nameEnglish : nameHebrew,
      taxId: '',
      addressHebrew: '',
      addressEnglish: '',
      poBox: '',
      city: '',
      zipCode: '',
      phone: '',
      fax: '',
      email: '',
      website: '',
      invoiceFooterText: '',
      paymentTerms: '',
      bankDetails: '',
      driverName: '',
      driverPhone: '',
      departureTime: '7:00',
      billingStatus: 'trial',
      trialEndsAt: trialUntil,
    );
    await CompanySettingsService(companyId: companyId).saveSettings(settings);

    final counters = FirestorePaths(firestore: _firestore).counters(companyId);
    final batch = _firestore.batch();
    for (final key in _counterKeys) {
      batch.set(counters.doc(key), {'lastNumber': 0});
    }
    await batch.commit();

    debugPrint('✅ [CompanyProvision] Created company $companyId');
    return true;
  }

  /// Используется при создании пользователя с новым companyId.
  Future<void> ensureCompanyExists({
    required String companyId,
    required String createdByUid,
  }) async {
    if (companyId.isEmpty) return;
    final ref = FirestorePaths(firestore: _firestore).companyDoc(companyId);
    if ((await ref.get()).exists) return;

    await createCompany(
      companyId: companyId,
      nameHebrew: companyId,
      nameEnglish: companyId,
      createdByUid: createdByUid,
    );
  }
}
