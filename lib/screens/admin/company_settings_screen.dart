import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/company_settings.dart';
import '../../services/company_settings_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/snackbar_helper.dart';
import '../../features/owner_dashboard/widgets/sections/integration_settings_dialog.dart';
import '../../features/owner_dashboard/widgets/sections/accounting_provider_settings_dialog.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  CompanySettingsService? _service;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _companyId;

  // Controllers
  final _nameHebrewController = TextEditingController();
  final _nameEnglishController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressHebrewController = TextEditingController();
  final _addressEnglishController = TextEditingController();
  final _poBoxController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _faxController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _invoiceFooterTextController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _bankDetailsController = TextEditingController();

  /// Загруженные настройки — чтобы при сохранении не затирать поля, которых
  /// нет на этой форме (departureTime, driver*, параметры маршрутизации).
  CompanySettings? _loaded;

  /// Политика «POD-фото обязательно на каждую доставку».
  bool _requirePodPhoto = false;

  /// Куда выгружать бухгалтерию: none | export | greeninvoice | icount
  String _accountingProvider = 'none';

  static const _accountingProviders = [
    'none',
    'export',
    'greeninvoice',
    'icount',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
  }

  void _initializeService() {
    debugPrint('🚀 [CompanySettings] Initializing service...');
    try {
      final companyCtx = CompanyContext.of(context);
      final companyId = companyCtx.effectiveCompanyId;
      debugPrint('📍 [CompanySettings] EffectiveCompanyId: $companyId');

      if (companyId == null || companyId.isEmpty) {
        debugPrint('❌ [CompanySettings] CompanyId is null or empty');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.companySettingsNotSelected),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      debugPrint(
          '✅ [CompanySettings] Setting up service for company: $companyId');
      setState(() {
        _companyId = companyId;
        _service = CompanySettingsService(companyId: companyId);
      });

      debugPrint('🔄 [CompanySettings] Calling _loadSettings...');
      _loadSettings();
    } catch (e) {
      debugPrint('❌ [CompanySettings] Error in _initializeService: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.companySettingsInitError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSettings() async {
    if (_companyId == null || _service == null) {
      debugPrint('❌ [CompanySettings] CompanyId or service is null');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final service = _service!;
    debugPrint(
        '🔍 [CompanySettings] Loading settings for company: $_companyId');
    setState(() => _isLoading = true);

    try {
      final settings = await service.getSettings();
      debugPrint(
          '📊 [CompanySettings] Settings result: ${settings != null ? "found" : "not found"}');

      if (mounted) {
        if (settings != null) {
          _nameHebrewController.text = settings.nameHebrew;
          _nameEnglishController.text = settings.nameEnglish;
          _taxIdController.text = settings.taxId;
          _addressHebrewController.text = settings.addressHebrew;
          _addressEnglishController.text = settings.addressEnglish;
          _poBoxController.text = settings.poBox;
          _cityController.text = settings.city;
          _zipCodeController.text = settings.zipCode;
          _phoneController.text = settings.phone;
          _faxController.text = settings.fax;
          _emailController.text = settings.email;
          _websiteController.text = settings.website;
          _invoiceFooterTextController.text = settings.invoiceFooterText;
          _paymentTermsController.text = settings.paymentTerms;
          _bankDetailsController.text = settings.bankDetails;
          _loaded = settings; // сохраняем для безопасного copyWith при записи
          _requirePodPhoto = settings.requirePodPhoto;
          _accountingProvider = settings.accountingProvider;
          debugPrint('✅ [CompanySettings] Settings loaded and applied');
        } else {
          debugPrint(
              '⚠️ [CompanySettings] No settings found - showing empty form');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.companySettingsEmptyWarning,
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [CompanySettings] Error loading settings: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.companySettingsLoadError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint(
          '🏁 [CompanySettings] Finishing load, setting isLoading = false');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_companyId == null || _service == null) return;
    if (!_formKey.currentState!.validate()) return;

    final service = _service!;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      // Базируемся на загруженных настройках, чтобы НЕ затереть поля вне этой
      // формы (departureTime, driver*, скорость/разгрузка/режим даты).
      final base = _loaded ??
          CompanySettings(
            id: 'settings',
            nameHebrew: '',
            nameEnglish: '',
            taxId: '',
            addressHebrew: '',
            addressEnglish: '',
            poBox: '',
            city: '',
            zipCode: '',
            phone: '',
            fax: '',
            email: '',
            website: '',
            invoiceFooterText: '',
            paymentTerms: '',
            bankDetails: '',
            driverName: '',
            driverPhone: '',
            departureTime: '07:00',
          );
      final settings = base.copyWith(
        nameHebrew: _nameHebrewController.text,
        nameEnglish: _nameEnglishController.text,
        taxId: _taxIdController.text,
        addressHebrew: _addressHebrewController.text,
        addressEnglish: _addressEnglishController.text,
        poBox: _poBoxController.text,
        city: _cityController.text,
        zipCode: _zipCodeController.text,
        phone: _phoneController.text,
        fax: _faxController.text,
        email: _emailController.text,
        website: _websiteController.text,
        invoiceFooterText: _invoiceFooterTextController.text,
        paymentTerms: _paymentTermsController.text,
        bankDetails: _bankDetailsController.text,
        requirePodPhoto: _requirePodPhoto,
        accountingProvider: _accountingProvider,
      );

      await service.saveSettings(settings);
      _loaded = settings;

      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.settingsSaved);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          l10n.companySettingsSaveFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameHebrewController.dispose();
    _nameEnglishController.dispose();
    _taxIdController.dispose();
    _addressHebrewController.dispose();
    _addressEnglishController.dispose();
    _poBoxController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    _faxController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _invoiceFooterTextController.dispose();
    _paymentTermsController.dispose();
    _bankDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    debugPrint(
        '🏗️ [CompanySettings] build() called, _isLoading=$_isLoading, _companyId=$_companyId');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companySettings),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: l10n.saveSettings,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSection(
                      l10n.companyDetails,
                      [
                        _buildTextField(
                          controller: _nameHebrewController,
                          label: l10n.companyNameHebrew,
                          icon: Icons.business,
                        ),
                        _buildTextField(
                          controller: _nameEnglishController,
                          label: l10n.companyNameEnglish,
                          icon: Icons.business_outlined,
                        ),
                        _buildTextField(
                          controller: _taxIdController,
                          label: l10n.taxId,
                          icon: Icons.numbers,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      l10n.address,
                      [
                        _buildTextField(
                          controller: _addressHebrewController,
                          label: l10n.addressHebrew,
                          icon: Icons.location_on,
                        ),
                        _buildTextField(
                          controller: _addressEnglishController,
                          label: l10n.addressEnglish,
                          icon: Icons.location_on_outlined,
                        ),
                        if (narrow)
                          Column(
                            children: [
                              _buildTextField(
                                controller: _poBoxController,
                                label: l10n.poBox,
                                icon: Icons.markunread_mailbox,
                                required: false,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _cityController,
                                label: l10n.city,
                                icon: Icons.location_city,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _zipCodeController,
                                label: l10n.zipCode,
                                icon: Icons.pin_drop,
                                required: false,
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _poBoxController,
                                  label: l10n.poBox,
                                  icon: Icons.markunread_mailbox,
                                  required: false,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _cityController,
                                  label: l10n.city,
                                  icon: Icons.location_city,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _zipCodeController,
                                  label: l10n.zipCode,
                                  icon: Icons.pin_drop,
                                  required: false,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      l10n.contact,
                      [
                        _buildTextField(
                          controller: _phoneController,
                          label: l10n.phone,
                          icon: Icons.phone,
                        ),
                        _buildTextField(
                          controller: _faxController,
                          label: l10n.fax,
                          icon: Icons.print,
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: l10n.email,
                          icon: Icons.email,
                          required: false,
                        ),
                        _buildTextField(
                          controller: _websiteController,
                          label: l10n.website,
                          icon: Icons.language,
                          required: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      l10n.invoice,
                      [
                        _buildTextField(
                          controller: _invoiceFooterTextController,
                          label: l10n.invoiceFooterText,
                          icon: Icons.notes,
                          maxLines: 5,
                          required: false,
                        ),
                        _buildTextField(
                          controller: _paymentTermsController,
                          label: l10n.paymentTerms,
                          icon: Icons.payment,
                          required: false,
                        ),
                        _buildTextField(
                          controller: _bankDetailsController,
                          label: l10n.bankDetails,
                          icon: Icons.account_balance,
                          maxLines: 3,
                          required: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      l10n.deliverySection,
                      [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _requirePodPhoto,
                          onChanged: (v) =>
                              setState(() => _requirePodPhoto = v),
                          title: Text(l10n.requirePodPhoto),
                          subtitle: Text(l10n.requirePodPhotoHint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildAccountingProviderSection(context),
                    const SizedBox(height: 24),
                    _buildIntegrationsSection(context),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: const Icon(Icons.save),
                      label: Text(l10n.saveSettings),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  String _accountingProviderLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'export':
        return l10n.accountingProviderExport;
      case 'greeninvoice':
        return l10n.accountingProviderGreeninvoice;
      case 'icount':
        return l10n.accountingProviderIcount;
      case 'none':
      default:
        return l10n.accountingProviderNone;
    }
  }

  Widget _buildAccountingProviderSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needsCreds = _accountingProvider == 'greeninvoice' ||
        _accountingProvider == 'icount';

    return _buildSection(
      l10n.accountingProviderSection,
      [
        DropdownButtonFormField<String>(
          initialValue: _accountingProvider,
          decoration: InputDecoration(
            labelText: l10n.accountingProviderLabel,
            border: const OutlineInputBorder(),
          ),
          items: _accountingProviders
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(_accountingProviderLabel(p, l10n)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _accountingProvider = v);
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.accountingProviderHint,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        if (needsCreds && _companyId != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => AccountingProviderSettingsDialog(
                companyId: _companyId!,
                provider: _accountingProvider,
              ),
            ),
            icon: const Icon(Icons.vpn_key_outlined, size: 18),
            label: Text(l10n.accountingProviderConfigure),
          ),
        ],
      ],
    );
  }

  Widget _buildIntegrationsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_companyId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(_companyId)
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
                Text(
                  l10n.settingsIntegrations,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 8),
                _integrationRow(
                  Icons.print,
                  l10n.settingsPrinting,
                  isEnabled('print'),
                  () => _openIntegrationDialog('print', l10n.settingsPrinting),
                ),
                _integrationRow(
                  Icons.email_outlined,
                  l10n.settingsEmailIntegration,
                  isEnabled('email'),
                  () => _openIntegrationDialog(
                      'email', l10n.settingsEmailIntegration),
                ),
                _integrationRow(
                  Icons.chat_outlined,
                  'WhatsApp',
                  isEnabled('whatsapp'),
                  () => _openIntegrationDialog('whatsapp', 'WhatsApp'),
                ),
                _integrationRow(
                  Icons.vpn_key_outlined,
                  l10n.settingsApiKeys,
                  isEnabled('apiKeys'),
                  () => _openIntegrationDialog('apiKeys', l10n.settingsApiKeys),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _integrationRow(
      IconData icon, String label, bool configured, VoidCallback onEdit) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label)),
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
                        color: configured
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        configured
                            ? l10n.settingsConfigured
                            : l10n.settingsNotConfigured,
                        style: TextStyle(
                          fontSize: 12,
                          color: configured ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
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
                Icon(icon, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: configured
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    configured
                        ? l10n.settingsConfigured
                        : l10n.settingsNotConfigured,
                    style: TextStyle(
                      fontSize: 12,
                      color: configured ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
    );
  }

  void _openIntegrationDialog(String key, String label) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => IntegrationSettingsDialog(
        companyId: _companyId!,
        integrationKey: key,
        integrationLabel: label,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool required = true,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return l10n.requiredField;
                }
                return null;
              }
            : null,
      ),
    );
  }
}
