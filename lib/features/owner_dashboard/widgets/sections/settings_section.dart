import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../../../services/auth_service.dart';
import '../../models/role_hierarchy.dart';
import '../../services/permissions_service.dart';
import '../../utils/company_profile_validator.dart';
import 'integration_settings_dialog.dart';

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
  late PermissionsService _permissions;

  // --- Company Profile form controllers ---
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

  final _profileFormKey = GlobalKey<FormState>();
  final _settingsFormKey = GlobalKey<FormState>();

  Map<String, String> _profileErrors = {};
  Map<String, String> _settingsErrors = {};
  bool _profileSaving = false;
  bool _settingsSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initControllers();
    _initPermissions();
  }

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
  }

  void _initPermissions() {
    final authService = context.read<AuthService>();
    final userModel = authService.userModel;
    final roleStr = userModel?.role ?? 'viewer';
    AppRole role;
    try {
      role = AppRole.fromString(roleStr);
    } catch (_) {
      role = AppRole.viewer;
    }
    _permissions = PermissionsService(
      role: role,
      userCompanyId: userModel?.companyId ?? '',
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: isNarrow,
          tabs: [
            Tab(
                text: l10n.settingsCompanyProfile,
                icon: const Icon(Icons.business_outlined)),
            Tab(text: l10n.settingsTab, icon: const Icon(Icons.tune_outlined)),
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
    final canEdit = _permissions.canEditCompanyProfile();
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
    final canEditSettings = _permissions.canEditSettings();
    final canEditInvoiceSettings = _permissions.canEditInvoiceSettings();
    final canManageIntegrations = _permissions.canManageIntegrations();

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

            // Tax settings (Req 7.3)
            _buildTaxSettingsCard(context, canEditSettings),
            const SizedBox(height: 16),

            // Invoice settings — owner can edit bank details, footer, payment terms
            _buildInvoiceSettingsCard(context, canEditInvoiceSettings),
            const SizedBox(height: 16),

            // Document numbering (Req 7.3)
            _buildNumberingCard(context, canEditSettings),
            const SizedBox(height: 16),

            // Print templates (Req 7.3)
            _buildPrintTemplatesCard(context, canEditSettings),
            const SizedBox(height: 16),

            // Integrations (Req 7.4)
            _buildIntegrationsCard(context, canManageIntegrations),
            const SizedBox(height: 24),

            // Save button — shown if user can edit any settings
            if (canEditSettings || canEditInvoiceSettings)
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

  Widget _buildTaxSettingsCard(BuildContext context, bool canEdit) {
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
              value: taxId.isNotEmpty ? taxId : '—',
              icon: Icons.badge_outlined,
            ),
            _ReadOnlyInfoRow(
              label: l10n.settingsVatRate,
              value: '18%',
              icon: Icons.percent_outlined,
            ),
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
  // Shared text field builder
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    String? errorText,
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
      // Save to /companies/{companyId} (Req 7.5)
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .update({
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
      });

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
    final canEditAll = _permissions.canEditSettings();
    final canEditInvoice = _permissions.canEditInvoiceSettings();
    if (!canEditAll && !canEditInvoice) return;

    setState(() {
      _settingsErrors = {};
      _settingsSaving = true;
    });

    try {
      // Owner can only save invoice-related fields; admin/super_admin save all
      final Map<String, dynamic> updates = {};
      if (canEditInvoice) {
        updates['invoiceFooterText'] = _invoiceFooterCtrl.text.trim();
        updates['paymentTerms'] = _paymentTermsCtrl.text.trim();
        updates['bankDetails'] = _bankDetailsCtrl.text.trim();
      }
      if (updates.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .update(updates);

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
      ),
    );
  }
}
