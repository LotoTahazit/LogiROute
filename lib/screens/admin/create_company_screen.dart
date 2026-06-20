import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/company_provision_service.dart';
import '../../services/company_selection_service.dart';

/// Super admin: создание новой компании без обязательного пользователя.
class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameHeCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameHeCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    if (auth.userModel?.isSuperAdmin != true) return;

    setState(() => _saving = true);
    try {
      final id = _idCtrl.text.trim().toLowerCase();
      final ok = await CompanyProvisionService().createCompany(
        companyId: id,
        nameHebrew: _nameHeCtrl.text.trim(),
        nameEnglish: _nameEnCtrl.text.trim(),
        createdByUid: auth.currentUser?.uid ?? '',
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.companyAlreadyExists)),
        );
        return;
      }

      final companyService = context.read<CompanySelectionService>();
      await companyService.loadCompanies();
      companyService.selectCompany(id);
      auth.setVirtualCompanyId(id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.companyCreatedSuccess(_nameHeCtrl.text.trim()))),
      );
      Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createCompanyTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.createCompanyDesc),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idCtrl,
                decoration: InputDecoration(
                  labelText: l10n.companyIdSlug,
                  hintText: l10n.companyIdSlugHint,
                  border: const OutlineInputBorder(),
                ),
                textDirection: TextDirection.ltr,
                autocorrect: false,
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
                controller: _nameHeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.companyNameHebrew,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameEnCtrl,
                decoration: InputDecoration(
                  labelText: l10n.companyNameEnglish,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.business),
                label: Text(l10n.createCompany),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
