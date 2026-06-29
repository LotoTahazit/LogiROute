import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/company_settings.dart';
import '../models/customer_health_summary.dart';
import 'company_health_service.dart';
import 'demo_company_service.dart';

class CustomerHealthPage {
  const CustomerHealthPage({
    required this.rows,
    required this.hasMore,
    this.lastDocument,
  });

  final List<CustomerHealthSummary> rows;
  final bool hasMore;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
}

/// Bounded summary для Customer Health Dashboard (super_admin).
class CustomerHealthDashboardService {
  CustomerHealthDashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const pageSize = 50;
  static const batchSize = 5;

  Future<CustomerHealthPage> loadPage({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool refresh = false,
  }) async {
    var query = _firestore
        .collection('companies')
        .orderBy(FieldPath.documentId)
        .limit(pageSize);

    if (startAfter != null && !refresh) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final rows = <CustomerHealthSummary>[];

    for (var i = 0; i < snap.docs.length; i += batchSize) {
      final batch = snap.docs.skip(i).take(batchSize);
      final part = await Future.wait(batch.map(_loadCompanyRow));
      rows.addAll(part);
    }

    rows.sort((a, b) => a.companyName.compareTo(b.companyName));

    return CustomerHealthPage(
      rows: rows,
      hasMore: snap.docs.length == pageSize,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
    );
  }

  Future<CustomerHealthSummary> _loadCompanyRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final companyId = doc.id;
    final raw = doc.data();
    var fetchOk = true;
    CompanySettings settings;

    try {
      settings = CompanySettings.fromFirestore(doc);
    } catch (_) {
      fetchOk = false;
      settings = _minimalSettings(companyId, raw);
    }

    CompanyHealthTenantSnapshot tenant;
    try {
      tenant = await CompanyHealthService(
        companyId: companyId,
        companySettings: settings,
      ).fetchTenantSnapshot(settings: settings);
    } catch (_) {
      fetchOk = false;
      tenant = CompanyHealthTenantSnapshot(
        companyId: companyId,
        companyName: settings.nameHebrew.isNotEmpty
            ? settings.nameHebrew
            : settings.nameEnglish,
        plan: settings.plan,
        billingStatus: settings.billingStatus,
        setupPercent: 0,
        driverCount: 0,
        activeRoutes: 0,
        failedSyncCount: 0,
        staleGpsDrivers: 0,
        problemsCount: 0,
        accounting: HealthCheckStatus.fail,
        fetchOk: false,
      );
    }

    final isDemo =
        companyId == DemoCompanyService.companyId || raw['isDemo'] == true;

    final level = computeCustomerHealthLevel(
      billingStatus: tenant.billingStatus,
      problemsCount: tenant.problemsCount,
      failedSyncCount: tenant.failedSyncCount,
      staleGpsDrivers: tenant.staleGpsDrivers,
      setupPercent: tenant.setupPercent,
      fetchOk: fetchOk && tenant.fetchOk,
    );

    return CustomerHealthSummary(
      companyId: companyId,
      companyName: tenant.companyName.isNotEmpty
          ? tenant.companyName
          : companyId,
      plan: tenant.plan,
      billingStatus: tenant.billingStatus,
      setupPercent: tenant.setupPercent,
      healthLevel: level,
      activeDrivers: tenant.driverCount,
      activeRoutes: tenant.activeRoutes,
      failedSyncCount: tenant.failedSyncCount,
      staleGpsDrivers: tenant.staleGpsDrivers,
      lastActivity: tenant.lastActivity,
      problemsCount: tenant.problemsCount,
      isDemo: isDemo,
    );
  }

  CompanySettings _minimalSettings(String id, Map<String, dynamic> raw) {
    return CompanySettings(
      id: id,
      nameHebrew: raw['nameHebrew'] as String? ?? '',
      nameEnglish: raw['nameEnglish'] as String? ?? id,
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
      plan: raw['plan'] as String? ?? '—',
      billingStatus: raw['billingStatus'] as String? ?? 'unknown',
    );
  }
}
