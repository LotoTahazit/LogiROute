import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/owner_dashboard/models/daily_metrics.dart';
import '../services/accounting_sync_service.dart';
import '../services/company_health_service.dart';
import 'company_settings.dart';
import 'onboarding_section.dart';

/// Одна запись в блоке Recent Errors (audit + systemEvents).
class SupportErrorEntry {
  const SupportErrorEntry({
    required this.source,
    required this.type,
    required this.message,
    this.correlationId,
    this.at,
    this.id,
  });

  final String source;
  final String type;
  final String message;
  final String? correlationId;
  final DateTime? at;
  final String? id;

  bool matchesCorrelation(String filter) {
    if (filter.isEmpty) return true;
    final cid = correlationId ?? '';
    return cid.contains(filter);
  }
}

/// Bounded snapshot для Support Console (одна компания).
class SupportDiagnosticSnapshot {
  const SupportDiagnosticSnapshot({
    required this.companyId,
    required this.settings,
    required this.tenant,
    required this.metrics,
    this.nextMissingRequiredSection,
    required this.totalUsers,
    required this.fcmTokenUsers,
    required this.pendingDeliveryPoints,
    required this.cancelledDeliveryPoints,
    this.latestSyncEntry,
    required this.unreadNotifications,
    this.lastSuccessfulPayment,
    this.lastFailedPayment,
    required this.recentErrors,
    required this.auditEvents,
    required this.paymentEvents,
    required this.notifications,
    required this.pushLogs,
    required this.emailLogs,
    required this.userNames,
    required this.loadedAt,
  });

  final String companyId;
  final CompanySettings settings;
  final CompanyHealthTenantSnapshot tenant;
  final DailyMetrics metrics;
  final OnboardingSectionId? nextMissingRequiredSection;
  final int totalUsers;
  final int fcmTokenUsers;
  final int pendingDeliveryPoints;
  final int cancelledDeliveryPoints;
  final AccountingSyncEntry? latestSyncEntry;
  final int unreadNotifications;
  final Map<String, dynamic>? lastSuccessfulPayment;
  final Map<String, dynamic>? lastFailedPayment;
  final List<SupportErrorEntry> recentErrors;
  final List<Map<String, dynamic>> auditEvents;
  final List<Map<String, dynamic>> paymentEvents;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> pushLogs;
  final List<Map<String, dynamic>> emailLogs;
  final Map<String, String> userNames;
  final DateTime loadedAt;

  /// Однострочное резюме для буфера / Slack.
  String summaryLine() {
    final name = settings.nameHebrew.isNotEmpty
        ? settings.nameHebrew
        : settings.nameEnglish;
    final next = nextMissingRequiredSection?.name ?? '—';
    return '$name ($companyId) | ${settings.billingStatus} | '
        'setup ${tenant.setupPercent}% | drivers ${tenant.driverCount} | '
        'routes ${tenant.activeRoutes} | sync failed ${tenant.failedSyncCount} | '
        'stale GPS ${tenant.staleGpsDrivers} | next: $next';
  }

  static DateTime? ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
