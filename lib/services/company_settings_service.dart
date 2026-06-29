import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/company_settings.dart';
import 'company_modules_service.dart';
import 'firestore_paths.dart';

class CompanySettingsService {
  static const String _defaultDocId = 'settings';

  /// Поля entitlements/billing — только root `companies/{id}` (см. CompanyModulesService).
  static const _rootOnlyKeys = {
    'modules',
    'limits',
    'plan',
    'billingStatus',
    'trialEndsAt',
    'trialUntil',
    'paidUntil',
    'gracePeriodDays',
    'paymentProvider',
    'subscriptionId',
    'paymentCustomerId',
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  CompanySettingsService({required this.companyId});

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      FirestorePaths(firestore: _firestore)
          .companySettings(companyId)
          .doc(_defaultDocId);

  DocumentReference<Map<String, dynamic>> get _companyDoc =>
      FirestorePaths(firestore: _firestore).companyDoc(companyId);

  CompanySettings? _mergeFromSnaps(
    DocumentSnapshot<Map<String, dynamic>> rootSnap,
    DocumentSnapshot<Map<String, dynamic>>? settingsSnap,
  ) {
    if (!rootSnap.exists) return null;
    final base = settingsSnap != null && settingsSnap.exists
        ? CompanySettings.fromFirestore(settingsSnap)
        : CompanySettings.fromFirestore(rootSnap);
    return CompanyModulesService.mergeRootEntitlements(
      rootSnap: rootSnap,
      base: base,
    );
  }

  /// Профиль из settings subdoc; modules/plan/limits — overlay с root (как firestore.rules).
  Future<CompanySettings?> getSettings() async {
    try {
      final rootSnap = await _companyDoc.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout reading company root doc');
        },
      );
      if (!rootSnap.exists) {
        debugPrint('⚠️ [CompanySettings] Root doc missing for $companyId');
        return null;
      }

      final settingsSnap = await _settingsDoc.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout reading settings subcollection');
        },
      );

      return _mergeFromSnaps(rootSnap, settingsSnap);
    } catch (e) {
      debugPrint(
          '❌ [CompanySettings] Error getting settings for company $companyId: $e');
      return null;
    }
  }

  Stream<CompanySettings?> getSettingsStream() {
    return Stream<CompanySettings?>.multi((controller) {
      DocumentSnapshot<Map<String, dynamic>>? latestRoot;
      DocumentSnapshot<Map<String, dynamic>>? latestSettings;

      void emitMerged() {
        if (latestRoot == null) return;
        controller.add(_mergeFromSnaps(latestRoot!, latestSettings));
      }

      late final StreamSubscription rootSub;
      late final StreamSubscription settingsSub;

      rootSub = _companyDoc.snapshots().listen((snap) {
        latestRoot = snap;
        emitMerged();
      });
      settingsSub = _settingsDoc.snapshots().listen((snap) {
        latestSettings = snap;
        emitMerged();
      });

      controller.onCancel = () async {
        await rootSub.cancel();
        await settingsSub.cancel();
      };
    });
  }

  Map<String, dynamic> _profileOnlyMap(CompanySettings settings) {
    final map = settings.toFirestore();
    for (final key in _rootOnlyKeys) {
      map.remove(key);
    }
    return map;
  }

  /// Сохраняет только profile-поля в settings subdoc (не modules/plan/limits).
  Future<void> saveSettings(CompanySettings settings) async {
    try {
      await _settingsDoc.set(
        _profileOnlyMap(settings),
        SetOptions(merge: true),
      );
      debugPrint(
          '✅ [CompanySettings] Profile saved for company $companyId');
    } catch (e) {
      debugPrint(
          '❌ [CompanySettings] Error saving settings for company $companyId: $e');
      rethrow;
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      final clean = Map<String, dynamic>.from(updates);
      for (final key in _rootOnlyKeys) {
        clean.remove(key);
      }
      if (clean.isEmpty) return;
      await _settingsDoc.set(clean, SetOptions(merge: true));
      debugPrint(
          '✅ [CompanySettings] Settings updated successfully for company $companyId');
    } catch (e) {
      debugPrint(
          '❌ [CompanySettings] Error updating settings for company $companyId: $e');
      rethrow;
    }
  }

  bool _warehouseFlag(Object? raw) {
    if (raw is! Map) return false;
    return raw['computerizedWarehouseEnabled'] == true;
  }

  Future<bool> readComputerizedWarehouseEnabled() async {
    final settingsSnap = await _settingsDoc.get();
    if (settingsSnap.exists && _warehouseFlag(settingsSnap.data())) {
      return true;
    }
    final rootSnap = await _companyDoc.get();
    return _warehouseFlag(rootSnap.data());
  }

  Stream<bool> watchComputerizedWarehouseEnabled() {
    return Stream<bool>.multi((controller) async {
      var settingsFlag = false;
      var rootFlag = false;
      StreamSubscription? settingsSub;
      StreamSubscription? rootSub;

      void emit() => controller.add(settingsFlag || rootFlag);

      settingsFlag = _warehouseFlag((await _settingsDoc.get()).data());
      rootFlag = _warehouseFlag((await _companyDoc.get()).data());
      emit();

      settingsSub = _settingsDoc.snapshots().listen((snap) {
        settingsFlag = snap.exists && _warehouseFlag(snap.data());
        emit();
      });
      rootSub = _companyDoc.snapshots().listen((snap) {
        rootFlag = _warehouseFlag(snap.data());
        emit();
      });

      controller.onCancel = () {
        settingsSub?.cancel();
        rootSub?.cancel();
      };
    });
  }

  Future<void> setComputerizedWarehouseEnabled(bool enabled) async {
    await updateSettings({'computerizedWarehouseEnabled': enabled});
    await _companyDoc.set(
      {'computerizedWarehouseEnabled': enabled},
      SetOptions(merge: true),
    );
  }

  Future<void> createDefaultSettings() async {
    try {
      final settingsSnap = await _settingsDoc.get();
      if (settingsSnap.exists) {
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
