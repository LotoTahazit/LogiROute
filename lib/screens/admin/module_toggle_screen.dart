import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/cross_module_audit_service.dart';
import '../../services/firestore_paths.dart';
import '../../l10n/app_localizations.dart';

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

  static const _moduleKeys = [
    'warehouse',
    'logistics',
    'dispatcher',
    'accounting',
    'reports'
  ];

  static const _moduleIcons = {
    'warehouse': Icons.warehouse,
    'logistics': Icons.local_shipping,
    'dispatcher': Icons.map,
    'accounting': Icons.receipt_long,
    'reports': Icons.analytics,
  };

  /// Модули определяются планом — без ручного переключения
  static const _planModules = {
    'warehouse_only': {
      'warehouse': true,
      'logistics': false,
      'dispatcher': false,
      'accounting': false,
      'reports': false
    },
    'ops': {
      'warehouse': true,
      'logistics': true,
      'dispatcher': true,
      'accounting': false,
      'reports': true
    },
    'full': {
      'warehouse': true,
      'logistics': true,
      'dispatcher': true,
      'accounting': true,
      'reports': true
    },
  };

  static const _planIconMap = {
    'warehouse_only': Icons.warehouse,
    'ops': Icons.local_shipping,
    'full': Icons.all_inclusive,
  };

  Map<String, bool> get _currentModules =>
      _planModules[_plan] ?? _planModules['full']!;

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

    final snap = await FirestorePaths(firestore: _firestore)
        .companySettings(id)
        .doc('settings')
        .get();
    final data = snap.data() ?? {};

    setState(() {
      final savedPlan = data['plan'] as String? ?? 'full';
      _plan = _planModules.containsKey(savedPlan) ? savedPlan : 'full';
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

      await FirestorePaths(firestore: _firestore)
          .companySettings(_companyId!)
          .doc('settings')
          .update({'modules': _currentModules, 'plan': _plan});

      await FirestorePaths(firestore: _firestore).audit(_companyId!).add({
        'moduleKey': 'admin',
        'type': CrossModuleAuditService.typeBillingStatusChanged,
        'entity': {'collection': 'companies', 'docId': _companyId},
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'reason': 'Plan changed to $_plan',
      });

      await FirestorePaths(firestore: _firestore).companyDoc(_companyId!).update({
        'plan': _plan,
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
                              children: _planModules.keys.map((planKey) {
                                final isSelected = _plan == planKey;
                                final label = _planName(planKey, l10n);
                                final icon =
                                    _planIconMap[planKey] ?? Icons.help;
                                // Prices are fixed, not translatable
                                final price = planKey == 'warehouse_only'
                                    ? '₪450 → ₪1,490'
                                    : planKey == 'ops'
                                        ? '₪890 → ₪2,900'
                                        : '₪1,490 → ₪4,900';
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
                                          color: Colors.grey.shade600)),
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
                                      enabled ? Colors.blue : Colors.grey[300]),
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
                                    enabled ? Colors.green : Colors.grey[300],
                              ),
                              dense: true,
                            );
                          }),
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
