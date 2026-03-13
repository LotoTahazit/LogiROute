import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/company_settings.dart';
import '../../services/company_settings_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import '../../features/owner_dashboard/widgets/sections/integration_settings_dialog.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Компания не выбрана'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка инициализации: $e'),
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
          debugPrint('✅ [CompanySettings] Settings loaded and applied');
        } else {
          debugPrint(
              '⚠️ [CompanySettings] No settings found - showing empty form');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Настройки не найдены. Заполните форму.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [CompanySettings] Error loading settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка загрузки: $e'),
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
      final settings = CompanySettings(
        id: 'settings',
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
        driverName: '',
        driverPhone: '',
        departureTime: '07:00',
      );

      await service.saveSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.settingsSaved}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${l10n.errorSavingSettings}: $e'),
            backgroundColor: Colors.red,
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: configured
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              configured ? l10n.settingsConfigured : l10n.settingsNotConfigured,
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
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
