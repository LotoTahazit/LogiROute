import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/owner_dashboard/utils/company_profile_validator.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/company_provision_service.dart';
import '../../utils/auth_error_messages.dart';
import '../../utils/validation_helper.dart';

/// Self-service: регистрация owner + компания. [resumeMode] — продолжить после прерывания.
class OwnerSignupScreen extends StatefulWidget {
  const OwnerSignupScreen({super.key, this.resumeMode = false});

  final bool resumeMode;

  @override
  State<OwnerSignupScreen> createState() => _OwnerSignupScreenState();
}

class _OwnerSignupScreenState extends State<OwnerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyIdCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  bool _busy = false;

  bool get _isResume =>
      widget.resumeMode || FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    if (_isResume) {
      final u = FirebaseAuth.instance.currentUser;
      if (u?.email != null) _emailCtrl.text = u!.email!;
      final name = u?.displayName ?? '';
      if (name.isNotEmpty) _nameCtrl.text = name;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _passwordCtrl,
      _phoneCtrl,
      _companyIdCtrl,
      _companyNameCtrl,
      _taxIdCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _mapError(AppLocalizations l10n, String code) {
    switch (code) {
      case 'company-exists':
        return l10n.companyAlreadyExists;
      case 'invalid-company-id':
        return l10n.invalidCompanyId;
      case 'user-already-provisioned':
        return l10n.registerAlreadyProvisioned;
      case 'missing-fields':
        return l10n.required;
      default:
        return AuthErrorMessages.message(l10n, code);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    try {
      final String? error;
      if (_isResume) {
        error = await auth.completeOwnerRegistration(
          name: _nameCtrl.text.trim(),
          companyId: _companyIdCtrl.text.trim().toLowerCase(),
          nameHebrew: _companyNameCtrl.text.trim(),
          taxId: _taxIdCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
      } else {
        error = await auth.registerOwnerWithCompany(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
          companyId: _companyIdCtrl.text.trim().toLowerCase(),
          nameHebrew: _companyNameCtrl.text.trim(),
          taxId: _taxIdCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapError(l10n, error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isResume ? l10n.registerResumeTitle : l10n.registerTitle),
        actions: [
          if (_isResume)
            TextButton(
              onPressed: _busy ? null : () => context.read<AuthService>().signOut(),
              child: Text(l10n.logout),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isResume ? l10n.registerResumeSubtitle : l10n.registerOwnerSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                readOnly: _isResume,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                validator: (v) {
                  final e = (v ?? '').trim();
                  if (e.isEmpty) return l10n.required;
                  if (!ValidationHelper.isValidEmail(e)) {
                    return l10n.invalidEmailShort;
                  }
                  return null;
                },
              ),
              if (!_isResume) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      (v ?? '').length < 6 ? l10n.minSixCharacters : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: l10n.phoneOptional,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
              ),
              const Divider(height: 32),
              Text(l10n.createCompanyTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyIdCtrl,
                decoration: InputDecoration(
                  labelText: l10n.companyIdSlug,
                  hintText: l10n.companyIdSlugHint,
                  border: const OutlineInputBorder(),
                ),
                textDirection: TextDirection.ltr,
                validator: (v) {
                  final id = (v ?? '').trim().toLowerCase();
                  if (id.isEmpty) return l10n.required;
                  if (!CompanyProvisionService.isValidCompanyId(id)) {
                    return l10n.invalidCompanyId;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyNameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.companyNameHebrew,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxIdCtrl,
                decoration: InputDecoration(
                  labelText: l10n.settingsTaxId,
                  hintText: l10n.taxIdLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    CompanyProfileValidator.validateIsraeliTaxId(v ?? ''),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isResume
                        ? l10n.registerContinueButton
                        : l10n.registerButton),
              ),
              if (!_isResume)
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(l10n.alreadyHaveAccountLogin),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
