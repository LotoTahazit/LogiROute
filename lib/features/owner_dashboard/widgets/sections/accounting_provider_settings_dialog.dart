import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// API-креды внешней бухгалтерии (Greeninvoice / iCount).
/// Хранение: companies/{companyId}/settings/accounting_credentials
class AccountingProviderSettingsDialog extends StatefulWidget {
  const AccountingProviderSettingsDialog({
    super.key,
    required this.companyId,
    required this.provider,
  });

  final String companyId;
  final String provider; // greeninvoice | icount

  @override
  State<AccountingProviderSettingsDialog> createState() =>
      _AccountingProviderSettingsDialogState();
}

class _AccountingProviderSettingsDialogState
    extends State<AccountingProviderSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _hasSaved = false;
  bool _sandbox = false;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('settings')
          .doc('accounting_credentials');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _docRef.get();
      if (snap.exists) {
        final data = snap.data() ?? {};
        _hasSaved = data['configured'] == true;
        if (widget.provider == 'icount') {
          _tokenCtrl.text = data['token'] ?? '';
        } else {
          _apiKeyCtrl.text = data['apiKey'] ?? '';
          _secretCtrl.text = data['secretKey'] ?? '';
          _sandbox = data['sandbox'] == true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ accounting credentials load: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'provider': widget.provider,
        'configured': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.provider == 'icount') {
        payload['token'] = _tokenCtrl.text.trim();
      } else {
        payload['apiKey'] = _apiKeyCtrl.text.trim();
        payload['secretKey'] = _secretCtrl.text.trim();
        if (widget.provider == 'greeninvoice') {
          payload['sandbox'] = _sandbox;
        }
      }
      await _docRef.set(payload, SetOptions(merge: true));
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountingProviderSaved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _secretCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.provider == 'icount'
        ? l10n.accountingProviderIcount
        : l10n.accountingProviderGreeninvoice;

    return AlertDialog(
      title: Text(title),
      content: _loading
          ? const SizedBox(
              width: 280,
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasSaved)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.accountingProviderConfigured,
                                style: TextStyle(
                                    color: Colors.green.shade800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.provider == 'icount')
                      TextFormField(
                        controller: _tokenCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.accountingProviderToken,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? ' ' : null,
                      )
                    else ...[
                      TextFormField(
                        controller: _apiKeyCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.accountingProviderApiKey,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? ' ' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _secretCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.accountingProviderSecret,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? ' ' : null,
                      ),
                      if (widget.provider == 'greeninvoice') ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.accountingProviderSandbox),
                          subtitle: Text(
                            l10n.accountingProviderSandboxHint,
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _sandbox,
                          onChanged: (v) => setState(() => _sandbox = v),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
