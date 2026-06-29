import 'package:flutter/material.dart';
import '../../models/delivery_point.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/delivery_point_address_resolver.dart';
import '../../utils/geocoding_helper.dart';

class EditPointDialog extends StatefulWidget {
  final DeliveryPoint point;

  const EditPointDialog({super.key, required this.point});

  @override
  State<EditPointDialog> createState() => _EditPointDialogState();
}

class _EditPointDialogState extends State<EditPointDialog> {
  late String _urgency;
  late int _orderInRoute;
  late bool _deliveryAddressDiffers;
  DateTime? _openingTime;
  DateTime? _closingTime;
  double? _overrideLat;
  double? _overrideLng;
  final _orderController = TextEditingController();
  final _overrideAddressController = TextEditingController();
  bool _geocoding = false;

  @override
  void initState() {
    super.initState();
    final p = widget.point;
    _urgency = p.urgency;
    _orderInRoute = p.orderInRoute;
    _openingTime = p.openingTime;
    _closingTime = p.closingTime;
    _orderController.text = (_orderInRoute + 1).toString();
    _deliveryAddressDiffers = p.hasDeliveryAddressOverride;
    if (_deliveryAddressDiffers) {
      _overrideAddressController.text = p.deliveryAddressOverride ?? '';
      _overrideLat = p.deliveryAddressOverrideLat;
      _overrideLng = p.deliveryAddressOverrideLng;
    }
  }

  Future<void> _pickTime({required bool opening}) async {
    final current = opening ? _openingTime : _closingTime;
    final initial = current != null
        ? TimeOfDay(hour: current.hour, minute: current.minute)
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final now = DateTime.now();
    final dt =
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    setState(() {
      if (opening) {
        _openingTime = dt;
      } else {
        _closingTime = dt;
      }
    });
  }

  String _fmt(DateTime? dt, AppLocalizations l10n) {
    if (dt == null) return l10n.deliveryWindowNotSet;
    return TimeOfDay(hour: dt.hour, minute: dt.minute).format(context);
  }

  Future<void> _geocodeOverride() async {
    final l10n = AppLocalizations.of(context)!;
    final addr = _overrideAddressController.text.trim();
    if (addr.isEmpty) return;
    setState(() => _geocoding = true);
    try {
      final geo = await GeocodingHelper.geocodeAddress(addr);
      if (!mounted) return;
      if (geo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addressNotFound)),
        );
        return;
      }
      setState(() {
        _overrideLat = geo['latitude'];
        _overrideLng = geo['longitude'];
      });
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  @override
  void dispose() {
    _orderController.dispose();
    _overrideAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolved = resolveDeliveryPointAddress(widget.point);

    return AlertDialog(
      title: Text('Edit: ${widget.point.clientName}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _urgency,
              decoration: const InputDecoration(labelText: 'Priority / עדיפות'),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal / רגיל')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent / דחוף')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _urgency = value);
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.deliveryWindowTitle,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 16),
                    label: Text(
                        '${l10n.deliveryWindowFrom}: ${_fmt(_openingTime, l10n)}'),
                    onPressed: () => _pickTime(opening: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_available, size: 16),
                    label: Text(
                        '${l10n.deliveryWindowTo}: ${_fmt(_closingTime, l10n)}'),
                    onPressed: () => _pickTime(opening: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${l10n.clientAddressLabel}: ${resolved.clientAddress}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.deliveryAddressOverrideToggle,
                style: const TextStyle(fontSize: 13),
              ),
              value: _deliveryAddressDiffers,
              onChanged: (v) => setState(() => _deliveryAddressDiffers = v),
            ),
            if (_deliveryAddressDiffers) ...[
              TextFormField(
                controller: _overrideAddressController,
                decoration: InputDecoration(
                  labelText: l10n.deliveryAddressOverrideLabel,
                  hintText: l10n.deliveryAddressOverrideHint,
                ),
                minLines: 1,
                maxLines: 2,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _geocoding ? null : _geocodeOverride,
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: Text(l10n.findCoordinates),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderController,
              decoration: const InputDecoration(
                labelText: 'Order in Route / סדר במסלול',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final order = int.tryParse(value);
                if (order != null && order > 0) {
                  _orderInRoute = order - 1;
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHi,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.pallets}: ${widget.point.pallets}'),
                  Text('Status: ${widget.point.status}'),
                  if (widget.point.driverName != null)
                    Text('Driver: ${widget.point.driverName}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {'cancelPoint': true}),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(l10n.cancelPoint),
        ),
        ElevatedButton(
          onPressed: () {
            final override = _deliveryAddressDiffers
                ? _overrideAddressController.text.trim()
                : null;
            Navigator.pop(context, {
              'urgency': _urgency,
              'orderInRoute': _orderInRoute,
              'updateWindow': true,
              'openingTime': _openingTime,
              'closingTime': _closingTime,
              'clearDeliveryAddressOverride': !_deliveryAddressDiffers,
              if (override != null && override.isNotEmpty)
                'deliveryAddressOverride': override,
              if (_overrideLat != null) 'deliveryAddressOverrideLat': _overrideLat,
              if (_overrideLng != null) 'deliveryAddressOverrideLng': _overrideLng,
            });
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
