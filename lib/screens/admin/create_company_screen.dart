import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/company_provision_service.dart';
import '../../services/company_selection_service.dart';
import '../../features/owner_dashboard/utils/company_profile_validator.dart';

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
  final _taxIdCtrl = TextEditingController();
  final _addrHeCtrl = TextEditingController();
  final _addrEnCtrl = TextEditingController();
  final _poBoxCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _faxCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _idCtrl,
      _nameHeCtrl,
      _nameEnCtrl,
      _taxIdCtrl,
      _addrHeCtrl,
      _addrEnCtrl,
      _poBoxCtrl,
      _cityCtrl,
      _zipCtrl,
      _phoneCtrl,
      _faxCtrl,
      _emailCtrl,
      _webCtrl,
    ]) {
      c.dispose();
    }
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
        taxId: _taxIdCtrl.text.trim(),
        addressHebrew: _addrHeCtrl.text.trim(),
        addressEnglish: _addrEnCtrl.text.trim(),
        poBox: _poBoxCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        zipCode: _zipCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        fax: _faxCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        website: _webCtrl.text.trim(),
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
        SnackBar(
            content: Text(l10n.companyCreatedSuccess(_nameHeCtrl.text.trim()))),
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

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        textDirection: textDirection,
        validator: validator ??
            (required
                ? (v) => (v ?? '').trim().isEmpty
                    ? AppLocalizations.of(context)!.required
                    : null
                : null),
      ),
    );
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
              const SizedBox(height: 12),
              _field(
                controller: _idCtrl,
                label: l10n.companyIdSlug,
                hint: l10n.companyIdSlugHint,
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
              _section(l10n.companyDetails, [
                _field(
                  controller: _nameHeCtrl,
                  label: l10n.companyNameHebrew,
                  required: true,
                ),
                _field(
                  controller: _nameEnCtrl,
                  label: l10n.companyNameEnglish,
                ),
                _field(
                  controller: _taxIdCtrl,
                  label: l10n.settingsTaxId,
                  hint: l10n.taxIdLabel,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: (v) =>
                      CompanyProfileValidator.validateIsraeliTaxId(v ?? ''),
                ),
              ]),
              _section(l10n.address, [
                _field(
                  controller: _addrHeCtrl,
                  label: l10n.addressHebrew,
                ),
                _field(
                  controller: _addrEnCtrl,
                  label: l10n.addressEnglish,
                  textDirection: TextDirection.ltr,
                ),
                _field(controller: _poBoxCtrl, label: l10n.poBox),
                _field(controller: _cityCtrl, label: l10n.city),
                _field(
                  controller: _zipCtrl,
                  label: l10n.zipCode,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                ),
              ]),
              _section(l10n.contact, [
                _field(
                  controller: _phoneCtrl,
                  label: l10n.phone,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                ),
                _field(
                  controller: _faxCtrl,
                  label: l10n.fax,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                ),
                _field(
                  controller: _emailCtrl,
                  label: l10n.email,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(
                  controller: _webCtrl,
                  label: l10n.website,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.url,
                ),
              ]),
              const SizedBox(height: 8),
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
