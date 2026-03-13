import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../services/client_service.dart';
import '../../../utils/geocoding_helper.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/zone_selector.dart';

/// Диалог создания нового клиента.
/// Возвращает [ClientModel] с заполненными данными после сохранения,
/// либо null если отменено.
class CreateClientDialog extends StatefulWidget {
  final String companyId;

  const CreateClientDialog({super.key, required this.companyId});

  @override
  State<CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<CreateClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactController = TextEditingController();
  final _vatIdController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isSaving = false;
  bool _manualCoordinates = false;
  List<String> _selectedZones = [];
  bool _zonesError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _contactController.dispose();
    _vatIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    final zonesValid = _selectedZones.isNotEmpty;
    setState(() => _zonesError = !zonesValid);
    if (!formValid || !zonesValid) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      double latitude = 0;
      double longitude = 0;

      if (_manualCoordinates) {
        latitude = double.parse(_latitudeController.text);
        longitude = double.parse(_longitudeController.text);
      } else {
        final result = await GeocodingHelper.geocodeAddress(
            _addressController.text.trim());
        if (result != null) {
          latitude = result['latitude']!;
          longitude = result['longitude']!;
        } else {
          if (mounted) {
            final useManual = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.addressNotFound),
                content: Text(
                    l10n.addressNotFoundDescription(_addressController.text)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.fixAddress),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.enterManualCoordinates),
                  ),
                ],
              ),
            );
            if (useManual == true) {
              setState(() {
                _manualCoordinates = true;
                _isSaving = false;
              });
              return;
            }
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      final client = ClientModel(
        id: '',
        clientNumber: _numberController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        contactPerson: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        vatId: _vatIdController.text.trim().isEmpty
            ? null
            : _vatIdController.text.trim(),
        companyId: widget.companyId,
        zones: _selectedZones,
      );

      await ClientService(companyId: widget.companyId).addClient(client);

      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.clientCreated);
        Navigator.pop(context, client);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.createClient),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _numberController,
                  decoration: InputDecoration(
                    labelText: l10n.clientNumberLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.clientNumberRequired;
                    }
                    if (v.length != 6) return l10n.clientNumberLength;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.clientName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.address,
                    border: const OutlineInputBorder(),
                    helperText: l10n.addressWillBeGeocoded,
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vatIdController,
                  decoration: InputDecoration(
                    labelText: l10n.vatId,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: l10n.contactPerson,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // אזורי חלוקה — обязательное поле
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.deliveryZones,
                    border: const OutlineInputBorder(),
                    errorText: _zonesError ? l10n.zonesRequired : null,
                  ),
                  child: ZoneSelector(
                    selectedZones: _selectedZones,
                    onChanged: (zones) => setState(() {
                      _selectedZones = zones;
                      _zonesError = zones.isEmpty;
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(l10n.manualCoordinates),
                  subtitle: Text(l10n.manualCoordinatesSubtitle),
                  value: _manualCoordinates,
                  onChanged: (v) => setState(() => _manualCoordinates = v),
                ),
                if (_manualCoordinates) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      labelText: l10n.latitude,
                      border: const OutlineInputBorder(),
                      helperText: l10n.latitudeExample,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.required;
                      if (double.tryParse(v) == null) return l10n.invalidNumber;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      labelText: l10n.longitude,
                      border: const OutlineInputBorder(),
                      helperText: l10n.longitudeExample,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.required;
                      if (double.tryParse(v) == null) return l10n.invalidNumber;
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.createClient),
        ),
      ],
    );
  }
}
