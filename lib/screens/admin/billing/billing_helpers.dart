import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Plan display info: plan key → (name, price, modules)
// ---------------------------------------------------------------------------

const planDisplayInfo = {
  'warehouse_only': (
    name: 'מחסן בלבד',
    price: '₪149',
    modules: ['warehouse'],
  ),
  'ops': (
    name: 'תפעול',
    price: '₪299',
    modules: ['warehouse', 'logistics', 'dispatcher'],
  ),
  'full': (
    name: 'מלא',
    price: '₪499',
    modules: ['warehouse', 'logistics', 'dispatcher', 'accounting', 'reports'],
  ),
  'custom': (
    name: 'מותאם אישית',
    price: '—',
    modules: <String>[],
  ),
};

// ---------------------------------------------------------------------------
// Status → Color mapping (Colors are not const, so we use final)
// ---------------------------------------------------------------------------

final statusColors = <String, Color>{
  'active': Colors.green,
  'trial': Colors.blue,
  'grace': Colors.orange,
  'suspended': Colors.red,
  'cancelled': Colors.grey,
};

// ---------------------------------------------------------------------------
// Usage warning level enum
// ---------------------------------------------------------------------------

enum UsageWarningLevel { normal, warning, critical }

// ---------------------------------------------------------------------------
// Pure functions
// ---------------------------------------------------------------------------

/// Returns the difference in days between [paidUntil] and [now].
/// Future dates → positive, past dates → negative or zero.
int remainingDays(DateTime paidUntil, DateTime now) {
  return paidUntil.difference(now).inDays;
}

/// Determines the warning level based on [current] usage vs [max] limit.
/// Requires [max] > 0.
UsageWarningLevel usageWarningLevel(int current, int max) {
  assert(max > 0, 'max must be > 0');
  final ratio = current / max;
  if (ratio >= 1.0) return UsageWarningLevel.critical;
  if (ratio >= 0.8) return UsageWarningLevel.warning;
  return UsageWarningLevel.normal;
}

/// Returns available plans excluding [currentPlan] and 'custom'.
List<String> availablePlans(String currentPlan) {
  return ['warehouse_only', 'ops', 'full']
      .where((p) => p != currentPlan)
      .toList();
}

/// Formats usage as "X / Y".
String formatUsage(int current, int max) {
  return '$current / $max';
}
