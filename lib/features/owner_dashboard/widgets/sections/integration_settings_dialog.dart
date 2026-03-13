import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

/// Диалог настройки интеграции.
///
/// Хранит данные в companies/{companyId}/settings/integrations
/// в виде map: { print: {...}, email: {...}, whatsapp: {...}, apiKeys: {...} }
class IntegrationSettingsDialog extends StatefulWidget {
  final String companyId;
  final String integrationKey; // print | email | whatsapp | apiKeys
  final String integrationLabel;

  const IntegrationSettingsDialog({
    super.key,
    required this.companyId,
    required this.integrationKey,
    required this.integrationLabel,
  });

  @override
  State<IntegrationSettingsDialog> createState() =>
      _IntegrationSettingsDialogState();
}

class _IntegrationSettingsDialogState extends State<IntegrationSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;

  // Print controllers
  final _printerIpCtrl = TextEditingController();
  final _printerPortCtrl = TextEditingController(text: '9100');
  final _printerModelCtrl = TextEditingController();
  String _paperSize = 'A4';

  // Email controllers
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController(text: '587');
  final _smtpUserCtrl = TextEditingController();
  final _smtpPasswordCtrl = TextEditingController();
  final _smtpFromCtrl = TextEditingController();
  bool _smtpSsl = true;

  // WhatsApp controllers
  final _waApiUrlCtrl = TextEditingController();
  final _waApiKeyCtrl = TextEditingController();
  final _waPhoneIdCtrl = TextEditingController();

  // API Keys
  String? _apiKeyValue;

  DocumentReference get _docRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.companyId)
      .collection('settings')
      .doc('integrations');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snap = await _docRef.get();
      if (snap.exists) {
        final all = snap.data() as Map<String, dynamic>? ?? {};
        final section =
            all[widget.integrationKey] as Map<String, dynamic>? ?? {};
        _enabled = section['enabled'] == true;
        _populateControllers(section);
      }
    } catch (e) {
      debugPrint('⚠️ [IntegrationDialog] Error loading settings: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _populateControllers(Map<String, dynamic> d) {
    switch (widget.integrationKey) {
      case 'print':
        _printerIpCtrl.text = d['ip'] ?? '';
        _printerPortCtrl.text = (d['port'] ?? 9100).toString();
        _printerModelCtrl.text = d['model'] ?? '';
        _paperSize = d['paperSize'] ?? 'A4';
      case 'email':
        _smtpHostCtrl.text = d['smtpHost'] ?? '';
        _smtpPortCtrl.text = (d['smtpPort'] ?? 587).toString();
        _smtpUserCtrl.text = d['smtpUser'] ?? '';
        _smtpPasswordCtrl.text = d['smtpPassword'] ?? '';
        _smtpFromCtrl.text = d['smtpFrom'] ?? '';
        _smtpSsl = d['smtpSsl'] ?? true;
      case 'whatsapp':
        _waApiUrlCtrl.text = d['apiUrl'] ?? '';
        _waApiKeyCtrl.text = d['apiKey'] ?? '';
        _waPhoneIdCtrl.text = d['phoneId'] ?? '';
      case 'apiKeys':
        _apiKeyValue = d['key'];
    }
  }

  Map<String, dynamic> _collectData() {
    final base = {'enabled': _enabled};
    switch (widget.integrationKey) {
      case 'print':
        return {
          ...base,
          'ip': _printerIpCtrl.text.trim(),
          'port': int.tryParse(_printerPortCtrl.text) ?? 9100,
          'model': _printerModelCtrl.text.trim(),
          'paperSize': _paperSize,
        };
      case 'email':
        return {
          ...base,
          'smtpHost': _smtpHostCtrl.text.trim(),
          'smtpPort': int.tryParse(_smtpPortCtrl.text) ?? 587,
          'smtpUser': _smtpUserCtrl.text.trim(),
          'smtpPassword': _smtpPasswordCtrl.text.trim(),
          'smtpFrom': _smtpFromCtrl.text.trim(),
          'smtpSsl': _smtpSsl,
        };
      case 'whatsapp':
        return {
          ...base,
          'apiUrl': _waApiUrlCtrl.text.trim(),
          'apiKey': _waApiKeyCtrl.text.trim(),
          'phoneId': _waPhoneIdCtrl.text.trim(),
        };
      case 'apiKeys':
        return {
          ...base,
          'key': _apiKeyValue,
        };
      default:
        return base;
    }
  }

  Future<void> _testIntegration() async {
    // Сначала сохраним текущие настройки
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _docRef.set(
        {widget.integrationKey: _collectData()},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
        setState(() => _saving = false);
      }
      return;
    }

    try {
      switch (widget.integrationKey) {
        case 'email':
          final callable =
              FirebaseFunctions.instance.httpsCallable('sendCompanyEmail');
          await callable.call({
            'companyId': widget.companyId,
            'to': [_smtpFromCtrl.text.trim()],
            'subject': 'LogiRoute - Test Email',
            'html':
                '<div dir="rtl"><h2>בדיקת חיבור</h2><p>אם אתה רואה הודעה זו, חיבור הדוא"ל עובד.</p></div>',
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('✅ Test email sent'),
                  backgroundColor: Colors.green),
            );
          }
        case 'whatsapp':
          final callable =
              FirebaseFunctions.instance.httpsCallable('sendWhatsApp');
          await callable.call({
            'companyId': widget.companyId,
            'phone': _waPhoneIdCtrl.text.trim(),
            'message': 'LogiRoute - בדיקת חיבור WhatsApp ✅',
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('✅ Test WhatsApp sent'),
                  backgroundColor: Colors.green),
            );
          }
        default:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Test failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _docRef.set(
        {widget.integrationKey: _collectData()},
        SetOptions(merge: true),
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.integrationSaved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.integrationSaveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _generateApiKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    setState(() => _apiKeyValue = key);
  }

  @override
  void dispose() {
    _printerIpCtrl.dispose();
    _printerPortCtrl.dispose();
    _printerModelCtrl.dispose();
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    _smtpUserCtrl.dispose();
    _smtpPasswordCtrl.dispose();
    _smtpFromCtrl.dispose();
    _waApiUrlCtrl.dispose();
    _waApiKeyCtrl.dispose();
    _waPhoneIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.integrationDialogTitle(widget.integrationLabel)),
      content: _loading
          ? const SizedBox(
              width: 300,
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: Text(l10n.integrationEnabled),
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                      const Divider(),
                      ..._buildFields(context),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        if (widget.integrationKey == 'email' ||
            widget.integrationKey == 'whatsapp')
          OutlinedButton.icon(
            onPressed: _saving ? null : _testIntegration,
            icon: const Icon(Icons.send, size: 16),
            label: Text(l10n.integrationTestConnection),
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

  List<Widget> _buildFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.integrationKey) {
      case 'print':
        return [
          _field(_printerIpCtrl, l10n.integrationPrinterIp),
          _field(_printerPortCtrl, l10n.integrationPrinterPort,
              keyboard: TextInputType.number),
          _field(_printerModelCtrl, l10n.integrationPrinterModel),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _paperSize,
            decoration: InputDecoration(
              labelText: l10n.integrationPrinterPaperSize,
              border: const OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'A4', child: Text('A4')),
              DropdownMenuItem(value: 'A5', child: Text('A5')),
              DropdownMenuItem(value: '80mm', child: Text('80mm (receipt)')),
            ],
            onChanged: (v) => setState(() => _paperSize = v ?? 'A4'),
          ),
        ];
      case 'email':
        return [
          _field(_smtpHostCtrl, l10n.integrationSmtpHost),
          _field(_smtpPortCtrl, l10n.integrationSmtpPort,
              keyboard: TextInputType.number),
          _field(_smtpUserCtrl, l10n.integrationSmtpUser),
          _field(_smtpPasswordCtrl, l10n.integrationSmtpPassword,
              obscure: true),
          _field(_smtpFromCtrl, l10n.integrationSmtpFrom,
              keyboard: TextInputType.emailAddress),
          SwitchListTile(
            title: Text(l10n.integrationSmtpSsl),
            value: _smtpSsl,
            onChanged: (v) => setState(() => _smtpSsl = v),
          ),
        ];
      case 'whatsapp':
        return [
          _field(_waApiUrlCtrl, l10n.integrationWhatsappApiUrl,
              keyboard: TextInputType.url),
          _field(_waApiKeyCtrl, l10n.integrationWhatsappApiKey),
          _field(_waPhoneIdCtrl, l10n.integrationWhatsappPhoneId),
        ];
      case 'apiKeys':
        return [
          if (_apiKeyValue != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _apiKeyValue!,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _apiKeyValue!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.integrationApiKeyCopied)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: _generateApiKey,
            icon: const Icon(Icons.vpn_key, size: 18),
            label: Text(l10n.integrationApiKeyGenerate),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
