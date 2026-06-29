import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/warehouse_structure.dart';
import '../../services/company_terminology_service.dart';
import '../../utils/snackbar_helper.dart';

/// Опросник: штуки / коробки / паллеты → профиль склада компании.
class WarehouseSetupQuestionnaireScreen extends StatefulWidget {
  const WarehouseSetupQuestionnaireScreen({
    super.key,
    required this.companyId,
  });

  final String companyId;

  @override
  State<WarehouseSetupQuestionnaireScreen> createState() =>
      _WarehouseSetupQuestionnaireScreenState();
}

class _WarehouseSetupQuestionnaireScreenState
    extends State<WarehouseSetupQuestionnaireScreen> {
  int _step = 0;
  bool _saving = false;

  String _unitPackaging = WarehouseStructure.mixedUnits;
  String _boxPalletMode = WarehouseStructure.palletized;
  final _unitsPerBoxCtrl = TextEditingController(text: '12');
  final _boxesPerPalletCtrl = TextEditingController(text: '16');

  @override
  void dispose() {
    _unitsPerBoxCtrl.dispose();
    _boxesPerPalletCtrl.dispose();
    super.dispose();
  }

  bool get _usesBoxes =>
      _unitPackaging == WarehouseStructure.boxed ||
      _unitPackaging == WarehouseStructure.mixedUnits;
  bool get _usesPallets =>
      _boxPalletMode == WarehouseStructure.palletized ||
      _boxPalletMode == WarehouseStructure.mixedPallets;

  bool get _needsDefaultsStep => _usesBoxes;

  int get _lastStep {
    if (!_usesBoxes && _unitPackaging == WarehouseStructure.loose) return 0;
    if (!_needsDefaultsStep) return 1;
    return 2;
  }

  void _next() {
    if (_step < _lastStep) {
      if (_step == 0 && _unitPackaging == WarehouseStructure.loose) {
        _boxPalletMode = WarehouseStructure.noPallets;
      }
      setState(() => _step++);
      return;
    }
    _save();
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    var units = int.tryParse(_unitsPerBoxCtrl.text.trim()) ?? 1;
    var boxes = int.tryParse(_boxesPerPalletCtrl.text.trim()) ?? 16;
    if (units < 1) units = 1;
    if (boxes < 1) boxes = 1;

    setState(() => _saving = true);
    try {
      await CompanyTerminologyService(companyId: widget.companyId)
          .saveWarehouseStructure(WarehouseStructure(
        unitPackaging: _unitPackaging,
        boxPalletMode: _boxPalletMode,
        defaultUnitsPerBox: units,
        defaultBoxesPerPallet: boxes,
      ));
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, l10n.warehouseQuestionnaireSaved);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '$e');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.warehouseQuestionnaireTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / (_lastStep + 1),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_step == 0) ...[
            Text(l10n.warehouseQuestionUnitTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.warehouseQuestionUnitHint,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            _choice(
              l10n.warehouseUnitLoose,
              l10n.warehouseUnitLooseHint,
              WarehouseStructure.loose,
              _unitPackaging,
              (v) => setState(() => _unitPackaging = v),
            ),
            _choice(
              l10n.warehouseUnitBoxed,
              l10n.warehouseUnitBoxedHint,
              WarehouseStructure.boxed,
              _unitPackaging,
              (v) => setState(() => _unitPackaging = v),
            ),
            _choice(
              l10n.warehouseUnitBoth,
              l10n.warehouseUnitBothHint,
              WarehouseStructure.mixedUnits,
              _unitPackaging,
              (v) => setState(() => _unitPackaging = v),
            ),
          ],
          if (_step == 1) ...[
            Text(l10n.warehouseQuestionPalletTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.warehouseQuestionPalletHint,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (_unitPackaging != WarehouseStructure.loose) ...[
              _choice(
                l10n.warehousePalletNone,
                l10n.warehousePalletNoneHint,
                WarehouseStructure.noPallets,
                _boxPalletMode,
                (v) => setState(() => _boxPalletMode = v),
              ),
              _choice(
                l10n.warehousePalletAlways,
                l10n.warehousePalletAlwaysHint,
                WarehouseStructure.palletized,
                _boxPalletMode,
                (v) => setState(() => _boxPalletMode = v),
              ),
              _choice(
                l10n.warehousePalletBoth,
                l10n.warehousePalletBothHint,
                WarehouseStructure.mixedPallets,
                _boxPalletMode,
                (v) => setState(() => _boxPalletMode = v),
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.warehouseLooseNoPallets),
                ),
              ),
          ],
          if (_step == 2 && _needsDefaultsStep) ...[
            Text(l10n.warehouseQuestionDefaultsTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.warehouseQuestionDefaultsHint,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            TextField(
              controller: _unitsPerBoxCtrl,
              decoration: InputDecoration(
                labelText: l10n.warehouseDefaultUnitsPerBox,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (_usesPallets) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _boxesPerPalletCtrl,
                decoration: InputDecoration(
                  labelText: l10n.warehouseDefaultBoxesPerPallet,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_step > 0)
                TextButton(onPressed: _saving ? null : _back, child: Text(l10n.previous))
              else
                const SizedBox(width: 64),
              const Spacer(),
              if (_step == 2 && _needsDefaultsStep)
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.setupWizardSkip),
                ),
              FilledButton(
                onPressed: _saving ? null : _next,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step < _lastStep ? l10n.next : l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice(
    String title,
    String subtitle,
    String value,
    String group,
    ValueChanged<String> onSelect,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: value,
        groupValue: group,
        onChanged: _saving ? null : (v) => onSelect(v!),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
