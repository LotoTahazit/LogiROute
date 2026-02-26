import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../utils/geocoding_helper.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../l10n/app_localizations.dart';

class EditClientDialog extends StatefulWidget {
  final ClientModel client;

  const EditClientDialog({super.key, required this.client});

  @override
  State<EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _contactController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isGeocoding = false;
  bool _manualCoordinates = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _numberController = TextEditingController(text: widget.client.clientNumber);
    _addressController = TextEditingController(text: widget.client.address);
    _phoneController = TextEditingController(text: widget.client.phone ?? '');
    _contactController =
        TextEditingController(text: widget.client.contactPerson ?? '');
    _latitudeController =
        TextEditingController(text: widget.client.latitude.toString());
    _longitudeController =
        TextEditingController(text: widget.client.longitude.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _contactController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isGeocoding = true);

    try {
      double latitude;
      double longitude;
      String addressToGeocode = _addressController.text.trim();

      // Если включен ручной режим - используем введенные координаты
      if (_manualCoordinates) {
        latitude = double.parse(_latitudeController.text);
        longitude = double.parse(_longitudeController.text);
        debugPrint(
            '✅ [Edit Client] Using manual coordinates: ($latitude, $longitude)');
      } else {
        latitude = widget.client.latitude;
        longitude = widget.client.longitude;

        // Геокодируем ТОЛЬКО если адрес изменился
        final addressChanged = addressToGeocode != widget.client.address;

        if (addressChanged) {
          debugPrint(
              '🗺️ [Edit Client] Address changed, geocoding: "$addressToGeocode"');

          final result = await GeocodingHelper.geocodeAddress(addressToGeocode);

          if (result != null) {
            latitude = result['latitude']!;
            longitude = result['longitude']!;
            _latitudeController.text = latitude.toString();
            _longitudeController.text = longitude.toString();
          } else {
            // Предлагаем ввести координаты вручную
            if (mounted) {
              final useManual = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.addressNotFound),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addressNotFoundDescription(
                            _addressController.text),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Вы можете ввести координаты вручную или исправить адрес.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.fixAddress),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ввести координаты вручную'),
                    ),
                  ],
                ),
              );

              if (useManual == true) {
                setState(() {
                  _manualCoordinates = true;
                  _isGeocoding = false;
                });
                return;
              }
            }

            setState(() => _isGeocoding = false);
            return;
          }
        } else {
          debugPrint(
              '✅ [Edit Client] Address unchanged, keeping coordinates: ($latitude, $longitude)');
        }
      }

      final updatedClient = ClientModel(
        id: widget.client.id,
        clientNumber: _numberController.text,
        name: _nameController.text,
        address: _addressController.text,
        latitude: latitude,
        longitude: longitude,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        contactPerson:
            _contactController.text.isEmpty ? null : _contactController.text,
        companyId: widget.client.companyId,
      );

      if (mounted) {
        Navigator.pop(context, updatedClient);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '${l10n.geocodingError}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editClient),
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
                    labelText: l10n.clientNumber,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.clientName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.address,
                    border: const OutlineInputBorder(),
                    helperText: l10n.addressWillBeGeocoded,
                  ),
                  maxLines: 2,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: l10n.contactPerson,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Ввести координаты вручную'),
                  subtitle:
                      const Text('Используйте если геокодирование не работает'),
                  value: _manualCoordinates,
                  onChanged: (value) {
                    setState(() => _manualCoordinates = value);
                  },
                ),
                if (_manualCoordinates) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Широта (Latitude)',
                      border: OutlineInputBorder(),
                      helperText: 'Например: 31.9539907',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.required;
                      if (double.tryParse(value!) == null) {
                        return 'Введите число';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Долгота (Longitude)',
                      border: OutlineInputBorder(),
                      helperText: 'Например: 34.8062546',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.required;
                      if (double.tryParse(value!) == null) {
                        return 'Введите число';
                      }
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
          onPressed: _isGeocoding ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isGeocoding ? null : _saveClient,
          child: _isGeocoding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
