import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/company_settings.dart';
import 'firestore_paths.dart';
import 'plan_limits_service.dart';

/// Source of truth для modules/limits/plan: `companies/{companyId}` (root).
/// Firestore rules `hasModule()` читают root doc — guards должны совпадать.
///
/// **H4:** Запрещено менять `plan` / `modules` / `limits` напрямую.
/// Все изменения тарифа — только через [applyPlan] (Dart) или
/// `applyPlanToCompany()` (Cloud Functions).
class CompanyModulesService {
  CompanyModulesService({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String companyId;
  final FirebaseFirestore _firestore;

  static const moduleKeys = [
    'warehouse',
    'logistics',
    'dispatcher',
    'accounting',
    'reports',
  ];

  /// Модули по плану (без изменения тарифной модели).
  static const planModules = {
    'logistics': {
      'warehouse': false,
      'logistics': true,
      'dispatcher': true,
      'accounting': false,
      'reports': true,
    },
    'warehouse_only': {
      'warehouse': true,
      'logistics': false,
      'dispatcher': false,
      'accounting': false,
      'reports': false,
    },
    'ops': {
      'warehouse': true,
      'logistics': true,
      'dispatcher': true,
      'accounting': false,
      'reports': true,
    },
    'full': {
      'warehouse': true,
      'logistics': true,
      'dispatcher': true,
      'accounting': true,
      'reports': true,
    },
  };

  static String normalizePlan(String? plan) =>
      planModules.containsKey(plan) ? plan! : 'full';

  static ModuleEntitlements entitlementsForPlan(String plan) {
    final key = normalizePlan(plan);
    return ModuleEntitlements.fromMap(
      Map<String, dynamic>.from(planModules[key]!),
    );
  }

  static PlanLimits limitsForPlan(String plan) =>
      PlanLimitsService.defaultLimitsForPlan(normalizePlan(plan));

  /// Entitlements с root doc; fallback — по plan (не all-true).
  static ModuleEntitlements entitlementsFromRootData(
    Map<String, dynamic> rootData,
  ) {
    final plan = normalizePlan(rootData['plan'] as String?);
    final raw = rootData['modules'];
    if (raw is Map) {
      return ModuleEntitlements.fromMap(Map<String, dynamic>.from(raw));
    }
    return entitlementsForPlan(plan);
  }

  static PlanLimits limitsFromRootData(Map<String, dynamic> rootData) {
    final plan = normalizePlan(rootData['plan'] as String?);
    final raw = rootData['limits'];
    return PlanLimitsService.resolveLimits(
      limitsMap: raw is Map ? Map<String, dynamic>.from(raw) : null,
      plan: plan,
    );
  }

  /// Patch для root company doc.
  static Map<String, dynamic> rootEntitlementsPatch(String plan) {
    final normalized = normalizePlan(plan);
    return {
      'plan': normalized,
      'modules': entitlementsForPlan(normalized).toMap(),
      'limits': limitsForPlan(normalized).toMap(),
    };
  }

  DocumentReference<Map<String, dynamic>> get _companyRef =>
      FirestorePaths(firestore: _firestore).companyDoc(companyId);

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      FirestorePaths(firestore: _firestore)
          .companySettings(companyId)
          .doc('settings');

  /// Атомарно обновляет root; settings.modules — deprecated mirror (не для guards).
  Future<void> applyPlan(String plan) async {
    final patch = rootEntitlementsPatch(plan);
    await _companyRef.set(patch, SetOptions(merge: true));
    await _settingsRef.set(
      {
        'plan': patch['plan'],
        'modules': patch['modules'],
        'modulesMirrorUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Overlay root entitlements на profile-based [base].
  static CompanySettings mergeRootEntitlements({
    required DocumentSnapshot<Map<String, dynamic>> rootSnap,
    required CompanySettings base,
  }) {
    if (!rootSnap.exists) return base;
    final rootData = rootSnap.data() ?? {};
    return base.copyWith(
      plan: normalizePlan(rootData['plan'] as String? ?? base.plan),
      billingStatus: rootData['billingStatus'] as String? ?? base.billingStatus,
      modules: entitlementsFromRootData(rootData),
      limits: limitsFromRootData(rootData),
      trialEndsAt: _dateFromRoot(rootData, 'trialUntil', 'trialEndsAt') ??
          base.trialEndsAt,
      paidUntil: _timestampDate(rootData['paidUntil']) ?? base.paidUntil,
      gracePeriodDays: (rootData['gracePeriodDays'] as num?)?.toInt() ??
          base.gracePeriodDays,
      paymentProvider:
          rootData['paymentProvider'] as String? ?? base.paymentProvider,
      subscriptionId:
          rootData['subscriptionId'] as String? ?? base.subscriptionId,
      paymentCustomerId: rootData['paymentCustomerId'] as String? ??
          base.paymentCustomerId,
    );
  }

  static DateTime? _timestampDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static DateTime? _dateFromRoot(
    Map<String, dynamic> data,
    String primary,
    String fallback,
  ) {
    return _timestampDate(data[primary]) ?? _timestampDate(data[fallback]);
  }
}
