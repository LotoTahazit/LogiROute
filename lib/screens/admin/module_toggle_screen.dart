import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';

/// מסך ניהול מודולים — הפעלה/כיבוי מודולים לכל חברה
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
  Map<String, bool> _modules = {};

  static const _moduleInfo = {
    'warehouse':
        _ModInfo('מחסן', 'ניהול מלאי, ספירות, סוגי אריזות', Icons.warehouse),
    'logistics': _ModInfo(
        'לוגיסטיקה', 'נקודות משלוח, מסלולים, מפה', Icons.local_shipping),
    'dispatcher': _ModInfo("דיספצ'ר", 'ניהול נהגים, חלוקה אוטומטית', Icons.map),
    'accounting': _ModInfo(
        'הנהלת חשבונות', 'חשבוניות, קבלות, זיכויים, ייצוא', Icons.receipt_long),
    'reports': _ModInfo(
        'דוחות', 'סטטיסטיקות משלוחים, חשבוניות, נהגים', Icons.analytics),
  };

  static const _planPresets = {
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

  static const _planLabels = {
    'warehouse_only': 'מחסן בלבד (₪149/חודש)',
    'ops': 'תפעול (₪299/חודש)',
    'full': 'מלא (₪499/חודש)',
    'custom': 'מותאם אישית',
  };

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

    final snap = await _firestore
        .collection('companies')
        .doc(id)
        .collection('settings')
        .doc('settings')
        .get();
    final data = snap.data() ?? {};
    final modulesMap = data['modules'] as Map<String, dynamic>? ?? {};

    setState(() {
      _plan = data['plan'] as String? ?? 'full';
      _modules = {
        'warehouse': modulesMap['warehouse'] ?? true,
        'logistics': modulesMap['logistics'] ?? true,
        'dispatcher': modulesMap['dispatcher'] ?? true,
        'accounting': modulesMap['accounting'] ?? true,
        'reports': modulesMap['reports'] ?? true,
      };
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_companyId == null) return;
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid ?? 'unknown';

      await _firestore
          .collection('companies')
          .doc(_companyId!)
          .collection('settings')
          .doc('settings')
          .update({
        'modules': _modules,
        'plan': _plan,
      });

      // Audit
      await _firestore
          .collection('companies')
          .doc(_companyId!)
          .collection('audit')
          .add({
        'moduleKey': 'admin',
        'type': 'billing_status_changed',
        'entity': {'collection': 'companies', 'docId': _companyId},
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'reason': 'Module toggle: plan=$_plan, modules=$_modules',
      });

      // Also update the company doc plan field
      await _firestore.collection('companies').doc(_companyId!).update({
        'plan': _plan,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('המודולים עודכנו בהצלחה'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyPlan(String plan) {
    final preset = _planPresets[plan];
    if (preset != null) {
      setState(() {
        _plan = plan;
        _modules = Map.from(preset);
      });
    } else {
      setState(() => _plan = plan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול מודולים'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('שמור', style: TextStyle(color: Colors.white)),
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
                          Text('תוכנית',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _planLabels.entries.map((e) {
                              final isSelected = _plan == e.key;
                              return ChoiceChip(
                                label: Text(e.value),
                                selected: isSelected,
                                onSelected: (_) => _applyPlan(e.key),
                                selectedColor: Colors.blue.shade100,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Module toggles
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('מודולים',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ..._moduleInfo.entries.map((e) {
                            final key = e.key;
                            final info = e.value;
                            final enabled = _modules[key] ?? true;
                            final isDep = key == 'dispatcher' &&
                                !(_modules['logistics'] ?? true);

                            return SwitchListTile(
                              secondary: Icon(info.icon,
                                  color: enabled ? Colors.blue : Colors.grey),
                              title: Text(info.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(info.description,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                  if (isDep)
                                    Text('דורש מודול לוגיסטיקה',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red.shade400)),
                                ],
                              ),
                              value: enabled && !isDep,
                              onChanged: isDep
                                  ? null
                                  : (v) {
                                      setState(() {
                                        _modules[key] = v;
                                        _plan = 'custom';
                                        // If logistics disabled, also disable dispatcher
                                        if (key == 'logistics' && !v) {
                                          _modules['dispatcher'] = false;
                                        }
                                      });
                                    },
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
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'שינויים ייכנסו לתוקף מיד. משתמשים שמנסים לגשת למודול מושבת יראו מסך "מודול לא זמין".',
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

class _ModInfo {
  final String name;
  final String description;
  final IconData icon;
  const _ModInfo(this.name, this.description, this.icon);
}
