import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_settings.dart';
import '../models/plan_limit_policy.dart';
import 'firestore_paths.dart';

/// Мягкий контроль лимитов по тарифу (H5).
/// Источник значений: `companies/{id}.limits` (applyPlan) → fallback по plan.
class PlanLimitsService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PlanLimitsService({required this.companyId});

  static String normalizePlan(String? plan) {
    const known = {'warehouse_only', 'logistics', 'ops', 'full'};
    return known.contains(plan) ? plan! : 'full';
  }

  /// Лимиты из root doc или fallback по plan (без magic 999/99999).
  static PlanLimits resolveLimits({
    Map<String, dynamic>? limitsMap,
    required String plan,
  }) =>
      PlanLimits.fromMap(limitsMap, plan: plan);

  static PlanLimits defaultLimitsForPlan(String plan) =>
      PlanLimits.fromMap(null, plan: normalizePlan(plan));

  /// Проверка текущего использования vs лимиты
  Future<PlanUsageReport> checkUsage() async {
    final companyDoc =
        await FirestorePaths(firestore: _firestore).companyDoc(companyId).get();
    final data = companyDoc.data() ?? {};
    final plan = normalizePlan(data['plan'] as String?);
    final limits = PlanLimitsService.resolveLimits(
      limitsMap: data['limits'] != null
          ? Map<String, dynamic>.from(data['limits'] as Map)
          : null,
      plan: plan,
    );

    // Count users
    final usersCount = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .count()
        .get();

    // Count docs this month
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final docsCount = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(monthStart))
        .count()
        .get();

    final users = usersCount.count ?? 0;
    final docs = docsCount.count ?? 0;

    return PlanUsageReport(
      plan: plan,
      limits: limits,
      currentUsers: users,
      currentDocsThisMonth: docs,
      usersWarning: PlanLimitPolicy.isOverLimit(users, limits.maxUsers),
      usersNearLimit: PlanLimitPolicy.isNearLimit(users, limits.maxUsers),
      docsWarning: PlanLimitPolicy.isOverLimit(docs, limits.maxDocsPerMonth),
      docsNearLimit:
          PlanLimitPolicy.isNearLimit(docs, limits.maxDocsPerMonth),
    );
  }
}

/// Отчёт об использовании лимитов
class PlanUsageReport {
  final String plan;
  final PlanLimits limits;
  final int currentUsers;
  final int currentDocsThisMonth;
  final bool usersWarning;
  final bool usersNearLimit;
  final bool docsWarning;
  final bool docsNearLimit;

  const PlanUsageReport({
    required this.plan,
    required this.limits,
    required this.currentUsers,
    required this.currentDocsThisMonth,
    required this.usersWarning,
    required this.usersNearLimit,
    required this.docsWarning,
    required this.docsNearLimit,
  });

  bool get hasWarnings => usersWarning || docsWarning;
  bool get hasNearLimits => usersNearLimit || docsNearLimit;

  String get summary {
    if (hasWarnings) {
      final issues = <String>[];
      if (usersWarning) {
        issues.add('Users: $currentUsers/${limits.maxUsers}');
      }
      if (docsWarning) {
        issues.add('Docs: $currentDocsThisMonth/${limits.maxDocsPerMonth}');
      }
      return '⚠️ Limit reached: ${issues.join(', ')}';
    }
    if (hasNearLimits) {
      return '⚡ Approaching limits';
    }
    return '✅ Within limits';
  }
}
