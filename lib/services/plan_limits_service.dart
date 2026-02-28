import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_settings.dart';

/// Мягкий контроль лимитов по тарифу.
/// Не блокирует — только предупреждает + отчёт.
///
/// Планы:
///   warehouse_only (₪149): 5 users, 500 docs/month, 10 routes/day
///   ops (₪299): 15 users, 2000 docs/month, 50 routes/day
///   full (₪499): 50 users, 10000 docs/month, 200 routes/day
///   custom: без лимитов (999/99999/999)
class PlanLimitsService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PlanLimitsService({required this.companyId});

  /// Дефолтные лимиты по плану (если не заданы в company doc)
  static PlanLimits defaultLimitsForPlan(String plan) {
    switch (plan) {
      case 'warehouse_only':
        return const PlanLimits(
            maxUsers: 5, maxDocsPerMonth: 500, maxRoutesPerDay: 10);
      case 'ops':
        return const PlanLimits(
            maxUsers: 15, maxDocsPerMonth: 2000, maxRoutesPerDay: 50);
      case 'full':
        return const PlanLimits(
            maxUsers: 50, maxDocsPerMonth: 10000, maxRoutesPerDay: 200);
      default: // custom
        return const PlanLimits();
    }
  }

  /// Проверка текущего использования vs лимиты
  Future<PlanUsageReport> checkUsage() async {
    final companyDoc =
        await _firestore.collection('companies').doc(companyId).get();
    final data = companyDoc.data() ?? {};
    final plan = data['plan'] ?? 'full';
    final limits = data['limits'] != null
        ? PlanLimits.fromMap(data['limits'] as Map<String, dynamic>)
        : defaultLimitsForPlan(plan);

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
      usersWarning: users >= limits.maxUsers,
      usersNearLimit: users >= (limits.maxUsers * 0.8).round(),
      docsWarning: docs >= limits.maxDocsPerMonth,
      docsNearLimit: docs >= (limits.maxDocsPerMonth * 0.8).round(),
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
