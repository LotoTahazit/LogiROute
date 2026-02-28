import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/company_context.dart';
import '../../services/cross_module_audit_service.dart';
import '../../services/auth_service.dart';

/// Admin screen for managing billing status and accounting period lock.
/// Reads/writes directly to companies/{companyId} document.
class BillingLocksScreen extends StatefulWidget {
  const BillingLocksScreen({super.key});

  @override
  State<BillingLocksScreen> createState() => _BillingLocksScreenState();
}

class _BillingLocksScreenState extends State<BillingLocksScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _companyId;

  // Billing fields
  String _billingStatus = 'active';
  DateTime? _trialUntil;
  DateTime? _accountingLockedUntil;
  DateTime? _paidUntil;
  String? _paymentProvider;
  int _gracePeriodDays = 7;

  // Предыдущие значения для audit delta
  String _prevBillingStatus = 'active';
  DateTime? _prevTrialUntil;
  DateTime? _prevAccountingLockedUntil;
  DateTime? _prevPaidUntil;

  static const _statuses = [
    'trial',
    'active',
    'grace',
    'suspended',
    'cancelled'
  ];
  static const _statusLabels = {
    'trial': '🧪 Trial',
    'active': '✅ Active',
    'grace': '⏳ Grace',
    'suspended': '🚫 Suspended',
    'cancelled': '❌ Cancelled',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DocumentReference _companyDoc(String id) =>
      _firestore.collection('companies').doc(id);

  Future<void> _load() async {
    final ctx = CompanyContext.of(context);
    final id = ctx.effectiveCompanyId;
    if (id == null || id.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _companyId = id;
    try {
      final snap = await _companyDoc(id).get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      setState(() {
        _billingStatus = data['billingStatus'] ?? 'active';
        _trialUntil = data['trialUntil'] != null
            ? (data['trialUntil'] as Timestamp).toDate()
            : null;
        _accountingLockedUntil = data['accountingLockedUntil'] != null
            ? (data['accountingLockedUntil'] as Timestamp).toDate()
            : null;
        _paidUntil = data['paidUntil'] != null
            ? (data['paidUntil'] as Timestamp).toDate()
            : null;
        _paymentProvider = data['paymentProvider'] as String?;
        _gracePeriodDays = data['gracePeriodDays'] as int? ?? 7;
        _prevBillingStatus = _billingStatus;
        _prevTrialUntil = _trialUntil;
        _prevAccountingLockedUntil = _accountingLockedUntil;
        _prevPaidUntil = _paidUntil;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (_companyId == null) return;
    setState(() => _isSaving = true);
    try {
      final updates = <String, dynamic>{
        'billingStatus': _billingStatus,
        'trialUntil':
            _trialUntil != null ? Timestamp.fromDate(_trialUntil!) : null,
        'accountingLockedUntil': _accountingLockedUntil != null
            ? Timestamp.fromDate(_accountingLockedUntil!)
            : null,
        'paidUntil':
            _paidUntil != null ? Timestamp.fromDate(_paidUntil!) : null,
        'paymentProvider': _paymentProvider,
        'gracePeriodDays': _gracePeriodDays,
      };
      await _companyDoc(_companyId!).update(updates);

      // Audit: логируем только изменённые поля
      final audit = CrossModuleAuditService(companyId: _companyId!);
      final uid = context.read<AuthService>().currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        if (_billingStatus != _prevBillingStatus) {
          audit.log(
            moduleKey: 'accounting',
            type: 'billing_status_changed',
            entityCollection: 'billing',
            entityDocId: _companyId!,
            uid: uid,
          );
        }
        if (_trialUntil != _prevTrialUntil) {
          audit.log(
            moduleKey: 'accounting',
            type: 'trial_until_changed',
            entityCollection: 'billing',
            entityDocId: _companyId!,
            uid: uid,
          );
        }
        if (_accountingLockedUntil != _prevAccountingLockedUntil) {
          audit.log(
            moduleKey: 'accounting',
            type: 'accounting_locked_until_changed',
            entityCollection: 'billing',
            entityDocId: _companyId!,
            uid: uid,
          );
        }
        if (_paidUntil != _prevPaidUntil) {
          audit.log(
            moduleKey: 'billing',
            type: 'billing_status_changed',
            entityCollection: 'billing',
            entityDocId: _companyId!,
            uid: uid,
            extra: {'reason': 'Manual paidUntil change'},
          );
        }
      }

      // Обновляем prev-значения
      _prevBillingStatus = _billingStatus;
      _prevTrialUntil = _trialUntil;
      _prevAccountingLockedUntil = _accountingLockedUntil;
      _prevPaidUntil = _paidUntil;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate(
      DateTime? current, ValueChanged<DateTime?> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Locks'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: _save),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Billing Status ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Billing Status',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _statuses.contains(_billingStatus)
                              ? _billingStatus
                              : 'active',
                          items: _statuses
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(_statusLabels[s] ?? s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _billingStatus = v ?? 'active'),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Status'),
                        ),
                        if (_billingStatus == 'suspended' ||
                            _billingStatus == 'cancelled')
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                '⚠️ Users will lose all access (read + write blocked)',
                                style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // --- Trial Until ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trial Period',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'When billingStatus = trial, access expires after this date.'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _trialUntil != null
                                    ? '${_trialUntil!.day}.${_trialUntil!.month}.${_trialUntil!.year}'
                                    : 'Not set',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Pick'),
                              onPressed: () => _pickDate(_trialUntil,
                                  (d) => setState(() => _trialUntil = d)),
                            ),
                            if (_trialUntil != null)
                              IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.red),
                                onPressed: () =>
                                    setState(() => _trialUntil = null),
                              ),
                          ],
                        ),
                        if (_billingStatus == 'trial' &&
                            _trialUntil != null &&
                            _trialUntil!.isBefore(DateTime.now()))
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                '⚠️ Trial has expired — access is blocked',
                                style: TextStyle(color: Colors.orange)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // --- Paid Until (Payment) ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment — Paid Until',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'Source of truth for billing automation. After this date → grace → suspended.'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _paidUntil != null
                                    ? '${_paidUntil!.day}.${_paidUntil!.month}.${_paidUntil!.year}'
                                    : 'Not set',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.payment),
                              label: const Text('Pick'),
                              onPressed: () => _pickDate(_paidUntil,
                                  (d) => setState(() => _paidUntil = d)),
                            ),
                            if (_paidUntil != null)
                              IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.red),
                                onPressed: () =>
                                    setState(() => _paidUntil = null),
                              ),
                          ],
                        ),
                        if (_paidUntil != null &&
                            _paidUntil!.isBefore(DateTime.now()))
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                '⚠️ Payment expired — billingEnforcer will transition to grace/suspended',
                                style: TextStyle(color: Colors.orange)),
                          ),
                        const SizedBox(height: 16),
                        // Payment provider
                        DropdownButtonFormField<String?>(
                          value: _paymentProvider,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Not set')),
                            ...[
                              'stripe',
                              'tranzila',
                              'payplus',
                              'yaad',
                              'manual'
                            ].map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                          ],
                          onChanged: (v) =>
                              setState(() => _paymentProvider = v),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Payment Provider'),
                        ),
                        const SizedBox(height: 12),
                        // Grace period days
                        Row(
                          children: [
                            const Text('Grace period: '),
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                initialValue: _gracePeriodDays.toString(),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final n = int.tryParse(v);
                                  if (n != null && n >= 0) {
                                    _gracePeriodDays = n;
                                  }
                                },
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const Text(' days'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // --- Accounting Period Lock ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Accounting Period Lock',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'Documents with deliveryDate ≤ this date cannot be created or modified.'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _accountingLockedUntil != null
                                    ? '${_accountingLockedUntil!.day}.${_accountingLockedUntil!.month}.${_accountingLockedUntil!.year}'
                                    : 'Not set (all periods open)',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.lock_clock),
                              label: const Text('Pick'),
                              onPressed: () => _pickDate(
                                  _accountingLockedUntil,
                                  (d) => setState(
                                      () => _accountingLockedUntil = d)),
                            ),
                            if (_accountingLockedUntil != null)
                              IconButton(
                                icon: const Icon(Icons.lock_open,
                                    color: Colors.green),
                                tooltip: 'Unlock all periods',
                                onPressed: () => setState(
                                    () => _accountingLockedUntil = null),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // --- Company ID info ---
                Text('Company: $_companyId',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
    );
  }
}
