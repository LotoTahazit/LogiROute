import 'package:flutter/material.dart';
import '../../models/company_settings.dart';
import '../../services/company_settings_service.dart';
import '../../l10n/app_localizations.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CompanySettingsService();

  bool _isLoading = true;
  bool _isSaving = false;

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
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _departureTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _service.getSettings();

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
        _driverNameController.text = settings.driverName;
        _driverPhoneController.text = settings.driverPhone;
        _departureTimeController.text = settings.departureTime;
      } else {
        // Создаем настройки по умолчанию
        await _service.createDefaultSettings();
        await _loadSettings();
        return;
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoadingSettings}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final settings = CompanySettings(
        id: 'default',
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
        driverName: _driverNameController.text,
        driverPhone: _driverPhoneController.text,
        departureTime: _departureTimeController.text,
      );

      await _service.saveSettings(settings);

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
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _departureTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                        ),
                        _buildTextField(
                          controller: _websiteController,
                          label: l10n.website,
                          icon: Icons.language,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      l10n.defaultDriver,
                      [
                        _buildTextField(
                          controller: _driverNameController,
                          label: l10n.driverName,
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          controller: _driverPhoneController,
                          label: l10n.driverPhone,
                          icon: Icons.phone_android,
                        ),
                        _buildTextField(
                          controller: _departureTimeController,
                          label: l10n.departureTime,
                          icon: Icons.access_time,
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
                        ),
                        _buildTextField(
                          controller: _paymentTermsController,
                          label: l10n.paymentTerms,
                          icon: Icons.payment,
                        ),
                        _buildTextField(
                          controller: _bankDetailsController,
                          label: l10n.bankDetails,
                          icon: Icons.account_balance,
                          maxLines: 3,
                        ),
                      ],
                    ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.requiredField;
          }
          return null;
        },
      ),
    );
  }
}
