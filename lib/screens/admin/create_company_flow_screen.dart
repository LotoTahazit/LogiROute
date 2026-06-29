import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/company_onboarding_mode.dart';
import '../../services/auth_service.dart';
import '../../services/company_modules_service.dart';
import '../../services/company_provision_service.dart';
import '../../services/company_selection_service.dart';
import '../../services/create_company_flow_service.dart';
import '../../features/owner_dashboard/utils/company_profile_validator.dart';
import 'create_company_success_screen.dart';

/// Super_admin: 4 шага — компания → owner → режим → подтверждение.
class CreateCompanyFlowScreen extends StatefulWidget {
  const CreateCompanyFlowScreen({super.key});

  @override
  State<CreateCompanyFlowScreen> createState() => _CreateCompanyFlowScreenState();
}

class _CreateCompanyFlowScreenState extends State<CreateCompanyFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;

  final _idCtrl = TextEditingController();
  final _nameHeCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();

  String _plan = 'full';
  String _initialRole = 'owner';
  CompanyOnboardingMode _mode = CompanyOnboardingMode.selfSetup;
  int _trialDays = 14;

  @override
  void dispose() {
    for (final c in [
      _idCtrl,
      _nameHeCtrl,
      _nameEnCtrl,
      _taxIdCtrl,
      _ownerNameCtrl,
      _ownerEmailCtrl,
      _ownerPhoneCtrl,
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
      final input = CreateCompanyFlowInput(
        companyId: _idCtrl.text.trim().toLowerCase(),
        nameHebrew: _nameHeCtrl.text.trim(),
        nameEnglish: _nameEnCtrl.text.trim(),
        taxId: _taxIdCtrl.text.trim(),
        plan: _plan,
        trialDays: _trialDays,
        ownerName: _ownerNameCtrl.text.trim(),
        ownerEmail: _ownerEmailCtrl.text.trim(),
        ownerPhone: _ownerPhoneCtrl.text.trim(),
        initialRole: _initialRole,
        onboardingMode: _mode,
        createdByUid: auth.currentUser?.uid ?? '',
      );

      final result = await CreateCompanyFlowService().execute(
        input: input,
        auth: auth,
        languageCode: Localizations.localeOf(context).languageCode,
      );

      if (!mounted) return;
      final companyService = context.read<CompanySelectionService>();
      await companyService.loadCompanies();
      companyService.selectCompany(result.companyId);
      auth.setVirtualCompanyId(result.companyId);

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreateCompanySuccessScreen(result: result),
        ),
      );
    } on CreateCompanyFlowException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_flowError(l10n, e.code))),
        );
      }
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

  String _flowError(AppLocalizations l10n, String code) {
    switch (code) {
      case 'company_exists':
        return l10n.companyAlreadyExists;
      case 'user-in-other-company':
        return l10n.createCompanyFlowUserInOtherCompany;
      case 'email-already-in-use':
        return l10n.createCompanyFlowEmailConflict;
      case 'invalid_tax_id':
        return l10n.bkmvTaxIdRequired;
      case 'missing_owner_name':
      case 'missing_owner_email':
        return l10n.createCompanyFlowOwnerRequired;
      default:
        return '${l10n.error}: $code';
    }
  }

  void _next() {
    if (_step < 3) {
      if (_formKey.currentState?.validate() != true) return;
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trialUntil = DateTime.now().add(Duration(days: _trialDays));
  final limits = CompanyModulesService.limitsForPlan(_plan);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createCompanyFlowTitle)),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: _saving ? null : _next,
          onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: _saving ? null : details.onStepContinue,
                    child: Text(_step == 3
                        ? l10n.createCompany
                        : l10n.next),
                  ),
                  if (_step > 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(l10n.importWizardBack),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text(l10n.createCompanyFlowStepCompany),
              isActive: _step >= 0,
              state: _step > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _idCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.companyIdSlug,
                      hintText: l10n.companyIdSlugHint,
                    ),
                    validator: (v) {
                      final id = (v ?? '').trim().toLowerCase();
                      if (id.isEmpty) return l10n.required;
                      if (!CompanyProvisionService.isValidCompanyId(id)) {
                        return l10n.invalidCompanyId;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nameHeCtrl,
                    decoration: InputDecoration(labelText: l10n.companyNameHebrew),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.required : null,
                  ),
                  TextFormField(
                    controller: _nameEnCtrl,
                    decoration: InputDecoration(labelText: l10n.companyNameEnglish),
                  ),
                  TextFormField(
                    controller: _taxIdCtrl,
                    decoration: InputDecoration(labelText: l10n.settingsTaxId),
                    validator: (v) =>
                        CompanyProfileValidator.validateIsraeliTaxId(v ?? ''),
                  ),
                  DropdownButtonFormField<String>(
                    value: _plan,
                    decoration: InputDecoration(labelText: l10n.planLabel),
                    items: CompanyModulesService.planModules.keys
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _plan = v ?? 'full'),
                  ),
                  Text(l10n.createCompanyFlowDefaults),
                ],
              ),
            ),
            Step(
              title: Text(l10n.createCompanyFlowStepOwner),
              isActive: _step >= 1,
              state: _step > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _ownerNameCtrl,
                    decoration: InputDecoration(labelText: l10n.colName),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.required : null,
                  ),
                  TextFormField(
                    controller: _ownerEmailCtrl,
                    decoration: InputDecoration(labelText: l10n.email),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.required : null,
                  ),
                  TextFormField(
                    controller: _ownerPhoneCtrl,
                    decoration: InputDecoration(labelText: l10n.phone),
                    keyboardType: TextInputType.phone,
                  ),
                  DropdownButtonFormField<String>(
                    value: _initialRole,
                    decoration: InputDecoration(labelText: l10n.role),
                    items: [
                      DropdownMenuItem(value: 'owner', child: Text(l10n.roleOwner)),
                      DropdownMenuItem(value: 'admin', child: Text(l10n.roleAdmin)),
                    ],
                    onChanged: (v) => setState(() => _initialRole = v ?? 'owner'),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.createCompanyFlowStepMode),
              isActive: _step >= 2,
              state: _step > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  RadioListTile<CompanyOnboardingMode>(
                    title: Text(l10n.createCompanyFlowModeSelf),
                    subtitle: Text(l10n.createCompanyFlowModeSelfHint),
                    value: CompanyOnboardingMode.selfSetup,
                    groupValue: _mode,
                    onChanged: (v) => setState(() => _mode = v!),
                  ),
                  RadioListTile<CompanyOnboardingMode>(
                    title: Text(l10n.createCompanyFlowModeDone),
                    subtitle: Text(l10n.createCompanyFlowModeDoneHint),
                    value: CompanyOnboardingMode.doneForYou,
                    groupValue: _mode,
                    onChanged: (v) => setState(() => _mode = v!),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.createCompanyFlowStepConfirm),
              isActive: _step >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.companyNameHebrew}: ${_nameHeCtrl.text}'),
                  Text('${l10n.planLabel}: $_plan'),
                  Text('${l10n.email}: ${_ownerEmailCtrl.text}'),
                  Text('${l10n.role}: $_initialRole'),
                  Text(l10n.createCompanyFlowModeLabel(_mode == CompanyOnboardingMode.selfSetup
                      ? l10n.createCompanyFlowModeSelf
                      : l10n.createCompanyFlowModeDone)),
                  Text('${l10n.trialEndsLabel}: ${DateFormat.yMMMd().format(trialUntil)}'),
                  Text('${l10n.createCompanyFlowMaxUsers}: ${limits.maxUsers}'),
                  if (_saving) const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
