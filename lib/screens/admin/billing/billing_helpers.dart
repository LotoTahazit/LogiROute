import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/plan_limit_policy.dart';

// Plan display info: plan key → (name, promoPrice, price, setupFee, modules)

// Sync with config/billing_pricing.json

// ---------------------------------------------------------------------------



const planDisplayInfo = {

  'logistics': (

    name: 'לוגיסטיקה',

    promoPrice: '₪1,490',

    price: '₪1,990',

    setupFee: '₪2,000',

    modules: ['logistics', 'dispatcher', 'reports'],

  ),

  'warehouse_only': (

    name: 'מחסן בלבד',

    promoPrice: '₪990',

    price: '₪1,290',

    setupFee: '₪1,500',

    modules: ['warehouse'],

  ),

  'ops': (

    name: 'תפעול',

    promoPrice: '₪2,290',

    price: '₪2,990',

    setupFee: '₪3,000',

    modules: ['warehouse', 'logistics', 'dispatcher', 'reports'],

  ),

  'full': (

    name: 'מלא',

    promoPrice: '₪2,990',

    price: '₪3,990',

    setupFee: '₪5,000',

    modules: ['warehouse', 'logistics', 'dispatcher', 'accounting', 'reports'],

  ),

};



/// Доплаты сверх включённого лимита (config/billing_pricing.addons)

const billingAddons = (

  includedDrivers: 5,

  extraDriverPerMonth: 99,

  includedWarehouseLocations: 1,

  extraWarehousePerMonth: 199,

  dedicatedExportPerMonth: 149,

);



/// Планы, где облачный DR (project-level GCP backup) включён в абонплату

const backupDrIncludedPlans = ['full'];



/// Минимальный срок подписки (месяцев)

const int minSubscriptionMonths = 12;



/// Количество промо-месяцев со сниженной ценой

const int promoMonths = 3;



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



/// Keys of all modules in UI order (billing plans).

const kPlanModuleOrder = [

  'warehouse',

  'logistics',

  'dispatcher',

  'accounting',

  'reports',

];



String localizedPlanDescription(String planKey, AppLocalizations l10n) {

  switch (planKey) {

    case 'logistics':

      return l10n.planDescLogistics;

    case 'warehouse_only':

      return l10n.planDescWarehouse;

    case 'ops':

      return l10n.planDescOps;

    case 'full':

      return l10n.planDescFull;

    default:

      return l10n.planDescCustom;

  }

}



String localizedModuleName(String moduleKey, AppLocalizations l10n) {

  switch (moduleKey) {

    case 'warehouse':

      return l10n.moduleWarehouseTitle;

    case 'logistics':

      return l10n.moduleLogisticsTitle;

    case 'dispatcher':

      return l10n.moduleDispatcherTitle;

    case 'accounting':

      return l10n.moduleAccountingTitle;

    case 'reports':

      return l10n.moduleReportsTitle;

    default:

      return moduleKey;

  }

}



bool planIncludesModule(String planKey, String moduleKey) {

  return planDisplayInfo[planKey]?.modules.contains(moduleKey) ?? false;

}



/// Returns localized module list with ✓/✗ for plan comparison.

String formatPlanModulesLine(String planKey, AppLocalizations l10n) {

  return kPlanModuleOrder

      .map((m) {

        final included = planIncludesModule(planKey, m);

        final mark = included ? '✓' : '✗';

        return '$mark ${localizedModuleName(m, l10n)}';

      })

      .join(' · ');

}

List<String> availablePlans(String currentPlan) {

  return ['logistics', 'warehouse_only', 'ops', 'full']

      .where((p) => p != currentPlan)

      .toList();

}



/// Formats usage as "X / Y".

String formatUsage(int current, int max) {

  return '$current / $max';

}

String limitEnforcementLabel(LimitEnforcement e, AppLocalizations l10n) {
  switch (e) {
    case LimitEnforcement.soft:
      return l10n.limitEnforcementSoft;
    case LimitEnforcement.hard:
      return l10n.limitEnforcementHard;
    case LimitEnforcement.notEnforced:
      return l10n.limitEnforcementNotEnforced;
  }
}


