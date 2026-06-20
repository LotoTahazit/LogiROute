import 'package:flutter/material.dart';
import '../../models/delivery_point.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class EditPointDialog extends StatefulWidget {
  final DeliveryPoint point;

  const EditPointDialog({super.key, required this.point});

  @override
  State<EditPointDialog> createState() => _EditPointDialogState();
}

class _EditPointDialogState extends State<EditPointDialog> {
  late String _urgency;
  late int _orderInRoute;
  late String _address;
  DateTime? _openingTime; // окно «с»
  DateTime? _closingTime; // окно «по»
  final _orderController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urgency = widget.point.urgency;
    _orderInRoute = widget.point.orderInRoute;
    _address = widget.point.address;
    _openingTime = widget.point.openingTime;
    _closingTime = widget.point.closingTime;
    _orderController.text = (_orderInRoute + 1).toString();
    _addressController.text = _address;
  }

  /// Открывает выбор времени и сохраняет как DateTime (сегодняшняя дата + время).
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

  @override
  void dispose() {
    _orderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text('Edit Point: ${widget.point.clientName}'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Приоритет
            DropdownButtonFormField<String>(
              initialValue: _urgency,
              decoration: const InputDecoration(labelText: 'Priority / עדיפות'),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal / רגיל')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent / דחוף')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _urgency = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Окно доставки: «с» — «по»
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.deliveryWindowTitle,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 16),
                    label: Text('${l10n.deliveryWindowFrom}: ${_fmt(_openingTime, l10n)}'),
                    onPressed: () => _pickTime(opening: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_available, size: 16),
                    label: Text('${l10n.deliveryWindowTo}: ${_fmt(_closingTime, l10n)}'),
                    onPressed: () => _pickTime(opening: false),
                  ),
                ),
                if (_openingTime != null || _closingTime != null)
                  IconButton(
                    tooltip: l10n.deliveryWindowClear,
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() {
                      _openingTime = null;
                      _closingTime = null;
                    }),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Временный адрес для этой доставки
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.temporaryAddress,
                hintText: l10n.temporaryAddressHint,
                helperText: l10n.temporaryAddressHelper,
                suffixIcon: Tooltip(
                  message: l10n.temporaryAddressTooltip,
                  child: const Icon(Icons.info_outline, color: Colors.blue),
                ),
              ),
              onChanged: (value) {
                _address = value;
              },
            ),

            const SizedBox(height: 16),

            // Порядок в маршруте
            TextFormField(
              controller: _orderController,
              decoration: const InputDecoration(
                labelText: 'Order in Route / סדר במסלול',
                hintText: '1, 2, 3...',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final order = int.tryParse(value);
                if (order != null && order > 0) {
                  _orderInRoute = order - 1; // Сохраняем как 0-based индекс
                }
              },
            ),

            const SizedBox(height: 16),

            // Информация о точке
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHi,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Address: ${widget.point.address}'),
                  Text('Pallets: ${widget.point.pallets}'),
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
        // Кнопка отмены точки
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {'cancelPoint': true}),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(l10n.cancelPoint),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'urgency': _urgency,
            'orderInRoute': _orderInRoute,
            'address': _address,
            'updateWindow': true,
            'openingTime': _openingTime,
            'closingTime': _closingTime,
          }),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
