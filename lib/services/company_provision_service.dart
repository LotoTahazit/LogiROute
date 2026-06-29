import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/company_settings.dart';
import 'company_modules_service.dart';
import 'company_settings_service.dart';
import 'firestore_paths.dart';

/// Создание и первичная инициализация компании (super_admin).
class CompanyProvisionService {
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
    String taxId = '',
    String addressHebrew = '',
    String addressEnglish = '',
    String poBox = '',
    String city = '',
    String zipCode = '',
    String phone = '',
    String fax = '',
    String email = '',
    String website = '',
    int trialDays = 14,
    String plan = 'full',
    String country = 'Israel',
    String defaultLanguage = 'he',
    String timezone = 'Asia/Jerusalem',
    String? onboardingMode,
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
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdByUid,
      'country': country,
      'defaultLanguage': defaultLanguage,
      'timezone': timezone,
      if (onboardingMode != null) 'onboardingMode': onboardingMode,
    });

    await CompanyModulesService(companyId: companyId, firestore: _firestore)
        .applyPlan(plan);

    final settings = CompanySettings(
      id: 'settings',
      nameHebrew: nameHebrew,
      nameEnglish: nameEnglish.isNotEmpty ? nameEnglish : nameHebrew,
      taxId: taxId.trim(),
      addressHebrew: addressHebrew.trim(),
      addressEnglish: addressEnglish.trim(),
      poBox: poBox.trim(),
      city: city.trim(),
      zipCode: zipCode.trim(),
      phone: phone.trim(),
      fax: fax.trim(),
      email: email.trim(),
      website: website.trim(),
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

    await FirestorePaths(firestore: _firestore)
        .companySettings(companyId)
        .doc('config')
        .set({
      'country': country,
      'language': defaultLanguage,
      'timezone': timezone,
    }, SetOptions(merge: true));

    debugPrint('✅ [CompanyProvision] Created company $companyId (counters via onCompanyCreated CF)');
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
