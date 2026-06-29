import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum CustomerHealthLevel { healthy, warning, critical, unknown }

enum CustomerHealthFilter { all, healthy, warning, critical, demo }

class CustomerHealthSummary {
  final String companyId;
  final String companyName;
  final String plan;
  final String billingStatus;
  final int setupPercent;
  final CustomerHealthLevel healthLevel;
  final int activeDrivers;
  final int activeRoutes;
  final int failedSyncCount;
  final int staleGpsDrivers;
  final DateTime? lastActivity;
  final int problemsCount;
  final bool isDemo;

  const CustomerHealthSummary({
    required this.companyId,
    required this.companyName,
    required this.plan,
    required this.billingStatus,
    required this.setupPercent,
    required this.healthLevel,
    required this.activeDrivers,
    required this.activeRoutes,
    required this.failedSyncCount,
    required this.staleGpsDrivers,
    this.lastActivity,
    required this.problemsCount,
    required this.isDemo,
  });

  bool matchesFilter(CustomerHealthFilter filter) {
    switch (filter) {
      case CustomerHealthFilter.all:
        return true;
      case CustomerHealthFilter.demo:
        return isDemo;
      case CustomerHealthFilter.healthy:
        return healthLevel == CustomerHealthLevel.healthy;
      case CustomerHealthFilter.warning:
        return healthLevel == CustomerHealthLevel.warning;
      case CustomerHealthFilter.critical:
        return healthLevel == CustomerHealthLevel.critical;
    }
  }
}

extension CustomerHealthLevelUi on CustomerHealthLevel {
  String label(AppLocalizations l10n) {
    switch (this) {
      case CustomerHealthLevel.healthy:
        return l10n.customerHealthHealthy;
      case CustomerHealthLevel.warning:
        return l10n.customerHealthWarning;
      case CustomerHealthLevel.critical:
        return l10n.customerHealthCritical;
      case CustomerHealthLevel.unknown:
        return l10n.customerHealthUnknown;
    }
  }

  Color color() {
    switch (this) {
      case CustomerHealthLevel.healthy:
        return Colors.green;
      case CustomerHealthLevel.warning:
        return Colors.orange;
      case CustomerHealthLevel.critical:
        return Colors.red;
      case CustomerHealthLevel.unknown:
        return Colors.grey;
    }
  }
}

/// Правила агрегированного health status (tenant-level, без FCM устройства).
CustomerHealthLevel computeCustomerHealthLevel({
  required String billingStatus,
  required int problemsCount,
  required int failedSyncCount,
  required int staleGpsDrivers,
  required int setupPercent,
  required bool fetchOk,
}) {
  if (!fetchOk) return CustomerHealthLevel.unknown;

  if (billingStatus == 'suspended' ||
      billingStatus == 'cancelled' ||
      problemsCount >= 2 ||
      failedSyncCount >= 3) {
    return CustomerHealthLevel.critical;
  }

  if (billingStatus == 'grace' ||
      problemsCount > 0 ||
      failedSyncCount > 0 ||
      staleGpsDrivers > 0 ||
      setupPercent < 100) {
    return CustomerHealthLevel.warning;
  }

  return CustomerHealthLevel.healthy;
}
