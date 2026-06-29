import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../../../services/auth_service.dart';
import '../../../../screens/admin/terminology_settings_screen.dart';
import '../../../../screens/setup/warehouse_setup_questionnaire_screen.dart';
import '../../../../services/company_settings_service.dart';
import '../../models/role_hierarchy.dart';
import '../../services/permissions_service.dart';
import '../../utils/company_profile_validator.dart';
import '../../../../widgets/logi_route_tab_bar.dart';
import '../../../../services/invoice_assignment_service.dart';
import 'integration_settings_dialog.dart';
import 'accounting_provider_settings_dialog.dart';
import '../../../../screens/admin/company_remote_config_screen.dart';
import '../../../../screens/admin/data_integrity_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Секция «Настройки» Owner Dashboard.
///
/// - Owner: форма редактирования профиля компании (название, taxId, адрес,
///   телефон, timezone, валюта); read-only для налоговых настроек, нумерации,
///   шаблонов, интеграций.
/// - Admin/Super_admin: формы редактирования всех настроек.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9
class SettingsSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const SettingsSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  PermissionsService _permissionsOf(BuildContext context) {
    final auth = context.watch<AuthService>();
    return PermissionsService.forUser(
      actualRole: auth.userModel?.role,
      viewAsRole: auth.viewAsRole,
      userCompanyId: widget.companyId,
    );
  }
  late TextEditingController _nameHebrewCtrl;
  late TextEditingController _nameEnglishCtrl;
  late TextEditingController _taxIdCtrl;
  late TextEditingController _addressHebrewCtrl;
  late TextEditingController _addressEnglishCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _zipCodeCtrl;
  late TextEditingController _poBoxCtrl;
  late TextEditingController _faxCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _websiteCtrl;

  // --- Admin settings controllers ---
  late TextEditingController _invoiceFooterCtrl;
  late TextEditingController _paymentTermsCtrl;
  late TextEditingController _bankDetailsCtrl;
  late TextEditingController _bkmvRegCtrl;
  late TextEditingController _driverNameCtrl;
  late TextEditingController _driverPhoneCtrl;
  late TextEditingController _departureTimeCtrl;

  final _profileFormKey = GlobalKey<FormState>();
  final _settingsFormKey = GlobalKey<FormState>();

  Map<String, String> _profileErrors = {};
  Map<String, String> _settingsErrors = {};
  bool _profileSaving = false;
  bool _settingsSaving = false;
  bool _dispatcherTaxInvoiceReceipt = false;
  bool _requirePodPhoto = false;
  bool _autoCloseEnabled = true;
  bool _computerizedWarehouseEnabled = false;
  String _vatRegime = 'authorized';
  String _accountingProvider = 'none';

  static const _vatRegimes = ['authorized', 'exempt', 'company'];
  static const _accountingProviders = [
    'none',
    'export',
    'greeninvoice',
    'icount',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initControllers();
  }

  // --- Company Profile form controllers ---
  void _initControllers() {
    final cs = widget.companySettings;
    _nameHebrewCtrl = TextEditingController(text: cs.nameHebrew);
    _nameEnglishCtrl = TextEditingController(text: cs.nameEnglish);
    _taxIdCtrl = TextEditingController(text: cs.taxId);
    _addressHebrewCtrl = TextEditingController(text: cs.addressHebrew);
    _addressEnglishCtrl = TextEditingController(text: cs.addressEnglish);
    _phoneCtrl = TextEditingController(text: cs.phone);
    _cityCtrl = TextEditingController(text: cs.city);
    _zipCodeCtrl = TextEditingController(text: cs.zipCode);
    _poBoxCtrl = TextEditingController(text: cs.poBox);
    _faxCtrl = TextEditingController(text: cs.fax);
    _emailCtrl = TextEditingController(text: cs.email);
    _websiteCtrl = TextEditingController(text: cs.website);

    _invoiceFooterCtrl = TextEditingController(text: cs.invoiceFooterText);
    _paymentTermsCtrl = TextEditingController(text: cs.paymentTerms);
    _bankDetailsCtrl = TextEditingController(text: cs.bankDetails);
    _bkmvRegCtrl = TextEditingController(
      text: cs.bkmvSoftwareRegistrationNumber == '00000000'
          ? ''
          : cs.bkmvSoftwareRegistrationNumber,
    );
    _dispatcherTaxInvoiceReceipt = cs.dispatcherTaxInvoiceReceipt;
    _vatRegime = cs.vatRegime;
    _accountingProvider = cs.accountingProvider;
    _requirePodPhoto = cs.requirePodPhoto;
    _autoCloseEnabled = cs.autoCloseEnabled;
    _computerizedWarehouseEnabled = cs.computerizedWarehouseEnabled;
    _driverNameCtrl = TextEditingController(text: cs.driverName);
    _driverPhoneCtrl = TextEditingController(text: cs.driverPhone);
    _departureTimeCtrl = TextEditingController(text: cs.departureTime);
  }

  @override
  void didUpdateWidget(covariant SettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companySettings != widget.companySettings) {
      _updateControllersFromSettings();
    }
  }

  void _updateControllersFromSettings() {
    final cs = widget.companySettings;
    _nameHebrewCtrl.text = cs.nameHebrew;
    _nameEnglishCtrl.text = cs.nameEnglish;
    _taxIdCtrl.text = cs.taxId;
    _addressHebrewCtrl.text = cs.addressHebrew;
    _addressEnglishCtrl.text = cs.addressEnglish;
    _phoneCtrl.text = cs.phone;
    _cityCtrl.text = cs.city;
    _zipCodeCtrl.text = cs.zipCode;
    _poBoxCtrl.text = cs.poBox;
    _faxCtrl.text = cs.fax;
    _emailCtrl.text = cs.email;
    _websiteCtrl.text = cs.website;
    _invoiceFooterCtrl.text = cs.invoiceFooterText;
    _paymentTermsCtrl.text = cs.paymentTerms;
    _bankDetailsCtrl.text = cs.bankDetails;
    _bkmvRegCtrl.text = cs.bkmvSoftwareRegistrationNumber == '00000000'
        ? ''
        : cs.bkmvSoftwareRegistrationNumber;
    _dispatcherTaxInvoiceReceipt = cs.dispatcherTaxInvoiceReceipt;
    _vatRegime = cs.vatRegime;
    _accountingProvider = cs.accountingProvider;
    _requirePodPhoto = cs.requirePodPhoto;
    _autoCloseEnabled = cs.autoCloseEnabled;
    _computerizedWarehouseEnabled = cs.computerizedWarehouseEnabled;
    _driverNameCtrl.text = cs.driverName;
    _driverPhoneCtrl.text = cs.driverPhone;
    _departureTimeCtrl.text = cs.departureTime;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameHebrewCtrl.dispose();
    _nameEnglishCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressHebrewCtrl.dispose();
    _addressEnglishCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _zipCodeCtrl.dispose();
    _poBoxCtrl.dispose();
    _faxCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _invoiceFooterCtrl.dispose();
    _paymentTermsCtrl.dispose();
    _bankDetailsCtrl.dispose();
    _bkmvRegCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _departureTimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        LogiRouteTabBar(
          controller: _tabController,
          isScrollable: isNarrow,
          tabs: [
            LogiRouteTabItem(
                label: l10n.settingsCompanyProfile,
                icon: Icons.business_outlined),
            LogiRouteTabItem(
                label: l10n.settingsTab, icon: Icons.tune_outlined),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(context),
              _buildSettingsTab(context),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Company Profile (Req 7.1, 7.5, 7.8, 7.9)
  // ---------------------------------------------------------------------------

  Widget _buildProfileTab(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final permissions = _permissionsOf(context);
    final canEdit = permissions.canEditCompanyProfile();
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.business, color: theme.colorScheme.primary),
                Text(
                  l10n.settingsCompanyProfile,
                  style: theme.textTheme.titleLarge,
                ),
                if (!canEdit)
                  Chip(
                    avatar: const Icon(Icons.lock_outline, size: 16),
                    label: Text(l10n.settingsReadOnly),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Company name fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.settingsCompanyName,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameHebrewCtrl,
                      label: l10n.settingsNameHebrew,
                      enabled: canEdit,
                      errorText: _profileErrors['nameHebrew'],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameEnglishCtrl,
                      label: l10n.settingsNameEnglish,
                      enabled: canEdit,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _taxIdCtrl,
                      label: l10n.settingsTaxId,
                      enabled: canEdit,
                      errorText: _profileErrors['taxId'],
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.settingsAddress,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressHebrewCtrl,
                      label: l10n.settingsAddressHebrew,
                      enabled: canEdit,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressEnglishCtrl,
                      label: l10n.settingsAddressEnglish,
                      enabled: canEdit,
                    ),
                    const SizedBox(height: 12),
                    if (isNarrow) ...[
                      _buildTextField(
                        controller: _cityCtrl,
                        label: l10n.settingsCity,
                        enabled: canEdit,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _zipCodeCtrl,
                        label: l10n.settingsZipCode,
                        enabled: canEdit,
                        keyboardType: TextInputType.number,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cityCtrl,
                              label: l10n.settingsCity,
                              enabled: canEdit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _zipCodeCtrl,
                              label: l10n.settingsZipCode,
                              enabled: canEdit,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _poBoxCtrl,
                      label: l10n.settingsPoBox,
                      enabled: canEdit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.settingsContactDetails,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneCtrl,
                      label: l10n.settingsPhone,
                      enabled: canEdit,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _faxCtrl,
                      label: l10n.settingsFax,
                      enabled: canEdit,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailCtrl,
                      label: l10n.settingsEmail,
                      enabled: canEdit,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _websiteCtrl,
                      label: l10n.settingsWebsite,
                      enabled: canEdit,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button (Req 7.5)
            if (canEdit)
              FilledButton.icon(
                onPressed: _profileSaving ? null : _saveProfile,
                icon: _profileSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_profileSaving
                    ? l10n.settingsSaving
                    : l10n.settingsSaveProfile),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Settings — tax, numbering, templates, integrations
  // (Req 7.2, 7.3, 7.4, 7.6, 7.7)
  // ---------------------------------------------------------------------------

  Widget _buildSettingsTab(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final permissions = _permissionsOf(context);
    final canEditSettings = permissions.canEditSettings();
    final canEditInvoiceSettings = permissions.canEditInvoiceSettings();
    final canManageIntegrations = permissions.canManageIntegrations();
    final canEditOps = permissions.canEditOpsSettings();
    final isOwner = permissions.role == AppRole.owner;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _settingsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.settingsSystemSettings,
                    style: theme.textTheme.titleLarge),
                const Spacer(),
                if (!canEditSettings && !canEditInvoiceSettings)
                  Chip(
                    avatar: const Icon(Icons.lock_outline, size: 16),
                    label: Text(l10n.settingsReadOnly),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (isOwner)
              MaterialBanner(
                padding: const EdgeInsets.all(12),
                backgroundColor: theme.colorScheme.primaryContainer,
                content: Text(l10n.settingsOwnerSetupHint),
                actions: [
                  TextButton(
                    onPressed: () => _tabController.animateTo(0),
                    child: Text(l10n.settingsCompanyProfile),
                  ),
                ],
              ),
            if (isOwner) const SizedBox(height: 8),

            if (permissions.canEditCompanyProfile())
              _buildWarehouseSetupCard(context),

            if (permissions.canEditCompanyProfile()) const SizedBox(height: 16),

            // Счета — первым для owner (текст внизу PDF, условия, банк)
            _buildInvoiceSettingsCard(context, canEditInvoiceSettings),
            const SizedBox(height: 16),

            // Tax settings (Req 7.3)
            _buildTaxSettingsCard(context, canEditSettings, permissions),
            const SizedBox(height: 16),

            _buildAccountingProviderCard(context, canEditSettings, permissions),
            const SizedBox(height: 16),

            // Document numbering (Req 7.3)
            _buildNumberingCard(context, canEditSettings),
            const SizedBox(height: 16),

            // Print templates (Req 7.3)
            _buildPrintTemplatesCard(context, canEditSettings),
            const SizedBox(height: 16),

            // Integrations (Req 7.4)
            _buildIntegrationsCard(context, canManageIntegrations),
            const SizedBox(height: 16),

            // חשבוניות ישראל — מספר הקצאה (нативная интеграция, OAuth-подключение)
            _buildIsraelInvoiceCard(context, canManageIntegrations),
            const SizedBox(height: 16),

            _buildDeliveryOpsCard(context, canEditOps),
            const SizedBox(height: 16),

            _buildComputerizedWarehouseCard(context, canEditOps),
          if (permissions.canEditCompanyProfile())
            _buildTerminologyCard(context),
            const SizedBox(height: 16),

            if (canEditSettings)
              _buildRemoteConfigCard(context),
            if (canEditSettings) const SizedBox(height: 16),
            if (canEditSettings)
              _buildDataIntegrityCard(context),
            const SizedBox(height: 24),

            // Save button — shown if user can edit any settings
            if (canEditSettings || canEditInvoiceSettings || canEditOps)
              FilledButton.icon(
                onPressed: _settingsSaving ? null : _saveSettings,
                icon: _settingsSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_settingsSaving
                    ? AppLocalizations.of(context)!.settingsSaving
                    : AppLocalizations.of(context)!.settingsSaveSettings),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tax Settings Card (Req 7.2, 7.3)
  // ---------------------------------------------------------------------------

  Widget _buildTaxSettingsCard(
    BuildContext context,
    bool canEdit,
    PermissionsService permissions,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final taxId = widget.companySettings.taxId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.settingsTaxSettings,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _ReadOnlyInfoRow(
              label: l10n.settingsTaxIdBn,
              value: taxId.isNotEmpty ? taxId : l10n.notSet,
              icon: Icons.badge_outlined,
            ),
            if (taxId.isEmpty && permissions.canEditCompanyProfile())
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.settingsTaxIdFillInProfile),
                ),
              ),
            if (canEdit) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _vatRegime,
                decoration: InputDecoration(
                  labelText: l10n.vatRegimeLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _vatRegimes
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_vatRegimeLabel(r, l10n)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _vatRegime = v);
                },
              ),
            ] else ...[
              _ReadOnlyInfoRow(
                label: l10n.vatRegimeLabel,
                value: _vatRegimeLabel(_vatRegime, l10n),
                icon: Icons.business_outlined,
              ),
            ],
            _ReadOnlyInfoRow(
              label: l10n.settingsVatRate,
              value: _vatRateDisplay(),
              icon: Icons.percent_outlined,
            ),
            const SizedBox(height: 12),
            if (canEdit)
              TextFormField(
                controller: _bkmvRegCtrl,
                decoration: InputDecoration(
                  labelText: l10n.bkmvSoftwareRegistrationLabel,
                  helperText: l10n.bkmvSoftwareRegistrationHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 8,
              )
            else
              _ReadOnlyInfoRow(
                label: l10n.bkmvSoftwareRegistrationLabel,
                value: widget.companySettings.bkmvSoftwareRegistrationNumber ==
                        '00000000'
                    ? l10n.notSet
                    : widget.companySettings.bkmvSoftwareRegistrationNumber,
                icon: Icons.app_registration_outlined,
              ),
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.settingsTaxManagedByAdmin,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _vatRegimeLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'exempt':
        return l10n.vatRegimeExempt;
      case 'company':
        return l10n.vatRegimeCompany;
      default:
        return l10n.vatRegimeAuthorized;
    }
  }

  /// עוסק פטור — 0%; מורשה/חברה — 18% (ставка Израиля).
  String _vatRateDisplay() => _vatRegime == 'exempt' ? '0%' : '18%';

  String _accountingProviderLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'export':
        return l10n.accountingProviderExport;
      case 'greeninvoice':
        return l10n.accountingProviderGreeninvoice;
      case 'icount':
        return l10n.accountingProviderIcount;
      default:
        return l10n.accountingProviderNone;
    }
  }

  Widget _buildAccountingProviderCard(
    BuildContext context,
    bool canEdit,
    PermissionsService permissions,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final needsCreds =
        _accountingProvider == 'greeninvoice' || _accountingProvider == 'icount';
    final canCreds = permissions.canManageAccountingCredentials();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_alt_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.accountingProviderSection,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (canEdit)
              DropdownButtonFormField<String>(
                initialValue: _accountingProvider,
                decoration: InputDecoration(
                  labelText: l10n.accountingProviderLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _accountingProviders
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(_accountingProviderLabel(p, l10n)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _accountingProvider = v);
                },
              )
            else
              _ReadOnlyInfoRow(
                label: l10n.accountingProviderLabel,
                value: _accountingProviderLabel(_accountingProvider, l10n),
                icon: Icons.sync_alt_outlined,
              ),
            const SizedBox(height: 8),
            Text(
              l10n.accountingProviderHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            if (needsCreds && canCreds) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => AccountingProviderSettingsDialog(
                    companyId: widget.companyId,
                    provider: _accountingProvider,
                  ),
                ),
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: Text(l10n.accountingProviderConfigure),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOpsCard(BuildContext context, bool canEdit) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = widget.companySettings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.settingsDeliveryAndOps,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: canEdit ? _requirePodPhoto : cs.requirePodPhoto,
              onChanged: canEdit
                  ? (v) => setState(() {
                        _requirePodPhoto = v;
                        if (v) _autoCloseEnabled = false;
                      })
                  : null,
              title: Text(l10n.requirePodPhoto),
              subtitle: Text(l10n.requirePodPhotoHint),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: canEdit
                  ? (_autoCloseEnabled && !_requirePodPhoto)
                  : (cs.autoCloseEnabled && !cs.requirePodPhoto),
              onChanged: canEdit && !_requirePodPhoto
                  ? (v) => setState(() => _autoCloseEnabled = v)
                  : null,
              title: Text(l10n.autoCloseEnabledTitle),
              subtitle: Text(l10n.autoCloseEnabledHint),
            ),
            const Divider(),
            Text(l10n.settingsDriverDefaults,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (canEdit) ...[
              _buildTextField(
                controller: _driverNameCtrl,
                label: l10n.driverName,
                enabled: true,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _driverPhoneCtrl,
                label: l10n.driverPhone,
                enabled: true,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _departureTimeCtrl,
                label: l10n.departureTime,
                enabled: true,
              ),
            ] else ...[
              _ReadOnlyInfoRow(
                label: l10n.driverName,
                value: cs.driverName.isNotEmpty ? cs.driverName : l10n.notSet,
                icon: Icons.person_outline,
              ),
              _ReadOnlyInfoRow(
                label: l10n.driverPhone,
                value: cs.driverPhone.isNotEmpty ? cs.driverPhone : l10n.notSet,
                icon: Icons.phone_outlined,
              ),
              _ReadOnlyInfoRow(
                label: l10n.departureTime,
                value: cs.departureTime.isNotEmpty
                    ? cs.departureTime
                    : l10n.notSet,
                icon: Icons.schedule_outlined,
              ),
            ],
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.settingsOpsManagedByAdmin,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSetupCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        leading: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
        title: Text(l10n.warehouseQuestionnaireTitle),
        subtitle: Text(l10n.warehouseQuestionnaireSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => WarehouseSetupQuestionnaireScreen(
              companyId: widget.companyId,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminologyCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: Icon(Icons.translate, color: theme.colorScheme.primary),
        title: Text(l10n.terminologySettings),
        subtitle: Text(l10n.selectTemplate),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => const TerminologySettingsScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildComputerizedWarehouseCard(BuildContext context, bool canEdit) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = widget.companySettings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.computerizedWarehouseTitle,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: canEdit
                  ? _computerizedWarehouseEnabled
                  : cs.computerizedWarehouseEnabled,
              onChanged: canEdit
                  ? (v) => setState(() => _computerizedWarehouseEnabled = v)
                  : null,
              title: Text(l10n.computerizedWarehouseEnabled),
              subtitle: Text(l10n.computerizedWarehouseHint),
            ),
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.settingsOpsManagedByAdmin,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Invoice Settings Card
  // ---------------------------------------------------------------------------

  Widget _buildInvoiceSettingsCard(BuildContext context, bool canEdit) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.settingsInvoiceSettings,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _buildTextField(
              controller: _invoiceFooterCtrl,
              label: l10n.settingsInvoiceFooter,
              enabled: canEdit,
              maxLines: 3,
              errorText: _settingsErrors['invoiceFooterText'],
              helperText: l10n.settingsInvoiceFooterHint,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _paymentTermsCtrl,
              label: l10n.settingsPaymentTerms,
              enabled: canEdit,
              errorText: _settingsErrors['paymentTerms'],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _bankDetailsCtrl,
              label: l10n.settingsBankDetails,
              enabled: canEdit,
              maxLines: 2,
              errorText: _settingsErrors['bankDetails'],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _dispatcherTaxInvoiceReceipt,
              onChanged: canEdit
                  ? (v) => setState(() => _dispatcherTaxInvoiceReceipt = v)
                  : null,
              title: Text(l10n.dispatcherTaxInvoiceReceiptTitle),
              subtitle: Text(l10n.dispatcherTaxInvoiceReceiptHint),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Document Numbering Card (Req 7.3)
  // ---------------------------------------------------------------------------

  Widget _buildNumberingCard(BuildContext context, bool canEdit) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_list_numbered,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.settingsDocNumbering,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _ReadOnlyInfoRow(
              label: l10n.settingsTaxInvoice,
              value: l10n.settingsAutoNumbering,
              icon: Icons.description_outlined,
            ),
            _ReadOnlyInfoRow(
              label: l10n.settingsReceipt,
              value: l10n.settingsAutoNumbering,
              icon: Icons.receipt_outlined,
            ),
            _ReadOnlyInfoRow(
              label: l10n.settingsDeliveryNote,
              value: l10n.settingsAutoNumbering,
              icon: Icons.local_shipping_outlined,
            ),
            _ReadOnlyInfoRow(
              label: l10n.settingsCreditNote,
              value: l10n.settingsAutoNumbering,
              icon: Icons.money_off_outlined,
            ),
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.settingsNumberingManagedBySystem,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Print Templates Card (Req 7.3)
  // ---------------------------------------------------------------------------

  Widget _buildPrintTemplatesCard(BuildContext context, bool canEdit) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.print_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.settingsPrintTemplates,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _ReadOnlyInfoRow(
              label: l10n.settingsTaxInvoice,
              value: l10n.settingsDefaultTemplate,
              icon: Icons.description_outlined,
            ),
            _ReadOnlyInfoRow(
              label: l10n.settingsDeliveryNote,
              value: l10n.settingsDefaultTemplate,
              icon: Icons.local_shipping_outlined,
            ),
            _ReadOnlyInfoRow(
              label: l10n.settingsReceipt,
              value: l10n.settingsDefaultTemplate,
              icon: Icons.receipt_outlined,
            ),
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.settingsTemplatesAdminOnly,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Integrations Card (Req 7.4)
  // ---------------------------------------------------------------------------

  Widget _buildIntegrationsCard(BuildContext context, bool canManage) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('settings')
          .doc('integrations')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        bool isEnabled(String key) {
          final section = data[key] as Map<String, dynamic>?;
          return section != null && section['enabled'] == true;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.extension_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.settingsIntegrations,
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                const Divider(),
                _IntegrationRow(
                  icon: Icons.print,
                  label: l10n.settingsPrinting,
                  statusLabel: isEnabled('print')
                      ? l10n.settingsConfigured
                      : l10n.settingsNotConfigured,
                  isConfigured: isEnabled('print'),
                  enabled: canManage,
                  onEdit: canManage
                      ? () =>
                          _openIntegrationDialog('print', l10n.settingsPrinting)
                      : null,
                ),
                _IntegrationRow(
                  icon: Icons.email_outlined,
                  label: l10n.settingsEmailIntegration,
                  statusLabel: isEnabled('email')
                      ? l10n.settingsConfigured
                      : l10n.settingsNotConfigured,
                  isConfigured: isEnabled('email'),
                  enabled: canManage,
                  onEdit: canManage
                      ? () => _openIntegrationDialog(
                          'email', l10n.settingsEmailIntegration)
                      : null,
                ),
                _IntegrationRow(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  statusLabel: isEnabled('whatsapp')
                      ? l10n.settingsConfigured
                      : l10n.settingsNotConfigured,
                  isConfigured: isEnabled('whatsapp'),
                  enabled: canManage,
                  onEdit: canManage
                      ? () => _openIntegrationDialog('whatsapp', 'WhatsApp')
                      : null,
                ),
                _IntegrationRow(
                  icon: Icons.vpn_key_outlined,
                  label: l10n.settingsApiKeys,
                  statusLabel: isEnabled('apiKeys')
                      ? l10n.settingsConfigured
                      : l10n.settingsNotConfigured,
                  isConfigured: isEnabled('apiKeys'),
                  enabled: canManage,
                  onEdit: canManage
                      ? () => _openIntegrationDialog(
                          'apiKeys', l10n.settingsApiKeys)
                      : null,
                ),
                if (!canManage)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.settingsIntegrationsAdminOnly,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openIntegrationDialog(String key, String label) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => IntegrationSettingsDialog(
        companyId: widget.companyId,
        integrationKey: key,
        integrationLabel: label,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // חשבוניות ישראל — разовое OAuth-подключение компании к рשут המסים.
  // Реальный обмен code→токен и запрос מספר הקצаה — на сервере (Cloud Functions).
  // ---------------------------------------------------------------------------

  Widget _buildIsraelInvoiceCard(BuildContext context, bool canManage) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<IsraelInvoiceStatus>(
          future:
              InvoiceAssignmentService(companyId: widget.companyId).getStatus(),
          builder: (context, snap) {
            final st = snap.data;
            final platformOk = st?.platformConfigured == true;
            final connected = st?.companyConnected == true;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.israelInvoiceStatusTitle,
                          style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const Divider(),
                if (snap.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else ...[
                  _israelStatusRow(
                    l10n.israelInvoicePlatformNotConfigured,
                    platformOk,
                    invert: true,
                  ),
                  const SizedBox(height: 4),
                  _israelStatusRow(
                    connected
                        ? l10n.israelInvoiceCompanyConnected
                        : l10n.israelInvoiceCompanyNotConnected,
                    connected,
                  ),
                  if (platformOk) ...[
                    const SizedBox(height: 4),
                    _israelStatusRow(
                      st?.assignmentReady == true
                          ? l10n.israelInvoiceAssignmentReady
                          : l10n.israelInvoiceAssignmentMissingOAuth,
                      st?.assignmentReady == true,
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.israelInvoiceConnectHint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      canManage && platformOk ? _connectIsraelInvoice : null,
                  icon: const Icon(Icons.link),
                  label: Text(l10n.israelInvoiceConnect),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _israelStatusRow(String label, bool ok, {bool invert = false}) {
    final good = invert ? !ok : ok;
    return Row(
      children: [
        Icon(
          good ? Icons.check_circle : Icons.warning_amber,
          size: 16,
          color: good ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Future<void> _connectIsraelInvoice() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await InvoiceAssignmentService(companyId: widget.companyId)
          .getConnectUrl();
      if (url.isEmpty) throw Exception('empty url');
      final ok =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('cannot launch url');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Shared text field builder
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    String? errorText,
    String? helperText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
        errorText: errorText,
        filled: !enabled,
        fillColor: enabled
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save Profile (Req 7.5, 7.8, 7.9)
  // ---------------------------------------------------------------------------

  Future<void> _saveProfile() async {
    // Validate required fields (Req 7.8)
    final errors = CompanyProfileValidator.validate(
      nameHebrew: _nameHebrewCtrl.text,
      taxId: _taxIdCtrl.text,
    );

    if (errors.isNotEmpty) {
      // Show inline errors (Req 7.9)
      setState(() => _profileErrors = errors);
      return;
    }

    setState(() {
      _profileErrors = {};
      _profileSaving = true;
    });

    try {
      final profileUpdates = {
        'nameHebrew': _nameHebrewCtrl.text.trim(),
        'nameEnglish': _nameEnglishCtrl.text.trim(),
        'taxId': _taxIdCtrl.text.trim(),
        'addressHebrew': _addressHebrewCtrl.text.trim(),
        'addressEnglish': _addressEnglishCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'zipCode': _zipCodeCtrl.text.trim(),
        'poBox': _poBoxCtrl.text.trim(),
        'fax': _faxCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .set(profileUpdates, SetOptions(merge: true));

      await CompanySettingsService(companyId: widget.companyId)
          .updateSettings(profileUpdates);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsProfileSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsProfileError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _profileSaving = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Save Settings (Req 7.7) — Admin only
  // ---------------------------------------------------------------------------

  Future<void> _saveSettings() async {
    final permissions = PermissionsService.forUser(
      actualRole: context.read<AuthService>().userModel?.role,
      viewAsRole: context.read<AuthService>().viewAsRole,
      userCompanyId: widget.companyId,
    );
    final canEditAll = permissions.canEditSettings();
    final canEditInvoice = permissions.canEditInvoiceSettings();
    final canEditOps = permissions.canEditOpsSettings();
    if (!canEditAll && !canEditInvoice && !canEditOps) return;

    setState(() {
      _settingsErrors = {};
      _settingsSaving = true;
    });

    try {
      final Map<String, dynamic> updates = {};
      if (canEditInvoice) {
        updates['invoiceFooterText'] = _invoiceFooterCtrl.text.trim();
        updates['paymentTerms'] = _paymentTermsCtrl.text.trim();
        updates['bankDetails'] = _bankDetailsCtrl.text.trim();
        updates['dispatcherTaxInvoiceReceipt'] = _dispatcherTaxInvoiceReceipt;
      }
      if (canEditAll) {
        updates['vatRegime'] = _vatRegime;
        final bkmv = _bkmvRegCtrl.text.trim();
        updates['bkmvSoftwareRegistrationNumber'] =
            bkmv.isEmpty ? '00000000' : bkmv;
        updates['accountingProvider'] = _accountingProvider;
      }
      if (canEditOps) {
        updates['requirePodPhoto'] = _requirePodPhoto;
        updates['autoCloseEnabled'] =
            _requirePodPhoto ? false : _autoCloseEnabled;
        updates['driverName'] = _driverNameCtrl.text.trim();
        updates['driverPhone'] = _driverPhoneCtrl.text.trim();
        updates['departureTime'] = _departureTimeCtrl.text.trim().isEmpty
            ? '7:00'
            : _departureTimeCtrl.text.trim();
        updates['computerizedWarehouseEnabled'] = _computerizedWarehouseEnabled;
      }
      if (updates.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .set(updates, SetOptions(merge: true));

      await CompanySettingsService(companyId: widget.companyId)
          .updateSettings(updates);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSettingsSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSettingsError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _settingsSaving = false);
      }
    }
  }

  Widget _buildRemoteConfigCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(Icons.tune_outlined, color: theme.colorScheme.primary),
        title: Text(AppLocalizations.of(context)!.remoteConfigTitle,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(AppLocalizations.of(context)!.remoteConfigSubtitle,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CompanyRemoteConfigScreen(companyId: widget.companyId),
        )),
      ),
    );
  }

  Widget _buildDataIntegrityCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(Icons.rule, color: theme.colorScheme.primary),
        title: Text(AppLocalizations.of(context)!.dataIntegrityTitle,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(AppLocalizations.of(context)!.dataIntegritySubtitle,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DataIntegrityScreen(companyId: widget.companyId),
        )),
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

/// Read-only info row with icon.
class _ReadOnlyInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: theme.colorScheme.outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: Text(label, style: theme.textTheme.bodyMedium),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Integration row with status indicator.
class _IntegrationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String statusLabel;
  final bool isConfigured;
  final bool enabled;
  final VoidCallback? onEdit;

  const _IntegrationRow({
    required this.icon,
    required this.label,
    required this.statusLabel,
    required this.isConfigured,
    required this.enabled,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: theme.colorScheme.outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isConfigured
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isConfigured ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    if (enabled)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: onEdit,
                        tooltip: AppLocalizations.of(context)!.settingsEditTooltip,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isConfigured ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    tooltip: AppLocalizations.of(context)!.settingsEditTooltip,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
    );
  }
}
