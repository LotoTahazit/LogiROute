import 'package:flutter/material.dart';
import '../../models/company_terminology.dart';
import '../../services/company_terminology_service.dart';
import '../../services/company_context.dart';
import '../../services/product_type_service.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Экран настройки терминологии компании
class TerminologySettingsScreen extends StatefulWidget {
  const TerminologySettingsScreen({super.key});

  @override
  State<TerminologySettingsScreen> createState() =>
      _TerminologySettingsScreenState();
}

class _TerminologySettingsScreenState extends State<TerminologySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _unitNameController;
  late TextEditingController _unitNamePluralController;
  late TextEditingController _palletNameController;
  late TextEditingController _palletNamePluralController;
  bool _usesPallets = true;
  String _capacityCalculation = 'units';
  String _businessType = 'custom';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _unitNameController = TextEditingController();
    _unitNamePluralController = TextEditingController();
    _palletNameController = TextEditingController();
    _palletNamePluralController = TextEditingController();
    _loadTerminology();
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _unitNamePluralController.dispose();
    _palletNameController.dispose();
    _palletNamePluralController.dispose();
    super.dispose();
  }

  Future<void> _loadTerminology() async {
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';

    if (companyId.isEmpty) return;

    final service = CompanyTerminologyService(companyId: companyId);
    final terminology = await service.getTerminology();

    setState(() {
      _unitNameController.text = terminology.unitName;
      _unitNamePluralController.text = terminology.unitNamePlural;
      _palletNameController.text = terminology.palletName;
      _palletNamePluralController.text = terminology.palletNamePlural;
      _usesPallets = terminology.usesPallets;
      _capacityCalculation = terminology.capacityCalculation;
      _businessType = terminology.businessType;
      _isLoading = false;
    });
  }

  Future<void> _applyTemplate(String businessType) async {
    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    final authService = context.read<AuthService>();
    final userName = authService.userModel?.name ?? 'Unknown';

    if (companyId.isEmpty) return;

    final service = CompanyTerminologyService(companyId: companyId);
    await service.setBusinessTypeTemplate(businessType);

    // Создаём шаблонные товары
    final productService = ProductTypeService(companyId: companyId);
    await productService.createTemplateProducts(businessType, userName);

    await _loadTerminology();

    if (mounted) {
      SnackbarHelper.showSuccess(context, l10n.terminologyUpdated);
    }
  }

  Future<void> _saveCustomTerminology() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';

    if (companyId.isEmpty) return;

    final terminology = CompanyTerminology(
      companyId: companyId,
      unitName: _unitNameController.text.trim(),
      unitNamePlural: _unitNamePluralController.text.trim(),
      palletName: _palletNameController.text.trim(),
      palletNamePlural: _palletNamePluralController.text.trim(),
      usesPallets: _usesPallets,
      capacityCalculation: _capacityCalculation,
      businessType: 'custom',
    );

    final service = CompanyTerminologyService(companyId: companyId);
    await service.saveTerminology(terminology);

    if (mounted) {
      SnackbarHelper.showSuccess(context, l10n.terminologyUpdated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.terminologySettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.terminologySettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCustomTerminology,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectTemplate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTemplateButtons(l10n),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              l10n.customSettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildCustomForm(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateButtons(AppLocalizations l10n) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildTemplateCard(
          l10n.businessTypePackaging,
          Icons.inventory_2,
          'packaging',
          Colors.blue,
        ),
        _buildTemplateCard(
          l10n.businessTypeFood,
          Icons.restaurant,
          'food',
          Colors.orange,
        ),
        _buildTemplateCard(
          l10n.businessTypeClothing,
          Icons.checkroom,
          'clothing',
          Colors.purple,
        ),
        _buildTemplateCard(
          l10n.businessTypeConstruction,
          Icons.construction,
          'construction',
          Colors.brown,
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
      String title, IconData icon, String type, Color color) {
    final isSelected = _businessType == type;

    return InkWell(
      onTap: () => _applyTemplate(type),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _unitNameController,
                  decoration: InputDecoration(
                    labelText: l10n.unitName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _unitNamePluralController,
                  decoration: InputDecoration(
                    labelText: l10n.unitNamePlural,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.usesPallets),
            value: _usesPallets,
            onChanged: (value) {
              setState(() => _usesPallets = value);
            },
          ),
          if (_usesPallets) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _palletNameController,
                    decoration: InputDecoration(
                      labelText: l10n.palletName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_usesPallets && (value == null || value.isEmpty)) {
                        return l10n.requiredField;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _palletNamePluralController,
                    decoration: InputDecoration(
                      labelText: l10n.palletNamePlural,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_usesPallets && (value == null || value.isEmpty)) {
                        return l10n.requiredField;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _capacityCalculation,
            decoration: InputDecoration(
              labelText: l10n.capacityCalculation,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                  value: 'units', child: Text(l10n.capacityByUnits)),
              DropdownMenuItem(
                  value: 'weight', child: Text(l10n.capacityByWeight)),
              DropdownMenuItem(
                  value: 'volume', child: Text(l10n.capacityByVolume)),
            ],
            onChanged: (value) {
              setState(() => _capacityCalculation = value ?? 'units');
            },
          ),
        ],
      ),
    );
  }
}
