import 'package:flutter/material.dart';
import '../../../models/box_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/box_type_selector.dart';

/// Секция деталей заказа
class OrderDetailsSection extends StatelessWidget {
  final List<BoxType> selectedBoxTypes;
  final TextEditingController palletsController;
  final TextEditingController boxesController;
  final String urgency;
  final Function(List<BoxType> boxTypes) onBoxTypesChanged;
  final Function(String urgency) onUrgencyChanged;

  const OrderDetailsSection({
    super.key,
    required this.selectedBoxTypes,
    required this.palletsController,
    required this.boxesController,
    required this.urgency,
    required this.onBoxTypesChanged,
    required this.onUrgencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פרטי הזמנה', // Order Details
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BoxTypeSelector(
          selectedBoxTypes: selectedBoxTypes,
          onChanged: onBoxTypesChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: palletsController,
                decoration: InputDecoration(
                  labelText: l10n.pallets,
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: boxesController,
                decoration: InputDecoration(
                  labelText: l10n.boxes,
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: urgency,
          decoration: InputDecoration(
            labelText: l10n.urgency,
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: 'normal', child: Text('רגיל')),
            const DropdownMenuItem(value: 'urgent', child: Text('דחוף')),
            const DropdownMenuItem(
                value: 'very_urgent', child: Text('דחוף מאוד')),
          ],
          onChanged: (value) {
            if (value != null) {
              onUrgencyChanged(value);
            }
          },
        ),
      ],
    );
  }
}
