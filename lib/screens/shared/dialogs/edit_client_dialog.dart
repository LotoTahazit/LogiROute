import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../models/delivery_point.dart';
import '../../../utils/geocoding_helper.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/zone_selector.dart';
import '../../../theme/app_theme.dart';

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
  late TextEditingController _vatIdController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isGeocoding = false;
  bool _manualCoordinates = false;
  late List<String> _selectedZones;
  bool _zonesError = false;
  late String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _numberController = TextEditingController(text: widget.client.clientNumber);
    _addressController = TextEditingController(text: widget.client.address);
    _phoneController = TextEditingController(text: widget.client.phone ?? '');
    _contactController =
        TextEditingController(text: widget.client.contactPerson ?? '');
    _vatIdController = TextEditingController(text: widget.client.vatId ?? '');
    _latitudeController =
        TextEditingController(text: widget.client.latitude.toString());
    _longitudeController =
        TextEditingController(text: widget.client.longitude.toString());
    _selectedZones = List<String>.from(widget.client.zones);
    _paymentMethod = widget.client.paymentMethod;
  }

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

  Future<void> _saveClient() async {
    final formValid = _formKey.currentState!.validate();
    final zonesValid = _selectedZones.isNotEmpty;
    setState(() => _zonesError = !zonesValid);
    if (!formValid || !zonesValid) return;

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
        // 🛡️ GUARD: проверяем ручные координаты
        if (!DeliveryPoint.isValidCoordinates(latitude, longitude)) {
          debugPrint(
              '⚠️ [Edit Client] REJECTED manual coords outside Israel: ($latitude, $longitude)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${l10n.error}: координаты ($latitude, $longitude) вне Израиля'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isGeocoding = false);
          return;
        }
        debugPrint(
            '✅ [Edit Client] Using manual coordinates: ($latitude, $longitude)');
      } else {
        latitude = widget.client.latitude;
        longitude = widget.client.longitude;

        // Геокодируем ТОЛЬКО если адрес изменился
        final addressChanged = addressToGeocode != widget.client.address.trim();

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
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.fixAddress),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.enterManualCoordinates),
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
        vatId: _vatIdController.text.isEmpty ? null : _vatIdController.text,
        companyId: widget.client.companyId,
        zones: _selectedZones,
        paymentMethod: _paymentMethod,
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
                if (widget.client.latitude != 0 &&
                    widget.client.longitude != 0 &&
                    !_manualCoordinates)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '📍 ${widget.client.latitude.toStringAsFixed(6)}, ${widget.client.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
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
                  controller: _vatIdController,
                  decoration: InputDecoration(
                    labelText: l10n.vatId,
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
                // אופן תשלום
                DropdownButtonFormField<String>(
                  key: ValueKey(_paymentMethod),
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: l10n.paymentMethodLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: null, child: Text(l10n.notSelected)),
                    DropdownMenuItem(value: 'מזומן', child: Text(l10n.cash)),
                    DropdownMenuItem(value: "צ'ק", child: Text(l10n.cheque)),
                    DropdownMenuItem(
                        value: 'העברה בנקאית', child: Text(l10n.bankTransfer)),
                    DropdownMenuItem(
                        value: 'כרטיס אשראי', child: Text(l10n.creditCard)),
                  ],
                  onChanged: (val) => setState(() => _paymentMethod = val),
                ),
                const SizedBox(height: 16),
                // אזורי חלוקה
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
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.manualCoordinates),
                  subtitle: Text(l10n.manualCoordinatesSubtitle),
                  value: _manualCoordinates,
                  onChanged: (value) {
                    setState(() => _manualCoordinates = value);
                  },
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
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.required;
                      if (double.tryParse(value!) == null) {
                        return l10n.invalidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      labelText: l10n.longitude,
                      border: const OutlineInputBorder(),
                      helperText: l10n.longitudeExample,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.required;
                      if (double.tryParse(value!) == null) {
                        return l10n.invalidNumber;
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
