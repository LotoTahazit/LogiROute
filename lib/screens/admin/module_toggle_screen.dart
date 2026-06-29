import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/company_modules_service.dart';
import '../../services/cross_module_audit_service.dart';
import '../../services/firestore_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'billing/billing_helpers.dart';

/// מסך ניהול מודולים — בחירת תוכנית → מודולים נקבעים אוטומטית
/// super_admin only
class ModuleToggleScreen extends StatefulWidget {
  const ModuleToggleScreen({super.key});

  @override
  State<ModuleToggleScreen> createState() => _ModuleToggleScreenState();
}

class _ModuleToggleScreenState extends State<ModuleToggleScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _companyId;
  String _plan = 'full';

  static const _moduleKeys = CompanyModulesService.moduleKeys;

  static const _moduleIcons = {
    'warehouse': Icons.warehouse,
    'logistics': Icons.local_shipping,
    'dispatcher': Icons.map,
    'accounting': Icons.receipt_long,
    'reports': Icons.analytics,
  };

  static const _planPriceLabel = {
    'warehouse_only': '₪990 → ₪1,290',
    'logistics': '₪1,490 → ₪1,990',
    'ops': '₪2,290 → ₪2,990',
    'full': '₪2,990 → ₪3,990',
  };

  static const _planIconMap = {
    'logistics': Icons.local_shipping_outlined,
    'warehouse_only': Icons.warehouse,
    'ops': Icons.inventory_2_outlined,
    'full': Icons.all_inclusive,
  };

  Map<String, bool> get _currentModules => Map<String, bool>.from(
        CompanyModulesService.planModules[_plan] ??
            CompanyModulesService.planModules['full']!,
      );

  String _moduleName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'warehouse':
        return l10n.moduleWarehouse;
      case 'logistics':
        return l10n.moduleLogistics;
      case 'dispatcher':
        return l10n.moduleDispatcher;
      case 'accounting':
        return l10n.moduleAccounting;
      case 'reports':
        return l10n.moduleReports;
      default:
        return key;
    }
  }

  String _moduleDesc(String key, AppLocalizations l10n) {
    switch (key) {
      case 'warehouse':
        return l10n.moduleWarehouseDesc;
      case 'logistics':
        return l10n.moduleLogisticsDesc;
      case 'dispatcher':
        return l10n.moduleDispatcherDesc;
      case 'accounting':
        return l10n.moduleAccountingDesc;
      case 'reports':
        return l10n.moduleReportsDesc;
      default:
        return '';
    }
  }

  String _planName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'logistics':
        return l10n.planLogistics;
      case 'warehouse_only':
        return l10n.planWarehouseOnly;
      case 'ops':
        return l10n.planOps;
      case 'full':
        return l10n.planFull;
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final ctx = CompanyContext.of(context);
    final id = ctx.effectiveCompanyId;
    if (id == null || id.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _companyId = id;

    final rootSnap =
        await FirestorePaths(firestore: _firestore).companyDoc(id).get();
    final data = rootSnap.data() ?? {};

    setState(() {
      _plan = CompanyModulesService.normalizePlan(data['plan'] as String?);
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_companyId == null) return;
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid ?? 'unknown';

      await CompanyModulesService(companyId: _companyId!).applyPlan(_plan);

      await FirestorePaths(firestore: _firestore).audit(_companyId!).add({
        'moduleKey': 'admin',
        'type': CrossModuleAuditService.typeBillingStatusChanged,
        'entity': {'collection': 'companies', 'docId': _companyId},
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'reason': 'Plan changed to $_plan',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.planUpdatedSuccess),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moduleManagementTitle),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Plan selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.planLabel,
                              style: Theme.of(context).textTheme.titleMedium),
                          RadioGroup<String>(
                            groupValue: _plan,
                            onChanged: (v) =>
                                setState(() => _plan = v ?? _plan),
                            child: Column(
                              children: CompanyModulesService.planModules.keys
                                  .map((planKey) {
                                final isSelected = _plan == planKey;
                                final label = _planName(planKey, l10n);
                                final icon =
                                    _planIconMap[planKey] ?? Icons.help;
                                final price =
                                    _planPriceLabel[planKey] ?? '';
                                return ListTile(
                                  leading: Radio<String>(value: planKey),
                                  title: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Icon(icon,
                                          size: 20,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.grey),
                                      Text(label,
                                          style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ],
                                  ),
                                  subtitle: Text(price,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.muted)),
                                  selected: isSelected,
                                  selectedTileColor: Colors.blue.shade50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.transparent),
                                  ),
                                  onTap: () => setState(() => _plan = planKey),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Modules (read-only, determined by plan)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.modulesInPlan,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ..._moduleKeys.map((key) {
                            final enabled = _currentModules[key] ?? false;
                            final icon = _moduleIcons[key] ?? Icons.help;
                            return ListTile(
                              leading: Icon(icon,
                                  color:
                                      enabled ? Colors.blue : AppTheme.surfaceHi),
                              title: Text(_moduleName(key, l10n),
                                  style: TextStyle(
                                      color: enabled
                                          ? null
                                          : Colors.grey.shade400)),
                              subtitle: Text(_moduleDesc(key, l10n),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: enabled
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade300)),
                              trailing: Icon(
                                enabled
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                color:
                                    enabled ? Colors.green : AppTheme.surfaceHi,
                              ),
                              dense: true,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.billingAddonsTitle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.billingExtraDriverMonthly(
                              billingAddons.extraDriverPerMonth,
                              billingAddons.includedDrivers,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.billingExtraWarehouseMonthly(
                              billingAddons.extraWarehousePerMonth,
                              billingAddons.includedWarehouseLocations,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.billingDedicatedExportMonthly(
                              billingAddons.dedicatedExportPerMonth,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: narrow ? 260 : 520),
                            child: Text(
                              l10n.moduleToggleInfo,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
