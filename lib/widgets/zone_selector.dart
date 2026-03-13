import 'package:flutter/material.dart';
import '../utils/zone_utils.dart';

/// Мульти-выбор зон доставки с цветными чипами
class ZoneSelector extends StatelessWidget {
  final List<String> selectedZones;
  final ValueChanged<List<String>> onChanged;
  final String locale;
  final String? errorText;

  const ZoneSelector({
    super.key,
    required this.selectedZones,
    required this.onChanged,
    this.locale = 'he',
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: ZoneUtils.allZones.map((zone) {
            final selected = selectedZones.contains(zone.id);
            return FilterChip(
              label: Text(
                zone.nameHe,
                style: TextStyle(
                  color: selected ? Colors.white : zone.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: selected,
              selectedColor: zone.color,
              checkmarkColor: Colors.white,
              backgroundColor: zone.color.withValues(alpha: 0.1),
              side: BorderSide(color: zone.color, width: 1.5),
              onSelected: (val) {
                final updated = List<String>.from(selectedZones);
                if (val) {
                  updated.add(zone.id);
                } else {
                  updated.remove(zone.id);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
